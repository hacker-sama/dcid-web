"""POST /ai/ingest — nhận job, trả 202 ngay, xử lý nền bằng BackgroundTasks (contract §1.1)."""

from fastapi import APIRouter, BackgroundTasks, Depends, status

from app.schemas import IngestAccepted, IngestRequest
from app.security import require_internal_token
from app.services.ingest_service import run_ingest

router = APIRouter(prefix="/ai", tags=["ingest"], dependencies=[Depends(require_internal_token)])


@router.post("/ingest", response_model=IngestAccepted, status_code=status.HTTP_202_ACCEPTED)
def ingest(req: IngestRequest, background_tasks: BackgroundTasks) -> IngestAccepted:
    background_tasks.add_task(run_ingest, req)
    return IngestAccepted(accepted=True)
