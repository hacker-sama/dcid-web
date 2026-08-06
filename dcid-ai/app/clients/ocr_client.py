"""HTTP client for the dedicated PaddleOCR sidecar, with a native-text fallback."""

import logging

import httpx

from app.config import get_settings
from app.pipeline.ocr import PageOcr
from app.security import INTERNAL_TOKEN_HEADER

logger = logging.getLogger("dcid-ai.ocr_client")

OCR_PATH = "/ocr"
TIMEOUT_SECONDS = 300.0  # OCR có thể chậm với PDF nhiều trang


def extract_pages(
    storage_key: str,
    langs: list[str] | None = None,
    image_key_prefix: str | None = None,
) -> list[PageOcr]:
    """Extract pages through ai-ocr; fall back to local PyMuPDF if it is unavailable.

    Args:
        storage_key: key MinIO của file PDF.
        langs: danh sách ngôn ngữ (không bắt buộc).

    Returns:
        list[PageOcr] containing OCR text, bboxes and optional MinIO page image keys.
    """
    settings = get_settings()
    payload = {
        "storageKey": storage_key,
        "langs": langs or ["vi", "en"],
        "imageKeyPrefix": image_key_prefix,
    }
    headers = {INTERNAL_TOKEN_HEADER: settings.ai_internal_token}

    try:
        response = httpx.post(
            f"{settings.ocr_service_url.rstrip('/')}{OCR_PATH}",
            json=payload,
            headers=headers,
            timeout=TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        body = response.json()
        pages = [
            PageOcr(
                page_no=int(item["pageNo"]),
                text=str(item.get("text") or ""),
                width=item.get("width"),
                height=item.get("height"),
                boxes=[tuple(float(v) for v in box[:4]) for box in item.get("boxes", [])],
                image_key=item.get("imageKey"),
            )
            for item in body.get("pages", [])
        ]
        logger.info("OCR sidecar OK: storageKey=%s pages=%d", storage_key, len(pages))
        return pages
    except Exception as exc:
        logger.warning("OCR sidecar unavailable, falling back to local text extraction: %s", exc)
        from app.clients import minio_client
        from app.pipeline import ocr as ocr_pipeline

        data = minio_client.get_object(storage_key)
        return ocr_pipeline.extract_pages(data, langs)
