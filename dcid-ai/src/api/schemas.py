"""Pydantic schemas cho REST API Request / Response (FastAPI)."""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class IngestRequest(BaseModel):
    """Schema cho Yêu cầu Ingest tài liệu."""
    versionId: str = Field(..., description="UUID phiên bản tài liệu")
    documentId: str = Field(..., description="UUID tài liệu gốc")
    filepath: str = Field(..., description="Đường dẫn đến file trong uploads/")
    enableVision: bool = Field(default=True, description="Kích hoạt Qwen2-VL 2B Visual Worker")


class CitationItem(BaseModel):
    """Schema Trích dẫn chi tiết trả về cho UI Frontend."""
    pageNo: Optional[int] = None
    versionId: Optional[str] = None
    documentId: Optional[str] = None
    bbox: Optional[str] = None
    imagePath: Optional[str] = Field(None, description="Đường dẫn uploads/crops/ render ảnh crop lên UI")
    snippet: Optional[str] = None
    score: float = 0.0


class QueryRequest(BaseModel):
    """Schema Truy vấn RAG."""
    question: str = Field(..., description="Câu hỏi từ kỹ sư / người dùng")
    allowedVersionIds: List[str] = Field(..., description="Danh sách versionId được cấp quyền")
    topK: int = Field(default=5, description="Số lượng context chunks tối đa")
    reasoningMode: bool = Field(default=False, description="Bật chế độ suy luận chuyên sâu")


class QueryResponse(BaseModel):
    """Schema Kết quả trả về cho Query RAG."""
    answer: str
    citations: List[CitationItem]
    latencyMs: float
    model: str
