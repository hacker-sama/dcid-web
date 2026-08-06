"""FastAPI Routes cho REST API hệ thống DCID AI."""

import json
import logging
import time
from typing import Any, Dict, List

from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import StreamingResponse

from src.api import schemas
from src.chunking import chunker
from src.embeddings import embedder
from src.ingestion import loader, ocr_engine
from src.llm import llm_client
from src.prompts import prompt_templates
from src.retrieval import retriever
from src.vectordb import vector_store

logger = logging.getLogger("dcid-ai.routes")

router = APIRouter(prefix="/api", tags=["DCID AI API"])


def _run_ingest_background(req: schemas.IngestRequest):
    """Hàm chạy Ingestion trong BackgroundTask."""
    try:
        pdf_bytes, _ = loader.load_file_bytes(req.filepath)
        page_results = ocr_engine.process_pdf_pages(
            pdf_bytes=pdf_bytes,
            version_id=req.versionId,
            enable_vision=req.enableVision,
            skip_pure_text_pages=True,
        )

        chunks = chunker.chunk_pages(page_results)
        texts = [c.text for c in chunks]
        embeddings = embedder.embed_texts(texts)

        vector_store.upsert_chunks(
            version_id=req.versionId,
            document_id=req.documentId,
            chunks=chunks,
            embeddings=embeddings,
        )
        logger.info("Ingest thanh cong cho versionId=%s chunks=%d", req.versionId, len(chunks))
    except Exception as exc:
        logger.error("Ingest FAILED cho versionId=%s: %s", req.versionId, exc)


@router.post("/ingest")
def ingest_document(req: schemas.IngestRequest, background_tasks: BackgroundTasks):
    """POST /api/ingest — Nạp & đọc file (PDF/Scan), chạy OCR, Visual Crop, Qwen2-VL 2B, embed & index vào ChromaDB."""
    background_tasks.add_task(_run_ingest_background, req)
    return {
        "status": "PROCESSING",
        "message": "Đã nhận yêu cầu Ingestion và đang xử lý ngầm.",
        "versionId": req.versionId,
    }


@router.post("/query", response_model=schemas.QueryResponse)
def query_rag(req: schemas.QueryRequest):
    """POST /api/query — Truy vấn RAG từ ChromaDB -> Main Text LLM -> Trả câu trả lời kèm citations (imagePath)."""
    start_t = time.time()

    hits, citations = retriever.retrieve_context(
        question=req.question,
        allowed_version_ids=req.allowedVersionIds,
        top_k=req.topK,
    )

    sys_prompt = prompt_templates.build_system_prompt(reasoning_mode=req.reasoningMode)
    user_prompt = prompt_templates.build_user_prompt(question=req.question, hits=hits)

    answer, model_used = llm_client.generate_rag_answer(
        system_prompt=sys_prompt,
        user_prompt=user_prompt,
    )

    latency = round((time.time() - start_t) * 1000, 2)

    return schemas.QueryResponse(
        answer=answer,
        citations=[schemas.CitationItem(**c) for c in citations],
        latencyMs=latency,
        model=model_used,
    )


@router.post("/query/stream")
def query_rag_stream(req: schemas.QueryRequest):
    """POST /api/query/stream — Streaming SSE variant trả từng từ cho UI."""
    hits, citations = retriever.retrieve_context(
        question=req.question,
        allowed_version_ids=req.allowedVersionIds,
        top_k=req.topK,
    )

    sys_prompt = prompt_templates.build_system_prompt(reasoning_mode=req.reasoningMode)
    user_prompt = prompt_templates.build_user_prompt(question=req.question, hits=hits)

    def event_generator():
        yield f"data: {json.dumps({'event': 'meta', 'citations': citations})}\n\n"

        for token in llm_client.generate_rag_answer_stream(
            system_prompt=sys_prompt,
            user_prompt=user_prompt,
        ):
            yield f"data: {json.dumps({'event': 'delta', 'text': token})}\n\n"

        yield f"data: {json.dumps({'event': 'done'})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )


@router.get("/health")
def health_check():
    """GET /api/health — Health check service status."""
    return {
        "status": "UP",
        "service": "DCID AI Python Service",
        "vector_store": "ChromaDB Persistent Local DB",
        "vision_model": "qwen2.5vl:3b",
    }


@router.delete("/documents/{document_id}")
def delete_document(document_id: str):
    """DELETE /api/documents/{document_id} — Xóa toàn bộ vector chunks và file crop của tài liệu."""
    deleted_count = vector_store.delete_document_chunks(document_id=document_id)
    return {
        "status": "SUCCESS",
        "message": f"Đã xóa toàn bộ vector chunks cho documentId={document_id}",
        "documentId": document_id,
        "deletedChunks": deleted_count,
    }
