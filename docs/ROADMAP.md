# Smart KCN Docs — Roadmap (cập nhật 14/07/2026)

> Dựa trực tiếp trên **code thực tế** trong repo (commit hiện tại) + tài liệu `PLAN-THESIS.md`,
> `ARCHITECTURE.md`, `API-CONTRACT.md`, `ERD.md`, `FRONTEND.md`.
> Cập nhật lại khi merge branch mới hoặc hoàn thành cột mốc.

---

## Trạng thái hệ thống (thực tế, không đoán)

### ✅ ĐÃ XONG — đang chạy thật (verified E2E)

| Hạng mục | Chi tiết kỹ thuật |
|---|---|
| **Backend — Auth/RBAC** | `AuthController`, `JwtService`, 4 vai `OPERATOR/ENGINEER/QA_ADMIN/ADMIN`, `@PreAuthorize` |
| **Backend — Upload tài liệu** | `DocumentController` + `DocumentService` + `MinioService` (multipart → MinIO) |
| **Backend — Ingest callback** | `InternalIngestController` + `IngestService` → ghi `document_pages`, auto-publish ACTIVE |
| **Backend — Query** | `QueryController` + `QueryService` → forward AI, ghi `query_logs` |
| **Backend — Audit log** | `AuditLogService` + `AuditLog` entity (JSONB fix đã apply) |
| **Backend — DB schema** | V1 (users, audit_logs) + V2 (documents, versions, pages) + V3 (query_logs) + V4 (work_orders) |
| **Backend — Entities** | `User`, `Document`, `DocumentVersion`, `DocumentPage`, `QueryLog`, `AuditLog` |
| **AI — Skeleton FastAPI** | 3 endpoint: `GET /ai/health`, `POST /ai/ingest` (202 async), `POST /ai/query` (mock) |
| **AI — Ingest thật (MinIO→OCR→callback)** | `ingest_service.py` gọi `ocr.extract_pages()` thật + callback BE |
| **AI — OCR thật** | `pipeline/ocr.py`: **PyMuPDF** (rasterize) + **PaddleOCR 3.7** (nhận dạng) — EN: CER 0%, VI: CER ~10% |
| **AI — Query mock** | `api/query.py`: deterministic mock (numeric rule regex + locked trigger) |
| **AI — Guardrails stub** | `pipeline/guardrails.py`: threshold=0.60, `check_numeric()` raise NotImplementedError |
| **AI — Pipeline stubs** | `chunk.py`, `embed.py`, `index.py` — đầy đủ stub + TODO rõ ràng |
| **Flutter — Login** | `auth/login_screen.dart` nối API thật |
| **Flutter — Shell/Nav** | `shell/home_shell.dart` + routing role-guard |
| **Flutter — Tài liệu** | `documents_screen.dart` + `document_detail_screen.dart` + `upload_document_sheet.dart` — nối API thật |
| **Flutter — Tra cứu** | `search/search_screen.dart` nối `POST /api/query` thật |
| **Flutter — Placeholder** | `admin_screen.dart`, `snap_ask_screen.dart`, `document_viewer_screen.dart` — placeholder |
| **Infra Docker** | postgres · redis · minio · zookeeper · kafka · backend · ai — tất cả `Started` |

### 🔴 CHƯA CÓ — cần làm trong T2–T6

| Hạng mục | Blocking gì |
|---|---|
| **chunk→embed→ChromaDB** (pipeline AI thật) | Retrieval thật, E1 experiment |
| **LLM thật** (llama-cpp + Qwen2.5-1.5B Q4) | Query RAG thật, E2/E3/E4 |
| **Guardrail thật** (cosine < 0.60, numeric rule-extraction) | E2 experiment |
| **ChromaDB** trong docker-compose | Pipeline index |
| **Dataset** (15–25 tài liệu VI/EN + degradation set) | Mọi thí nghiệm |
| **Eval set** (80–120 câu hỏi + ground truth) | Số liệu chương 4 |
| **Eval harness tự động** | Chạy E1–E5, in bảng metric |
| **Flutter — Citation viewer** (bbox + banner guardrail) | Demo UI đầy đủ |
| **Flutter — Admin console** (version management, audit) | M3 |
| **BE — `GET /api/files` proxy** (serve ảnh/crop từ MinIO) | Citation viewer Flutter |
| **Outline + quyển luận văn** (chương 1–2) | Bảo vệ |

---

## Milestones (đã cập nhật thực tế)

