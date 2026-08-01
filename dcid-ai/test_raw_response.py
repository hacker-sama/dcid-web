"""Test refined prompt and zero frequency/presence penalties."""
import json
from openai import OpenAI

client = OpenAI(base_url="http://localhost:1234/v1", api_key="lm-studio")

# Thêm yêu cầu rõ ràng để model suy luận và trả lời hoàn toàn bằng tiếng Việt
system_prompt = (
    "Bạn là kỹ sư cơ khí KCN. Hãy đọc kỹ [TÀI LIỆU] và trả lời câu hỏi bằng tiếng Việt.\n"
    "Quy tắc:\n"
    "1. Chỉ sử dụng thông tin từ [TÀI LIỆU]. Ghi rõ (Trang X) sau thông số.\n"
    "2. Trả lời rõ ràng theo từng bước: Bước 1, Bước 2, Bước 3.\n"
    "3. Tuyệt đối không dùng tiếng Anh trong câu trả lời.\n\n"
    "[TÀI LIỆU]\n"
    "[Đoạn 1 | Bản vẽ kỹ thuật | Trang 1 | Liên quan: 87%]\n"
    "Hộp giảm tốc bánh răng trụ 2 cấp đồng trục. Vòng ngoài ổ lăn cố định chặt trong vỏ hộp. "
    "Trục chủ động (trục I): Ø40 mm. Dung sai lắp ghép: H7/k6. Bu lông bích nắp M12x40, lực siết 45 Nm.\n"
    "[HẾT TÀI LIỆU]"
)
user_prompt = "Quy trình các bước lắp đặt hộp giảm tốc theo bản vẽ là gì?"

# Test C: freq=0, pres=0, rep_penalty=1.01 (tối ưu cho tiếng Việt)
resp_clean_pen = client.chat.completions.create(
    model="deepseek-r1-distill-qwen-1.5b",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ],
    temperature=0.1,
    max_tokens=1500,
    frequency_penalty=0.0,
    presence_penalty=0.0,
    extra_body={"repetition_penalty": 1.01, "repeat_penalty": 1.01}
)

output = {
    "test_C_refined_and_tuned": {
        "content": resp_clean_pen.choices[0].message.content,
        "reasoning": getattr(resp_clean_pen.choices[0].message, "reasoning_content", None),
        "usage": resp_clean_pen.usage.model_dump() if hasattr(resp_clean_pen.usage, "model_dump") else str(resp_clean_pen.usage)
    }
}

with open("penalty_comparison_2.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print("SUCCESS: wrote penalty_comparison_2.json")
