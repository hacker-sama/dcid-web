"""POST /ai/query — RAG pipeline thực tế kết nối Qdrant + Ollama.
POST /ai/query/stream — Streaming SSE variant: chữ hiện ra từng từ như ChatGPT.

Luồng xử lý được tách hoàn toàn sang app/services/query_service.py
để dễ unit test. Router này chỉ làm nhiệm vụ HTTP layer thuần túy:
- Xác thực token (dependency X-Internal-Token).
- Validate request schema (Pydantic).
- Delegate sang query_service.run_query() hoặc run_query_stream().
- Trả về QueryResponse (sync) hoặc StreamingResponse SSE (stream).

Xem chi tiết luồng RAG tại app/services/query_service.py và
app/pipeline/ (embed.py, index.py, guardrails.py, prompts.py).

SSE Event Format (cho /query/stream):
    data: {"event": "meta", "citations": [...], "confidence": 0.9, "guard": {...}}
    data: {"event": "delta", "text": "Đây là câu trả lời"}
    data: {"event": "done", "latencyMs": 1234, "model": "qwen2-vl-2b-instruct"}
    data: {"event": "error", "message": "Lỗi..."}
"""

import logging

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse

from app.schemas import QueryRequest, QueryResponse
from app.security import require_internal_token
from app.services import query_service

logger = logging.getLogger("dcid-ai.api.query")

router = APIRouter(prefix="/ai", tags=["query"], dependencies=[Depends(require_internal_token)])


@router.post("/query", response_model=QueryResponse)
def query(req: QueryRequest) -> QueryResponse:
    """Truy vấn RAG pipeline — embed → Qdrant → guardrail → Ollama → response.

    Request (contract §2.2):
        question:          Câu hỏi từ kỹ sư.
        topK:              Số chunk Qdrant tối đa (mặc định 5).
        allowedVersionIds: Danh sách UUID phiên bản được phép truy cập (RBAC từ BE).
        machineCode:       (Tuỳ chọn) Mã máy để filter bổ sung.

    Response (contract §2.2):
        answer:      Câu trả lời sinh từ LM Studio.
        confidence:  Điểm tổng hợp từ retrieval và bằng chứng ảnh/OCR (0.0–1.0).
        guard:       {locked, numericRule} — trạng thái guardrail.
        citations:   Danh sách trích dẫn trang từ Qdrant hits.
        latencyMs:   Thời gian xử lý end-to-end (ms).
        model:       Tên model LM Studio đã dùng.
    """
    logger.info(
        "POST /ai/query: question=%s topK=%d versions=%d",
        req.question[:80], req.topK, len(req.allowedVersionIds),
    )
    return query_service.run_query(req)


@router.post("/query/stream")
def query_stream(req: QueryRequest) -> StreamingResponse:
    """Streaming SSE variant — trả về Server-Sent Events, chữ hiện từng từ như ChatGPT.

    Giống /ai/query nhưng thay vì đợi LLM xong mới trả JSON,
    endpoint này stream từng token text về ngay khi LM Studio sinh ra.

    Client đọc SSE stream và xử lý từng event:
        - event "meta":  Nhận ngay citations/confidence/guard để hiển thị UI
        - event "delta": Append từng đoạn text vào khung chat
        - event "done":  Stream kết thúc, có latencyMs và model name
        - event "error": Lỗi xảy ra, message mô tả nguyên nhân

    Ví dụ đọc bằng cURL:
        curl -N -X POST http://localhost:8000/ai/query/stream \\
            -H "Content-Type: application/json" \\
            -H "X-Internal-Token: change-me-internal-token" \\
            -d '{"question":"...","allowedVersionIds":["..."]}'
    """
    logger.info(
        "POST /ai/query/stream: question=%s topK=%d versions=%d",
        req.question[:80], req.topK, len(req.allowedVersionIds),
    )
    return StreamingResponse(
        query_service.run_query_stream(req),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",    # Tắt Nginx buffering để SSE hoạt động đúng
            "Connection": "keep-alive",
        },
    )
