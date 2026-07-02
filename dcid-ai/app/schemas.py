"""Pydantic models — copy từ docs/API-CONTRACT.md §4 (giữ nguyên camelCase từng ký tự)."""

from typing import Literal
from uuid import UUID

from pydantic import BaseModel


class IngestRequest(BaseModel):
    """BE → AI (contract §1.1)."""

    versionId: UUID
    documentId: UUID
    storageKey: str
    langs: list[str] = ["vi", "en"]
    metadata: dict[str, str] = {}


class PageInfo(BaseModel):
    """Một trang trong ingest-callback (contract §1.2). imageKey nullable ở skeleton (chưa render ảnh)."""

    pageNo: int
    imageKey: str | None = None
    width: int | None = None
    height: int | None = None
    ocrText: str | None = None


class IngestCallback(BaseModel):
    """AI → BE: POST /api/internal/ingest-callback (contract §1.2)."""

    versionId: UUID
    status: Literal["READY", "FAILED"]
    pageCount: int | None = None
    pages: list[PageInfo] = []
    error: str | None = None


class QueryRequest(BaseModel):
    """BE → AI (contract §2.2)."""

    question: str
    topK: int = 5
    allowedVersionIds: list[UUID]
    machineCode: str | None = None


class Guard(BaseModel):
    locked: bool = False
    numericRule: bool = False


class Citation(BaseModel):
    versionId: UUID
    pageNo: int
    bboxKey: str | None = None
    snippet: str | None = None


class QueryResponse(BaseModel):
    """AI → BE (contract §2.2 response)."""

    answer: str
    confidence: float
    guard: Guard
    citations: list[Citation] = []
    latencyMs: int | None = None
    model: str | None = None


class HealthResponse(BaseModel):
    """GET /ai/health (contract §3)."""

    status: str = "ok"
    model_loaded: bool = False


class IngestAccepted(BaseModel):
    """202 body của POST /ai/ingest."""

    accepted: bool = True
