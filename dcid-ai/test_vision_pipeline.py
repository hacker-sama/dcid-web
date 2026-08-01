"""Test kiểm tra Vision pipeline: ảnh trang có tồn tại trong MinIO không?"""
import sys, os
os.environ["LM_STUDIO_BASE_URL"] = "http://localhost:1234/v1"
os.environ["LM_STUDIO_API_KEY"] = "lm-studio"
os.environ["LLM_TIMEOUT"] = "120"
sys.path.insert(0, ".")

from app.config import get_settings
get_settings.cache_clear()

# 1. Kiểm tra MinIO connectivity
print("="*60)
print("1. Kiểm tra MinIO connectivity")
print("="*60)
try:
    from app.clients import minio_client
    s = get_settings()
    print(f"MinIO endpoint: {s.minio_endpoint}")
    print(f"MinIO bucket: {s.minio_bucket}")
except Exception as e:
    print(f"MinIO client error: {e}")

# 2. Liệt kê tất cả objects trong thư mục pages/
print("\n" + "="*60)
print("2. Liệt kê objects trong MinIO bucket (pages/)")
print("="*60)
try:
    from minio import Minio
    client = Minio(
        s.minio_endpoint,
        access_key=s.minio_access_key,
        secret_key=s.minio_secret_key,
        secure=s.minio_secure,
    )
    
    page_objects = list(client.list_objects(s.minio_bucket, prefix="pages/", recursive=True))
    if page_objects:
        print(f"Tìm thấy {len(page_objects)} ảnh trang trong MinIO:")
        for obj in page_objects[:20]:  # Show max 20
            print(f"  - {obj.object_name} ({obj.size} bytes)")
    else:
        print("❌ KHÔNG CÓ ảnh trang nào trong MinIO (pages/ prefix rỗng)")
        print("   => Vision pipeline sẽ KHÔNG hoạt động!")
        print("   => Model VLM chỉ nhận text OCR, không nhận ảnh bản vẽ")
        
    # Liệt kê toàn bộ objects
    print(f"\nTất cả objects trong bucket '{s.minio_bucket}':")
    all_objects = list(client.list_objects(s.minio_bucket, recursive=True))
    prefixes = set()
    for obj in all_objects:
        prefix = obj.object_name.split("/")[0] if "/" in obj.object_name else "(root)"
        prefixes.add(prefix)
    print(f"  Tổng: {len(all_objects)} objects")
    print(f"  Prefixes: {sorted(prefixes)}")
    
except Exception as e:
    print(f"MinIO listing error: {e}")

# 3. Kiểm tra ChromaDB để tìm version_id của tài liệu phandoi
print("\n" + "="*60)
print("3. Kiểm tra ChromaDB: version_id của tài liệu phandoi")
print("="*60)
try:
    import chromadb
    chroma_client = chromadb.HttpClient(host=s.chroma_host, port=s.chroma_port)
    collection = chroma_client.get_or_create_collection(name="kcn_chunks", metadata={"hnsw:space": "cosine"})
    
    # Lấy tất cả metadata
    all_data = collection.get(limit=100, include=["metadatas"])
    version_ids = set()
    for meta in all_data.get("metadatas", []):
        vid = meta.get("version_id", "")
        title = meta.get("title", "")  
        if vid:
            version_ids.add((vid, title))
    
    print(f"Tổng chunks trong Chroma: {collection.count()}")
    print(f"Version IDs:")
    for vid, title in sorted(version_ids):
        print(f"  - {vid} (title='{title}')")
        # Kiểm tra ảnh trang trong MinIO cho version_id này
        try:
            page_key = f"pages/{vid}/1.png"
            data = minio_client.get_object(page_key)
            print(f"    ✅ Ảnh trang 1 TỒN TẠI trong MinIO ({len(data)} bytes)")
        except Exception:
            print(f"    ❌ Ảnh trang 1 KHÔNG tồn tại trong MinIO")
            
except Exception as e:
    print(f"ChromaDB error: {e}")

print("\n" + "="*60)
print("4. Kết luận")
print("="*60)
