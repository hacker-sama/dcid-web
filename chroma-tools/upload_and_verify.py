#!/usr/bin/env python3
"""
Tải file tài liệu qua Backend (:8080) và xác minh trực tiếp việc nạp chunk vào ChromaDB (:8001).
"""
import sys
import io
import time
import json
import uuid
import argparse
import urllib.request
import urllib.error

# Force UTF-8 stdout
if hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

BE_BASE_URL = "http://localhost:8080"
CHROMA_HOST = "localhost"
CHROMA_PORT = 8001
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"

def make_sample_pdf() -> bytes:
    """Tạo PDF mẫu hợp lệ (pure Python) để test nạp vào ChromaDB."""
    stream_content = (
        "BT /F1 12 Tf 50 720 Td (SOP-2026: KCN Substation & Electrical Safety Standard) Tj\n"
        "0 -20 Td (1. Nominal High Voltage is 22kV and Low Voltage distribution is 0.4kV.) Tj\n"
        "0 -20 Td (2. All technical staff must wear certified insulating gloves and helmets.) Tj\n"
        "0 -20 Td (3. In case of transformer overload or thermal alarms, immediately disconnect circuit breaker CB-01.) Tj\n"
        "0 -20 Td (4. Routine inspection schedule must be logged every Monday morning at 08:00 AM.) Tj ET\n"
    )
    stream_bytes = stream_content.encode("ascii")
    stream_len = len(stream_bytes)

    obj1 = b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    obj2 = b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    obj3 = b"3 0 obj\n<< /Type /Page /MediaBox [0 0 612 792] /Parent 2 0 R /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n"
    obj4 = f"4 0 obj\n<< /Length {stream_len} >>\nstream\n".encode("ascii") + stream_bytes + b"endstream\nendobj\n"
    obj5 = b"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"

    header = b"%PDF-1.4\n"
    pos1 = len(header)
    pos2 = pos1 + len(obj1)
    pos3 = pos2 + len(obj2)
    pos4 = pos3 + len(obj3)
    pos5 = pos4 + len(obj4)
    xref_pos = pos5 + len(obj5)

    xref = (
        f"xref\n0 6\n"
        f"0000000000 65535 f \n"
        f"{pos1:010d} 00000 n \n"
        f"{pos2:010d} 00000 n \n"
        f"{pos3:010d} 00000 n \n"
        f"{pos4:010d} 00000 n \n"
        f"{pos5:010d} 00000 n \n"
        f"trailer\n<< /Size 6 /Root 1 0 R >>\n"
        f"startxref\n{xref_pos}\n%%EOF"
    ).encode("ascii")

    return header + obj1 + obj2 + obj3 + obj4 + obj5 + xref

def get_jwt_token():
    try:
        req = urllib.request.Request(
            f"{BE_BASE_URL}/api/auth/login",
            data=json.dumps({"username": ADMIN_USER, "password": ADMIN_PASS}).encode(),
            headers={"Content-Type": "application/json"}
        )
        res = urllib.request.urlopen(req, timeout=10)
        return json.loads(res.read().decode())["data"]["token"]
    except Exception as e:
        print(f"❌ Lỗi đăng nhập vào Backend (:8080): {e}")
        sys.exit(1)

def upload_document(token, file_bytes, filename, title, category, min_role):
    try:
        import requests
        headers = {"Authorization": f"Bearer {token}"}
        data = {"title": title, "category": category, "minRole": min_role}
        files = {"file": (filename, file_bytes, "application/pdf")}
        
        print(f"🚀 Đang tải lên tài liệu: \"{title}\" (File: {filename}, size: {len(file_bytes)} bytes)...")
        r = requests.post(f"{BE_BASE_URL}/api/documents", headers=headers, data=data, files=files, timeout=30)
        r.raise_for_status()
        res_data = r.json()["data"]
        doc_id = res_data["document"]["id"]
        ver_id = res_data["versions"][0]["id"]
        print(f"✅ Tải lên MinIO & PostgreSQL thành công! Document ID: {doc_id} | Version ID: {ver_id}")
        return doc_id, ver_id
    except ImportError:
        print("❌ Chưa cài đặt thư viện requests. Hãy chạy: pip install requests")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Lỗi khi tải tài liệu lên Backend: {e}")
        sys.exit(1)

