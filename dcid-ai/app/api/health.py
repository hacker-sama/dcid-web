"""GET /ai/health — readiness cho BE/compose (contract §3). KHÔNG cần token."""

from fastapi import APIRouter

from app.schemas import HealthResponse

router = APIRouter(prefix="/ai", tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    # model_loaded cố định False ở skeleton — đợt sau set True khi LLM đã nạp.
    return HealthResponse(status="ok", model_loaded=False)
