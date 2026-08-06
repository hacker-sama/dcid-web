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
from app.config import get_settings
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

    # ── 0.5. Vision Query: Tải ảnh base64 từ MinIO & OCR (nếu có) ──────────────
    image_base64: str | None = None
    if req.imageStorageKey:
        try:
            from app.clients import minio_client, ocr_client
            logger.info("Vision Query: đang tải ảnh base64 & OCR file ảnh %s", req.imageStorageKey)
            image_base64 = minio_client.get_object_base64(req.imageStorageKey)
            pages = ocr_client.extract_pages(req.imageStorageKey, ["vi", "en"])
            image_text = "\n".join(p.text for p in pages if p.text)
            if image_text:
                req.question = f"{req.question}\n[Thông tin từ OCR ảnh chụp]:\n{image_text}"
                logger.info("Đã nối text OCR từ ảnh vào câu hỏi (%d ký tự)", len(image_text))
        except Exception as exc:
            logger.error("Xử lý Vision Query ảnh %s thất bại: %s", req.imageStorageKey, exc)

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
            machine_code=req.machineCode,
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
            citations=_build_citations(hits, locked=True),   # trả hits để kỹ sư tự xem, nhưng ẩn snippet
            latencyMs=_elapsed_ms(start_ns),
            model="guardrail-locked",
        )

    # Nếu chưa có image_base64 từ SnapAsk, tự động bốc/dựng ảnh trang PDF của kết quả top 1 từ MinIO
    if not image_base64 and hits:
        top_hit = hits[0]
        top_v_id = top_hit.get("version_id")
        top_doc_id = top_hit.get("document_id")
        top_p_no = top_hit.get("page_no", 1)
        if top_v_id:
            page_img_key = f"pages/{top_v_id}/{top_p_no}.png"
            try:
                from app.clients import minio_client
                image_base64 = minio_client.get_or_render_page_base64(
                    page_img_key=page_img_key,
                    version_id=top_v_id,
                    document_id=top_doc_id,
                    page_no=int(top_p_no) if str(top_p_no).isdigit() else 1,
                )
                if image_base64:
                    logger.info("Auto-Vision RAG: Đã bốc/dựng ảnh trang bản vẽ %s truyền sang Vision LLM", page_img_key)
            except Exception as exc:
                logger.warning("Không thể lấy/dựng ảnh trang %s: %s", page_img_key, exc)

    # ── 4. Build Prompt ──────────────────────────────────────────────────────
    has_img = bool(image_base64)
    if has_img:
        logger.info("Vision LLM Mode: Đã kích hoạt Vision Prompt đa thức thể kèm dữ liệu hình ảnh Base64")

    system_prompt = prompts.build_system_prompt(numeric_rule=numeric_rule, reasoning_mode=reasoning_mode, has_image=has_img)
    user_prompt = prompts.build_user_prompt(req.question, hits, reasoning_mode=reasoning_mode, history=req.history, has_image=has_img, machine_code=req.machineCode)

    # ── 5. Gọi LM Studio ────────────────────────────────────────────────────
    try:
        answer_text, model_name = llm_client.generate_answer(
            system_prompt, user_prompt, history=req.history, image_base64=image_base64
        )
    except LLMConnectionError as exc:
        logger.error("LLM kết nối thất bại (Ollama không chạy?): %s", exc)
        # Khi LM Studio chết → vẫn trả response nhưng là locked để BE không bị 503
        return QueryResponse(
            answer=(
                "Dịch vụ AI tạm thời không khả dụng (Ollama chưa sẵn sàng). "
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
            "LLM trả blank answer (hallucination hoặc blank): model=%s confidence=%.3f — fall back message.",
            model_name, confidence,
        )
        return QueryResponse(
            answer="Tài liệu này chủ yếu chứa bản vẽ kỹ thuật scan, nội dung text OCR khó đọc. "
                   "Vui lòng mở trực tiếp file tài liệu để xem bản vẽ gốc, "
                   "hoặc đặt câu hỏi cụ thể hơn về thông số kỹ thuật cần tra cứu.",
            confidence=confidence,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits, locked=True),
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


def _build_citations(hits: list[dict], locked: bool = False) -> list[Citation]:
    """Chuyển ChromaDB hits thành danh sách Citation đúng contract §2.2 kèm tọa độ Bbox (Spatial Mapping).

    Args:
        hits:   Danh sách kết quả ChromaDB search.
        locked: Nếu True (guardrail đã khóa), ẩn trường snippet để ngăn rò rỉ
                nội dung tài liệu bảo mật qua API response.
    """
    citations: list[Citation] = []
    for hit in hits:
        try:
            version_uuid = UUID(str(hit["version_id"]))
        except (ValueError, KeyError):
            logger.warning("Bỏ qua hit có version_id không hợp lệ: %s", hit.get("version_id"))
            continue

        bbox_val = str(hit.get("bbox", "") or "").strip()
        bbox_key = f"p{hit.get('page_no', 1)}_[{bbox_val}]" if bbox_val and bbox_val != "N/A" else None
        # Khi guardrail đã khóa → ẩn snippet để tránh rò rỉ 300 ký tự đầu tài liệu bảo mật
        snippet_val = None if locked else str(hit.get("snippet", "") or hit.get("text", "") or "")[:300].strip()

        citations.append(
            Citation(
                versionId=version_uuid,
                pageNo=hit.get("page_no", 1),
                bboxKey=bbox_key,
                imagePath=hit.get("image_path") or None,
                snippet=snippet_val or None,
            )
        )
    return citations


def run_query_stream(req: QueryRequest):
    """Generator cho SSE streaming: Thực hiện RAG pipeline và yield từng SSE event.

    Luồng SSE protocol:
        event: meta      → gửi metadata (citations, confidence, guard) TRƯỚC khi stream text
        event: delta     → gửi từng token text từ LLM
        event: done      → báo hiệu kết thúc stream

    Format mỗi event (Server-Sent Events):
        data: {"event": "meta", "citations": [...], "confidence": 0.9, "guard": {...}}\\n\\n
        data: {"event": "delta", "text": "Đây là"}\\n\\n
        data: {"event": "delta", "text": " câu trả lời"}\\n\\n
        data: {"event": "done"}\\n\\n

    Yields:
        str: SSE-formatted lines để pipe vào FastAPI StreamingResponse.
    """
    import json  # noqa: PLC0415

    start_ns = time.perf_counter()

    def _sse(event: str, **data) -> str:
        """Helper tạo SSE line chuẩn RFC 8895."""
        return f"data: {json.dumps({'event': event, **data}, ensure_ascii=False)}\n\n"

    # ── Fast-path: no versions ──────────────────────────────────────────────
    if not req.allowedVersionIds:
        yield _sse("meta", citations=[], confidence=LOCKED_CONFIDENCE, guard={"locked": True, "numericRule": False, "reasoningMode": False})
        yield _sse("delta", text=LOCKED_ANSWER)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="guardrail-no-versions")
        return

    # ── 0.5. Vision Query: Tải ảnh base64 từ MinIO & OCR (nếu có) ──────────────
    image_base64: str | None = None
    if req.imageStorageKey:
        try:
            from app.clients import minio_client, ocr_client
            logger.info("Vision Query (stream): đang tải ảnh base64 & OCR file ảnh %s", req.imageStorageKey)
            image_base64 = minio_client.get_object_base64(req.imageStorageKey)
            pages = ocr_client.extract_pages(req.imageStorageKey, ["vi", "en"])
            image_text = "\n".join(p.text for p in pages if p.text)
            if image_text:
                req.question = f"{req.question}\n[Thông tin từ OCR ảnh chụp]:\n{image_text}"
                logger.info("Đã nối text OCR từ ảnh vào câu hỏi (%d ký tự)", len(image_text))
        except Exception as exc:
            logger.error("Xử lý Vision Query ảnh %s thất bại (stream): %s", req.imageStorageKey, exc)

    # ── 1. Embed câu hỏi ────────────────────────────────────────────────────
    try:
        query_vec = embed_pipeline.embed_query(req.question)
    except Exception as exc:
        logger.error("Embed câu hỏi thất bại (stream): %s", exc)
        yield _sse("error", message="Lỗi embed câu hỏi.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-embed")
        return

    # ── 2. Truy vấn ChromaDB ─────────────────────────────────────────────────
    try:
        hits = index_pipeline.search(
            query_embedding=query_vec,
            allowed_version_ids=req.allowedVersionIds,
            top_k=req.topK,
            machine_code=req.machineCode,
        )
    except Exception as exc:
        logger.error("ChromaDB search thất bại (stream): %s", exc)
        yield _sse("error", message="Lỗi tìm kiếm tài liệu.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-chroma")
        return

    # ── 3. Guardrail ─────────────────────────────────────────────────────────
    numeric_rule = guardrails.check_numeric(req.question)
    reasoning_mode = guardrails.check_reasoning_mode(req.question, explicit_flag=req.reasoningMode)
    locked = guardrails.is_locked(hits, req.question, reasoning_mode=reasoning_mode)
    confidence = round(hits[0]["score"], 4) if hits else 0.0
    citations_data = [
        {
            "versionId": str(c.versionId),
            "pageNo": c.pageNo,
            "bboxKey": c.bboxKey,
            "snippet": c.snippet,
        }
        for c in _build_citations(hits, locked=locked)
    ]
    guard_data = {"locked": locked, "numericRule": numeric_rule, "reasoningMode": reasoning_mode}

    # Gửi metadata TRƯỚC (citations, confidence) để client hiển thị ngay
    yield _sse("meta", citations=citations_data, confidence=confidence, guard=guard_data)

    if locked:
        yield _sse("delta", text=LOCKED_ANSWER)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="guardrail-locked")
        return

    # Nếu chưa có image_base64 từ SnapAsk, tự động bốc/dựng ảnh trang PDF của kết quả top 1 từ MinIO (nếu có)
    if not image_base64 and hits:
        top_hit = hits[0]
        top_v_id = top_hit.get("version_id")
        top_doc_id = top_hit.get("document_id")
        top_p_no = top_hit.get("page_no", 1)
        if top_v_id:
            page_img_key = f"pages/{top_v_id}/{top_p_no}.png"
            try:
                from app.clients import minio_client
                image_base64 = minio_client.get_or_render_page_base64(
                    page_img_key=page_img_key,
                    version_id=top_v_id,
                    document_id=top_doc_id,
                    page_no=int(top_p_no) if str(top_p_no).isdigit() else 1,
                )
                if image_base64:
                    logger.info("Auto-Vision RAG (stream): Đã bốc/dựng ảnh trang bản vẽ %s truyền sang Vision LLM", page_img_key)
            except Exception as exc:
                logger.warning("Không thể bốc/dựng ảnh trang (stream) %s: %s", page_img_key, exc)

    # ── 4. Build Prompt ──────────────────────────────────────────────────────
    has_img = bool(image_base64)
    if has_img:
        logger.info("Vision LLM Mode (stream): Đã kích hoạt Vision Prompt kèm dữ liệu hình ảnh Base64")

    system_prompt = prompts.build_system_prompt(numeric_rule=numeric_rule, reasoning_mode=reasoning_mode, has_image=has_img)
    user_prompt = prompts.build_user_prompt(req.question, hits, reasoning_mode=reasoning_mode, history=req.history, has_image=has_img, machine_code=req.machineCode)

    # ── 5. Stream từ LM Studio ──────────────────────────────────────────────
    try:
        model_name = get_settings().lm_studio_model
        for token in llm_client.generate_answer_stream(
            system_prompt, user_prompt, history=req.history, image_base64=image_base64
        ):
            yield _sse("delta", text=token)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model=model_name)

    except llm_client.LLMConnectionError:
        yield _sse("error", message="Ollama chưa sẵn sàng. Vui lòng liên hệ quản trị viên.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-llm-connection")
    except llm_client.LLMInferenceError as exc:
        yield _sse("error", message=f"Lỗi LLM inference: {exc}")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-llm-inference")
    except Exception as exc:  # noqa: BLE001
        logger.error("Stream query lỗi không xác định: %s", exc)
        yield _sse("error", message="Lỗi không xác định.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-unknown")
