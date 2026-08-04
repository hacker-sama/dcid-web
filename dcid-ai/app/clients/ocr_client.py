"""Client gọi ai-ocr service (HTTP) để thực hiện OCR PDF → pages.

ai-ocr chạy tại OCR_SERVICE_URL (env), expose POST /ocr với X-Internal-Token.
"""

import logging

import httpx

from app.config import get_settings
from app.pipeline.ocr import PageOcr
from app.security import INTERNAL_TOKEN_HEADER

logger = logging.getLogger("dcid-ai.ocr_client")

OCR_PATH = "/ocr"
TIMEOUT_SECONDS = 300.0  # OCR có thể chậm với PDF nhiều trang


def extract_pages(storage_key: str, langs: list[str] | None = None) -> list[PageOcr]:
    """Tải PDF từ MinIO và trích xuất chữ trực tiếp (PyMuPDF) không qua OCR HTTP service.

    Args:
        storage_key: key MinIO của file PDF.
        langs: danh sách ngôn ngữ (không bắt buộc).

    Returns:
        list[PageOcr] chứa văn bản tự nhiên + ảnh trang PNG.
    """
    from app.clients import minio_client
    from app.pipeline import ocr as ocr_pipeline

    logger.info("Tải PDF từ MinIO và trích xuất văn bản trực tiếp: storageKey=%s", storage_key)
    pdf_bytes = minio_client.get_object(storage_key)
    pages = ocr_pipeline.extract_pages(pdf_bytes, langs)
    logger.info("Đã trích xuất %d trang trực tiếp từ PDF %s", len(pages), storage_key)
    return pages
