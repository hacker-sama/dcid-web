"""Client kết nối LM Studio qua OpenAI-compatible REST API.

LM Studio expose endpoint `/v1/chat/completions` tương thích 100% OpenAI SDK.
Khi chạy trong Docker container: host.docker.internal:1234 trỏ về Host OS (Windows/Linux).
Khi dev local không Docker: sửa LM_STUDIO_BASE_URL=http://localhost:1234/v1 trong .env.

Thiết kế:
- Client singleton per process (lazy init, thread-safe với lru_cache).
- Mọi exception từ OpenAI SDK đều được bắt và re-raise cùng context rõ ràng.
- Timeout riêng biệt theo settings (mặc định 60s — đủ cho CPU inference).
- Hàm `is_available()` probe nhanh không raise — dùng cho health check.
"""

from __future__ import annotations

import logging
import re
from functools import lru_cache
from typing import Any

from app.config import get_settings

logger = logging.getLogger("dcid-ai.llm_client")


@lru_cache(maxsize=1)
def _get_client():
    """Khởi tạo OpenAI client một lần, cache theo process.

    Import openai bên trong tránh import-time crash khi chưa cài.
    """
    try:
        from openai import OpenAI  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError(
            "openai chưa cài. Chạy: pip install openai>=1.40"
        ) from exc

    s = get_settings()
    logger.info(
        "Khởi tạo LLM client → base_url=%s model=%s timeout=%.1fs",
        s.lm_studio_base_url,
        s.lm_studio_model,
        s.llm_timeout,
    )
    return OpenAI(
        base_url=s.lm_studio_base_url,
        api_key=s.lm_studio_api_key,
        timeout=s.llm_timeout,
    )


# ────────────────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────────────────

