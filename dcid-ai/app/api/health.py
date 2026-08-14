"""GET /ai/health — readiness cho BE/compose (contract §3). KHÔNG cần token.

model_loaded: True khi Ollama đang chạy và model đã sẵn sàng phản hồi.
Probe nhanh bằng llm_client.is_available() — max_tokens=1, không ảnh hưởng hiệu năng.
"""

import logging

from fastapi import APIRouter

from app.clients import llm_client
from app.schemas import HealthResponse

logger = logging.getLogger("dcid-ai.api.health")

router = APIRouter(prefix="/ai", tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Kiểm tra trạng thái service — probe Ollama để báo model_loaded."""
    model_loaded = llm_client.is_available()
    if model_loaded:
        logger.debug("Health check: Ollama OK")
    else:
        logger.warning("Health check: Ollama không phản hồi — model_loaded=False")
    return HealthResponse(status="ok", model_loaded=model_loaded)
