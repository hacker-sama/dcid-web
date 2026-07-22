"""Query Service — RAG Pipeline Orchestrator cho Smart KCN Docs.

Luồng xử lý (theo contract §2.2):
    1. Embed câu hỏi bằng multilingual-e5-small (prefix "query: ").
    2. Truy vấn ChromaDB với filter allowedVersionIds.
    3. Kiểm tra guardrail (cosine threshold + trigger phrase).
    4. Build system prompt + inject context chunks từ ChromaDB.
    5. Gọi LM Studio để sinh câu trả lời (gọi qua llm_client).
    6. Tính confidence từ điểm similarity tốt nhất.
    7. Trả về QueryResponse đúng schema contract.

Service này tách hoàn toàn business logic ra khỏi FastAPI router
để dễ unit test và tái sử dụng.
"""

from __future__ import annotations

import logging
import time
from uuid import UUID

from app.clients import llm_client
from app.clients.llm_client import LLMConnectionError, LLMInferenceError
from app.pipeline import embed as embed_pipeline
from app.pipeline import index as index_pipeline
from app.pipeline import guardrails
from app.pipeline import prompts
from app.schemas import Citation, Guard, QueryRequest, QueryResponse

logger = logging.getLogger("dcid-ai.query_service")

LOCKED_ANSWER = (
    "Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm."
)
LOCKED_CONFIDENCE = 0.30


def run_query(req: QueryRequest) -> QueryResponse:
    """Thực thi RAG pipeline đầy đủ cho một câu hỏi.

    Args:
        req: QueryRequest từ BE (question, topK, allowedVersionIds, machineCode).

    Returns:
        QueryResponse đúng contract §2.2 — luôn trả về, không raise.
        Khi LLM lỗi → trả về fallback locked response kèm error log.
    """
    start_ns = time.perf_counter()

    # ── 0. Fast-path: allowedVersionIds rỗng → không cần query chroma ──────
    if not req.allowedVersionIds:
        logger.info("Query bị khóa sớm: allowedVersionIds rỗng (question=%s)", req.question[:80])
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="guardrail-no-versions",
        )

    # ── 1. Embed câu hỏi ────────────────────────────────────────────────────
    try:
        query_vec = embed_pipeline.embed_query(req.question)
    except Exception as exc:
        logger.error("Embed câu hỏi thất bại: %s", exc)
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="error-embed",
        )

    # ── 2. Truy vấn ChromaDB ─────────────────────────────────────────────────
    try:
        hits = index_pipeline.search(
            query_embedding=query_vec,
            allowed_version_ids=req.allowedVersionIds,
            top_k=req.topK,
        )
    except Exception as exc:
        logger.error("ChromaDB search thất bại: %s", exc)
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="error-chroma",
        )

    logger.info(
        "ChromaDB: %d hits | top_score=%.3f | question=%s",
        len(hits),
        hits[0]["score"] if hits else 0.0,
        req.question[:80],
    )

    # ── 3. Guardrail — cosine threshold & trigger phrase ─────────────────────
    numeric_rule = guardrails.check_numeric(req.question)
    reasoning_mode = guardrails.check_reasoning_mode(req.question, explicit_flag=req.reasoningMode)
    locked       = guardrails.is_locked(hits, req.question, reasoning_mode=reasoning_mode)

    if locked:
        logger.info(
            "Guardrail LOCKED: top_score=%.3f threshold=%.2f numeric=%s reasoning=%s",
            hits[0]["score"] if hits else 0.0,
            guardrails.THRESHOLD,
            numeric_rule,
            reasoning_mode,
        )
        return QueryResponse(
            answer=LOCKED_ANSWER,
            confidence=LOCKED_CONFIDENCE,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits),   # trả hits để kỹ sư tự xem
            latencyMs=_elapsed_ms(start_ns),
            model="guardrail-locked",
        )

    # ── 4. Build Prompt ──────────────────────────────────────────────────────
    system_prompt = prompts.build_system_prompt(
        hits, numeric_rule=numeric_rule, reasoning_mode=reasoning_mode
    )
    user_prompt   = prompts.build_user_prompt(req.question, reasoning_mode=reasoning_mode, history=req.history)

    # ── 5. Gọi LM Studio ────────────────────────────────────────────────────
    try:
        answer_text, model_name = llm_client.generate_answer(system_prompt, user_prompt)
    except LLMConnectionError as exc:
        logger.error("LLM kết nối thất bại (LM Studio không chạy?): %s", exc)
        # Khi LM Studio chết → vẫn trả response nhưng là locked để BE không bị 503
        return QueryResponse(
            answer=(
                "Dịch vụ AI tạm thời không khả dụng (LM Studio chưa chạy). "
                "Vui lòng liên hệ quản trị viên hệ thống."
            ),
            confidence=0.0,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits),
            latencyMs=_elapsed_ms(start_ns),
            model="error-llm-connection",
        )
    except LLMInferenceError as exc:
        logger.error("LLM inference lỗi: %s", exc)
        return QueryResponse(
            answer=(
                "Mô hình AI gặp lỗi khi xử lý câu hỏi. "
                "Vui lòng thử lại hoặc đặt câu hỏi theo cách khác."
            ),
            confidence=0.0,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits),
            latencyMs=_elapsed_ms(start_ns),
            model="error-llm-inference",
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("Lỗi không xác định trong query pipeline: %s", exc)
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="error-unknown",
            numeric_rule=numeric_rule,
            reasoning_mode=reasoning_mode,
        )

    # ── 6. Tính confidence từ điểm similarity ────────────────────────────────────────
    confidence = round(hits[0]["score"], 4) if hits else 0.0

    # Kiểm tra blank answer (model 1.5B đôi khi trả rỗng sau khi bóc thẻ <think>)
    if not answer_text.strip():
        logger.warning(
            "LLM trả blank answer: model=%s confidence=%.3f — fall back locked message.",
            model_name, confidence,
        )
        return QueryResponse(
            answer="Mô hình AI không tạo được nội dung trả lời. "
                   "Vui lòng thử lại hoặc đặt câu hỏi theo cách khác.",
            confidence=confidence,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits),
            latencyMs=_elapsed_ms(start_ns),
            model=model_name,
        )

    # ── 7. Build Response ────────────────────────────────────────────────────
    citations = _build_citations(hits)

    logger.info(
        "Query OK: model=%s confidence=%.3f latency=%dms citations=%d reasoning=%s",
        model_name, confidence, _elapsed_ms(start_ns), len(citations), reasoning_mode,
    )

    return QueryResponse(
        answer=answer_text,
        confidence=confidence,
        guard=Guard(locked=False, numericRule=numeric_rule, reasoningMode=reasoning_mode),
        citations=citations,
        latencyMs=_elapsed_ms(start_ns),
        model=model_name,
    )


