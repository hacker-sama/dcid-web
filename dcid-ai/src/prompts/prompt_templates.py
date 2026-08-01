"""Quản lý Prompt Templates cho Qwen2-VL-2B (Visual Captioner) và Main LLM (RAG Reasoning)."""

from typing import Any, Dict, List, Optional

# ────────────────────────────────────────────────────────────────────────────
# 1. TASK-TUNED PROMPTS CHO QWEN2-VL-2B (Visual Captioner ở khâu Ingestion)
# ────────────────────────────────────────────────────────────────────────────

PROMPT_QWEN_VL_CAPTION = (
    "Trích xuất toàn bộ văn bản trong ảnh này và mô tả ngắn gọn nội dung hình ảnh trong 2-3 câu."
)

PROMPT_QWEN_VL_LABELS = (
    "Hãy đọc và liệt kê tất cả các nhãn chữ (labels), ký hiệu và con số có trong hình này."
)

PROMPT_QWEN_VL_TABLE = (
    "Trích xuất dữ liệu bảng này thành định dạng Markdown Table."
)

PROMPT_QWEN_VL_CLASSIFY = (
    "Bức ảnh này biểu diễn cái gì? Chọn 1 trong các loại: [Sơ đồ khối, Bảng biểu, Bản vẽ kỹ thuật, Sơ đồ mạch]."
)


# ────────────────────────────────────────────────────────────────────────────
# 2. PROMPTS CHO MAIN TEXT LLM (Qwen2.5-7B / Gemma-2-9B ở khâu RAG Query)
# ────────────────────────────────────────────────────────────────────────────

SYSTEM_RAG_BASE = """Bạn là chuyên gia tư vấn kỹ thuật và phân tích tài liệu DCID.
Hãy trả lời câu hỏi của người dùng một cách chính xác, tự nhiên dựa trên các đoạn tài liệu được cung cấp.
Nếu trong thông tin có đề cập đến ảnh crop (image_path), hãy dẫn chiếu rõ ràng để người dùng tiện theo dõi."""

SYSTEM_REASONING_BASE = """Bạn là chuyên gia cơ khí và kỹ thuật hệ thống.
Hãy suy luận tự do và giải đáp chi tiết câu hỏi dựa trên dữ liệu tài liệu đính kèm bên dưới."""

NUMERIC_RULE_SUFFIX = "\nLƯU Ý QUAN TRỌNG: Phải trích xuất chính xác các thông số, con số và đơn vị đo kỹ thuật (như V, A, bar, mm, kW...) từ tài liệu."

CONTEXT_HEADER = "\n<context_documents>\n"
CONTEXT_FOOTER = "</context_documents>\n"
NO_CONTEXT = "<context_documents><!-- Không tìm thấy tài liệu phù hợp trong cơ sở dữ liệu --></context_documents>\n"


def build_system_prompt(
    numeric_rule: bool = False,
    reasoning_mode: bool = False,
) -> str:
    """Tạo System Prompt cho Main Text LLM."""
    base = SYSTEM_REASONING_BASE if reasoning_mode else SYSTEM_RAG_BASE
    if numeric_rule:
        return base + NUMERIC_RULE_SUFFIX
    return base


def build_user_prompt(
    question: str,
    hits: List[Dict[str, Any]],
) -> str:
    """Đóng gói User Prompt chứa context chunks (có kèm `image_path` nếu có) + câu hỏi."""
    parts: List[str] = [CONTEXT_HEADER]

    if hits:
        for i, hit in enumerate(hits, start=1):
            title = hit.get("title", "").strip()
            page_no = hit.get("page_no", "?")
            bbox_str = hit.get("bbox", "").strip()
            image_path = hit.get("image_path", "").strip()
            text = hit.get("text", "").strip()

            header_attrs = [f'id="{i}"', f'page="{page_no}"']
            if title:
                header_attrs.append(f'title="{title}"')
            if bbox_str and bbox_str.upper() != "N/A":
                header_attrs.append(f'bbox="{bbox_str}"')
            if image_path:
                header_attrs.append(f'image_path="{image_path}"')

            attrs_str = " ".join(header_attrs)
            parts.append(f"<document {attrs_str}>\n{text}\n</document>\n")
        parts.append(CONTEXT_FOOTER)
    else:
        parts.append(NO_CONTEXT)

    parts.append(f"\nCâu hỏi của người dùng: {question.strip()}\n")
    return "".join(parts)
