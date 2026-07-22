"""Prompt Templates cho Smart KCN Docs — RAG Query Pipeline.

Thiết kế cho model nhỏ (1.5B): prompt ngắn gọn, rõ ràng, ít bị echo lại.
"""

from __future__ import annotations

# ── System prompt cơ bản (ngắn để model 1.5B - 9B không echo) ──────────────────────
_SYSTEM_BASE = """Bạn là chuyên gia kỹ thuật của hệ thống Smart KCN Docs.
Trả lời dựa trên [TÀI LIỆU] bên dưới. Dữ liệu chứa kết quả OCR cấu trúc hóa từ bản vẽ hoặc bảng biểu kèm tọa độ không gian (Bbox). Hãy kết nối logic cấu trúc và không gian này để tìm ra câu trả lời.
Nếu không có thông tin, nói rõ không có.
Quy tắc quan trọng: Trả lời ngắn gọn, đúng trọng tâm. ĐẶC BIỆT: Phải trả lời bằng CÙNG NGÔN NGỮ với câu hỏi của người dùng (hỏi tiếng Việt -> trả lời tiếng Việt, hỏi English -> trả lời English). Ghi rõ số (Trang X | Bbox Y) khi trích dẫn số liệu kỹ thuật hoặc chi tiết từ bản vẽ."""

_SYSTEM_REASONING_BASE = """Bạn là chuyên gia kỹ thuật của hệ thống Smart KCN Docs.
Dựa trên [TÀI LIỆU] bên dưới, hãy hướng dẫn từng bước (Bước 1, 2, 3...) hoặc phân tích chi tiết bản vẽ kỹ thuật.
Lưu ý: Dữ liệu [TÀI LIỆU] là văn bản OCR được cấu trúc hóa theo không gian (Bbox), chứa BOM, danh sách chi tiết, số hiệu, vật liệu. Hãy tự xâu chuỗi các mã số với tên gọi và tọa độ tương ứng.
Mỗi bước: làm gì, công cụ gì, lý do kỹ thuật. 
Quy tắc quan trọng: ĐẶC BIỆT: Phải trả lời bằng CÙNG NGÔN NGỮ với câu hỏi của người dùng (hỏi tiếng Việt -> trả lời tiếng Việt, hỏi English -> trả lời English). Ghi rõ số (Trang X | Bbox Y) khi trích dẫn số liệu hoặc chi tiết từ bản vẽ."""

_NUMERIC_SUFFIX = "\nTRÍCH XUẤT CHÍNH XÁC: số liệu + đơn vị đo + tọa độ Bbox. Không làm tròn."

_CONTEXT_HEADER = "\n\n[TÀI LIỆU]\n"
_CONTEXT_FOOTER = "\n[HẾT TÀI LIỆU]\n"
_NO_CONTEXT = "\n[TÀI LIỆU: Không có thông tin liên quan.]\n"


def build_system_prompt(
    hits: list[dict],
    numeric_rule: bool = False,
    reasoning_mode: bool = False,
) -> str:
    """Xây dựng system prompt đầy đủ gồm base + cấu trúc không gian context."""
    base = _SYSTEM_REASONING_BASE if reasoning_mode else _SYSTEM_BASE
    parts: list[str] = [base]

    if numeric_rule:
        parts.append(_NUMERIC_SUFFIX)

    parts.append(_CONTEXT_HEADER)
    if hits:
        for i, hit in enumerate(hits, start=1):
            page_no   = hit.get("page_no", "?")
            score_pct = round(hit.get("score", 0) * 100, 1)
            title     = hit.get("title", "").strip() or "Tài liệu kỹ thuật"
            category  = hit.get("category", "").strip()
            title_str = f"{category}: {title}" if category else title
            bbox_str  = hit.get("bbox", "").strip() or "N/A"
            text      = hit.get("text", "").strip()
            parts.append(
                f"\n[Đoạn {i} | {title_str} | Trang {page_no} | Bbox: {bbox_str} | Liên quan: {score_pct}%]\n{text}\n"
            )
        parts.append(_CONTEXT_FOOTER)
    else:
        parts.append(_NO_CONTEXT)

    return "".join(parts)


def build_user_prompt(question: str, reasoning_mode: bool = False, history: list | None = None) -> str:
    """Trả về câu hỏi kèm lịch sử hội thoại gần nhất (nếu có)."""
    clean_q = question.strip()
    if not history:
        return clean_q

    lines = ["[LỊCH SỬ]"]
    for msg in history[-4:]:  # giới hạn 4 lượt để giảm token cho model 1.5B
        role = getattr(msg, "role", None) if not isinstance(msg, dict) else msg.get("role")
        content = getattr(msg, "content", None) if not isinstance(msg, dict) else msg.get("content", "")
        role_label = "Người dùng" if role == "user" else "AI"
        if content and content.strip():
            lines.append(f"{role_label}: {content.strip()}")
    lines.append(f"\n[CÂU HỎI]\n{clean_q}")
    return "\n".join(lines)
