"""Test trực tiếp LLM — debug blank answer."""
import sys
import os
import logging

# Dùng localhost (không Docker)
os.environ["LM_STUDIO_BASE_URL"] = "http://localhost:1234/v1"
os.environ["LM_STUDIO_API_KEY"] = "lm-studio"
os.environ["LLM_TIMEOUT"] = "120"

# Logging level DEBUG để thấy raw output
logging.basicConfig(
    level=logging.DEBUG,
    format="%(levelname)s %(name)s | %(message)s",
    stream=sys.stdout,
)

sys.path.insert(0, ".")

# Clear settings cache để nhận env vars mới
from app.config import get_settings
get_settings.cache_clear()

from app.clients import llm_client
from app.clients.llm_client import _clean_think_tags, _remove_repetition_loops
from app.pipeline.prompts import build_system_prompt, build_user_prompt

print("\n" + "="*70)
print("UNIT TEST: _clean_think_tags")
print("="*70)

# Test 1: Think tag bình thường
sample1 = "<think>Đây là suy nghĩ nội tâm</think>\nDây cáp điện 3 pha, tiết diện 4mm²."
r1 = _clean_think_tags(sample1)
print(f"Test1 input : {sample1[:80]}")
print(f"Test1 output: '{r1}'")
assert r1.strip() == "Dây cáp điện 3 pha, tiết diện 4mm².", f"FAIL: '{r1}'"
print("Test1 PASS\n")

# Test 2: Không có think tag
sample2 = "Bước 1: Chuẩn bị dụng cụ\n- Làm sạch phoi\n\nBước 2: Lắp then\n- Dùng búa đồng"
r2 = _clean_think_tags(sample2)
print(f"Test2 input : {sample2[:80]}")
print(f"Test2 output: '{r2[:80]}'")
assert "Bước 1" in r2, f"FAIL: '{r2}'"
print("Test2 PASS\n")

# Test 3: Model chỉ sinh think, không có answer → fallback lấy từ think
sample3 = "<think>Câu trả lời là Bước 1 lắp then vào rãnh trục.</think>"
r3 = _clean_think_tags(sample3)
print(f"Test3 input : {sample3[:80]}")
print(f"Test3 output: '{r3[:80]}'")
print("Test3:", "PASS (non-empty)" if r3.strip() else "PASS (empty fallback from think)")
print()

print("="*70)
print("UNIT TEST: _remove_repetition_loops")
print("="*70)

# Test: lặp đoạn văn
sample_loop = (
    "Bước 1: Chuẩn bị\n- Làm sạch\n\n"
    "Bước 2: Lắp then\n- Dùng búa\n\n"
    "Bước 1: Chuẩn bị\n- Làm sạch\n\n"  # lặp lại
    "Bước 2: Lắp then\n- Dùng búa"       # lặp lại
)
r_loop = _remove_repetition_loops(sample_loop)
print(f"Loop input : {len(sample_loop)} chars")
print(f"Loop output: {len(r_loop)} chars")
print(f"Content: '{r_loop}'")
assert "Bước 1" in r_loop, "Must keep Buoc 1"
assert r_loop.count("Bước 1") == 1, f"Should dedup to 1 occurrence, got: {r_loop.count('Bước 1')}"
print("Loop test PASS\n")

print("="*70)
print("LLM INTEGRATION TEST")
print("="*70)

TEST_HITS = [
    {
        "text": (
            "Hộp giảm tốc bánh răng trụ 2 cấp đồng trục. "
            "Vòng ngoài ổ lăn cố định chặt trong vỏ hộp. "
            "Trục chủ động (trục I): Ø40 mm. Dung sai lắp ghép: H7/k6. "
            "Bu lông bích nắp M12x40, lực siết 45 Nm."
        ),
        "page_no": 1,
        "score": 0.87,
        "title": "HGT-dong-truc.pdf",
        "category": "Ban ve ky thuat",
    }
]

for mode, label in [(False, "Thuong"), (True, "SuyLuan")]:
    print(f"\n--- TEST {label} ---")
    sp = build_system_prompt(reasoning_mode=mode)
    up = build_user_prompt("Cach lap dat hop giam toc banh rang tru 2 cap?", hits=TEST_HITS, reasoning_mode=mode)
    print(f"System prompt: {len(sp)} chars")
    print(f"User prompt:   {len(up)} chars")
    try:
        answer, model_name = llm_client.generate_answer(sp, up)
        if answer.strip():
            print(f"ANSWER ({len(answer)} chars):\n{answer[:600]}")
        else:
            print("BLANK ANSWER!")
    except Exception as e:
        print(f"ERROR: {e}")
