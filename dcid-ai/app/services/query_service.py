"""Query Service — RAG Pipeline Orchestrator cho DCID.

Luồng xử lý (theo contract §2.2):
    1. Embed câu hỏi bằng multilingual-e5-small (prefix "query: ").
    2. Truy vấn Qdrant với filter allowedVersionIds.
    3. Kiểm tra guardrail (cosine threshold + trigger phrase).
    4. Build system prompt + inject context chunks từ Qdrant.
    5. Gọi LM Studio để sinh câu trả lời (gọi qua llm_client).
    6. Tính confidence từ retrieval và bằng chứng ảnh/OCR độc lập.
    7. Trả về QueryResponse đúng schema contract.

Service này tách hoàn toàn business logic ra khỏi FastAPI router
để dễ unit test và tái sử dụng.
"""

from __future__ import annotations

import logging
import re
import time
import unicodedata
from typing import Any
from uuid import UUID

from app.clients import llm_client
from app.clients.llm_client import LLMConnectionError, LLMInferenceError
from app.config import get_settings
from app.pipeline import embed as embed_pipeline
from app.pipeline import index as index_pipeline
from app.pipeline import guardrails
from app.pipeline import prompts
from app.schemas import Citation, Guard, QueryRequest, QueryResponse
from app.services.resource_gate import ResourceBusyError

logger = logging.getLogger("dcid-ai.query_service")

LOCKED_ANSWER = (
    "Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm."
)
LOCKED_CONFIDENCE = 0.30
VISION_IMAGE_MAX_SIDE = 800

_NUMBER_RE = re.compile(r"(?<![\w])[-+]?\d+(?:[.,]\d+)?")
_TECHNICAL_QUANTITY_RE = re.compile(
    r"(?<![\w])([-+]?\d+(?:[.,]\d+)?)\s*"
    r"(?:mm|cm|km|m|v|vac|vdc|kv|a|ma|w|kw|mw|hz|khz|rpm|bar|psi|pa|mpa|"
    r"n(?:\s*[.·]\s*)?m|kg|g|°\s*c|deg(?:ree)?|%)(?![\w])",
    re.IGNORECASE,
)


def _normalize_question(question: str) -> str:
    normalized = unicodedata.normalize("NFKD", question.lower().replace("đ", "d"))
    return normalized.encode("ascii", "ignore").decode("ascii")


def _prefers_ocr_only(question: str) -> bool:
    """Questions that can be answered from recognized text without visual reasoning."""
    normalized = _normalize_question(question)
    text_terms = (
        "doc chu",
        "trich xuat van ban",
        "noi dung van ban",
        "ten ban ve",
        "ma ban ve",
        "so ban ve",
        "khung ten",
        "ty le ban ve",
        "nguoi ve",
        "ngay ve",
        "drawing no",
        "project",
        "title",
        "scale",
    )
    return any(term in normalized for term in text_terms)


def _usable_ocr_text(text: str) -> bool:
    normalized = _normalize_question(text)
    if "chua hinh anh" in normalized and "xem anh dinh kem" in normalized:
        return False
    return sum(char.isalnum() for char in normalized) >= 12


