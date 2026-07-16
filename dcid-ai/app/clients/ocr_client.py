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


def extract_pages(storage_key: str, langs: list[str]) -> list[PageOcr]:
    """Gọi ai-ocr service để OCR PDF từ MinIO.

    Args:
        storage_key: key MinIO của file PDF.
        langs: danh sách ngôn ngữ, ví dụ ["vi", "en"].

    Returns:
        list[PageOcr] mỗi phần tử là dataclass PageOcr

    Raises:
        httpx.HTTPError: lỗi kết nối / timeout / HTTP error.
        KeyError: response thiếu field bắt buộc.
    """
    s = get_settings()
    url = f"{s.ocr_service_url.rstrip('/')}{OCR_PATH}"
    payload = {"storageKey": storage_key, "langs": langs}

    logger.info("Gọi ai-ocr: url=%s storageKey=%s", url, storage_key)
    with httpx.Client(timeout=TIMEOUT_SECONDS) as client:
        resp = client.post(
            url,
            json=payload,
            headers={
                "Content-Type": "application/json",
                INTERNAL_TOKEN_HEADER: s.ai_internal_token,
            },
        )
        resp.raise_for_status()

    data = resp.json()
    raw_pages = data.get("pages", [])
    logger.info("ai-ocr trả về %d trang", len(raw_pages))

    pages: list[PageOcr] = []
    for item in raw_pages:
        pages.append(
            PageOcr(
                page_no=item["pageNo"],
                text=item["text"],
                width=item.get("width"),
                height=item.get("height"),
            )
        )
    return pages