def generate_answer(system_prompt: str, user_prompt: str) -> tuple[str, str]:
    """Gọi LM Studio để sinh câu trả lời.

    Args:
        system_prompt: Hướng dẫn hành vi + context chunks đã được inject.
        user_prompt:   Câu hỏi cuối cùng của người dùng.

    Returns:
        (answer_text, model_name) — cả 2 luôn là str không None.

    Raises:
        LLMConnectionError: LM Studio chưa chạy hoặc không thể kết nối.
        LLMInferenceError:  Model đã nạp nhưng gặp lỗi inference.
    """
    try:
        from openai import APIConnectionError, APIStatusError, APITimeoutError  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError("openai chưa cài.") from exc

    s = get_settings()
    client = _get_client()

    logger.debug(
        "Gọi LLM: model=%s max_tokens=%d temperature=%.2f",
        s.lm_studio_model, s.llm_max_tokens, s.llm_temperature,
    )

    # Chỉ thêm penalty params khi thực sự khác 0 — LM Studio crash channel
    # khi nhận extra_body hoặc penalty fields không hỗ trợ (DeepSeek-R1).
    call_kwargs: dict[str, Any] = {
        "model": s.lm_studio_model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_prompt},
        ],
        "temperature": s.llm_temperature,
        "max_tokens": s.llm_max_tokens,
    }
    # top_p — chỉ thêm khi cấu hình rõ ràng
    top_p = getattr(s, "llm_top_p", 0.0)
    if top_p and 0.0 < top_p < 1.0:
        call_kwargs["top_p"] = top_p
    # frequency/presence penalty — CHỈ thêm khi khác 0;
    # LM Studio có thể trả Channel Error khi nhận các field này cho một số model
    freq_p = getattr(s, "llm_frequency_penalty", 0.0)
    pres_p = getattr(s, "llm_presence_penalty", 0.0)
    if freq_p:
        call_kwargs["frequency_penalty"] = freq_p
    if pres_p:
        call_kwargs["presence_penalty"] = pres_p
    # Truyền repetition_penalty an toàn (Cấu hình suy luận tối ưu theo sơ đồ: 1.2)
    rep_p = getattr(s, "llm_repetition_penalty", 1.0)
    if rep_p and rep_p > 1.0:
        call_kwargs["extra_body"] = {"repetition_penalty": rep_p}

    try:
        response = client.chat.completions.create(**call_kwargs)
    except APIConnectionError as exc:
        logger.error(
            "LM Studio không thể kết nối tại %s — Kiểm tra LM Studio đang chạy trên Host (port 1234). Error: %s",
            s.lm_studio_base_url, exc,
        )
        raise LLMConnectionError(
            f"LM Studio không phản hồi tại {s.lm_studio_base_url}. "
            "Hãy mở LM Studio trên máy Host → nạp model → Start Server (port 1234)."
        ) from exc
    except APITimeoutError as exc:
        logger.error(
            "LM Studio timeout sau %.1fs — model=%s. Thử tăng LLM_TIMEOUT hoặc dùng model nhỏ hơn.",
            s.llm_timeout, s.lm_studio_model,
        )
        raise LLMInferenceError(
            f"LM Studio timeout sau {s.llm_timeout}s. "
            "Kiểm tra: model còn xử lý? RAM/VRAM đủ? Thử model nhỏ hơn (1.5B)."
        ) from exc
    except APIStatusError as exc:
        # Channel Error — LM Studio trả HTTP error (400/500) do params không hợp lệ
        logger.error(
            "LM Studio Channel Error (status %s): %s — thử lại với params tối thiểu.",
            exc.status_code, exc.message,
        )
        # Retry với params tối thiểu (chỉ messages + temperature + max_tokens)
        try:
            response = client.chat.completions.create(
                model=s.lm_studio_model,
                messages=call_kwargs["messages"],
                temperature=s.llm_temperature,
                max_tokens=s.llm_max_tokens,
            )
        except Exception as retry_exc:  # noqa: BLE001
            logger.error("Retry thất bại: %s", retry_exc)
            raise LLMInferenceError(
                f"LM Studio Channel Error (status {exc.status_code}). "
                "Kiểm tra: model đã nạp chưa? LM Studio Server đang chạy?"
            ) from exc
    except Exception as exc:  # noqa: BLE001
        logger.error("LLM inference lỗi không xác định: %s", exc)
        raise LLMInferenceError(f"Lỗi LLM không xác định: {exc}") from exc

    msg = response.choices[0].message
    raw_content = msg.content or ""
    reasoning_content = getattr(msg, "reasoning_content", None) or getattr(msg, "reasoning", None) or ""
    answer = _clean_think_tags(raw_content, fallback_reasoning=reasoning_content)
    model_used = response.model or s.lm_studio_model

    # DEBUG: log raw và cleaned để phát hiện blank answer
    logger.debug(
        "LLM RAW (%d chars | reasoning %d chars): %.300s",
        len(raw_content), len(reasoning_content), raw_content.replace("\n", "↵"),
    )
    logger.debug(
        "LLM CLEANED (%d chars): %.300s",
        len(answer), answer.replace("\n", "↵"),
    )
    if not answer.strip():
        logger.warning(
            "LLM BLANK ANSWER — raw_content (%d chars) và reasoning (%d chars) bị xóa hết. Raw preview: %.500s",
            len(raw_content), len(reasoning_content), raw_content[:500],
        )

    logger.info(
        "LLM OK: model=%s tokens_used=%s answer_chars=%d",
        model_used,
        getattr(response.usage, "total_tokens", "N/A"),
        len(answer),
    )
    return answer, model_used


