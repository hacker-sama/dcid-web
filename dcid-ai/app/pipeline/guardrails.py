"""Guardrails — Kiểm tra chất lượng và phân loại câu hỏi (contract §2.2).

Hai tầng guardrail:
1. Cosine threshold (THRESHOLD = 0.60):
   - Điểm similarity tốt nhất từ ChromaDB < ngưỡng → locked=True.
   - Tài liệu không đủ liên quan → không gọi LLM, trả thông báo chuẩn.

2. Numeric rule extraction:
   - Câu hỏi đề cập đến thông số kỹ thuật số liệu (điện áp, áp suất, v.v.)
   - Kích hoạt chỉ thị đặc biệt trong prompt buộc LLM trích xuất con số chính xác.
"""

from __future__ import annotations

import re

# ────────────────────────────────────────────────────────────────────────────
# Ngưỡng cosine — dưới ngưỡng → guardrail locked (contract §2.2)
# ────────────────────────────────────────────────────────────────────────────
THRESHOLD: float = 0.60

# ────────────────────────────────────────────────────────────────────────────
# Regex nhận diện câu hỏi về thông số kỹ thuật (numeric rule)
# ────────────────────────────────────────────────────────────────────────────
_NUMERIC_PATTERN = re.compile(
    r"""
    \b(
        điện\s*áp   | voltage  | volt
      | áp\s*suất   | pressure | bar  | psi
      | nhiệt\s*độ  | temperature | celsius | độ\s*c
      | dung\s*sai  | tolerance
      | mô\s*men    | momen    | torque
      | công\s*suất | watt     | kw   | hp
      | tốc\s*độ    | rpm      | vòng\s*/\s*phút
      | lưu\s*lượng | flow\s*rate | l\s*/\s*phút | m3
      | kích\s*thước | chiều\s*(rộng|cao|dài|dày|sâu)
      | đường\s*kính | bán\s*kính | mm   | cm   | m\b
      | khối\s*lượng | kg       | tấn  | lbs
      | tần\s*số    | hz       | khz
      | điện\s*trở  | ohm
      | dòng\s*điện | ampere   | amp  | \ba\b
      | công\s*thức
    )\b
    """,
    re.IGNORECASE | re.VERBOSE,
)


_REASONING_PATTERN = re.compile(
    r"""
    \b(
        tư\s*vấn   | suy\s*luận | suy\s*đoán
      | lắp\s*đặt  | lắp\s*ráp  | các\s*bước\s*lắp | quy\s*trình\s*lắp | hướng\s*dẫn\s*lắp
      | tháo\s*lắp | bảo\s*trì  | thao\s*tác
      | reasoning  | assembly   | procedure
    )\b
    """,
    re.IGNORECASE | re.VERBOSE,
)


def check_numeric(question: str) -> bool:
    """True nếu câu hỏi đề cập thông số kỹ thuật số liệu.

    Khi True → numeric rule được kích hoạt trong prompt, LLM được chỉ thị
    trích xuất chính xác tuyệt đối con số + đơn vị đo lường từ văn bản.

    Args:
        question: Câu hỏi người dùng (UTF-8, tiếng Việt hoặc tiếng Anh).

    Returns:
        True nếu phát hiện từ khóa số liệu kỹ thuật.
    """
    return bool(_NUMERIC_PATTERN.search(question))


def check_reasoning_mode(question: str, explicit_flag: bool = False) -> bool:
    """True nếu bật chế độ tư vấn/suy luận (từ cờ API hoặc từ khóa câu hỏi)."""
    if explicit_flag:
        return True
    return bool(_REASONING_PATTERN.search(question))


def is_locked(hits: list[dict], question: str, reasoning_mode: bool = False) -> bool:
    """True nếu cần kích hoạt guardrail khóa (không gọi LLM).

    Các trường hợp kích hoạt:
    - Không có hits nào từ ChromaDB.
    - Điểm similarity tốt nhất (hits[0]["score"]) < THRESHOLD (trừ khi bật reasoning_mode).
    - Câu hỏi chứa trigger phrase "không có trong tài liệu".

    Args:
        hits:           Danh sách kết quả search từ ChromaDB (đã sort theo score desc).
        question:       Câu hỏi người dùng.
        reasoning_mode: Chế độ tư vấn/suy luận lắp đặt.

    Returns:
        True nếu nên khóa (trả thông báo chuẩn, không gọi LLM).
    """
    locked_trigger = "không có trong tài liệu"
    if locked_trigger in question.lower():
        return True
    if not hits:
        return True
    # Khi ở chế độ tư vấn/suy luận, cho phép ngưỡng similarity thấp hơn (0.25)
    # để lấy được các chi tiết bản vẽ và thực hiện suy luận quy trình,
    # hoặc trả lời các câu hỏi tóm tắt chung chung (độ tương đồng ngữ nghĩa thấp).
    threshold = 0.25 if reasoning_mode else THRESHOLD
    return hits[0]["score"] < threshold
