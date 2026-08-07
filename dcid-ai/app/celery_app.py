"""Celery application singleton cho dcid-ai.

Tách ra file riêng để tránh circular import giữa workers và API.
Workers import từ đây; FastAPI app chỉ cần import khi dispatch task.

Chạy worker (trong container hoặc local):
    celery -A app.celery_app.celery_app worker --loglevel=info --concurrency=2

Chạy Flower monitoring UI:
    celery -A app.celery_app.celery_app flower --port=5555
"""

from __future__ import annotations

import logging

from celery import Celery

from app.config import get_settings

logger = logging.getLogger("dcid-ai.celery")


def _make_celery() -> Celery:
    """Khởi tạo và cấu hình Celery app — gọi 1 lần tại module import."""
    s = get_settings()

    app = Celery(
        "dcid-ai",
        broker=s.redis_url,
        backend=s.redis_url,
        include=["app.workers.embed_worker"],
    )

    app.conf.update(
        # Serialization — dùng JSON để human-readable, không cần pickle
        task_serializer="json",
        result_serializer="json",
        accept_content=["json"],
        # Timezone
        timezone="Asia/Ho_Chi_Minh",
        enable_utc=True,
        # Reliability
        task_acks_late=True,             # Chỉ ack sau khi task hoàn thành — không mất job khi worker restart
        worker_prefetch_multiplier=1,    # Mỗi worker chỉ nhận 1 task/lần — tránh OOM khi embed model nặng
        task_reject_on_worker_lost=True, # Reject (requeue) task nếu worker đột ngột chết
        # Restore unacked Redis tasks after five minutes instead of one hour.
        broker_transport_options={"visibility_timeout": 300},
        # Timeouts
        task_soft_time_limit=s.celery_task_soft_time_limit,
        task_time_limit=s.celery_task_time_limit,
        # Result expiry — giữ kết quả 24h để /status có thể query
        result_expires=86400,
        # Routing — ingest task đi vào queue "ingest" riêng biệt
        task_routes={
            "dcid_ai.tasks.run_ingest": {"queue": "ingest"},
        },
        task_default_queue="default",
    )

    logger.info(
        "Celery khởi tạo: broker=%s include=%s",
        s.redis_url, ["app.workers.embed_worker"],
    )
    return app


celery_app = _make_celery()
