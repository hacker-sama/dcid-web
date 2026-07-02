"""POST /ai/query — mock đồng bộ, deterministic (work order §4.3, contract §2.2).

Logic mock (bắt buộc giữ deterministic để backend/app/test dựa vào):
1. allowedVersionIds rỗng HOẶC câu hỏi chứa "không có trong tài liệu" → guardrail locked.
2. Câu hỏi chạm từ khóa số liệu (điện áp/áp suất/nhiệt độ/dung sai/momen/volt/voltage)
   → numeric rule (contract §2.2).
3. Còn lại → mock answer thường.
"""

import re
import time

from fastapi import APIRouter, Depends

from app.schemas import Citation, Guard, QueryRequest, QueryResponse
from app.security import require_internal_token

router = APIRouter(prefix="/ai", tags=["query"], dependencies=[Depends(require_internal_token)])

MODEL_NAME = "mock-skeleton"
LOCKED_ANSWER = (
    "Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm."
)
LOCKED_TRIGGER = "không có trong tài liệu"
NUMERIC_PATTERN = re.compile(
    r"điện áp|áp suất|nhiệt độ|dung sai|momen|volt|voltage", re.IGNORECASE
)


@router.post("/query", response_model=QueryResponse)
def query(req: QueryRequest) -> QueryResponse:
    start = time.perf_counter()
    question_lower = req.question.lower()

    if not req.allowedVersionIds or LOCKED_TRIGGER in question_lower:
        guard = Guard(locked=True, numericRule=False)
        answer = LOCKED_ANSWER
        confidence = 0.30
        citations: list[Citation] = []
    elif NUMERIC_PATTERN.search(req.question):
        guard = Guard(locked=False, numericRule=True)
        answer = "[MOCK-NUMERIC] Thông số trích xuất trực tiếp: 220V (nguồn: trang 1)"
        confidence = 0.90
        citations = [_mock_citation(req)]
    else:
        guard = Guard(locked=False, numericRule=False)
        answer = f"[MOCK] Trả lời cho câu hỏi: {req.question}"
        confidence = 0.75
        citations = [_mock_citation(req)]

    latency_ms = int((time.perf_counter() - start) * 1000)
    return QueryResponse(
        answer=answer,
        confidence=confidence,
        guard=guard,
        citations=citations,
        latencyMs=latency_ms,
        model=MODEL_NAME,
    )


def _mock_citation(req: QueryRequest) -> Citation:
    return Citation(
        versionId=req.allowedVersionIds[0],
        pageNo=1,
        bboxKey=None,
        snippet="[mock snippet]",
    )