def generate_answer_stream(system_prompt: str, user_prompt: str):
    """Generator: Stream từng token text từ LM Studio về client qua SSE.

    Sử dụng OpenAI SDK streaming mode (stream=True). Mỗi lần yield là một
    đoạn text (delta) nhỏ từ model — phù hợp để pipe thẳng vào SSE response.

    Args:
        system_prompt: Hướng dẫn hành vi + context chunks đã được inject.
        user_prompt:   Câu hỏi cuối cùng của người dùng.

    Yields:
        str: Từng đoạn text delta từ LM Studio (có thể là 1 từ, 1 câu, hoặc nhiều ký tự).

    Raises:
        LLMConnectionError: LM Studio chưa chạy hoặc không thể kết nối.
        LLMInferenceError:  Model đã nạp nhưng gặp lỗi inference.

    Ví dụ dùng trong FastAPI SSE:
        async def event_stream():
            for chunk in generate_answer_stream(sys_prompt, user_prompt):
                yield f"data: {json.dumps({'delta': chunk})}\\n\\n"
    """
    try:
        from openai import APIConnectionError, APIStatusError, APITimeoutError  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError("openai chưa cài.") from exc

    s = get_settings()
    client = _get_client()

    logger.debug(
        "Gọi LLM stream: model=%s max_tokens=%d temperature=%.2f",
        s.lm_studio_model, s.llm_max_tokens, s.llm_temperature,
    )

    stream_kwargs: dict = {
        "model": s.lm_studio_model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_prompt},
        ],
        "temperature": s.llm_temperature,
        "max_tokens": s.llm_max_tokens,
        "stream": True,
    }
    # Thêm top_p nếu cấu hình
    top_p = getattr(s, "llm_top_p", 0.0)
    if top_p and 0.0 < top_p < 1.0:
        stream_kwargs["top_p"] = top_p

    try:
        stream = client.chat.completions.create(**stream_kwargs)
        token_count = 0
        for chunk in stream:
            delta = chunk.choices[0].delta if chunk.choices else None
            if delta is None:
                continue
            # Xử lý cả trường hợp model trả reasoning_content riêng (DeepSeek-R1)
            content = getattr(delta, "content", None) or ""
            if content:
                token_count += 1
                yield content

        logger.info("LLM stream OK: model=%s tokens_streamed=%d", s.lm_studio_model, token_count)

    except APIConnectionError as exc:
        logger.error("LLM stream kết nối thất bại: %s", exc)
        raise LLMConnectionError(
            f"LM Studio không phản hồi tại {s.lm_studio_base_url}. "
            "Hãy mở LM Studio trên máy Host → nạp model → Start Server (port 1234)."
        ) from exc
    except APITimeoutError as exc:
        logger.error("LLM stream timeout sau %.1fs", s.llm_timeout)
        raise LLMInferenceError(
            f"LM Studio timeout sau {s.llm_timeout}s khi streaming."
        ) from exc
    except APIStatusError as exc:
        logger.error("LLM stream Channel Error (status %s): %s", exc.status_code, exc.message)
        raise LLMInferenceError(
            f"LM Studio Channel Error (status {exc.status_code}) khi streaming."
        ) from exc
    except Exception as exc:  # noqa: BLE001
        logger.error("LLM stream lỗi không xác định: %s", exc)
        raise LLMInferenceError(f"Lỗi LLM stream không xác định: {exc}") from exc


