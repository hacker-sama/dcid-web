#!/usr/bin/env python3
"""
E2E smoke test cho pipeline Tuần 2 (M1c verification).

Chạy sau khi `docker compose up -d` đã ổn định:
    python scripts/smoke_test_t2.py

Test sequence:
  1. Kiểm tra AI health (GET /ai/health)
  2. Kiểm tra ChromaDB sẵn sàng (GET http://localhost:8001/api/v1/heartbeat)
  3. Login lấy JWT
  4. Upload PDF nhỏ → lấy versionId
  5. Chờ ingest (polling status, tối đa 120s)
  6. Kiểm tra ChromaDB collection có chunk
  7. Gọi /api/query → in response

Yêu cầu: requests, chromadb (pip install requests chromadb)
"""

import sys
import time
import io
import json
import uuid

try:
    import requests
except ImportError:
    print("❌  pip install requests  rồi chạy lại")
    sys.exit(1)

# Force UTF-8 output on Windows console
if sys.stdout.encoding != "utf-8" and hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# ─── Config ─────────────────────────────────────────────────────────────
BE  = "http://localhost:8080"
AI  = "http://localhost:8000"
CHR = "http://localhost:8001"
INTERNAL_TOKEN = "change-me-internal-token"
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"

POLL_INTERVAL = 5   # giây
POLL_TIMEOUT  = 120 # giây tối đa chờ ingest

# ─── Helpers ─────────────────────────────────────────────────────────────

def ok(msg):   print(f"  ✅  {msg}")
def fail(msg): print(f"  ❌  {msg}"); sys.exit(1)
def info(msg): print(f"  ℹ️   {msg}")

def step(n, title):
    print(f"\n{'─'*60}")
    print(f"  STEP {n}: {title}")
    print(f"{'─'*60}")

# ─── Test PDF tạo bằng fpdf2 nếu có, hoặc 1-page PDF tối giản ───────────

def make_minimal_pdf() -> bytes:
    """Tạo PDF 1 trang tối giản (pure Python, không cần thư viện).
    Chứa đủ số từ (≥ MIN_CHUNK_WORDS = 10) để chunker tạo ra ít nhất 1 chunk.
    """
    stream_content = (
        "BT /F1 12 Tf 50 720 Td (Standard Operating Procedure S-01 for KCN Substation System.) Tj\n"
        "0 -20 Td (The nominal operating voltage of this electrical distribution transformer) Tj\n"
        "0 -20 Td (is 22kV high voltage and 0.4kV low voltage for industrial operations.) Tj\n"
        "0 -20 Td (All maintenance procedures must strictly adhere to electrical safety standards.) Tj ET\n"
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

# ═════════════════════════════════════════════════════════════════════════
# STEP 1: AI health
# ═════════════════════════════════════════════════════════════════════════
step(1, "AI health check")
try:
    r = requests.get(f"{AI}/ai/health", timeout=5)
    r.raise_for_status()
    info(f"Response: {r.json()}")
    ok("AI service sẵn sàng")
except Exception as e:
    fail(f"AI không phản hồi: {e}")

# ═════════════════════════════════════════════════════════════════════════
# STEP 2: ChromaDB heartbeat
# ═════════════════════════════════════════════════════════════════════════
step(2, "ChromaDB heartbeat")
try:
    r = requests.get(f"{CHR}/api/v2/heartbeat", timeout=5)
    r.raise_for_status()
    info(f"Response: {r.json()}")
    ok("ChromaDB dcid-chroma sẵn sàng")
except Exception as e:
    fail(f"ChromaDB không phản hồi tại {CHR}: {e}\n"
         "     → Kiểm tra: docker logs dcid-chroma")

# ═════════════════════════════════════════════════════════════════════════
# STEP 3: Login lấy JWT
# ═════════════════════════════════════════════════════════════════════════
step(3, "Login → JWT")
try:
    r = requests.post(
        f"{BE}/api/auth/login",
        json={"username": ADMIN_USER, "password": ADMIN_PASS},
        timeout=10,
    )
    r.raise_for_status()
    token = r.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}
    ok(f"JWT nhận được (len={len(token)})")
except Exception as e:
    fail(f"Login thất bại: {e}\n     → Kiểm tra: docker logs dcid-backend")