def poll_ingest_status(token, doc_id, timeout_sec=120):
    print("⏳ Đang theo dõi tiến trình OCR → Chunking → Embedding → ChromaDB Indexing...")
    headers = {"Authorization": f"Bearer {token}"}
    start = time.time()
    while time.time() - start < timeout_sec:
        try:
            req = urllib.request.Request(f"{BE_BASE_URL}/api/documents/{doc_id}", headers=headers)
            res = urllib.request.urlopen(req, timeout=10)
            data = json.loads(res.read().decode())["data"]
            ver = data["versions"][0]
            status = ver["status"]
            print(f"   ► Trạng thái hiện tại: [{status}] ...")
            if status == "ACTIVE":
                print(f"🎉 Hoàn tất xử lý AI! Tài liệu đã được đánh dấu ACTIVE sau {int(time.time() - start)}s.")
                return ver["id"]
            elif status == "FAILED":
                print(f"❌ Xử lý AI thất bại (status = FAILED) cho version {ver['id']}")
                sys.exit(1)
        except Exception as e:
            print(f"⚠️ Lỗi khi poll status: {e}")
        time.sleep(4)
    print("❌ Quá thời gian chờ (timeout) không thấy tài liệu chuyển sang ACTIVE.")
    sys.exit(1)

def verify_chromadb_chunks(version_id):
    print(f"\n═" * 70)
    print(f" 📦 KIỂM TRA TRỰC TIẾP TRONG CHROMADB (COLLECTION `kcn_chunks`)")
    print(f"═" * 70)
    try:
        import chromadb
        client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)
        col = client.get_collection("kcn_chunks")
        
        # Query by version_id metadata
        res = col.get(where={"version_id": str(version_id)}, include=["metadatas", "documents"])
        ids = res.get("ids", [])
        metas = res.get("metadatas", [])
        docs = res.get("documents", [])
        
        if not ids:
            print(f"❌ Không tìm thấy chunk nào cho version_id {version_id} trong ChromaDB!")
        else:
            print(f"✅ XÁC NHẬN THÀNH CÔNG: Tìm thấy [{len(ids)}] chunks đã được nạp vào ChromaDB!")
            for idx, cid in enumerate(ids):
                meta = metas[idx]
                text = docs[idx]
                print(f"\n   🔹 Chunk ID: {cid}")
                print(f"      ├─ Trang số   : {meta.get('page_no')}")
                print(f"      ├─ Thứ tự     : {meta.get('chunk_index')}")
                print(f"      ├─ MinRole    : {meta.get('minRole')}")
                print(f"      └─ Nội dung   : \"{text.strip().replace(chr(10), ' ')}\"")
    except Exception as e:
        print(f"❌ Lỗi truy vấn ChromaDB: {e}")

def main():
    parser = argparse.ArgumentParser(description="Upload tài liệu và kiểm tra trong ChromaDB.")
    parser.add_argument("--file", help="Đường dẫn file PDF cần upload")
    parser.add_argument("--title", default="SOP KCN Safety & Operation", help="Tiêu đề tài liệu")
    parser.add_argument("--category", default="SOP", help="Phân loại (SOP, MANUAL, POLICY, GENERAL)")
    parser.add_argument("--role", default="OPERATOR", help="Quyền truy cập tối thiểu (OPERATOR, ENGINEER, QA_ADMIN, ADMIN)")
    args = parser.parse_args()

    token = get_jwt_token()

    if args.file:
        try:
            with open(args.file, "rb") as f:
                file_bytes = f.read()
            filename = args.file.split("/")[-1].split("\\")[-1]
        except Exception as e:
            print(f"❌ Không thể đọc file {args.file}: {e}")
            sys.exit(1)
    else:
        print("ℹ️ Không chỉ định --file, đang tự động tạo file PDF mẫu kỹ thuật KCN...")
        file_bytes = make_sample_pdf()
        filename = f"sop_kcn_{int(time.time())}.pdf"

    doc_id, ver_id = upload_document(token, file_bytes, filename, args.title, args.category, args.role)
    poll_ingest_status(token, doc_id)
    verify_chromadb_chunks(ver_id)
    print("\n═" * 70)

if __name__ == "__main__":
    main()