| # | Tên | Khi nào | Điều kiện DONE |
|---|---|---|---|
| **M0** | Nền tảng + Auth + skeleton | ✅ **Xong** | Docker, self-JWT, RBAC, audit |
| **M1a** | Upload + Ingest E2E (pypdf mock) | ✅ **Xong** | upload PDF → MinIO → ACTIVE, E2E pass |
| **M1b** | OCR thật tích hợp (PaddleOCR) | ✅ **Xong** | ingest thật EN/VI, CER baseline đo được |
| **M1c** | chunk → embed → ChromaDB | ✅ **Xong** | ingest ghi vector vào Chroma, query retrieve được |
| **M1d** | LLM thật + RAG query | ⬜ **T3** | `/api/query` trả câu trả lời thật + citation trang |
| **M2** | Guardrails đầy đủ + Experiments E1–E2 | ⬜ **T4–T5** | bảng số liệu hallucination rate, Recall@k |
| **M3** | Flutter citation viewer + BE file proxy | ⬜ **T5** | UI hiện bbox, banner guardrail |
| **M4** | Luận văn + eval set hoàn chỉnh | ⬜ **T6–T7** | bảng metric E1–E2, code freeze |
| **M5** | Demo + bảo vệ | ⬜ **T8** | video demo dự phòng, slide, Q&A thử |

---

## Hướng đi tiếp theo — theo thứ tự ưu tiên

### 🔴 T2 — Việc cần làm NGAY (đường găng)

#### AI Engineer (Người 3)

**Bước 1 — Chunking (pipeline/chunk.py)** ✅ **DONE**
- Layout-aware chunking: giữ bảng nguyên vẹn, sliding window 400 từ / overlap 60
- Input: `list[PageOcr]` → Output: `list[Chunk]` (với page_no, chunk_index)
- Unit tests: 10 test cases pass (TestIsTable, TestSplitBlocks, TestChunkPages)

**Bước 2 — Embedding (pipeline/embed.py)** ✅ **DONE**
- `sentence-transformers>=3.0` + model `intfloat/multilingual-e5-small`
- Prefix chuẩn E5: "passage: " cho ingest, "query: " cho query (T3)
- Singleton lazy-load per process (lru_cache)

**Bước 3 — ChromaDB index (pipeline/index.py)** ✅ **DONE**
- `chromadb.HttpClient` kết nối service `chroma` trong docker-compose
- `upsert_chunks()` idempotent theo version_id, `search()` filter RBAC version_id
- Cosine similarity score ∈ [0,1]

**Bước 4 — Thêm ChromaDB vào docker-compose.yml** ✅ **DONE**
```yaml
chroma:
  image: chromadb/chroma:latest
  container_name: dcid-chroma
  volumes:
    - chroma_data:/chroma/.chroma/index
  ports:
    - "8001:8000"
  restart: unless-stopped
```
Thêm `CHROMA_HOST: chroma` và `CHROMA_PORT: 8000` vào service `ai`.

**Bước 5 — Nối ingest_service.py** ✅ **DONE**
- Pipeline đầy đủ: `ocr → chunk → embed → index → callback READY`
- Mọi lỗi (kể cả Chroma/embed fail) → callback FAILED, service không crash

**Bước tiếp theo để verify M1c:**
- Chạy `docker compose up --build -d` → kiểm tra dcid-chroma Started
- Upload 1 PDF và kiểm tra log: `Chroma upsert OK: ... chunks=N`

#### Data/Eval (Người 5)

**Sưu tầm tài liệu đợt 1:**
- Siemens S7-1200 System Manual (EN, có bảng điện áp/dòng điện)
- ABB ACS580 Drive User Manual (EN)
- 1–2 TCVN về an toàn máy (VI)
- Mục tiêu: **10 tài liệu, 80–100 trang** trước cuối T2

**Bắt đầu degradation set:**
- In ~10 trang → scan lại (nghiêng, mờ) → thư mục `data/degraded/`

#### PM (Người 1)

- Tạo `docs/THESIS-OUTLINE.md` — mục lục 5 chương, phân công ai viết phần nào
- Bắt đầu viết **Chương 1** (giới thiệu bài toán, RQ1–3)

---

### 🟠 T3 — LLM + RAG query thật

#### AI Engineer

**LLM (llm/engine.py)**
```bash
pip install llama-cpp-python
# Download: Qwen2.5-1.5B-Instruct-Q4_K_M.gguf (~1.1GB)
# Từ: huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF
```

**RAG query (pipeline/retrieve.py)**
- Nhận `question + allowedVersionIds` → embed câu hỏi → query Chroma top-k
- Filter: `version_id ∈ allowedVersionIds`
- Trả `list[RetrievedChunk]` với score cosine

**Cập nhật api/query.py**
- Thay mock bằng: retrieve → guardrail cosine → LLM sinh câu trả lời
- Giữ nguyên schema response (Flutter đang parse đúng format này)

#### Backend (Người 2)

**GET /api/files proxy**
- Serve ảnh trang / bbox crop từ MinIO qua JWT
- Flutter citation viewer cần endpoint này

---

### 🟡 T4–T5 — Guardrail + Experiments

#### AI Engineer

**Guardrail thật (pipeline/guardrails.py)**
- `check_confidence(score: float) → bool`: score < 0.60 → locked
- `check_numeric(question: str) → bool`: regex keyword → True
- Khi numeric → trích số liệu trực tiếp từ `chunk.text` (regex đơn vị: V, bar, °C, mm, Nm)

