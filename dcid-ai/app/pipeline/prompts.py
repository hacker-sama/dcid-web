"""Prompt Templates cho Smart KCN Docs — RAG Query Pipeline.

Thiết kế cho model nhỏ (1.5B–2B): prompt ngắn gọn, rõ ràng, ép buộc bám sát context,
KHÔNG cho phép hallucination (bịa đặt) khi context là OCR rác hoặc không đủ thông tin.
"""

from __future__ import annotations

# ────────────────────────────────────────────────────────────────────────────
# System Prompts — Quy tắc chống hallucination CỨNG cho model nhỏ
# ────────────────────────────────────────────────────────────────────────────

_SYSTEM_BASE = """Bạn là chuyên gia phân tích tài liệu kỹ thuật.

NHIỆM VỤ: Đọc phần "THÔNG TIN TỪ TÀI LIỆU" bên dưới rồi trả lời câu hỏi của người dùng.

QUY TẮC BẮT BUỘC:
1. CHỈ ĐƯỢC sử dụng thông tin CÓ TRONG phần "THÔNG TIN TỪ TÀI LIỆU". TUYỆT ĐỐI KHÔNG ĐƯỢC bịa thêm thông tin không có trong tài liệu.
2. Phải TRÍCH DẪN trực tiếp các con số, thông số, tên chi tiết, vật liệu tìm thấy trong tài liệu.
3. Nếu text tài liệu khó đọc hoặc bị lỗi OCR (ví dụ: toàn ký tự rời rạc, số liệu không rõ ràng), hãy nói thẳng: "Text tài liệu bị lỗi OCR, chỉ đọc được một số thông tin sau: ..." rồi liệt kê những gì đọc được.
4. KHÔNG ĐƯỢC nhắc tới các tính năng hệ thống (Search by Image, Image Recognition, Smart KCN Docs...). Chỉ trả lời về NỘI DUNG tài liệu.
5. KHÔNG lặp lại câu hỏi. Trả lời bằng CÙNG NGÔN NGỮ với câu hỏi."""

_SYSTEM_REASONING_BASE = """Bạn là chuyên gia phân tích tài liệu và bản vẽ kỹ thuật.

NHIỆM VỤ: Đọc phần "THÔNG TIN TỪ TÀI LIỆU" bên dưới rồi giải thích chi tiết cho người dùng.

QUY TẮC BẮT BUỘC:
1. CHỈ ĐƯỢC sử dụng thông tin CÓ TRONG phần "THÔNG TIN TỪ TÀI LIỆU". TUYỆT ĐỐI KHÔNG ĐƯỢC bịa thêm thông tin không có trong tài liệu.
2. Phải TRÍCH DẪN trực tiếp các con số, thông số, tên chi tiết, vật liệu tìm thấy trong tài liệu.
3. Nếu text tài liệu khó đọc hoặc bị lỗi OCR (ví dụ: toàn ký tự rời rạc, số liệu không rõ ràng), hãy nói thẳng: "Text tài liệu bị lỗi OCR, chỉ đọc được một số thông tin sau: ..." rồi liệt kê những gì đọc được.
4. KHÔNG ĐƯỢC nhắc tới các tính năng hệ thống (Search by Image, Image Recognition, Smart KCN Docs...). Chỉ trả lời về NỘI DUNG tài liệu.
5. KHÔNG lặp lại câu hỏi. Trả lời bằng CÙNG NGÔN NGỮ với câu hỏi."""

_NUMERIC_SUFFIX = "\nLƯU Ý THÊM: Phải trích xuất chính xác các con số và đơn vị đo từ tài liệu."

_CONTEXT_HEADER = "\n--- THÔNG TIN TỪ TÀI LIỆU ---\n"
_CONTEXT_FOOTER = "\n--- HẾT THÔNG TIN TÀI LIỆU ---\n"
_NO_CONTEXT = "\n--- KHÔNG CÓ THÔNG TIN TÀI LIỆU ---\n"


def build_system_prompt(
    numeric_rule: bool = False,
    reasoning_mode: bool = False,
) -> str:
    """Xây dựng system prompt (chỉ chứa chỉ dẫn hệ thống)."""
    base = _SYSTEM_REASONING_BASE if reasoning_mode else _SYSTEM_BASE
    if numeric_rule:
        return base + _NUMERIC_SUFFIX
    return base


def build_user_prompt(question: str, hits: list[dict], reasoning_mode: bool = False, history: list | None = None) -> str:
    """Xây dựng user prompt với context chunks từ ChromaDB."""
    parts: list[str] = []
    
    parts.append(_CONTEXT_HEADER)
    if hits:
        for i, hit in enumerate(hits, start=1):
            title     = hit.get("title", "").strip()
            category  = hit.get("category", "").strip()
            page_no   = hit.get("page_no", "?")
            bbox_str  = hit.get("bbox", "").strip()
            text      = hit.get("text", "").strip()

            # Header rõ ràng: tên tài liệu + loại + trang
            header_parts = []
            if title:
                header_parts.append(f"Tài liệu: '{title}'")
            if category:
                header_parts.append(f"Loại: {category}")
            header_parts.append(f"Trang {page_no}")
            if bbox_str and bbox_str.upper() != "N/A":
                header_parts.append(f"Tọa độ: {bbox_str}")
            location_info = " | ".join(header_parts)

            parts.append(f"[Đoạn {i} - {location_info}]\n{text}\n")
        parts.append(_CONTEXT_FOOTER)
    else:
        parts.append(_NO_CONTEXT)

    # Câu hỏi + chỉ thị bám sát context cứng
    parts.append(f"\nCâu hỏi: {question.strip()}\n")
    parts.append("Trả lời DỰA TRÊN NỘI DUNG tài liệu ở trên. Nếu text khó đọc thì liệt kê những gì đọc được.")
    return "".join(parts)
