"""Cross-process gate for memory-heavy AI work on small CPU-only hosts."""

from __future__ import annotations

import logging
import threading
from contextlib import contextmanager
from functools import lru_cache, wraps
from inspect import isgeneratorfunction
from typing import Callable, Iterator, TypeVar

from app.config import get_settings

logger = logging.getLogger("dcid-ai.resource_gate")

F = TypeVar("F", bound=Callable)
_local = threading.local()


class ResourceBusyError(TimeoutError):
    """Raised when the single heavy-AI slot cannot be acquired in time."""


@lru_cache(maxsize=1)
def _redis_client():
    import redis

    return redis.Redis.from_url(
        get_settings().redis_url,
        socket_connect_timeout=2,
        socket_timeout=2,
        health_check_interval=30,
    )


@contextmanager
def heavy_ai_slot(operation: str) -> Iterator[None]:
    """Serialize OCR, embeddings and LLM inference across all containers."""
    settings = get_settings()
    if not settings.ai_resource_gate_enabled:
        yield
        return

    depth = getattr(_local, "heavy_depth", 0)
    if depth:
        _local.heavy_depth = depth + 1
        try:
            yield
        finally:
            _local.heavy_depth -= 1
        return

    try:
        client = _redis_client()
        client.ping()
    except Exception as exc:  # noqa: BLE001
        if settings.ai_resource_gate_fail_open:
            logger.warning("Resource gate unavailable; running %s without lock: %s", operation, exc)
            yield
            return
        raise ResourceBusyError("AI resource coordinator is unavailable") from exc

    lease_seconds = max(60, settings.ai_resource_lock_lease_seconds)
    lock = client.lock(
        settings.ai_resource_lock_name,
        timeout=lease_seconds,
        blocking_timeout=max(0, settings.ai_resource_lock_wait_seconds),
        # Heartbeat renews the lease from another thread, so share the token.
        thread_local=False,
    )
    if not lock.acquire(blocking=True):
        raise ResourceBusyError(
            f"AI resources are busy; could not start {operation} within "
            f"{settings.ai_resource_lock_wait_seconds}s"
        )

    stop_heartbeat = threading.Event()

    def _renew() -> None:
        while not stop_heartbeat.wait(max(20, lease_seconds // 3)):
            try:
                lock.extend(lease_seconds, replace_ttl=True)
            except Exception as exc:  # noqa: BLE001
                logger.error("Could not renew AI resource lease for %s: %s", operation, exc)
                return

    heartbeat = threading.Thread(target=_renew, name="ai-resource-lease", daemon=True)
    heartbeat.start()
    _local.heavy_depth = 1
    logger.info("Heavy AI slot acquired: %s", operation)
    try:
        yield
    finally:
        _local.heavy_depth = 0
        stop_heartbeat.set()
        heartbeat.join(timeout=2)
        try:
            lock.release()
        except Exception as exc:  # noqa: BLE001
            logger.warning("Could not release AI resource slot for %s: %s", operation, exc)
        logger.info("Heavy AI slot released: %s", operation)


def serialized_heavy(operation: str) -> Callable[[F], F]:
    """Hold the shared slot for a regular function or a streaming generator."""

    def decorator(func: F) -> F:
        if isgeneratorfunction(func):
            @wraps(func)
            def generator_wrapper(*args, **kwargs):
                with heavy_ai_slot(operation):
                    yield from func(*args, **kwargs)

            return generator_wrapper  # type: ignore[return-value]

        @wraps(func)
        def wrapper(*args, **kwargs):
            with heavy_ai_slot(operation):
                return func(*args, **kwargs)

        return wrapper  # type: ignore[return-value]

    return decorator
