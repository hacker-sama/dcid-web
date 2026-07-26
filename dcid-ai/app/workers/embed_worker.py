"""Celery Worker — Ingest Pipeline: OCR → Chunk → Embed → ChromaDB → Callback.

Worker này được chạy như một tiến trình riêng biệt (container `ai-worker`),
tách hoàn toàn khỏi FastAPI API server. Việc tách giúp:
  - Embed model (470MB) chỉ nạp 1 lần trong worker process, không chiếm RAM của API.
  - API server phản hồi tức thì (202), không bao giờ bị block bởi OCR/Embed.
  - Retry tự động khi lỗi mạng/timeout (max 3 lần, backoff).
  - Callback push trạng thái về BE tại mỗi bước — không cần polling.

Task state flow:
    PENDING → PROCESSING_OCR → PROCESSING_EMBED → PROCESSING_INDEX → SUCCESS | FAILURE
"""

from __future__ import annotations

import logging
from uuid import UUID

from celery import Task
from celery.exceptions import SoftTimeLimitExceeded

from app.celery_app import celery_app
from app.clients import backend_client, minio_client, ocr_client
from app.pipeline import chunk as chunk_pipeline
from app.pipeline import embed as embed_pipeline
from app.pipeline import index as index_pipeline
from app.schemas import IngestCallback, IngestStatusPush, PageInfo

logger = logging.getLogger("dcid-ai.workers.embed")


# ────────────────────────────────────────────────────────────────────────────
# Helper: callback push từng bước về Backend
# ────────────────────────────────────────────────────────────────────────────

def _push_status(
    version_id: str,
    status: str,
    step: str,
    *,
    page_count: int | None = None,
    chunk_count: int | None = None,
    error: str | None = None,
) -> None:
    """Push trạng thái xử lý về BE tại mỗi bước — không raise nếu BE unreachable."""
    payload = IngestStatusPush(
        versionId=UUID(version_id),
        status=status,
        step=step,
        pageCount=page_count,
        chunkCount=chunk_count,
        error=error,
    )
    try:
        backend_client.post_ingest_status(payload)
        logger.debug("Status push OK: versionId=%s status=%s step=%s", version_id, status, step)
    except Exception as exc:  # noqa: BLE001
        # Callback lỗi không được làm crash worker — chỉ log
        logger.warning(
            "Status push FAILED (BE unreachable?): versionId=%s step=%s error=%s",
            version_id, step, exc,
        )


# ────────────────────────────────────────────────────────────────────────────
# Celery Task
# ────────────────────────────────────────────────────────────────────────────

