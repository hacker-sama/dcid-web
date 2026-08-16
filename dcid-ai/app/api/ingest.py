"""Document ingestion endpoints."""

from fastapi import APIRouter, Depends, status

from app.schemas import IngestAccepted, IngestRequest
from app.security import require_internal_token
from app.workers.embed_worker import run_ingest_task

router = APIRouter(prefix="/ai", tags=["ingest"], dependencies=[Depends(require_internal_token)])


@router.post("/ingest", response_model=IngestAccepted, status_code=status.HTTP_202_ACCEPTED)
def ingest(req: IngestRequest) -> IngestAccepted:
    """Queue OCR, chunking, embedding and indexing, then return immediately."""
    task = run_ingest_task.delay(
        version_id=str(req.versionId),
        document_id=str(req.documentId),
        storage_key=req.storageKey,
        langs=req.langs,
        metadata=req.metadata,
    )
    return IngestAccepted(accepted=True, taskId=task.id)


@router.delete("/documents/{document_id}")
def delete_document_vector(document_id: str):
    """Delete all indexed vectors that belong to a document."""
    from src.vectordb import vector_store

    deleted_count = vector_store.delete_document_chunks(document_id=document_id)
    return {
        "status": "SUCCESS",
        "message": f"Đã xóa vector chunks cho document_id={document_id}",
        "documentId": document_id,
        "deletedChunks": deleted_count,
    }
