# Smart KCN Docs — Roadmap (cập nhật 16/07/2026)

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
| **AI — Ingest thật (MinIO→OCR→callback)** | `ingest_service.py` gọi `ocr_client.extract_pages()` + chunk + embed + index + callback BE |
| **AI — OCR thật (Service ai-ocr)** | `main_ocr.py` & `pipeline/ocr.py`: **PyMuPDF** (rasterize) + **PaddleOCR 3.7** (nhận dạng) — EN: CER 0%, VI: CER ~10% |
| **AI — Chunking thật** | `pipeline/chunk.py`: layout-aware (giữ bảng nguyên vẹn), sliding window 400 từ / overlap 60 |
| **AI — Embedding thật** | `pipeline/embed.py`: `multilingual-e5-small` ONNX/PyTorch, prefix chuẩn E5 (`passage: / query:`) |
| **AI — Vector Index ChromaDB** | `pipeline/index.py`: upsert vào collection `kcn_chunks`, idempotent theo `version_id` |
| **AI — Query RAG thật** | `api/query.py` & `services/query_service.py`: retrieve top-k ChromaDB + guardrails + gọi LLM qua LM Studio (`deepseek-r1-distill-qwen-1.5b`) |
| **AI — LLM Client (LM Studio)** | `clients/llm_client.py`: OpenAILike REST client, tự động bóc tách thẻ `<think>` (reasoning mode), timeout 120s, max_tokens 2048 |
| **AI — Guardrails cơ bản** | `query_service.py`: kiểm tra allowed versions, cosine threshold θ=0.60 (confidence gate), và numeric rule |
| **Flutter — Login** | `auth/login_screen.dart` nối API thật |
| **Flutter — Shell/Nav** | `shell/home_shell.dart` + routing role-guard |
| **Flutter — Tài liệu** | `documents_screen.dart` + `document_detail_screen.dart` + `upload_document_sheet.dart` — nối API thật |
| **Flutter — Tra cứu** | `search/search_screen.dart` nối `POST /api/query` thật |
| **Flutter — Layout & Density** | Áp dụng `VisualDensity.adaptivePlatformDensity`, `ConstrainedContent`, và responsive layout cho các màn hình theo `flutter-design.md` |
| **Flutter — Placeholder** | `admin_screen.dart`, `snap_ask_screen.dart`, `document_viewer_screen.dart` — placeholder |
| **Infra Docker** | postgres · redis · minio · zookeeper · kafka · chroma · backend · ai · ai-ocr — tất cả `Up`/`Started` |

### 🔴 CHƯA CÓ — cần làm trong T3–T6

| Hạng mục | Blocking gì |
|---|---|
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
| **M1d** | LLM thật + RAG query (LM Studio DeepSeek R1) | ✅ **Xong** | `/api/query` trả câu trả lời thật từ LLM + citation trang + guardrails |
| **M2** | Experiments E1–E2 (đo đạc chi tiết guardrail/chunking) | ⬜ **T4–T5** | bảng số liệu hallucination rate, Recall@k |
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

**Tiến độ M1c:** ✅ **ĐÃ HOÀN THÀNH & VERIFY E2E (16/07/2026)** — đã kiểm chứng qua `smoke_test_t2.py` và chạy thực tế trong Docker (`ai-ocr` bóc tách → chunk layout-aware → embed `multilingual-e5-small` → lưu ChromaDB `kcn_chunks` → callback `ACTIVE`).

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

### 🟢 T3 — Việc cần làm cho Tuần 3 (Query E2E + Data Prep)

Đường găng của T3 là khép kín E2E giao diện Tra cứu (Flutter) hiển thị ảnh trích dẫn lấy từ BE, và chuẩn bị bộ câu hỏi đánh giá.

#### AI Engineer (Người 3) — 🌟 (Vượt tiến độ)

**LLM Client & LM Studio integration** ✅ **DONE (Sớm)**
- Tích hợp qua REST API tới **LM Studio**.
- Đã sửa triệt để lỗi `Channel Error` (bỏ `repetition_penalty`).
- Prompt hỗ trợ đa ngôn ngữ và xử lý tốt dữ liệu OCR (Bill of Materials).

