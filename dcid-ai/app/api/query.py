"""POST /ai/query — RAG pipeline thực tế kết nối ChromaDB + LM Studio.

Luồng xử lý được tách hoàn toàn sang app/services/query_service.py
để dễ unit test. Router này chỉ làm nhiệm vụ HTTP layer thuần túy:
- Xác thực token (dependency X-Internal-Token).
- Validate request schema (Pydantic).
- Delegate sang query_service.run_query().
- Trả về QueryResponse.

Xem chi tiết luồng RAG tại app/services/query_service.py và
app/pipeline/ (embed.py, index.py, guardrails.py, prompts.py).
"""

import logging

from fastapi import APIRouter, Depends

from app.schemas import QueryRequest, QueryResponse
from app.security import require_internal_token
from app.services import query_service

logger = logging.getLogger("dcid-ai.api.query")

router = APIRouter(prefix="/ai", tags=["query"], dependencies=[Depends(require_internal_token)])


@router.post("/query", response_model=QueryResponse)
def query(req: QueryRequest) -> QueryResponse:
    """Truy vấn RAG pipeline — embed → ChromaDB → guardrail → LM Studio → response.

    Request (contract §2.2):
        question:          Câu hỏi từ kỹ sư.
        topK:              Số chunk ChromaDB tối đa (mặc định 5).
        allowedVersionIds: Danh sách UUID phiên bản được phép truy cập (RBAC từ BE).
        machineCode:       (Tuỳ chọn) Mã máy để filter bổ sung.

    Response (contract §2.2):
        answer:      Câu trả lời sinh từ LM Studio.
        confidence:  Điểm similarity cao nhất từ ChromaDB (0.0–1.0).
        guard:       {locked, numericRule} — trạng thái guardrail.
        citations:   Danh sách trích dẫn trang từ ChromaDB hits.
        latencyMs:   Thời gian xử lý end-to-end (ms).
        model:       Tên model LM Studio đã dùng.
    """
    logger.info(
        "POST /ai/query: question=%s topK=%d versions=%d",
        req.question[:80], req.topK, len(req.allowedVersionIds),
    )
    return query_service.run_query(req)
