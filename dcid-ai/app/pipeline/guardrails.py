"""Guardrails — STUB (một phần). θ cosine và numeric rule (contract §2.2).

Lưu ý: skeleton hiện dùng regex numeric riêng trong app/api/query.py (mock).
Đợt sau chuyển query.py sang gọi check_numeric() ở đây.
"""

# Ngưỡng cosine: dưới ngưỡng → guardrail locked (contract §2.2)
THRESHOLD: float = 0.60


def check_numeric(question: str) -> bool:
    """True nếu câu hỏi chạm nhóm thông số kỹ thuật
    (điện áp/áp suất/nhiệt độ/dung sai/momen) → kích hoạt numeric rule-extraction.

    TODO(đợt sau): rule-extraction thật (regex đơn vị + tra bảng thông số từ chunk).
    """
    raise NotImplementedError("Numeric guardrail chưa triển khai — đợt sau")