def _clean_think_tags(text: str, fallback_reasoning: str = "") -> str:
    """Bóc tách thẻ <think> và loại bỏ hoàn toàn các dòng/đoạn chỉ thị hệ thống (meta-instructions)
    nếu model 1.5B lỡ lặp lại (echo) vào câu trả lời cuối cùng.
    Nếu sau khi bóc tách mà câu trả lời bị rỗng (do model để toàn bộ câu trả lời bên trong <think>
    hoặc bị ngắt trước khi đóng thẻ, hoặc LM Studio/Ollama tách riêng sang reasoning_content),
    tự động trích xuất nội dung bên trong <think> hoặc fallback_reasoning làm câu trả lời.
    """
    cleaned = re.sub(r"<think>.*?</think>", "", text, flags=re.DOTALL)
    if "<think>" in cleaned:
        cleaned = cleaned.split("<think>")[0]

    # Loại bỏ các block meta (ví dụ: [CHỈ THỊ CHUYÊN GIA...]: ... TUYỆT ĐỐI KHÔNG... \n\n hoặc ---)
    meta_patterns = [
        r"\[CHỈ THỊ[^\]]*\][:.]?\s*(.*?)(?=\n\s*\n|\n\s*---|$)",
        r"\[YÊU CẦU[^\]]*\][:.]?\s*(.*?)(?=\n\s*\n|\n\s*---|$)",
        r"\[NGUYÊN TẮC[^\]]*\][:.]?\s*(.*?)(?=\n\s*\n|\n\s*---|$)",
        r"\[LƯU Ý[^\]]*\][:.]?\s*(.*?)(?=\n\s*\n|\n\s*---|$)",
        r"\[HẾT CONTEXT[^\]]*\]",
        r"\[KHÔNG CÓ CONTEXT[^\]]*\]",
    ]
    for pat in meta_patterns:
        cleaned = re.sub(pat, "", cleaned, flags=re.IGNORECASE | re.DOTALL)

    # Loại bỏ đường viền phân cách "---" thừa ở đầu câu trả lời sau khi lọc meta
    cleaned = re.sub(r"^\s*---\s*", "", cleaned).strip()

    # Loại bỏ thêm nếu model chép lại tiêu đề không có ngoặc vuông ở đầu dòng
    lines = cleaned.split("\n")
    filtered = []
    for line in lines:
        stripped = line.strip()
        if any(stripped.startswith(p) and len(stripped) < 120 for p in [
            "[CHỈ THỊ", "CHỈ THỊ CHUYÊN GIA", "CHỈ THỊ ĐẶC BIỆT",
            "[YÊU CẦU", "YÊU CẦU TƯ VẤN", "NGUYÊN TẮC HƯỚNG DẪN",
            "NGUYÊN TẮC SUY LUẬN", "DƯỚI ĐÂY LÀ CÁC ĐOẠN"
        ]):
            continue
        filtered.append(line)

    cleaned = "\n".join(filtered).strip()
    cleaned = re.sub(r"^\s*---\s*", "", cleaned).strip()

    # Fallback 1: nếu sau khi xoá <think> mà cleaned rỗng (tức toàn bộ text nằm trong <think>)
    if not cleaned and text:
        think_match = re.search(r"<think>(.*?)(?:</think>|$)", text, flags=re.DOTALL)
        if think_match:
            raw_think = think_match.group(1).strip()
            for pat in meta_patterns:
                raw_think = re.sub(pat, "", raw_think, flags=re.IGNORECASE | re.DOTALL)
            think_lines = raw_think.split("\n")
            think_filtered = []
            for line in think_lines:
                stripped = line.strip()
                if any(stripped.startswith(p) and len(stripped) < 120 for p in [
                    "[CHỈ THỊ", "CHỈ THỊ CHUYÊN GIA", "CHỈ THỊ ĐẶC BIỆT",
                    "[YÊU CẦU", "YÊU CẦU TƯ VẤN", "NGUYÊN TẮC HƯỚNG DẪN",
                    "NGUYÊN TẮC SUY LUẬN", "DƯỚI ĐÂY LÀ CÁC ĐOẠN"
                ]):
                    continue
                think_filtered.append(line)
            cleaned = "\n".join(think_filtered).strip()
            cleaned = re.sub(r"^\s*---\s*", "", cleaned).strip()

    # Fallback 2: nếu cleaned vẫn rỗng và LM Studio tách suy luận ra field reasoning_content
    if not cleaned and fallback_reasoning:
        raw_think = fallback_reasoning.strip()
        for pat in meta_patterns:
            raw_think = re.sub(pat, "", raw_think, flags=re.IGNORECASE | re.DOTALL)
        think_lines = raw_think.split("\n")
        think_filtered = []
        for line in think_lines:
            stripped = line.strip()
            if any(stripped.startswith(p) and len(stripped) < 120 for p in [
                "[CHỈ THỊ", "CHỈ THỊ CHUYÊN GIA", "CHỈ THỊ ĐẶC BIỆT",
                "[YÊU CẦU", "YÊU CẦU TƯ VẤN", "NGUYÊN TẮC HƯỚNG DẪN",
                "NGUYÊN TẮC SUY LUẬN", "DƯỚI ĐÂY LÀ CÁC ĐOẠN"
            ]):
                continue
            think_filtered.append(line)
        cleaned = "\n".join(think_filtered).strip()
        cleaned = re.sub(r"^\s*---\s*", "", cleaned).strip()

    final_text = cleaned or text.strip() or fallback_reasoning.strip()
    return _remove_repetition_loops(final_text)