**RAG query (services/query_service.py)** ✅ **DONE (Sớm)**
- Retrieve top-k ChromaDB, áp dụng guardrails.
- Xử lý tốt cờ `reasoningMode` và tránh lỗi blank answer sau thẻ `<think>`.
- *Việc tiếp theo:* Hỗ trợ Người 5 xây dựng script Harness chạy tự động, hoặc bắt đầu làm sớm T4 (Bbox extraction).

#### Backend (Người 2)

**1. API `GET /api/files/**` (Proxy MinIO)**
- Viết controller để load file/ảnh trang từ bucket MinIO.
- Yêu cầu xác thực JWT (chỉ user đã login mới xem được ảnh).
- Output: Trả về binary image (jpeg/png). Dùng cho Frontend hiển thị ảnh trích dẫn.

#### Flutter (Người 4)

**1. Màn tra cứu + Answer UI**
- Gắn api `GET /api/files/**` vào giao diện Citation Viewer.
- Xử lý hiển thị ảnh trang bên cạnh câu trả lời.
- Hoàn thiện UI thẻ báo hiệu Reasoning Mode.

#### PM (Người 1)

**1. Viết Chương 2 (Cơ sở lý thuyết)**
- RAG (Retrieval-Augmented Generation).
- SLM (Small Language Models) và Quantization.
- Kỹ thuật kiểm soát ảo giác (Hallucination control).

#### Data/Eval (Người 5)

**1. Eval set v1 + Harness v1**
- Tạo file `data/eval/questions.csv` (80–120 câu hỏi có đáp án chuẩn).
- Phân nhóm: Factual/số liệu (40%), Quy trình (40%), Ngoài phạm vi (20%).
- Bắt đầu nháp script Python (`harness.py`) để đọc CSV và tự động gọi API `/ai/query`.

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

## Lưu ý nâng cấp Model & Cờ Reasoning (`reasoningMode`)

Khi nâng cấp sang dòng model suy luận (Reasoning Model) như **DeepSeek R1 (`deepseek-r1-distill-qwen-1.5b`)**, hệ thống bổ sung các xử lý và cờ nhận diện đặc biệt để khai thác tối đa năng lực tư duy mà vẫn giữ trải nghiệm người dùng mượt mà:

1. **Cờ `reasoningMode` trong Guardrail (`guard`)**:
   - Phản hồi của `POST /ai/query` trong object `guard` được tích hợp thêm cờ `reasoningMode: bool`.
   - Cờ này xác định model có kích hoạt chế độ suy luận chuyên sâu (chain-of-thought) hay không, hỗ trợ frontend và hệ thống audit theo dõi chính xác cơ chế sinh câu trả lời.
2. **Bóc tách thẻ `<think>...</think>` (Clean Output)**:
   - Các model DeepSeek R1 luôn sinh ra quá trình lập luận logic bên trong cặp thẻ `<think>...</think>` trước khi đưa ra kết quả.
   - `clients/llm_client.py` được thiết kế để tự động bóc tách và lọc bỏ phần suy luận thô này, đảm bảo `answer` cuối cùng gửi đến người dùng luôn ngắn gọn, đúng trọng tâm và dễ đọc trên giao diện Kiosk/Mobile.
3. **Điều chỉnh tài nguyên (`max_tokens` & `timeout`)**:
   - Quá trình suy luận `<think>` tiêu tốn nhiều token và thời gian hơn bình thường. Cấu hình `config.py` / `.env` được nâng cấp với `llm_max_tokens: 2048` và `llm_timeout: 120s` để đảm bảo model không bị ngắt kết nối khi xử lý các câu hỏi phức tạp cần đối chiếu nhiều số liệu kỹ thuật.

---

## Quyết định kỹ thuật đã chốt

| # | Quyết định | Lý do |
|---|---|---|
| 1 | **OCR: PaddleOCR 3.7 + PyMuPDF** | Không cần system deps (poppler), cài thuần pip, CER 0% EN |
| 2 | **Rasterize: RENDER_DPI=200** | A4 ~1650×2340px — đủ nét OCR, không quá nặng |
| 3 | **enable_mkldnn=False** | paddlepaddle 3.3.0 lỗi oneDNN/PIR runtime khi mkldnn=True |
| 4 | **LLM: LM Studio (REST API) + DeepSeek R1 Distill Qwen 1.5B Q8_0** | Tách inference engine sang LM Studio local, hỗ trợ reasoning `<think>`, không phụ thuộc C++ binding trong container |
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
