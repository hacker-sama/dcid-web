"""Client gọi ngược về dcid-backend (AI → BE), gắn X-Internal-Token (contract §0.3, §1.2)."""

import logging

import httpx

from app.config import get_settings
from app.schemas import IngestCallback
from app.security import INTERNAL_TOKEN_HEADER

logger = logging.getLogger("dcid-ai.backend_client")

CALLBACK_PATH = "/api/internal/ingest-callback"
TIMEOUT_SECONDS = 30.0


def post_ingest_callback(payload: IngestCallback) -> None:
    """POST {BE_BASE_URL}/api/internal/ingest-callback.

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