@celery_app.task(
    bind=True,
    name="dcid_ai.tasks.run_ingest",
    queue="ingest",
    max_retries=3,
    default_retry_delay=60,      # retry sau 60s
    autoretry_for=(OSError, ConnectionError),  # Retry chỉ lỗi hạ tầng — không retry lỗi business
    retry_backoff=True,          # Exponential backoff: 60s, 120s, 240s
    retry_backoff_max=300,       # Backoff tối đa 5 phút
    retry_jitter=True,           # Thêm jitter để tránh thundering herd
)
def run_ingest_task(
    self: Task,
    version_id: str,
    document_id: str,
    storage_key: str,
    langs: list[str],
    metadata: dict[str, str],
) -> dict:
    """Celery Task: Orchestrate toàn bộ ingest pipeline bất đồng bộ.

    Args:
        version_id:   UUID (str) của phiên bản tài liệu.
        document_id:  UUID (str) của tài liệu gốc.
        storage_key:  MinIO object key của file PDF.
        langs:        Danh sách ngôn ngữ OCR, ví dụ ["vi", "en"].
        metadata:     Dict bổ sung từ BE (lang, machine_code, min_role…).

    Returns:
        Dict kết quả khi SUCCESS: {status, pages, chunks, task_id}.

    Side effects:
        - Push trạng thái về BE tại mỗi bước (callback push).
        - Upsert vectors vào ChromaDB.
        - Gửi IngestCallback READY/FAILED về BE khi hoàn tất.
    """
    task_id = self.request.id
    logger.info(
        "Ingest task START: taskId=%s versionId=%s storageKey=%s",
        task_id, version_id, storage_key,
    )

    try:
        # ── Bước 1: OCR ─────────────────────────────────────────────────────
        self.update_state(
            state="PROCESSING_OCR",
            meta={"step": "OCR", "version_id": version_id},
        )
        _push_status(version_id, "PROCESSING_OCR", "OCR")

        page_results = ocr_client.extract_pages(storage_key, langs)
        page_count = len(page_results)

        logger.info(
            "Ingest task OCR OK: taskId=%s versionId=%s pages=%d",
            task_id, version_id, page_count,
        )
        _push_status(version_id, "PROCESSING_EMBED", "EMBED", page_count=page_count)

        # ── Bước 2: Chunk ────────────────────────────────────────────────────
        self.update_state(
            state="PROCESSING_EMBED",
            meta={"step": "Chunk+Embed", "version_id": version_id, "pages": page_count},
        )

        chunks = chunk_pipeline.chunk_pages(page_results)
        texts = [c.text for c in chunks]
        chunk_count = len(chunks)
        logger.info(
            "Ingest task CHUNK OK: taskId=%s versionId=%s chunks=%d",
            task_id, version_id, chunk_count,
        )

        # ── Bước 3: Embed ────────────────────────────────────────────────────
        embeddings = embed_pipeline.embed_texts(texts)
        logger.info(
            "Ingest task EMBED OK: taskId=%s versionId=%s vectors=%d dim=%d",
            task_id, version_id, len(embeddings),
            len(embeddings[0]) if embeddings else 0,
        )
        _push_status(version_id, "PROCESSING_INDEX", "INDEX", page_count=page_count, chunk_count=chunk_count)

        # ── Bước 4: Upsert ChromaDB ──────────────────────────────────────────
        self.update_state(
            state="PROCESSING_INDEX",
            meta={"step": "Upsert ChromaDB", "version_id": version_id, "chunks": chunk_count},
        )

        index_pipeline.upsert_chunks(
            version_id=UUID(version_id),
            document_id=UUID(document_id),
            chunks=chunks,
            embeddings=embeddings,
            metadata=metadata,
        )
        logger.info(
            "Ingest task INDEX OK: taskId=%s versionId=%s chunks=%d",
            task_id, version_id, chunk_count,
        )

        # ── Bước 5: Lưu ảnh trang lên MinIO & Callback READY ─────────
        pages_list = []
        for p in page_results:
            img_key = f"pages/{version_id}/{p.page_no}.png"
            if p.image_bytes:
                try:
                    minio_client.put_object(img_key, p.image_bytes, content_type="image/png")
                except Exception as exc:
                    logger.warning("Worker không thể lưu ảnh trang %s lên MinIO: %s", img_key, exc)
                    img_key = None
            else:
                img_key = None
            pages_list.append(
                PageInfo(
                    pageNo=p.page_no,
                    imageKey=img_key,
                    width=p.width,
                    height=p.height,
                    ocrText=p.text,
                )
            )

        final_callback = IngestCallback(
            versionId=UUID(version_id),
            status="READY",
            pageCount=page_count,
            pages=pages_list,
            error=None,
        )
        backend_client.post_ingest_callback(final_callback)

        logger.info(
            "Ingest task READY: taskId=%s versionId=%s pages=%d chunks=%d",
            task_id, version_id, page_count, chunk_count,
        )
        return {
            "status": "READY",
            "version_id": version_id,
            "task_id": task_id,
            "pages": page_count,
            "chunks": chunk_count,
        }

    except SoftTimeLimitExceeded:
        # Hết soft time limit — cleanup và gửi FAILED về BE
        logger.error(
            "Ingest task SOFT TIMEOUT: taskId=%s versionId=%s (giới hạn %ds)",
            task_id, version_id, self.soft_time_limit,
        )
        _push_status(version_id, "FAILED", "TIMEOUT", error="Task vượt quá thời gian xử lý tối đa.")
        _send_failed_callback(version_id, "Task timeout — vượt quá giới hạn xử lý.")
        raise  # Re-raise để Celery ghi state FAILURE

    except Exception as exc:  # noqa: BLE001
        logger.error(
            "Ingest task FAILED: taskId=%s versionId=%s error=%s",
            task_id, version_id, exc, exc_info=True,
        )
        _push_status(version_id, "FAILED", "ERROR", error=str(exc))
        _send_failed_callback(version_id, str(exc))
        # Không retry lỗi business (PDF hỏng, chunk rỗng…) — raise để ghi FAILURE
        raise


def _send_failed_callback(version_id: str, error_message: str) -> None:
    """Gửi IngestCallback FAILED về BE — không raise nếu lỗi."""
    try:
        backend_client.post_ingest_callback(
            IngestCallback(
                versionId=UUID(version_id),
                status="FAILED",
                pageCount=None,
                pages=[],
                error=error_message,
            )
        )
    except Exception as exc:  # noqa: BLE001
        logger.error(
            "FAILED callback cũng lỗi (BE unreachable?): versionId=%s error=%s",
            version_id, exc,
        )
