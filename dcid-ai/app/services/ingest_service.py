"""Ingest nền: MinIO → OCR (PaddleOCR) → chunk → embed → index (Qdrant) → callback BE.

Pipeline T2 (M1c):
  1. Tải PDF từ MinIO (storageKey).
  2. OCR từng trang: PyMuPDF rasterize + PaddleOCR nhận dạng.
  3. Chunk layout-aware: giữ bảng nguyên vẹn, sliding window cho text thường.
  4. Embed: multilingual-e5-small (passage prefix theo chuẩn E5).
  5. Upsert vào Qdrant collection `kcn_chunks` (idempotent theo version_id).
  6. Callback BE: READY (OCR + index thành công) hoặc FAILED (bất kỳ bước nào lỗi).

Ghi chú:
- imageKey vẫn None — render ảnh trang lên MinIO dành cho M3 (Flutter citation viewer).
- Mọi exception đều được bắt và chuyển thành callback FAILED để BE không bị treo.
"""

import logging

from app.clients import backend_client, minio_client, ocr_client
from app.pipeline import chunk as chunk_pipeline
from app.pipeline import embed as embed_pipeline
from app.pipeline import index as index_pipeline
from app.schemas import IngestCallback, IngestRequest, PageInfo

logger = logging.getLogger("dcid-ai.ingest")


def run_ingest(req: IngestRequest) -> None:
    """Chạy trong BackgroundTasks. Mọi lỗi → callback FAILED; callback lỗi → log, không crash."""
    try:
        # ── 1. OCR qua ai-ocr service (ai-ocr tự tải PDF từ MinIO) ─────────
        page_results = ocr_client.extract_pages(
            req.storageKey,
            req.langs,
            image_key_prefix=f"pages/{req.versionId}",
        )
        logger.info(
            "OCR OK: versionId=%s storageKey=%s pages=%d",
            req.versionId, req.storageKey, len(page_results),
        )

        # ── 3. Chunk layout-aware ────────────────────────────────
        chunks = chunk_pipeline.chunk_pages(page_results)
        logger.info(
            "Chunk OK: versionId=%s chunks=%d",
            req.versionId, len(chunks),
        )

        # ── 4. Embed (multilingual-e5-small) ─────────────────────
        texts = [c.text for c in chunks]
        embeddings = embed_pipeline.embed_texts(texts)
        logger.info(
            "Embed OK: versionId=%s vectors=%d dim=%d",
            req.versionId, len(embeddings),
            len(embeddings[0]) if embeddings else 0,
        )

        # ── 5. Upsert vào Qdrant ─────────────────────────────────
        index_pipeline.upsert_chunks(
            version_id=req.versionId,
            document_id=req.documentId,
            chunks=chunks,
            embeddings=embeddings,
            metadata=req.metadata,  # lang, machine_code, min_role … từ BE
        )

        # ── 6. Lưu ảnh trang lên MinIO & Callback READY ─────────
        pages_list = []
        for p in page_results:
            img_key = p.image_key
            if not img_key and p.image_bytes:
                img_key = f"pages/{req.versionId}/{p.page_no}.png"
                try:
                    minio_client.put_object(img_key, p.image_bytes, content_type="image/png")
                except Exception as exc:
                    logger.warning("Không thể lưu ảnh trang %s lên MinIO: %s", img_key, exc)
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

        callback = IngestCallback(
            versionId=req.versionId,
            status="READY",
            pageCount=len(page_results),
            pages=pages_list,
            error=None,
        )
        logger.info(
            "Ingest READY: versionId=%s pageCount=%d chunks=%d",
            req.versionId, len(page_results), len(chunks),
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