# ────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────

def _elapsed_ms(start_ns: float) -> int:
    """Tính số milliseconds từ thời điểm bắt đầu."""
    return int((time.perf_counter() - start_ns) * 1000)


def _locked_response(
    latency_ms: int,
    model: str,
    numeric_rule: bool = False,
    reasoning_mode: bool = False,
) -> QueryResponse:
    """Tạo QueryResponse cho trường hợp guardrail locked hoặc lỗi."""
    return QueryResponse(
        answer=LOCKED_ANSWER,
        confidence=LOCKED_CONFIDENCE,
        guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
        citations=[],
        latencyMs=latency_ms,
        model=model,
    )


def _build_citations(hits: list[dict]) -> list[Citation]:
    """Chuyển ChromaDB hits thành danh sách Citation đúng contract §2.2 kèm tọa độ Bbox (Spatial Mapping)."""
    citations: list[Citation] = []
    for hit in hits:
        try:
            version_uuid = UUID(str(hit["version_id"]))
        except (ValueError, KeyError):
            logger.warning("Bỏ qua hit có version_id không hợp lệ: %s", hit.get("version_id"))
            continue

        bbox_val = str(hit.get("bbox", "") or "").strip()
        bbox_key = f"p{hit.get('page_no', 1)}_[{bbox_val}]" if bbox_val and bbox_val != "N/A" else None
        snippet_val = str(hit.get("snippet", "") or hit.get("text", "") or "")[:300].strip()

        citations.append(
            Citation(
                versionId=version_uuid,
                pageNo=hit.get("page_no", 1),
                bboxKey=bbox_key,
                snippet=snippet_val or None,
            )
        )
    return citations
