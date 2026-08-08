from types import SimpleNamespace
from unittest.mock import MagicMock

from app.services import resource_gate


def _settings():
    return SimpleNamespace(
        ai_resource_gate_enabled=True,
        ai_resource_gate_fail_open=False,
        ai_resource_lock_name="test:heavy",
        ai_resource_lock_wait_seconds=1,
        ai_resource_lock_lease_seconds=60,
    )


def test_serialized_regular_call_acquires_and_releases(monkeypatch):
    lock = MagicMock()
    lock.acquire.return_value = True
    client = MagicMock()
    client.lock.return_value = lock
    monkeypatch.setattr(resource_gate, "get_settings", _settings)
    monkeypatch.setattr(resource_gate, "_redis_client", lambda: client)

    @resource_gate.serialized_heavy("unit-test")
    def work(value):
        return value + 1

    assert work(4) == 5
    lock.acquire.assert_called_once_with(blocking=True)
    lock.release.assert_called_once()


def test_nested_stream_reuses_current_slot(monkeypatch):
    lock = MagicMock()
    lock.acquire.return_value = True
    client = MagicMock()
    client.lock.return_value = lock
    monkeypatch.setattr(resource_gate, "get_settings", _settings)
    monkeypatch.setattr(resource_gate, "_redis_client", lambda: client)

    @resource_gate.serialized_heavy("inner")
    def inner():
        return "ok"

    @resource_gate.serialized_heavy("outer")
    def stream():
        yield inner()

    assert list(stream()) == ["ok"]
    assert lock.acquire.call_count == 1
    assert lock.release.call_count == 1