# ═════════════════════════════════════════════════════════════════════════
# STEP 4: Upload PDF nhỏ
# ═════════════════════════════════════════════════════════════════════════
step(4, "Upload PDF tối giản")
pdf_bytes = make_minimal_pdf()
info(f"PDF size: {len(pdf_bytes)} bytes")

try:
    r = requests.post(
        f"{BE}/api/documents",
        headers=headers,
        files={"file": ("smoke_test.pdf", io.BytesIO(pdf_bytes), "application/pdf")},
        data={"title": "Smoke Test T2", "category": "SOP", "lang": "vi,en"},
        timeout=30,
    )
    r.raise_for_status()
    body = r.json()
    info(f"Response: {json.dumps(body, ensure_ascii=False, indent=2)}")
    doc_id     = body["data"]["document"]["id"]
    version_id = body["data"]["versions"][0]["id"]
    ok(f"Tải lên thành công: docId={doc_id}  versionId={version_id}")
except Exception as e:
    fail(f"Upload thất bại: {e}")

# ═════════════════════════════════════════════════════════════════════════
# STEP 5: Polling ingest status
# ═════════════════════════════════════════════════════════════════════════
step(5, f"Polling ingest (tối đa {POLL_TIMEOUT}s)")
deadline = time.time() + POLL_TIMEOUT
status = None
while time.time() < deadline:
    try:
        r = requests.get(f"{BE}/api/documents/{doc_id}", headers=headers, timeout=10)
        r.raise_for_status()
        data   = r.json()["data"]
        versions = data.get("versions", [])
        status = versions[0].get("status") if versions else None
        info(f"status={status} (chờ ACTIVE...)")
        if status == "ACTIVE":
            ok(f"Ingest hoàn tất → status=ACTIVE")
            break
        if status == "FAILED":
            fail("Ingest FAILED → xem: docker logs dcid-ai")
    except Exception as e:
        info(f"Polling lỗi: {e}")
    time.sleep(POLL_INTERVAL)
else:
    fail(f"Timeout {POLL_TIMEOUT}s — status vẫn là {status!r}\n"
         "     → docker logs dcid-ai | grep -E 'OK|FAIL|ERROR'")

# ═════════════════════════════════════════════════════════════════════════
# STEP 6: Kiểm tra ChromaDB có chunk
# ═════════════════════════════════════════════════════════════════════════
step(6, "Kiểm tra ChromaDB collection kcn_chunks")
try:
    import chromadb  # noqa
    client = chromadb.HttpClient(host="localhost", port=8001)
    col = client.get_collection("kcn_chunks")
    n = col.count()
    info(f"Collection kcn_chunks: {n} chunk(s)")
    if n > 0:
        ok(f"ChromaDB có {n} chunk — pipeline chunk→embed→index thành công!")
    else:
        fail("Collection rỗng — kiểm tra log: docker logs dcid-ai | grep -E 'Chunk|Embed|Chroma'")
    # Thử query 1 vector
    results = col.query(
        query_texts=["test"],
        n_results=min(3, n),
        include=["metadatas", "distances"],
    )
    info(f"Query test → {len(results['metadatas'][0])} kết quả:")
    for meta, dist in zip(results["metadatas"][0], results["distances"][0]):
        info(f"  page={meta.get('page_no')}  version={str(meta.get('version_id'))[:8]}…  dist={dist:.3f}")
except ImportError:
    info("chromadb chưa cài trên host → bỏ qua bước kiểm tra trực tiếp")
except Exception as e:
    fail(f"ChromaDB query lỗi: {e}")

# ═════════════════════════════════════════════════════════════════════════
# STEP 7: Query API
# ═════════════════════════════════════════════════════════════════════════
step(7, "Gọi /api/query")
try:
    r = requests.post(
        f"{BE}/api/query",
        headers=headers,
        json={"question": "Điện áp vận hành là bao nhiêu?"},
        timeout=30,
    )
    r.raise_for_status()
    body = r.json()
    info(f"Response:\n{json.dumps(body, ensure_ascii=False, indent=2)}")
    ok("Query API phản hồi thành công")
except Exception as e:
    fail(f"Query thất bại: {e}")

# ═════════════════════════════════════════════════════════════════════════
print(f"\n{'═'*60}")
print("  🎉  SMOKE TEST T2 HOÀN THÀNH")
print(f"{'═'*60}")
print("  Pipeline đã verify: OCR → Chunk → Embed → ChromaDB → Callback ACTIVE")
print()
