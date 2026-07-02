"""Ingest nền (skeleton): MinIO → pypdf đếm trang → callback BE (work order §4.2).

Đợt sau thay phần mock bằng pipeline thật:
MinIO → app.pipeline.ocr → chunk → embed → index (Chroma) → render ảnh trang → callback.
"""

import io
import logging

from pypdf import PdfReader

from app.clients import backend_client, minio_client
from app.schemas import IngestCallback, IngestRequest, PageInfo

logger = logging.getLogger("dcid-ai.ingest")

SKELETON_OCR_TEXT = "[skeleton] chưa OCR"


def run_ingest(req: IngestRequest) -> None:
    """Chạy trong BackgroundTasks. Mọi lỗi → callback FAILED; callback lỗi → log, không crash."""
    try:
        pdf_bytes = minio_client.get_object(req.storageKey)
        page_count = _count_pages(pdf_bytes)
        callback = IngestCallback(
            versionId=req.versionId,
            status="READY",
            pageCount=page_count,
            pages=[
                PageInfo(
                    pageNo=page_no,
                    imageKey=None,  # TODO(đợt sau): render ảnh trang bằng poppler → MinIO
                    width=None,
                    height=None,
                    ocrText=SKELETON_OCR_TEXT,
                )
                for page_no in range(1, page_count + 1)
            ],
            error=None,
        )
        logger.info(
            "Ingest READY: versionId=%s storageKey=%s pageCount=%d",
            req.versionId, req.storageKey, page_count,
        )
    except Exception as exc:  # noqa: BLE001 — mọi lỗi đều phải chuyển thành FAILED
        logger.warning(
            "Ingest FAILED: versionId=%s storageKey=%s error=%s",
            req.versionId, req.storageKey, exc,
        )
        callback = IngestCallback(
            versionId=req.versionId,
            status="FAILED",
            pageCount=None,
            pages=[],
            error=str(exc),
        )

    _send_callback(callback)


def _count_pages(pdf_bytes: bytes) -> int:
    """Đếm số trang bằng pypdf; PDF hỏng sẽ raise và được chuyển thành FAILED."""
    reader = PdfReader(io.BytesIO(pdf_bytes))
    return len(reader.pages)


def _send_callback(callback: IngestCallback) -> None:
    """Gửi callback về BE; nếu chính callback lỗi thì chỉ log — service phải sống."""
    try:
        backend_client.post_ingest_callback(callback)
    except Exception as exc:  # noqa: BLE001
        logger.error(
            "Ingest callback FAILED (BE unreachable?): versionId=%s status=%s error=%s",
            callback.versionId, callback.status, exc,
        )
