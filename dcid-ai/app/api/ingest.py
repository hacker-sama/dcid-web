"""POST /ai/ingest — nhận job, trả 202 ngay kèm taskId, xử lý nền bằng Celery (contract §1.1)."""

from fastapi import APIRouter, Depends, status

from app.schemas import IngestAccepted, IngestRequest
from app.security import require_internal_token
from app.workers.embed_worker import run_ingest_task

router = APIRouter(prefix="/ai", tags=["ingest"], dependencies=[Depends(require_internal_token)])


@router.post("/ingest", response_model=IngestAccepted, status_code=status.HTTP_202_ACCEPTED)
def ingest(req: IngestRequest) -> IngestAccepted:
    """Nhận yêu cầu ingest, đẩy vào Celery queue và trả 202 ngay.

    Celery Worker (`ai-worker` container) sẽ xử lý bất đồng bộ:
        OCR (via ai-ocr service) → Chunk → Embed → Upsert ChromaDB → Callback BE

    Trạng thái có thể theo dõi qua:
        - GET /ai/status/{taskId}  — polling trạng thái Celery
        - POST /api/internal/ingest-status (BE) — push callback tại mỗi bước
    """
    task = run_ingest_task.delay(
        version_id=str(req.versionId),
        document_id=str(req.documentId),
        storage_key=req.storageKey,
        langs=req.langs,
        metadata=req.metadata,
    )
    return IngestAccepted(accepted=True, taskId=task.id)
