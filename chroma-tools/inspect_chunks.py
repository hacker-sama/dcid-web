#!/usr/bin/env python3
"""
Xem chi tiết và tìm kiếm các đoạn văn bản (chunk) đang lưu trong ChromaDB (`kcn_chunks`).
"""
import sys
import io
import argparse

# Force UTF-8 stdout
if hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

CHROMA_HOST = "localhost"
CHROMA_PORT = 8001

def main():
    parser = argparse.ArgumentParser(description="Tra cứu chunk trong ChromaDB.")
    parser.add_argument("--doc-id", help="Lọc chunk theo Document ID")
    parser.add_argument("--version-id", help="Lọc chunk theo Version ID")
    parser.add_argument("--limit", type=int, default=20, help="Số lượng chunk tối đa hiển thị")
    args = parser.parse_args()

    try:
        import chromadb
        client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)
        col = client.get_collection("kcn_chunks")
        
        where_filter = {}
        if args.doc_id:
            where_filter["document_id"] = args.doc_id
        if args.version_id:
            where_filter["version_id"] = args.version_id

        res = col.get(
            where=where_filter if where_filter else None,
            limit=args.limit,
            include=["metadatas", "documents"]
        )
        
        ids = res.get("ids", [])
        metas = res.get("metadatas", [])
        docs = res.get("documents", [])
        
        print(f"\n═" * 70)
        print(f" 📑 KẾT QUẢ TRA CỨU CHROMADB (`kcn_chunks`) - Tìm thấy: {len(ids)} chunk(s)")
        print(f"═" * 70)
        
        if not ids:
            print("   (Không có dữ liệu phù hợp)")
        else:
            for idx, cid in enumerate(ids):
                meta = metas[idx]
                text = docs[idx]
                print(f"\n[{idx + 1}] ID: {cid}")
                print(f"    ├─ Document ID: {meta.get('document_id')}")
                print(f"    ├─ Version ID : {meta.get('version_id')}")
                print(f"    ├─ Trang / Vị trí: Page {meta.get('page_no')} | Chunk #{meta.get('chunk_index')}")
                print(f"    └─ Văn bản    :\n       \"{text.strip()}\"")
        print("\n═" * 70)
    except ImportError:
        print("❌ Chưa cài đặt chromadb. Hãy chạy: pip install chromadb")
    except Exception as e:
        print(f"❌ Lỗi kết nối ChromaDB: {e}")

if __name__ == "__main__":
    main()
