"""Prompt Templates cho Smart KCN Docs — RAG Query Pipeline.

Thiết kế cho model nhỏ (1.5B–2B, hỗ trợ cả Text LLM lẫn Vision VLM như Qwen2-VL): prompt ngắn gọn, rõ ràng,
KHÔNG cho phép hallucination (bịa đặt) khi context là OCR rác hoặc không đủ thông tin.
"""

from __future__ import annotations

# ────────────────────────────────────────────────────────────────────────────
# Task-Tuned Prompts cho Qwen2-VL-2B (Visual Captioner ở khâu Ingestion)
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
# System Prompts — Quy tắc chống hallucination CỨNG cho model nhỏ (Text & Vision)
# ────────────────────────────────────────────────────────────────────────────

_SYSTEM_BASE = """Bạn là trợ lý AI phân tích tài liệu kỹ thuật.
Hãy trả lời trực tiếp, tự nhiên và hữu ích như một trợ lý hội thoại thông thường, dựa trên tài liệu được cung cấp.
Không chép lại câu hỏi, không mô tả nhiệm vụ của bạn và không mở đầu bằng các nhãn như "Câu hỏi" hay "Câu hỏi mới nhất"."""

_SYSTEM_REASONING_BASE = """Bạn là chuyên gia cơ khí tư vấn kỹ thuật và tháo lắp thiết bị.
Hãy suy luận tự do và giải đáp chính xác câu hỏi của người dùng dựa trên dữ liệu tài liệu đính kèm."""

_SYSTEM_VISION_BASE = """Bạn là trợ lý AI đa thức thể phân tích bản vẽ kỹ thuật.
Hãy trực tiếp quan sát hình ảnh bản vẽ đính kèm kết hợp với dữ liệu văn bản để suy luận và trả lời câu hỏi của người dùng một cách đầy đủ, tự nhiên."""

_SYSTEM_VISION_REASONING_BASE = """Bạn là chuyên gia cơ khí đa thức thể phân tích bản vẽ và tư vấn kỹ thuật.
Hãy quan sát hình ảnh bản vẽ đính kèm và đọc dữ liệu văn bản để suy luận tự do, trả lời đúng trọng tâm câu hỏi của người dùng."""

_NUMERIC_SUFFIX = "\nLƯU Ý THÊM: Phải trích xuất chính xác các con số và đơn vị đo từ tài liệu/hình ảnh nếu có."

_CONTEXT_HEADER = "\n<context_documents>\n"
_CONTEXT_FOOTER = "</context_documents>\n"
_NO_CONTEXT = "<context_documents><!-- Không tìm thấy tài liệu phù hợp --></context_documents>\n"


def build_system_prompt(
    numeric_rule: bool = False,
    reasoning_mode: bool = False,
    has_image: bool = False,
) -> str:
    """Build system prompt hướng dẫn LLM trả lời dựa trên context tài liệu + ảnh đã được cung cấp."""
    if has_image and reasoning_mode:
        base = _SYSTEM_VISION_REASONING_BASE
    elif has_image:
        base = _SYSTEM_VISION_BASE
    elif reasoning_mode:
        base = _SYSTEM_REASONING_BASE
    else:
        base = _SYSTEM_BASE

    suffix = _NUMERIC_SUFFIX if numeric_rule else ""

    # Chỉ thị cứng: LLM phải trả lời trực tiếp từ dữ liệu đã có, KHÔNG hỏi thêm
    direct_instruction = (
        "\nDữ liệu cần dùng nằm trong context của tin nhắn người dùng. "
        "Chỉ xuất ra câu trả lời cuối cùng; không lặp lại câu hỏi hoặc chỉ dẫn. "
        "Nếu yêu cầu mang tính tổng quát như 'phân tích tài liệu', hãy chủ động tóm tắt nội dung, "
        "nêu các ý chính, thông số kỹ thuật, quy trình và cảnh báo tìm thấy. "
        "Nếu tài liệu chỉ có một phần thông tin, hãy phân tích phần hiện có và nói rõ giới hạn ở cuối. "
        "Không yêu cầu người dùng cung cấp lại tài liệu hoặc hình ảnh đã có trong context."
    )

    return base + direct_instruction + suffix


def build_user_prompt(
    question: str,
    hits: list[dict],
    reasoning_mode: bool = False,
    history: list | None = None,
    has_image: bool = False,
    machine_code: str | None = None,
) -> str:
    """Xây dựng user prompt trực tiếp: dữ liệu tài liệu + câu hỏi của người dùng."""
    parts: list[str] = []
    
    if machine_code:
        parts.append(f"\n[Bối cảnh: Bạn đang hỗ trợ bảo trì cho máy có mã {machine_code}. Hãy ưu tiên thông tin liên quan đến thiết bị này.]\n")

    parts.append(_CONTEXT_HEADER)
    if hits:
        for i, hit in enumerate(hits, start=1):
            title     = hit.get("title", "").strip()
            category  = hit.get("category", "").strip()
            page_no   = hit.get("page_no", "?")
            bbox_str  = hit.get("bbox", "").strip()
            text      = hit.get("text", "").strip()
            if has_image and len(text) > 400:
                text = text[:400] + "..."

            header_parts = []
            if title:
                header_parts.append(f"title='{title}'")
            if category:
                header_parts.append(f"category='{category}'")
            header_parts.append(f"page='{page_no}'")
            if bbox_str and bbox_str.upper() != "N/A":
                header_parts.append(f"bbox='{bbox_str}'")
            image_path = hit.get("image_path", "").strip()
            if image_path:
                header_parts.append(f"image_path='{image_path}'")
            attrs = " ".join(header_parts)

            parts.append(f"<document id=\"{i}\" {attrs}>\n{text}\n</document>\n")
        parts.append(_CONTEXT_FOOTER)
    else:
        parts.append(_NO_CONTEXT)

    if has_image:
        q_lower = question.lower()
        if any(kw in q_lower for kw in ["chỉ ra", "ở đâu", "vùng nào", "chỗ nào", "vị trí"]):
            parts.append(
                "\n[YÊU CẦU ĐẶC BIỆT]: Người dùng đang hỏi về vị trí. "
                "Nếu xác định được vị trí chi tiết trên ảnh, hãy thêm tọa độ vào cuối câu trả lời theo đúng định dạng:\n"
                "[LOC] (x1,y1),(x2,y2) [/LOC]\n"
                "Lưu ý: Tọa độ là các số nguyên từ 0 đến 1000.\n"
            )

    parts.append(
        "\n<user_request>\n"
        f"{question.strip()}\n"
        "</user_request>\n"
        "Trả lời ngay yêu cầu trên bằng nội dung hoàn chỉnh, không chép lại yêu cầu.\n"
    )
    return "".join(parts)
