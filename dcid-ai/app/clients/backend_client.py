"""Client gọi ngược về dcid-backend (AI → BE), gắn X-Internal-Token (contract §0.3, §1.2)."""

import logging

import httpx

from app.config import get_settings
from app.schemas import IngestCallback, IngestStatusPush
from app.security import INTERNAL_TOKEN_HEADER

logger = logging.getLogger("dcid-ai.backend_client")

CALLBACK_PATH = "/api/internal/ingest-callback"
STATUS_PUSH_PATH = "/api/internal/ingest-status"
TIMEOUT_SECONDS = 30.0


def post_ingest_callback(payload: IngestCallback) -> None:
    """POST {BE_BASE_URL}/api/internal/ingest-callback — callback kết quả cuối cùng (READY/FAILED).

    Raises:
        httpx.HTTPError: lỗi mạng/timeout/status != 2xx — caller quyết định log,
            KHÔNG được để crash service.
    """
    s = get_settings()
    url = f"{s.be_base_url.rstrip('/')}{CALLBACK_PATH}"
    with httpx.Client(timeout=TIMEOUT_SECONDS) as client:
        response = client.post(
            url,
            content=payload.model_dump_json(),
            headers={
                "Content-Type": "application/json",
                INTERNAL_TOKEN_HEADER: s.ai_internal_token,
            },
        )
        response.raise_for_status()
    logger.info("Ingest callback OK: versionId=%s status=%s", payload.versionId, payload.status)


def post_ingest_status(payload: IngestStatusPush) -> None:
    """POST {BE_BASE_URL}/api/internal/ingest-status — push trạng thái từng bước xử lý.

    Được gọi bởi embed_worker tại mỗi giai đoạn:
        PROCESSING_OCR → PROCESSING_EMBED → PROCESSING_INDEX
    Cho phép BE/Flutter hiển thị thanh tiến độ mà không cần polling.

    Raises:
        httpx.HTTPError: lỗi mạng/timeout — caller (worker) bắt và chỉ log, không crash.
    """
    s = get_settings()
    url = f"{s.be_base_url.rstrip('/')}{STATUS_PUSH_PATH}"
    with httpx.Client(timeout=TIMEOUT_SECONDS) as client:
        response = client.post(
            url,
            content=payload.model_dump_json(),
            headers={
                "Content-Type": "application/json",
                INTERNAL_TOKEN_HEADER: s.ai_internal_token,
            },
        )
        response.raise_for_status()
    logger.debug(
        "Ingest status push OK: versionId=%s status=%s step=%s",
        payload.versionId, payload.status, payload.step,
    )
