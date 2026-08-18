"""Test performance & accuracy of DCID RAG Web Pipeline with Chroma DB insertion into kcn_chunks."""
import os
import time
import json
import requests
from uuid import UUID

AI_URL = "http://localhost:8000/ai/query"
TOKEN = "change-me-internal-token"
SAMPLE_VERSION_ID = "11111111-1111-1111-1111-111111111111"

def setup_sample_chroma():
    """Nạp 1 đoạn tài liệu mẫu vào ChromaDB collection kcn_chunks để test đúng luồng RAG thật."""
    try:
        import chromadb
        from app.pipeline import embed as embed_pipeline
        from app.pipeline import index as index_pipeline
        
        client = chromadb.HttpClient(host="localhost", port=8001)
        col = client.get_or_create_collection(name=index_pipeline.COLLECTION_NAME, metadata={"hnsw:space": "cosine"})
        
        doc_text = (
            "Hộp giảm tốc bánh răng trụ 2 cấp đồng trục. Vòng ngoài ổ lăn cố định chặt trong vỏ hộp. "
            "Trục chủ động (trục I): Ø40 mm. Dung sai lắp ghép: H7/k6. Bu lông bích nắp M12x40, lực siết 45 Nm. "
            "Quy trình lắp đặt: Bước 1 Làm sạch bavia phoi gia công; "
            "Bước 2 Lắp gối đỡ và ổ bi vào trục I với dung sai H7/k6; "
            "Bước 3 Đặt cụm trục vào vỏ hộp và siết bu lông nắp M12x40 với lực siết 45 Nm."
        )
        
        vec = embed_pipeline.embed_texts([doc_text])[0]
        col.upsert(
            ids=[f"{SAMPLE_VERSION_ID}_1_0"],
            embeddings=[vec],
            documents=[doc_text],
            metadatas=[{
                "version_id": SAMPLE_VERSION_ID,
                "document_id": "22222222-2222-2222-2222-222222222222",
                "page_no": 1,
                "chunk_index": 0,
                "bbox_key": "page-1-bbox-1",
                "title": "Bản vẽ HGT đồng trục",
                "category": "Cơ khí"
            }]
        )
        print(f"[SUCCESS] Đã nạp tài liệu mẫu vào Chroma collection '{index_pipeline.COLLECTION_NAME}' với version_id={SAMPLE_VERSION_ID}")
    except Exception as e:
        print(f"[ERROR] Không nạp được mẫu vào ChromaDB: {e}")

def run_test(question: str, reasoning_mode: bool):
    payload = {
        "question": question,
        "topK": 5,
        "allowedVersionIds": [SAMPLE_VERSION_ID],
        "reasoningMode": reasoning_mode
    }
    headers = {"X-Internal-Token": TOKEN, "Content-Type": "application/json"}
    
    start = time.perf_counter()
    resp = requests.post(AI_URL, json=payload, headers=headers, timeout=120)
    elapsed = round((time.perf_counter() - start) * 1000, 2)
    
    if resp.status_code != 200:
        print(f"[{'SUY LUẬN' if reasoning_mode else 'THƯỜNG'}] ERROR {resp.status_code}: {resp.text}")
        return None
        
    data = resp.json()
    print(f"\n=======================================================")
    print(f"CHẾ ĐỘ: {'SUY LUẬN (Từng bước theo prompt.py)' if reasoning_mode else 'THƯỜNG (Ngắn gọn theo prompt.py)'}")
    print(f"Câu hỏi: {question}")
    print(f"Thời gian phản hồi tổng (Total Latency): {elapsed} ms (AI inference latencyMs: {data.get('latencyMs')} ms)")
    print(f"Model: {data.get('model')} | Confidence: {data.get('confidence')}")
    print(f"Guard: {data.get('guard')}")
    print(f"Citations: {len(data.get('citations', []))} hits")
    for c in data.get('citations', []):
        print(f"   -> Trang {c.get('pageNo')} | Bbox: {c.get('bboxKey')}")
    print(f"-------------------------------------------------------")
    print(f"CÂU TRẢ LỜI TỪ AI:\n{data.get('answer')}")
    print(f"=======================================================")
    return data

if __name__ == "__main__":
    setup_sample_chroma()
    
    print("\n=== BẮT ĐẦU TEST HIỆU NĂNG & ĐỘ CHÍNH XÁC THEO PROMPT.PY ===")
    q = "Quy trình các bước lắp đặt hộp giảm tốc theo bản vẽ là gì?"
    
    # 1. Test chế độ Thường
    run_test(q, reasoning_mode=False)
    
    # 2. Test chế độ Suy Luận
    run_test(q, reasoning_mode=True)
