#!/usr/bin/env python3
"""
Kiểm tra trạng thái ChromaDB (`kcn_chunks`) và đối chiếu với dữ liệu từ Backend.
"""
import sys
import io
import json
import urllib.request
import urllib.error

# Force UTF-8 stdout
if hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

CHROMA_HOST = "localhost"
CHROMA_PORT = 8001
BE_BASE_URL = "http://localhost:8080"
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"

def print_header(title):
    print(f"\n{'═' * 70}")
    print(f" 🔍  {title}")
    print(f"{'═' * 70}")

def get_chroma_collection_stats():
    try:
        import chromadb
        client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)
        
        # Check heartbeat
        heartbeat = client.heartbeat()
        print(f"✅ ChromaDB tại {CHROMA_HOST}:{CHROMA_PORT} hoạt động bình thường (heartbeat: {heartbeat})")
        
        try:
            col = client.get_collection("kcn_chunks")
            count = col.count()
            print(f"📦 Collection `kcn_chunks`: Hiện đang lưu trữ [{count}] chunks vector.")
            
            if count > 0:
                data = col.get(include=["metadatas", "documents"])
                metas = data.get("metadatas", [])
                docs = data.get("documents", [])
                
                # Group by version_id & document_id
                grouped = {}
                for idx, meta in enumerate(metas):
                    v_id = meta.get("version_id", "N/A")
                    d_id = meta.get("document_id", "N/A")
                    key = (d_id, v_id)
                    if key not in grouped:
                        grouped[key] = []
                    grouped[key].append({"page_no": meta.get("page_no"), "chunk_index": meta.get("chunk_index"), "text": docs[idx] if idx < len(docs) else ""})
                
                print(f"\n📑 Chi tiết {len(grouped)} phiên bản tài liệu có trong ChromaDB:")
                for (d_id, v_id), chunks in grouped.items():
                    print(f"\n   ├─ Document ID: {d_id}")
                    print(f"   ├─ Version ID : {v_id}")
                    print(f"   └─ Số chunks  : {len(chunks)} đoạn (Pages: {sorted(list(set(c['page_no'] for c in chunks)))})")
                    if chunks:
                        snippet = chunks[0]['text'][:100].replace('\n', ' ')
                        print(f"      [Preview chunk 0]: \"{snippet}...\"")
            return count
        except Exception as e:
            print(f"⚠️ Collection `kcn_chunks` chưa được tạo hoặc trống: {e}")
            return 0
    except ImportError:
        print("❌ Chưa cài đặt chromadb. Hãy chạy: pip install chromadb")
        return -1
    except Exception as e:
        print(f"❌ Không thể kết nối tới ChromaDB ({CHROMA_HOST}:{CHROMA_PORT}): {e}")
        return -1

def check_backend_documents():
    print_header("Đối chiếu với danh sách tài liệu từ Backend (:8080)")
    try:
        # Login
        req = urllib.request.Request(
            f"{BE_BASE_URL}/api/auth/login",
            data=json.dumps({"username": ADMIN_USER, "password": ADMIN_PASS}).encode(),
            headers={"Content-Type": "application/json"}
        )
        res = urllib.request.urlopen(req, timeout=10)
        token = json.loads(res.read().decode())["data"]["token"]
        
        # Get documents
        req_docs = urllib.request.Request(
            f"{BE_BASE_URL}/api/documents?size=100",
            headers={"Authorization": f"Bearer {token}"}
        )
        res_docs = urllib.request.urlopen(req_docs, timeout=10)
        items = json.loads(res_docs.read().decode())["data"]["items"]
        
        print(f"📋 Tổng số tài liệu trên Backend PostgreSQL: [{len(items)}] tài liệu.\n")
        if not items:
            print("   (Chưa có tài liệu nào trong PostgreSQL. Hãy dùng `upload_and_verify.py` để tải lên!)")
        else:
            for item in items:
                status = item.get("status", "UNKNOWN")
                status_icon = "🟢" if status == "ACTIVE" else ("🟡" if status == "PROCESSING" else "🔴")
                print(f"   {status_icon} [{status}] Tiêu đề: \"{item.get('title')}\"")
                print(f"      ID: {item.get('id')} | Category: {item.get('category')} | MinRole: {item.get('minRole')}")
                print(f"      Ngày tạo: {item.get('createdAt')}\n")
    except Exception as e:
        print(f"❌ Lỗi khi đối chiếu với Backend: {e}")

if __name__ == "__main__":
    print_header("Kiểm tra ChromaDB & Vector Store")
    get_chroma_collection_stats()
    check_backend_documents()
    print("\n═" * 70)
