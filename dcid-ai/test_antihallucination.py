"""Test prompt mới với text OCR thực tế từ tài liệu phandoi."""
import sys, os
os.environ["LM_STUDIO_BASE_URL"] = "http://localhost:1234/v1"
os.environ["LM_STUDIO_API_KEY"] = "lm-studio"
os.environ["LLM_TIMEOUT"] = "120"
sys.path.insert(0, ".")

from app.config import get_settings
get_settings.cache_clear()
from app.clients import llm_client
from app.pipeline.prompts import build_system_prompt, build_user_prompt

# Text OCR thực tế từ ChromaDB cho tài liệu phandoi (version c2b8d494...)
PHANDOI_HIT = {
    "text": (
        "### [Đoạn kỹ thuật - Trang 1 | Bbox: N/A]\n"
        "8 2 5 8 2 5 2 3 4 G72H7/h6 É 8 2 11 8 E o 91 5 F 23 3 "
        "M(N.mm) N(KW) n(vg/ph) 3 Tne 18599 2,785 1430 Déng cs "
        "DC TÍNH KÝ THUT Nói Truc Vòng Dàn Hi 18599 2,785 1430 "
        "54.15 71909 2,594 344,5 = (h - 3,46 238845 2,491 906 三 9 5 "
        "452270 9 bich -2 2 Ký hięu HT · M8 0em nlp4 Ten goi a Mng "
        "wir bich DONG BÄNG TÁI TK HÊ THÓNG DÁN u U SLgKLg Vąt lișu "
        "Thsip li Thip45 Thip 46 Thip 36 Thip (11 Thip CT) They CT) "
        "TNy CT7 Thip-11 LOP HCIC-KTIOA COI KHI Si kamy 7 CHITIET MAY "
        "DO AN MON HOC Ghi chú 1314 Ihuing lhoi Thuley lkoe"
    ),
    "page_no": 1,
    "score": 0.85,
    "title": "phandoi",
    "category": "DRAWING",
}

questions = [
    "giai thich ve tai lieu phandoi",
    "giai thich ban ve phandoi",
    "giai thich tai lieu tren",
]

for q in questions:
    print("\n" + "="*70)
    print(f"Q: '{q}'")
    print("="*70)
    sp = build_system_prompt(reasoning_mode=True)
    up = build_user_prompt(q, hits=[PHANDOI_HIT], reasoning_mode=True)
    answer, model = llm_client.generate_answer(sp, up)
    print(f"ANSWER ({len(answer)} chars):\n{answer[:800]}")
    print()
