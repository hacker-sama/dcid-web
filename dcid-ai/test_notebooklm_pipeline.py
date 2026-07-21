import urllib.request
import urllib.error
import json
import uuid
import sys

def run_test():
    sys.stdout.reconfigure(encoding='utf-8')
    print("=== TEST NOTEBOOKLM PIPELINE (DOCUMENT TARGETING & MULTI-TURN CHAT) ===")

    # 1. Test unit build_user_prompt trong prompts.py
    print("\n[1] Kiểm tra hàm format lịch sử hội thoại (prompts.build_user_prompt)...")
    try:
        from app.pipeline import prompts
        from app.schemas import ChatMessage
        
        q = "Thế các bước lắp ráp nó như thế nào?"
        hist = [
            ChatMessage(role="user", content="HGT động cơ chính có dung sai trục bao nhiêu?"),
            ChatMessage(role="assistant", content="Dung sai trục là H7/g6 theo bản vẽ kỹ thuật trang 4.")
        ]
        res = prompts.build_user_prompt(q, reasoning_mode=False, history=hist)
        print(" -> Kết quả format prompt với history:")
        print("--------------------------------------------------")
        print(res)
        print("--------------------------------------------------")
        assert "[LỊCH SỬ TRÒ CHUYỆN TRƯỚC ĐÓ]" in res
        assert "Người dùng: HGT động cơ chính có dung sai trục bao nhiêu?" in res
        assert "AI Tư vấn: Dung sai trục là H7/g6 theo bản vẽ kỹ thuật trang 4." in res
        assert "[CÂU HỎI HIỆN TẠI]" in res
        assert q in res
        print(" [✔] build_user_prompt format lịch sử hội thoại CHÍNH XÁC!")
    except Exception as e:
        print(f" [❌] Lỗi kiểm tra build_user_prompt: {e}")
        return False

    # 2. Test gọi trực tiếp API /ai/query với history và allowedVersionIds bị giới hạn (Document Targeting)
    print("\n[2] Kiểm tra API POST /ai/query với tham số history và allowedVersionIds cụ thể...")
    target_vid = str(uuid.uuid4())
    req_body = {
        "question": "Thế cách tháo lắp cụm chi tiết này ra sao?",
        "topK": 3,
        "allowedVersionIds": [target_vid], # Chỉ định 1 tài liệu mục tiêu
        "reasoningMode": True,
        "history": [
            {"role": "user", "content": "Bản vẽ này thuộc máy CNC XK-500 đúng không?"},
            {"role": "assistant", "content": "Đúng vậy, tài liệu này mô tả chi tiết máy CNC XK-500."}
        ]
    }

    url = "http://localhost:8000/ai/query"
    data_bytes = json.dumps(req_body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Internal-Token": "change-me-internal-token"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            resp_data = json.loads(resp.read().decode("utf-8"))
            print(" -> Phản hồi từ /ai/query:")
            print(f"    + Answer preview: {resp_data.get('answer')[:150]}...")
            print(f"    + Confidence: {resp_data.get('confidence')}")
            print(f"    + Guard: {resp_data.get('guard')}")
            print(" [✔] API /ai/query xử lý thành công request NotebookLM (Targeting + History)!")
            return True
    except urllib.error.HTTPError as he:
        print(f" [❌] HTTP Error {he.code}: {he.read().decode('utf-8')}")
        return False
    except Exception as ex:
        print(f" [❌] Lỗi gọi API /ai/query: {ex}")
        return False

if __name__ == "__main__":
    success = run_test()
    sys.exit(0 if success else 1)