**Thí nghiệm E1** (chunking):
- Arm 1: fixed-size 512 tokens → đo Recall@3
- Arm 2: layout-aware (giữ bảng) → đo Recall@3
- Dùng eval harness

**Thí nghiệm E2** (guardrail):
- Arm 1: LLM thuần → đo hallucination rate
- Arm 2: + confidence-gate (θ=0.60)
- Arm 3: + numeric rule-extraction
- Dùng eval harness

#### Data/Eval (Người 5)

**Eval set v1 (80–120 câu):**
```
data/eval/questions.csv
  id, question, ground_truth_answer, source_page, doc_filename, category
```
3 nhóm: factual/số liệu (40%), quy trình/SOP (40%), ngoài phạm vi (20%)

**Eval harness:**
```bash
python eval/run_eval.py --config eval/config.yaml
# In bảng: Recall@3, Recall@5, hallucination_rate, false_answer_rate, latency_p50
```

#### Flutter (Người 4)

**Citation viewer:**
- Load ảnh trang từ `GET /api/files/{imageKey}`
- Overlay bbox crop (khi bboxKey có trong citation)
- Banner đỏ khi `guard.locked = true`
- Chip "Số liệu trực tiếp" khi `guard.numericRule = true`

---

### 🟢 T6 — Đóng băng thí nghiệm

- Chốt bảng kết quả E1–E2 (+ E3/E4 nếu kịp)
- Phân tích lỗi OCR (VI) + lỗi retrieval
- Quay **video demo dự phòng**
- Code freeze — chỉ bugfix sau đây

---

### 📝 T7–T8 — Viết luận văn + Bảo vệ

- T7: Mỗi người viết phần mình theo outline
- T8: Dry-run demo, slide, Q&A kỹ thuật thử

---

## Số liệu đã có (baseline cho chương 4)

| Metric | Giá trị | Điều kiện đo | Ghi chú |
|---|---|---|---|
| OCR CER — Tiếng Anh | **0%** | 8 câu VI+EN có số liệu kỹ thuật | PaddleOCR 3.7, model PP-OCRv6 |
| OCR CER — Tiếng Việt (bản sạch) | **10.4%** | Như trên | Lỗi ở nguyên âm 2 dấu chồng |
| OCR CER — Tiếng Việt (degraded) | **11.1%** | Bản nhiễu/mờ/nghiêng | Robust, chỉ tăng 0.7 điểm % |

> KPI mục tiêu: OCR ≥ 95%, Recall@3 ≥ 85%, Hallucination số liệu = 0%, Latency < 5s.
> Recall@k và hallucination chưa có số — sẽ đo sau khi có chunk+embed+LLM (T3–T4).

---

## Quyết định kỹ thuật đã chốt

| # | Quyết định | Lý do |
|---|---|---|
| 1 | **OCR: PaddleOCR 3.7 + PyMuPDF** | Không cần system deps (poppler), cài thuần pip, CER 0% EN |
| 2 | **Rasterize: RENDER_DPI=200** | A4 ~1650×2340px — đủ nét OCR, không quá nặng |
| 3 | **enable_mkldnn=False** | paddlepaddle 3.3.0 lỗi oneDNN/PIR runtime khi mkldnn=True |
| 4 | **LLM: llama-cpp-python + Qwen2.5-1.5B Q4_K_M** | On-premise CPU, ~1.1GB, < 3GB RAM |
| 5 | **Embed: multilingual-e5-small ONNX** | <400MB, multilingual, chạy CPU |
| 6 | **Vector DB: ChromaDB** | Persistent trên edge, dễ đóng gói offline |
| 7 | **Frontend: Flutter Web + Android** | 1 codebase, target chính: Web kiosk + Android mobile |
| 8 | **Upload: bytes-based (không path)** | `PlatformFile.path = null` trên Flutter Web |
| 9 | **Guardrail threshold: cosine < 0.60** | Theo contract API-CONTRACT.md §2.2 |

---

## Rủi ro còn lại

| Rủi ro | Mức | Đối sách |
|---|---|---|
| OCR VI CER 10% dưới KPI 95% | 🟡 | Thử hybrid PaddleOCR-detect + VietOCR-recog ở E1; hoặc báo cáo trung thực trade-off |
| Latency LLM > 5s trên CPU | 🟡 | Đo tại T3; giảm top-k/context; đổi 0.5B nếu cần |
| Dataset tự sưu tầm kém chất lượng | 🟡 | PM + người 5 review chéo từng câu eval; ground truth phải có trang nguồn |
| Không kịp viết luận văn | 🔴 | CODE FREEZE T6; viết chương 1–2 song song từ T2 ngay |
| Demo hỏng hôm bảo vệ | 🟢 | Quay video dự phòng T6; compose 1 lệnh khởi động lại |