def _clamp_score(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def _minimum_answer_confidence() -> float:
    """Return the configured confidence target, safely clamped to [0, 1]."""
    return _clamp_score(getattr(get_settings(), "min_answer_confidence", 0.80))


def _best_effort_answer(
    answer: str,
    confidence: float,
    *,
    numeric_verified: bool | None = None,
) -> str:
    """Keep the best available answer while clearly disclosing weak evidence."""
    threshold_percent = round(_minimum_answer_confidence() * 100)
    confidence_percent = round(_clamp_score(confidence) * 100)
    numeric_note = (
        " Số liệu kỹ thuật trong câu trả lời chưa được OCR/tài liệu xác nhận đầy đủ."
        if numeric_verified is False
        else ""
    )
    return (
        f"⚠️ **Câu trả lời tham khảo — độ tin cậy {confidence_percent}% "
        f"(mục tiêu {threshold_percent}%).**{numeric_note}\n\n{answer.strip()}"
    )


def _ocr_quality_score(text: str) -> float:
    """Estimate whether OCR contains enough diverse, readable evidence.

    This is deliberately deterministic: it measures coverage, character density
    and token diversity instead of asking the answering model to grade itself.
    """
    if not _usable_ocr_text(text):
        return 0.0

    compact = text.strip()
    alnum_count = sum(char.isalnum() for char in compact)
    tokens = re.findall(r"[\w.+:/%-]+", _normalize_question(compact))
    unique_ratio = len(set(tokens)) / max(1, len(tokens))
    density = alnum_count / max(1, len(compact))

    coverage_score = min(1.0, alnum_count / 120.0)
    density_score = min(1.0, density / 0.75)
    diversity_score = min(1.0, unique_ratio / 0.70)
    return _clamp_score(
        0.25 * coverage_score + 0.35 * density_score + 0.40 * diversity_score
    )


def _numeric_values(text: str, *, technical_only: bool = False) -> set[str]:
    """Extract normalized numeric claims while ignoring Markdown list numbers."""
    pattern = _TECHNICAL_QUANTITY_RE if technical_only else _NUMBER_RE
    values: set[str] = set()
    for match in pattern.finditer(text or ""):
        value = match.group(1) if technical_only else match.group(0)
        line_prefix = text[text.rfind("\n", 0, match.start()) + 1 : match.start()]
        suffix = text[match.end() : match.end() + 2]
        if not technical_only and not line_prefix.strip(" #*-_") and suffix.startswith(". "):
            continue
        try:
            normalized = f"{float(value.replace(',', '.')):.6f}".rstrip("0").rstrip(".")
        except ValueError:
            continue
        values.add(normalized)
    return values


def _image_evidence_confidence(
    image_text: str,
    *,
    has_pixels: bool,
    answer_text: str | None = None,
    numeric_rule: bool = False,
) -> tuple[float, bool | None]:
    """Score independent image evidence and verify answer numbers against OCR.

    Returns ``(score, numeric_verified)``. ``numeric_verified`` is ``False``
    only when OCR can actually contradict an answer; vision-only answers are
    capped conservatively instead of being rejected without a second source.
    """
    usable_ocr = _usable_ocr_text(image_text)
    if not has_pixels and not usable_ocr:
        return 0.0, None

    score = 0.55 if has_pixels else 0.0
    if usable_ocr:
        score = max(score, 0.58 + 0.28 * _ocr_quality_score(image_text))

    if answer_text is None:
        return round(_clamp_score(score), 4), None

    answer_numbers = _numeric_values(answer_text, technical_only=True)
    if numeric_rule and not answer_numbers:
        answer_numbers = _numeric_values(answer_text)
    # Placeholder text such as "Trang 1 chứa hình ảnh" is not OCR evidence;
    # its page number must never be mistaken for a conflicting measurement.
    ocr_numbers = _numeric_values(image_text) if usable_ocr else set()

    if answer_numbers and ocr_numbers:
        support_ratio = len(answer_numbers & ocr_numbers) / len(answer_numbers)
        score = 0.55 * score + 0.45 * support_ratio
        verified = support_ratio >= 0.80
        if not verified:
            score = min(score, 0.39)
        return round(_clamp_score(score), 4), verified

    if answer_numbers and not ocr_numbers:
        # The VLM may still read a value that OCR missed, but there is no
        # independent evidence for advertising high confidence.
        return round(min(score, 0.55), 4), None

    if numeric_rule:
        return round(min(score, 0.45), 4), False if ocr_numbers else None

    return round(_clamp_score(score), 4), None


def _calculate_confidence(
    hits: list[dict],
    *,
    image_text: str = "",
    has_pixels: bool = False,
    answer_text: str | None = None,
    numeric_rule: bool = False,
) -> tuple[float, bool | None]:
    """Combine retrieval relevance with independently measured image evidence."""
    retrieval_score = _clamp_score(hits[0].get("score", 0.0)) if hits else 0.0
    image_score, image_numeric_verified = _image_evidence_confidence(
        image_text,
        has_pixels=has_pixels,
        answer_text=answer_text,
        numeric_rule=numeric_rule,
    )

    document_numeric_verified: bool | None = None
    if answer_text is not None and hits:
        answer_numbers = _numeric_values(answer_text, technical_only=True)
        if numeric_rule and not answer_numbers:
            answer_numbers = _numeric_values(answer_text)
        document_numbers: set[str] = set()
        for hit in hits:
            document_numbers.update(
                _numeric_values(str(hit.get("text") or hit.get("snippet") or ""))
            )
        if answer_numbers:
            document_support = len(answer_numbers & document_numbers) / len(answer_numbers)
            document_numeric_verified = document_support >= 0.80
        elif numeric_rule:
            # A numeric question whose answer contains no verifiable value must
            # not be advertised as a high-confidence technical answer.
            document_numeric_verified = False

    verification_results = [
        value
        for value in (image_numeric_verified, document_numeric_verified)
        if value is not None
    ]
    numeric_verified: bool | None
    if False in verification_results:
        numeric_verified = False
    elif True in verification_results:
        numeric_verified = True
    else:
        numeric_verified = None

    if image_score and retrieval_score:
        confidence = 0.45 * retrieval_score + 0.55 * image_score
    else:
        confidence = image_score or retrieval_score
    if numeric_verified is False:
        confidence = min(confidence, 0.39)
    elif image_numeric_verified is True and document_numeric_verified is True:
        # Two independent sources support the same numeric claim.
        confidence = min(0.95, confidence + 0.03)
    confidence = round(_clamp_score(confidence), 4)
    logger.info(
        "Confidence audit: retrieval=%.3f image=%.3f image_numeric=%s "
        "document_numeric=%s combined=%.3f",
        retrieval_score,
        image_score,
        image_numeric_verified,
        document_numeric_verified,
        confidence,
    )
    return confidence, numeric_verified


def _needs_visual_context(question: str) -> bool:
    """Use the expensive Vision path only when the question refers to visuals."""
    if _prefers_ocr_only(question):
        return False
    normalized = _normalize_question(question)
    visual_terms = (
        "so do",
        "hinh anh",
        "hinh ve",
        "anh chup",
        "ky hieu",
        "nhin vao",
        "vi tri tren hinh",
        "kich thuoc tren ban ve",
        "doc nhan",
        "nhan thiet bi",
        "image",
        "diagram",
        "vi tri",
        "o dau",
        "hinh dang",
        "bo tri",
        "cau tao",
        "duong kinh",
        "ban kinh",
        "khoang cach",
        "kich thuoc cua",
    )
    return any(term in normalized for term in visual_terms)


def _prepare_uploaded_image(req: QueryRequest, *, stream: bool = False) -> tuple[str | None, str]:
    """OCR an uploaded image first; attach pixels only when visual reasoning is needed."""
    if not req.imageStorageKey:
        return None, ""

    from app.clients import minio_client, ocr_client

    mode = " (stream)" if stream else ""
    ocr_only_requested = _prefers_ocr_only(req.question)
    image_text = ""
    try:
        pages = ocr_client.extract_pages(req.imageStorageKey, ["vi", "en"])
        image_text = "\n".join(page.text for page in pages if page.text).strip()
        if _usable_ocr_text(image_text):
            req.question = f"{req.question}\n[Thông tin OCR từ ảnh]:\n{image_text}"
            logger.info("Vision Query%s: OCR OK (%d ký tự)", mode, len(image_text))
    except Exception as exc:
        logger.warning("Vision Query%s: OCR thất bại, chuyển sang Vision: %s", mode, exc)

    use_vision = not (ocr_only_requested and _usable_ocr_text(image_text))
    if not use_vision:
        logger.info("Vision Query%s: chọn OCR-only để giảm độ trễ", mode)
        return None, image_text

    try:
        image_base64 = minio_client.get_object_base64(
            req.imageStorageKey,
            max_side=VISION_IMAGE_MAX_SIDE,
        )
        logger.info("Vision Query%s: chọn OCR + Vision (%dpx)", mode, VISION_IMAGE_MAX_SIDE)
        return image_base64, image_text
    except Exception as exc:
        logger.error("Vision Query%s: không thể tải ảnh %s: %s", mode, req.imageStorageKey, exc)
        return None, image_text


def _retrieve_hits(
    req: QueryRequest,
    query_vec: list[float],
    low_memory_query: bool,
    settings,
) -> list[dict[str, Any]]:
    """Execute hybrid BM25 + Dense or Lexical retrieval based on settings."""
    if not req.allowedVersionIds:
        return []
    if low_memory_query:
        return index_pipeline.search_selected_text(
            question=req.question,
            allowed_version_ids=req.allowedVersionIds,
            top_k=req.topK,
            machine_code=req.machineCode,
        )

    hybrid_enabled = getattr(settings, "hybrid_retrieval_enabled", True)
    alpha = getattr(settings, "hybrid_alpha", 0.70)

    if hybrid_enabled:
        return index_pipeline.search_hybrid(
            query_embedding=query_vec,
            question=req.question,
            allowed_version_ids=req.allowedVersionIds,
            top_k=req.topK,
            machine_code=req.machineCode,
            alpha=alpha,
        )
    else:
        return index_pipeline.search(
            query_embedding=query_vec,
            allowed_version_ids=req.allowedVersionIds,
            top_k=req.topK,
            machine_code=req.machineCode,
        )


def run_query(req: QueryRequest) -> QueryResponse:
    """Thực thi RAG pipeline đầy đủ cho một câu hỏi.

    Args:
        req: QueryRequest từ BE (question, topK, allowedVersionIds, machineCode).

    Returns:
        QueryResponse đúng contract §2.2 — luôn trả về, không raise.
        Khi LLM lỗi → trả về fallback locked response kèm error log.
    """
    start_ns = time.perf_counter()
    original_question = req.question

    # An uploaded image is a valid standalone source even when the user has not
    # selected any indexed document version.
    image_base64, image_text = _prepare_uploaded_image(req)

    # ── 0. Fast-path: allowedVersionIds rỗng → không cần query chroma ──────
    if not req.allowedVersionIds and not req.imageStorageKey:
        logger.info("Query bị khóa sớm: allowedVersionIds rỗng (question=%s)", req.question[:80])
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="guardrail-no-versions",
        )

    # ── 0.5. Vision Query: Tải ảnh base64 từ MinIO & OCR (nếu có) ──────────────
    # ── 1. Embed câu hỏi ────────────────────────────────────────────────────
    low_memory_query = getattr(get_settings(), "low_memory_query_mode", True)
    query_vec: list[float] = []
    if not low_memory_query:
        try:
            query_vec = embed_pipeline.embed_query(req.question) if req.allowedVersionIds else []
        except Exception as exc:
            logger.error("Embed câu hỏi thất bại: %s", exc)
            return _locked_response(
                latency_ms=_elapsed_ms(start_ns),
                model="error-embed",
            )

    # ── 2. Truy vấn Qdrant (Hybrid BM25 + Dense / Lexical) ───────────────────
    try:
        settings = get_settings()
        hits = _retrieve_hits(req, query_vec, low_memory_query, settings)
    except Exception as exc:
        logger.error("Qdrant search thất bại: %s", exc)
        return _locked_response(
            latency_ms=_elapsed_ms(start_ns),
            model="error-qdrant",
        )

    logger.info(
        "Qdrant: %d hits | top_score=%.3f | question=%s",
        len(hits),
        hits[0]["score"] if hits else 0.0,
        req.question[:80],
    )

    # ── 3. Guardrail — cosine threshold & trigger phrase ─────────────────────
    numeric_rule = guardrails.check_numeric(original_question)
    reasoning_mode = guardrails.check_reasoning_mode(original_question, explicit_flag=req.reasoningMode)
    locked = guardrails.is_locked(hits, original_question, reasoning_mode=reasoning_mode)
    if req.imageStorageKey and (image_base64 or _usable_ocr_text(image_text)):
        locked = False

    if locked and not hits and not (image_base64 or _usable_ocr_text(image_text)):
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
    if locked:
        logger.info(
            "Guardrail đánh dấu bằng chứng yếu nhưng tiếp tục best-effort: "
            "top_score=%.3f threshold=%.2f",
            hits[0]["score"] if hits else 0.0,
            guardrails.THRESHOLD,
        )

    # Nếu chưa có image_base64 từ SnapAsk, tự động bốc/dựng ảnh trang PDF của kết quả top 1 từ MinIO
    if not req.imageStorageKey and not image_base64 and hits and _needs_visual_context(req.question):
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
    except ResourceBusyError as exc:
        logger.warning("AI resources busy: %s", exc)
        return QueryResponse(
            answer="Hệ thống AI đang xử lý một tác vụ nặng. Vui lòng thử lại sau ít phút.",
            confidence=0.0,
            guard=Guard(locked=True, numericRule=numeric_rule, reasoningMode=reasoning_mode),
            citations=_build_citations(hits),
            latencyMs=_elapsed_ms(start_ns),
            model="busy-resource-gate",
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

    # ── 6. Tính confidence từ các nguồn bằng chứng độc lập ───────────────────
    confidence, numeric_verified = _calculate_confidence(
        hits,
        image_text=image_text,
        has_pixels=has_img,
        answer_text=answer_text,
        numeric_rule=numeric_rule,
    )

    if numeric_verified is False:
        logger.warning(
            "Số liệu trong câu trả lời chưa được nguồn độc lập xác nhận "
            "(confidence=%.3f); trả best-effort kèm cảnh báo",
            confidence,
        )

    # Kiểm tra blank answer (model nhỏ đôi khi trả rỗng sau khi bóc thẻ <think>)
    if not answer_text.strip():
        logger.warning(
            "LLM trả blank answer (hallucination hoặc blank): model=%s confidence=%.3f — fall back message.",
            model_name, confidence,
        )
        answer_text = (
            "Tài liệu này chủ yếu chứa bản vẽ kỹ thuật scan và phần chữ OCR khó đọc. "
            "Từ dữ liệu hiện có, tôi chưa thể trích xuất thêm nội dung cụ thể; "
            "hãy xem bản vẽ gốc hoặc cung cấp ảnh rõ hơn."
        )
        confidence = min(confidence, LOCKED_CONFIDENCE)

    minimum_confidence = _minimum_answer_confidence()
    if confidence < minimum_confidence or numeric_verified is False:
        logger.warning(
            "Answer dưới mục tiêu confidence nhưng vẫn trả best-effort: "
            "confidence=%.3f target=%.3f model=%s",
            confidence,
            minimum_confidence,
            model_name,
        )
        answer_text = _best_effort_answer(
            answer_text,
            confidence,
            numeric_verified=numeric_verified,
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
        event: meta      → gửi metadata đã kiểm tra (citations, confidence, guard) trước nội dung
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
    original_question = req.question

    def _sse(event: str, **data) -> str:
        """Helper tạo SSE line chuẩn RFC 8895."""
        return f"data: {json.dumps({'event': event, **data}, ensure_ascii=False)}\n\n"

    image_base64, image_text = _prepare_uploaded_image(req, stream=True)

    # ── Fast-path: no versions ──────────────────────────────────────────────
    if not req.allowedVersionIds and not req.imageStorageKey:
        yield _sse("meta", citations=[], confidence=LOCKED_CONFIDENCE, guard={"locked": True, "numericRule": False, "reasoningMode": False})
        yield _sse("delta", text=LOCKED_ANSWER)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="guardrail-no-versions")
        return

    # ── 0.5. Vision Query: Tải ảnh base64 từ MinIO & OCR (nếu có) ──────────────
    # ── 1. Embed câu hỏi ────────────────────────────────────────────────────
    low_memory_query = getattr(get_settings(), "low_memory_query_mode", True)
    query_vec: list[float] = []
    if not low_memory_query:
        try:
            query_vec = embed_pipeline.embed_query(req.question) if req.allowedVersionIds else []
        except Exception as exc:
            logger.error("Embed câu hỏi thất bại (stream): %s", exc)
            yield _sse("error", message="Lỗi embed câu hỏi.")
            yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-embed")
            return

    # ── 2. Truy vấn Qdrant (Hybrid BM25 + Dense / Lexical) ───────────────────
    try:
        settings = get_settings()
        hits = _retrieve_hits(req, query_vec, low_memory_query, settings)
    except Exception as exc:
        logger.error("Qdrant search thất bại (stream): %s", exc)
        yield _sse("error", message="Lỗi tìm kiếm tài liệu.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-qdrant")
        return

    # ── 3. Guardrail ─────────────────────────────────────────────────────────
    numeric_rule = guardrails.check_numeric(original_question)
    reasoning_mode = guardrails.check_reasoning_mode(original_question, explicit_flag=req.reasoningMode)
    locked = guardrails.is_locked(hits, original_question, reasoning_mode=reasoning_mode)
    if req.imageStorageKey and (image_base64 or _usable_ocr_text(image_text)):
        locked = False
    if locked and not hits and not (image_base64 or _usable_ocr_text(image_text)):
        confidence, _ = _calculate_confidence(
            hits,
            image_text=image_text,
            has_pixels=bool(image_base64),
            answer_text=None,
            numeric_rule=numeric_rule,
        )
        citations_data = [
            {
                "versionId": str(c.versionId),
                "pageNo": c.pageNo,
                "bboxKey": c.bboxKey,
                "snippet": c.snippet,
            }
            for c in _build_citations(hits, locked=True)
        ]
        yield _sse(
            "meta",
            citations=citations_data,
            confidence=confidence,
            guard={"locked": True, "numericRule": numeric_rule, "reasoningMode": reasoning_mode},
        )
        yield _sse("delta", text=LOCKED_ANSWER)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="guardrail-locked")
        return
    if locked:
        logger.info(
            "Guardrail stream đánh dấu bằng chứng yếu nhưng tiếp tục best-effort: "
            "top_score=%.3f threshold=%.2f",
            hits[0]["score"] if hits else 0.0,
            guardrails.THRESHOLD,
        )

    # Nếu chưa có image_base64 từ SnapAsk, tự động bốc/dựng ảnh trang PDF của kết quả top 1 từ MinIO (nếu có)
    if not req.imageStorageKey and not image_base64 and hits and _needs_visual_context(req.question):
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

    # ── 5. Sinh và giữ câu trả lời trong bộ đệm ─────────────────────────────
    # Giữ token đến khi tính xong confidence để có thể thêm cảnh báo chính xác
    # trước câu trả lời best-effort khi chưa đạt mục tiêu 80%.
    try:
        model_name = llm_client.get_model_name(image_base64)
        answer_parts = list(
            llm_client.generate_answer_stream(
                system_prompt, user_prompt, history=req.history, image_base64=image_base64
            )
        )
        answer_text = "".join(answer_parts)
        confidence, numeric_verified = _calculate_confidence(
            hits,
            image_text=image_text,
            has_pixels=has_img,
            answer_text=answer_text,
            numeric_rule=numeric_rule,
        )
        if not answer_text.strip():
            answer_text = (
                "Tài liệu này chủ yếu chứa bản vẽ kỹ thuật scan và phần chữ OCR khó đọc. "
                "Từ dữ liệu hiện có, tôi chưa thể trích xuất thêm nội dung cụ thể; "
                "hãy xem bản vẽ gốc hoặc cung cấp ảnh rõ hơn."
            )
            confidence = min(confidence, LOCKED_CONFIDENCE)
            answer_parts = [answer_text]

        needs_warning = (
            numeric_verified is False
            or confidence < _minimum_answer_confidence()
        )
        citations_data = [
            {
                "versionId": str(c.versionId),
                "pageNo": c.pageNo,
                "bboxKey": c.bboxKey,
                "snippet": c.snippet,
            }
            for c in _build_citations(hits, locked=False)
        ]
        yield _sse(
            "meta",
            citations=citations_data,
            confidence=confidence,
            guard={
                "locked": False,
                "numericRule": numeric_rule,
                "reasoningMode": reasoning_mode,
            },
        )
        if needs_warning:
            yield _sse(
                "delta",
                text=_best_effort_answer(
                    answer_text,
                    confidence,
                    numeric_verified=numeric_verified,
                ),
            )
        else:
            for token in answer_parts:
                yield _sse("delta", text=token)
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model=model_name)

    except ResourceBusyError:
        yield _sse("meta", citations=[], confidence=0.0, guard={"locked": True, "numericRule": numeric_rule, "reasoningMode": reasoning_mode})
        yield _sse("error", message="Hệ thống AI đang bận. Vui lòng thử lại sau ít phút.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="busy-resource-gate")
    except llm_client.LLMConnectionError:
        yield _sse("meta", citations=[], confidence=0.0, guard={"locked": True, "numericRule": numeric_rule, "reasoningMode": reasoning_mode})
        yield _sse("error", message="Ollama chưa sẵn sàng. Vui lòng liên hệ quản trị viên.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-llm-connection")
    except llm_client.LLMInferenceError as exc:
        yield _sse("meta", citations=[], confidence=0.0, guard={"locked": True, "numericRule": numeric_rule, "reasoningMode": reasoning_mode})
        yield _sse("error", message=f"Lỗi LLM inference: {exc}")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-llm-inference")
    except Exception as exc:  # noqa: BLE001
        logger.error("Stream query lỗi không xác định: %s", exc)
        yield _sse("meta", citations=[], confidence=0.0, guard={"locked": True, "numericRule": numeric_rule, "reasoningMode": reasoning_mode})
        yield _sse("error", message="Lỗi không xác định.")
        yield _sse("done", latencyMs=_elapsed_ms(start_ns), model="error-unknown")