def _remove_repetition_loops(text: str) -> str:
    """Phát hiện và CẮT NGANG (truncate) triệt để khi model local bị rơi vào vòng lặp đoạn văn,
    lặp khối danh sách (block loop) hoặc lặp câu/cụm từ (degeneration loop).
    """
    if not text or len(text) < 30:
        return text

    # 1. PHÁT HIỆN LẶP CHUỖI ĐOẠN VĂN / KHỐI LỆNH (PARAGRAPH & BLOCK CYCLE TRUNCATION)
    # Tách thành các đoạn theo dòng trống (\n\n) hoặc xuống dòng (\n)
    paragraphs = [p.strip() for p in re.split(r'\n{2,}', text) if p.strip()]
    if len(paragraphs) >= 3:
        truncated_paragraphs = []
        cycle_found = False
        for i, p in enumerate(paragraphs):
            # Chuẩn hóa để so sánh (bỏ cả markdown ###, **, số đầu dòng 1., -)
            norm_p = re.sub(r'^[\#\*\_\-\.\s0-9]+', '', p).lower().strip()
            # Bỏ dải phân cách ---
            if re.match(r'^-{3,}$', p.strip()):
                continue
            
            is_loop = False
            # Kiểm tra lặp chu kỳ k đoạn (k từ 1 đến 12 để bắt được cả khối lớn 6-10 bước)
            for k in range(1, min(i + 1, 13)):
                if i >= 2 * k - 1:
                    prev_cycle = [re.sub(r'^[\#\*\_\-\.\s0-9]+', '', x).lower().strip() for x in paragraphs[i - 2*k + 1 : i - k + 1] if not re.match(r'^-{3,}$', x.strip())]
                    curr_cycle = [re.sub(r'^[\#\*\_\-\.\s0-9]+', '', x).lower().strip() for x in paragraphs[i - k + 1 : i + 1] if not re.match(r'^-{3,}$', x.strip())]
                    if prev_cycle == curr_cycle and all(len(x) > 10 for x in curr_cycle):
                        is_loop = True
                        break
                # Kiểm tra lặp đoạn/bước lùi k bước
                if k <= 8 and i >= k:
                    prev_p = re.sub(r'^[\#\*\_\-\.\s0-9]+', '', paragraphs[i - k]).lower().strip()
                    if len(norm_p) > 15 and (norm_p == prev_p or (len(norm_p) > 40 and norm_p in prev_p)):
                        is_loop = True
                        break
            
            if is_loop:
                cycle_found = True
                break
            truncated_paragraphs.append(p)
            
        if cycle_found and truncated_paragraphs:
            text = "\n\n".join(truncated_paragraphs)

    # 2. PHÁT HIỆN LẶP DÒNG LIÊN TỤC TRONG CÙNG 1 ĐOẠN
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    if len(lines) >= 3:
        clean_lines = []
        for i, line in enumerate(lines):
            norm_l = re.sub(r'^[\#\*\_\-\.\s0-9]+', '', line).lower().strip()
            if re.match(r'^-{3,}$', line.strip()):
                clean_lines.append(line)
                continue
            is_line_loop = False
            for k in range(1, min(i + 1, 8)):
                prev_l = re.sub(r'^[\#\*\_\-\.\s0-9]+', '', lines[i - k]).lower().strip()
                if len(norm_l) > 15 and norm_l == prev_l:
                    is_line_loop = True
                    break
            if is_line_loop:
                break
            clean_lines.append(line)
        text = "\n".join(clean_lines)

    # 3. PHÁT HIỆN LẶP CỤM TỪ LIÊN TỤC (N-GRAM LOOP)
    loop_pattern = re.compile(r"((?:\b\w+[\s.,;:?!]+){2,25}?)\1{2,}", re.IGNORECASE)
    def _replace_loop(match: re.Match[str]) -> str:
        return match.group(1).strip()
    for _ in range(3):
        new_text = loop_pattern.sub(_replace_loop, text)
        if new_text == text:
            break
        text = new_text

    return text.strip()


def is_available() -> bool:
    """Probe nhanh để kiểm tra LM Studio có sẵn sàng không.

    Gửi 1 request tối thiểu (max_tokens=1) — không raise exception,
    chỉ trả True/False. Dùng cho health check endpoint.

    Returns:
        True nếu LM Studio phản hồi hợp lệ, False nếu không.
    """
    s = get_settings()
    try:
        client = _get_client()
        client.chat.completions.create(
            model=s.lm_studio_model,
            messages=[{"role": "user", "content": "ping"}],
            max_tokens=1,
            temperature=0.0,
        )
        return True
    except Exception as exc:  # noqa: BLE001
        logger.debug("LLM health probe thất bại: %s", exc)
        return False


# ────────────────────────────────────────────────────────────────────────────
# Custom Exceptions
# ────────────────────────────────────────────────────────────────────────────

class LLMConnectionError(RuntimeError):
    """LM Studio không thể kết nối — chưa chạy hoặc sai port."""


class LLMInferenceError(RuntimeError):
    """Model đang chạy nhưng sinh câu trả lời thất bại."""
