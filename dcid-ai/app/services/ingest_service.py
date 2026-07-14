"""Ingest nền: MinIO → OCR thật (PaddleOCR) → callback BE (work order §4.2).

Đợt sau: chunk → embed → index (Chroma); render + upload ảnh trang lên MinIO
(imageKey hiện vẫn None — cần cho viewer/bbox citation, chưa nằm trong OCR spike này).
"""

import logging

from app.clients import backend_client, minio_client
from app.pipeline import ocr
from app.schemas import IngestCallback, IngestRequest, PageInfo

logger = logging.getLogger("dcid-ai.ingest")


def run_ingest(req: IngestRequest) -> None:
    """Chạy trong BackgroundTasks. Mọi lỗi → callback FAILED; callback lỗi → log, không crash."""
    try:
        pdf_bytes = minio_client.get_object(req.storageKey)
        page_results = ocr.extract_pages(pdf_bytes, req.langs)
        callback = IngestCallback(
            versionId=req.versionId,
            status="READY",
            pageCount=len(page_results),
            pages=[
                PageInfo(
                    pageNo=p.page_no,
                    imageKey=None,  # TODO(đợt sau): render ảnh trang → MinIO cho viewer/bbox
                    width=p.width,
                    height=p.height,
                    ocrText=p.text,
                )
                for p in page_results
            ],
            error=None,
        )
        logger.info(
            "Ingest READY: versionId=%s storageKey=%s pageCount=%d",
            req.versionId, req.storageKey, len(page_results),
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


def _send_callback(callback: IngestCallback) -> None:
    """Gửi callback về BE; nếu chính callback lỗi thì chỉ log — service phải sống."""
    try:
        backend_client.post_ingest_callback(callback)
    except Exception as exc:  # noqa: BLE001
        logger.error(
            "Ingest callback FAILED (BE unreachable?): versionId=%s status=%s error=%s",
            callback.versionId, callback.status, exc,
        )
