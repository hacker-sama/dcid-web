# Smart KCN Docs — Roadmap (cập nhật 06/08/2026)

> Dựa trực tiếp trên **code thực tế** trong repo (commit hiện tại) + tài liệu `PLAN-THESIS.md`,
> `ARCHITECTURE.md`, `API-CONTRACT.md`, `ERD.md`, `FRONTEND.md`.
> Cập nhật lại khi merge branch mới hoặc hoàn thành cột mốc.

---

## Trạng thái hệ thống (thực tế, không đoán)

### ✅ ĐÃ XONG — đang chạy thật (verified E2E)

| Hạng mục | Chi tiết kỹ thuật |
|---|---|
| **Backend — Auth/RBAC** | `AuthController`, `JwtService`, 4 vai `OPERATOR/ENGINEER/QA_ADMIN/ADMIN`, `@PreAuthorize` |
| **Backend — Upload tài liệu** | `DocumentController` + `DocumentService` + `MinioService` (multipart -> MinIO) |
| **Backend — Ingest callback** | `InternalIngestController` (`POST /api/internal/ingest-callback`) + `IngestService` -> ghi `document_pages`, auto-publish ACTIVE |
| **Backend — Query** | `QueryController` (`POST /api/query`) + `QueryService` -> forward AI, ghi `query_logs` |
| **Backend — Audit log** | `AuditLogService` + `AuditLog` entity (JSONB fix đã apply) |
| **Backend — Xóa Tài Liệu (Delete API)** | `DocumentController` (`DELETE /api/documents/{id}`) + `DocumentService.deleteDocument` (MinIO PDF/page PNGs + Postgres DB + Audit log `DOCUMENT_DELETE` + AI vector purge) |
| **Backend — DB schema** | V1 (users, audit_logs) + V2 (documents, versions, pages) + V3 (query_logs) + V4 (work_orders) |
| **Backend — Entities** | `User`, `Document`, `DocumentVersion`, `DocumentPage`, `QueryLog`, `AuditLog` |
| **Backend — WebSocket skeleton** | `WebSocketConfig` STOMP: endpoint `/ws` (SockJS), broker `/topic` + `/queue` — chưa có business broadcast |
| **AI — FastAPI + endpoints** | `GET /ai/health`, `POST /ai/ingest` (202 async), `POST /ai/query`, `POST /ai/query/stream`, `GET /ai/status/{task_id}`, `DELETE /ai/documents/{document_id}` |
| **AI — Codebase Restructuring (`src/`)** | Kiến trúc mô-đun hóa `src/ingestion`, `src/chunking`, `src/embeddings`, `src/vectordb`, `src/retrieval`, `src/prompts`, `src/llm`, `src/api`, `src/utils`, `config.yaml`, `main.py` |
| **AI — Visual Bounding Box Chunking** | Tự động phát hiện sơ đồ/bản vẽ (`MIN_DRAWING_AREA`), crop vùng ảnh thành file `uploads/crops/{version_id}_p{page}_c{idx}.png`, lưu metadata `image_path` vào ChromaDB cho UI snippet rendering |
| **AI — Qwen2-VL 2B (Q4_K_M) Visual Captioner** | Task-tuned prompts cho Qwen2-VL 2B khâu Ingestion (đọc nhãn, Markdown tables, tóm tắt hình vẽ 2-3 câu) |
| **AI — Pure-Text Vision Skip** | Tự động bỏ qua lượt gọi Qwen2-VL 2B khi trang PDF là thuần văn bản để tối ưu Ingestion latency và tiết kiệm tài nguyên |
| **AI — Static Upload Server (`/uploads`)** | Serve trực tiếp file ảnh crop qua FastAPI static files server (`http://localhost:8000/uploads/...`) |
| **AI — Vector Purge on Delete** | `vector_store.delete_document_chunks` xóa sạch embeddings trong ChromaDB + dọn dẹp file crop đĩa khi xóa tài liệu |
| **AI — Ingest thật (MinIO->OCR->callback)** | `ingest_service.py` goi `ocr_client.extract_pages()` + chunk + embed + index + callback BE |
| **AI — OCR thật (Service ai-ocr)** | `main_ocr.py` & `pipeline/ocr.py`: **PyMuPDF** (rasterize) + **PaddleOCR 3.7** — EN: CER 0%, VI: CER ~10% |
| **AI — Chunking thật** | `pipeline/chunk.py`: layout-aware (giu bang nguyen ven), sliding window 400 tu / overlap 60 |
| **AI — Embedding thật** | `pipeline/embed.py`: `multilingual-e5-small` ONNX/PyTorch, prefix chuan E5 (`passage: / query:`) |
| **AI — Vector Index ChromaDB** | `pipeline/index.py`: upsert vào collection `kcn_chunks`, idempotent theo `version_id` |
| **AI — Query RAG thật** | `api/query.py` & `services/query_service.py`: retrieve top-k ChromaDB + guardrails + goi LLM LM Studio |
| **AI — LLM Client (LM Studio)** | `clients/llm_client.py`: OpenAILike REST client, boc tach the `<think>` (reasoning mode), timeout 120s |
| **AI — Guardrails hoàn chỉnh** | `pipeline/guardrails.py`: `check_confidence` (theta=0.60), `check_numeric` (regex ky thuat da don vi), `check_reasoning_mode`, `is_locked` (dual-threshold: 0.60 / 0.25 cho reasoning mode) |
| **AI — Decoupled Async (Celery + Redis)** | `app/celery_app.py` + `app/workers/embed_worker.py`. Retry backoff, soft/hard timeout, task khong mat khi restart. |
| **AI — Callback Push per-step** | `clients/backend_client.py` + `schemas.IngestStatusPush`: push `PROCESSING_OCR -> PROCESSING_EMBED -> PROCESSING_INDEX -> READY/FAILED` ve BE tai moi buoc |
| **AI — SSE Streaming Query** | `POST /ai/query/stream` — `StreamingResponse` SSE: gui `meta` event (citations+guard) ngay, roi stream tung token tu LM Studio. Format RFC 8895. |
| **AI — LLM Stream Generator** | `clients/llm_client.generate_answer_stream()`: OpenAI SDK `stream=True`, xu ly delta.content + loc the `<think>` (DeepSeek-R1) co fallback. |
| **AI — True Multimodal Vision (VLM)** | `minio_client.get_object_base64()` + `llm_client.py` + `query_service.py`: truyen du lieu anh Base64 (`image_url`) sang OpenAI-compatible API cho cac model Vision (Qwen2-VL, Llama-3.2-Vision) phan tich truc tiep hinh ve ban ve. |
| **AI — ChatML & Prompt Optimization for Small Models** | `prompts.py` + `llm_client.py`: chuyen history ve mảng `messages` OpenAPI chuan, toi uu prompt ngan cho model 1.5B/3B (Qwen2.5, Llama-3.2) tranh hallucinate. |
| **Flutter — Login** | `auth/login_screen.dart` noi API that |
| **Flutter — Shell/Nav** | `shell/home_shell.dart` + routing role-guard |
| **Flutter — Tai lieu & Xóa Tài Liệu** | `documents_screen.dart` + `document_detail_screen.dart` + `upload_document_sheet.dart` — nối API thật + nút Xóa (Thùng rác đỏ) + Dialog xác nhận cảnh báo |
| **Flutter — SSE Chat UI (ChatGPT-like)** | `search/search_screen.dart` + `DocsRepository.askStream`: streaming token-by-token từng `event: delta` (typing effect), `event: meta` cita citations+guard ngay lập tức, `event: done` latencyMs, `event: error` banner lỗi. Chat history multi-turn (`_chatMessages` list). Filter theo tài liệu. |
| **Flutter — Global Exception Handling & Error Boundaries** | `ApiClient` Dio onError (401 auto token-clear) + `main.dart` Global Flutter & Async Error Catchers |
| **Flutter — Document BBox Viewer** | `document_viewer_screen.dart` + `bbox_painter.dart`: viewer anh MinIO có JWT headers + CustomPaint ve bounding box ky thuat |
| **Flutter — Layout & Density** | `VisualDensity.adaptivePlatformDensity`, `ConstrainedContent`, responsive layout cho ca Web & Mobile APK |
| **Flutter — Snap & Ask (Vision multimodal)** | `snap_ask/snap_ask_screen.dart` (1100 dòng): chụp ảnh (camera) hoặc chọn file (file_picker), hỏi đáp đa lượt per-ảnh (`_SnapEntry` + `_ChatMessage`), gọi `POST /api/query/vision` multipart, render `AnswerResult` + guardrail, fallback offline graceful. |
| **Flutter — Admin Console (Quản lý người dùng)** | `admin/admin_screen.dart`: danh sách user + filter role + tìm kiếm, dialog tạo tài khoản mới (form validation), reset mật khẩu, kích hoạt/khóa tài khoản (Switch). Nối API thật `GET/POST /api/admin/users`. |
| **BE — Admin User Management CRUD** | `UserController` (`/api/admin/users`): `GET` danh sách (phân trang, filter role, tìm kiếm), `POST` tạo user, `PUT /{id}` cập nhật, `PUT /{id}/password` reset mật khẩu, `PATCH /{id}/status` kích hoạt/khóa. `@PreAuthorize("hasRole('ADMIN')")`. |
| **BE — `POST /api/query/vision`** | `QueryController.askWithVision()`: nhận multipart (question + machineCode + file ảnh), forward sang AI `/ai/query/vision`, trả `AnswerDTO` kèm guardrail. |
| **Infra Docker** | postgres, redis, minio, zookeeper, kafka, chroma, backend, ai, ai-ocr, **ai-worker**, **ai-flower**, **ollama** — tất cả Up/Started |
| **BE — `POST /api/internal/ingest-status`** | Nhận per-step push từ AI, broadcast STOMP `/topic/ingest/{versionId}` — `SimpMessagingTemplate` |
| **BE — `POST /api/query/stream`** | SSE proxy từ AI `/ai/query/stream` về Flutter — `SseEmitter`, `CompletableFuture.runAsync`, `@EnableAsync` |
| **BE — `GET /api/files/{versionId}/{pageNo}/{bboxKey}`** | Proxy ảnh trang từ MinIO qua `FileProxyController`, JWT-protected, `Cache-Control: max-age=3600` |
| **BE — MinioService exceptions** | Thay `UnsupportedOperationException` bằng `IllegalStateException` proper |
| **Infra — Production deploy** | `docker-compose.prod.yml` (port isolation, memory limits), `nginx/dcid.conf` (SSE no-buffer, WS, HTTPS), `.env.example`, `scripts/deploy.sh`, `scripts/backup.sh` |
| **Infra — CI/CD** | `.github/workflows/deploy.yml` — GitHub Actions: build-backend → build-flutter-web → SCP+SSH deploy |


### 🔴 CHUA CO — can lam trong T4–T6

| Hạng mục | Blocking gì |
|---|---|
| **Dataset** (15–25 tai lieu VI/EN + degradation set) | Moi thi nghiem |
| **Eval set** (80–120 cau hoi + ground truth) | So lieu chuong 4 |
| **Eval harness tu dong** | Chay E1–E5, in bang metric |
| **OCR Pre-processing** (denoising, deskew, sieu phan giai) | Giam CER VI xuong < 5% |
| **DSPy optimization** (uu tien 1 — toi uu prompt lap dat, khong can GPU) | Cai thien do chinh xac cau tra loi lap dat |
| **Unsloth + LoRA SFT** (uu tien 2 — fine-tune Qwen 1.5B tren Google Colab, xuat GGUF) | Model chuyen biet hieu SOP/BOM/ban ve lap dat |
| **Flutter — Upload progress UI** (subscribe STOMP `/topic/ingest/{versionId}` sau upload) | Demo upload flow realtime |
| **Outline + quyen luan van** (chuong 1–2) | Bao ve |

---

## Milestones (đã cập nhật thực tế)

| # | Tên | Khi nào | Điều kiện DONE |
|---|---|---|---|
| **M0** | Nen tang + Auth + skeleton | ✅ **Xong** | Docker, self-JWT, RBAC, audit |
| **M1a** | Upload + Ingest E2E (pypdf mock) | ✅ **Xong** | upload PDF -> MinIO -> ACTIVE, E2E pass |
| **M1b** | OCR that tich hop (PaddleOCR) | ✅ **Xong** | ingest that EN/VI, CER baseline do duoc |
| **M1c** | chunk -> embed -> ChromaDB | ✅ **Xong** | ingest ghi vector vao Chroma, query retrieve duoc |
| **M1d** | LLM that + RAG query (LM Studio DeepSeek R1) | ✅ **Xong** | `/api/query` tra cau tra loi that tu LLM + citation trang + guardrails |
| **M1e** | Decoupled Async Architecture (Celery + Redis + SSE) | ✅ **Xong (25/07/2026)** | Celery Worker tach roi, callback push per-step, SSE streaming `/query/stream`, Flower monitoring |
| **M3** | Flutter SSE Chat + BE stream proxy + Citation viewer + Admin User Management + Snap & Ask | ✅ **Xong (06/08/2026)** | SSE chat typing effect, citation bbox, banner guardrail, Admin CRUD user, Vision multimodal Snap & Ask |
| **M2** | Experiments E1–E2 (do dac chi tiet guardrail/chunking) | ⏳ **T4** | bang so lieu hallucination rate, Recall@k |
| **M2b** | OCR Pre-processing + DSPy optimization | ⏳ **T4–T5** | CER VI < 5%, cau tra loi lap dat chinh xac hon |
| **M2c** | Unsloth + LoRA SFT — fine-tune Qwen 1.5B | ⏳ **T5–T6** | Dataset JSONL >= 100 mau, model GGUF load duoc LM Studio, do order_accuracy |
| **M3b** | Flutter Upload progress realtime (STOMP) | ⏳ **T4** | progress bar per-step OCR → Embed → ACTIVE sau upload |
| **M4** | Luan van + eval set hoan chinh | ⏳ **T6–T7** | bang metric E1–E2, code freeze |
| **M5** | Demo + bao ve | ⏳ **T8** | video demo du phong, slide, Q&A thu |


---

## Huong di tiep theo — theo thu tu uu tien

### ✅ T2 — Hoàn thành (25/07/2026)

Da hoan tat: kien truc Celery async, callback push per-step, SSE Query streaming AI-side, guardrails hoan chinh (`pipeline/guardrails.py`).

---

### ✅ T3 — Hoàn thành (06/08/2026)

**Hoàn tất toàn bộ M3:** SSE Chat UI ChatGPT-like (token streaming), BE SSE proxy, File proxy MinIO JWT-protected, STOMP broadcast ingest status, Admin Console (Flutter + BE CRUD), Snap & Ask Vision multimodal, `POST /api/query/vision` BE endpoint.

#### Các việc đã xong trong T3:

| Hạng mục | Chi tiết |
|---|---|
| **BE — `POST /api/query/stream`** | `QueryController.askStreaming()` → `SseEmitter`, proxy SSE từ AI, ghi `query_logs` khi done |
| **BE — `POST /api/internal/ingest-status`** | `InternalIngestController.ingestStatus()` → broadcast STOMP `/topic/ingest/{versionId}` qua `SimpMessagingTemplate` |
| **BE — `GET /api/files/{versionId}/{pageNo}/{bboxKey}`** | `FileProxyController` → proxy ảnh trang từ MinIO, JWT-protected |
| **BE — Admin User CRUD** | `UserController` `/api/admin/users`: GET (filter role/search), POST create, PUT update, PUT password, PATCH status |
| **BE — `POST /api/query/vision`** | `QueryController.askWithVision()` multipart: question + machineCode + ảnh file → AI vision endpoint |
| **Flutter — SSE Chat UI** | `search_screen.dart`: `askStream()` SSE, typing effect, multi-turn history, filter tài liệu, guard banner |
| **Flutter — Snap & Ask** | `snap_ask_screen.dart` (1100 dòng): camera/file_picker, per-image chat thread, gọi `/api/query/vision`, fallback offline |
| **Flutter — Admin Console** | `admin_screen.dart`: CRUD user, search/filter role, tạo tài khoản dialog, reset mật khẩu, kích hoạt/khóa Switch |

---

### 🟢 T4 — Việc cần làm NGAY (tuần hiện tại)

**Đường găng T4:** Thu thập eval set + OCR pre-processing + bắt đầu thực nghiệm E1–E2.

#### AI Engineer (Nguoi 3)

- Thu thap bo eval set v1 (20–30 cau hoi + trang nguon)
- OCR pre-processing: tang DPI 300, denoising OpenCV, do CER lai
- DSPy BootstrapFewShot de toi uu prompt lap dat
- Dam bao bbox metadata khong NULL trong ChromaDB (chunk.py / index.py)

#### Flutter (Nguoi 4)

**Upload progress UI (STOMP WebSocket)** — con lai trong M3b
- Sau khi upload thanh cong, subscribe `/topic/ingest/{versionId}` qua STOMP
- Hien thi progress bar: `OCR → Embedding → Đã sẵn sàng`
- Fallback polling `GET /ai/status/{taskId}` neu WS unstable

#### PM (Nguoi 1)

- Viet Chuong 2 luan van (Co so ly thuyet: RAG, SLM, Hallucination control)
- Cap nhat `docs/API-CONTRACT.md` voi cac endpoint T3 moi: `/api/query/stream`, `/api/query/vision`, `/api/admin/users/**`, `/api/internal/ingest-status`, `/api/files/**`

#### Data/Eval (Nguoi 5)

**Eval set v1 + Harness v1**
- Tao file `data/eval/questions.csv` (80–120 cau hoi co dap an chuan)
- Phan nhom: Factual/so lieu (40%), Quy trinh (40%), Ngoai pham vi (20%)
- Viet script Python `harness.py` de doc CSV va tu dong goi API `/ai/query`

---

### 🟡 T4–T5 — Experiments + OCR Pre-processing + DSPy

#### AI Engineer (Nguoi 3)

> ✅ **Luu y**: `pipeline/guardrails.py` da hoan chinh (check_confidence, check_numeric, check_reasoning_mode, is_locked voi dual-threshold). T4 tap trung do dac thuc nghiem va OCR pre-processing.

**Thuc nghiem E1–E2:**
- E1: Hallucination rate (% cau tra loi ngoai pham vi bi chan dung)
- E2: Recall@k (% cau hoi co chunk dung trong top-k)
- Ghi ket qua vao bang thuc nghiem chuong 4

**OCR Pre-processing (`pipeline/ocr.py`) — Muc tieu: CER VI tu 10.4% xuong < 5%**

| Buoc | Viec lam | Cong cu | Vi tri code |
|---|---|---|---|
| **Pre-1** | Tang `RENDER_DPI` len 300 cho ban ve A3/A2/A1 | PyMuPDF `Matrix(scale)` | `ocr.py` — `RENDER_DPI` |
| **Pre-2** | Khu nhieu (denoising) anh scan truoc PaddleOCR | `cv2.fastNlMeansDenoisingColored()` | Them ham `_preprocess_img(img)` trong `ocr.py` |
| **Pre-3** | Deskew (chinh nghieng) tu dong cho anh scan | `cv2.HoughLinesP` + `warpAffine` | Trong `_preprocess_img()` |
| **Pre-4** | Hybrid: PaddleOCR detection + **VietOCR** recognition cho doan VI | `pip install vietocr` | Tach nhanh `lang="vi"` trong `_get_engine()` |
| **Pre-5** | Do CER lai sau tung buoc -> ghi vao bang E5 | `jiwer` CER/WER | `tests/test_ocr_cer.py` |

**Dam bao Bbox metadata trong Chunking (`pipeline/chunk.py`)**

Moi chunk trong ChromaDB **bat buoc** giu `page_no` + `bbox` — cac buoc lap dat trong ban ve luon di kem chu thich toa do cu the.

**DSPy Optimization — Toi uu Prompt cho Quy trinh Lap dat**

Tich hop **DSPy** de toi uu tu dong `prompts.py` cho tinh huong lap dat tu ban ve. Chay tren LM Studio local — khong can GPU, khong them ha tang.

#### Data/Eval (Nguoi 5)

**Eval set v1 (80–120 cau):**
```
data/eval/questions.csv
  id, question, ground_truth_answer, source_page, doc_filename, category
```

---

### 🟠 T5 — Unsloth + LoRA SFT (Uu tien 2)

#### AI Engineer (Nguoi 3)

**Muc tieu**: Fine-tune Qwen 1.5B thanh model chuyen biet hieu SOP/BOM/quy trinh lap dat tu ban ve.

#### Data/Eval (Nguoi 5)

- Chon loc 100–300 mau tu eval set + trang ban ve that
- Xac nhan output ground truth voi ky su truoc khi dung lam du lieu huan luyen
- Luu vao `training_data/installation_qa.jsonl`

---

## Quyet dinh ky thuat da chot

| # | Quyet dinh | Ly do |
|---|---|---|
| 1 | **OCR: PaddleOCR 3.7 + PyMuPDF** | Khong can system deps (poppler), cai thuan pip, CER 0% EN |
| 2 | **Rasterize: RENDER_DPI=200 -> 300 (T4)** | A4 du net; nang len 300 DPI cho ban ve A3/A2/A1 co ky hieu nho |
| 3 | **enable_mkldnn=False** | paddlepaddle 3.3.0 loi oneDNN/PIR runtime khi mkldnn=True |
| 4 | **LLM & Vision VLM: Ollama (production) / LM Studio (dev) + Qwen2-VL-2B-Instruct GGUF Q4_K_M** | Ollama chạy headless trong Docker (server/VPS), LM Studio cho dev local. Qwen2-VL hỗ trợ cả Text RAG lẫn Multimodal Vision phân tích trực tiếp hình ảnh bản vẽ, RAM ~1.3GB Q4 vừa đủ VPS 8GB |
| 5 | **Embed: multilingual-e5-small ONNX** | <400MB, multilingual, chay CPU |
| 6 | **Vector DB: ChromaDB** | Persistent tren edge, de dong goi offline |
| 7 | **Frontend: Flutter Web + Android** | 1 codebase, target chinh: Web kiosk + Android mobile |
| 8 | **Upload: bytes-based (khong path)** | `PlatformFile.path = null` tren Flutter Web |
| 9 | **Guardrail threshold: cosine < 0.60 / 0.25 (reasoning)** | Theo contract API-CONTRACT.md §2.2; reasoning mode dung threshold 0.25 de lay chi tiet ban ve |
| 10 | **OCR Pre-processing: denoising + deskew (T4)** | CER VI 10.4% duoi KPI 95%; tien xu ly bang OpenCV giam nhieu scan truoc PaddleOCR |
| 11 | **Chunking metadata: bbox bat buoc khong NULL (T4)** | Buoc lap dat ban ve can toa do Bbox chinh xac de citation viewer va eval harness hoat dong dung |
| 12 | **DSPy BootstrapFewShot — Uu tien 1 (T4–T5)** | Toi uu prompt quy trinh lap dat tu dong tu 30–50 vi du Q&A; chay tren LM Studio local, khong can GPU |
| 13 | **Unsloth + LoRA SFT — Uu tien 2 (T5–T6)** | Fine-tune weight that su khi DSPy chua du; chay tren Google Colab Free (T4 GPU 16GB), xuat GGUF -> load LM Studio |
| 14 | **Async Ingest: Celery + Redis (T2)** | Thay the FastAPI BackgroundTasks. Embed model (470MB) chi nap 1 lan trong worker, task_acks_late=True |
| 15 | **Callback Push per-step (T2)** | AI worker chu dong push trang thai ve BE tai moi buoc — khong can BE polling. Endpoint: `POST /api/internal/ingest-status` |
| 16 | **SSE Streaming Query (T2)** | `POST /ai/query/stream` stream tung token tu LM Studio theo RFC 8895. Meta event -> chu hien dan — trai nghiem giong ChatGPT |
| 17 | **BE SSE Proxy `POST /api/query/stream` (T3)** | `QueryController.askStreaming()` forward SSE tu AI ve Flutter qua `SseEmitter`. Ghi query_logs khi nhan event `done`. Flutter khong goi thang AI service. |
| 18 | **STOMP WebSocket cho ingest progress (T3)** | `InternalIngestController.ingestStatus()` broadcast per-step qua `/topic/ingest/{versionId}` bang `SimpMessagingTemplate`. |
| 19 | **True Multimodal Vision API (VLM)** | Ho tro gui `image_url` base64 qua LM Studio voi model **Qwen2-VL-2B-Instruct GGUF Q4_K_M** xem truc tiep va phan tich hinh ve ban ve ky thuat. |
| 20 | **ChatML & Small Model Prompt Tuning** | Chuyen history ve OpenAI message list `[{"role": "user/assistant", ...}]`, rut gon system prompt de cac model 1.5B/3B (Qwen 2.5, Llama 3.2) chay mượt ma khong lặp lai system prompt. |
| 21 | **Visual Bounding Box Chunking & `image_path`** | Cắt các vùng sơ đồ/bản vẽ thành file ảnh riêng trong `uploads/crops/`, lưu `image_path` vào metadata ChromaDB để Frontend UI render ảnh trích dẫn trực tiếp. |
| 22 | **Pure-Text Vision Skip** | Tự động phát hiện và bỏ qua Qwen2-VL 2B khi trang PDF là thuần văn bản để tối ưu Ingestion latency và tiết kiệm tài nguyên CPU/GPU. |
| 23 | **Fullstack Delete Document Pipeline** | Xóa tài liệu đồng bộ qua `DELETE /api/documents/{id}` ở Backend (MinIO PDF/pages + DB records) + `DELETE /ai/documents/{document_id}` ở AI Service (purge ChromaDB vectors + crop files) + nút xóa UI Flutter. |
| 24 | **Admin Console Flutter + BE CRUD (T3)** | `admin_screen.dart` quản lý toàn bộ người dùng: search/filter/tạo/reset-mật-khẩu/kích-hoạt-khóa. BE `UserController` `/api/admin/users` với 5 endpoint, `@PreAuthorize("hasRole('ADMIN')")`. |
| 25 | **SSE Chat UI multi-turn (T3)** | `search_screen.dart` nâng cấp thành ChatGPT-like: `_ChatEntry` list, stream từng token SSE `delta`, citations render ngay lập tức khi nhận `meta`, filter tài liệu theo version ID. |
| 26 | **Snap & Ask Vision Screen (T3)** | `snap_ask_screen.dart`: per-image Q&A threads (`_SnapEntry` + `_ChatMessage`), camera/file_picker, gọi `POST /api/query/vision` multipart, fallback answer offline graceful. |


---

## Rui ro con lai

| Rui ro | Muc | Doi sach |
|---|---|---|
| OCR VI CER 10% duoi KPI 95% | 🟡 | **[T4]** Bat OCR pre-processing (denoising + deskew) + thu VietOCR hybrid; do CER lai sau tung buoc |
| Bbox metadata bi None -> citation viewer vo | 🟡 | **[T4]** Patch `chunk.py` + `index.py` dam bao bbox luon la chuoi toa do hoac chuoi rong `""`; them test case bbox_not_none |
| DSPy compile chay cham tren CPU (>30 phut) | 🟡 | **[T4]** Gioi han `max_bootstrapped_demos=3`, `num_candidates=10`; neu vuot T5 -> cat DSPy, giu ket qua prompt thu cong lam baseline |
| Ky hieu ky thuat (um, N.m, +-) bi OCR nhan sai | 🟡 | **[T4]** Tang DPI len 300, bat sharpen kernel; do CER rieng tren cau co ky hieu dac biet |
| Latency LLM > 5s tren CPU | 🟡 | Do tai T3; giam top-k/context; doi 0.5B neu can |
| SSE proxy BE bi Nginx buffering -> Flutter khong nhan token theo tung chunk | 🟡 | **[T3]** Them header `X-Accel-Buffering: no` + `Cache-Control: no-cache` trong BE SSE response; test voi curl -N truoc Flutter |
| STOMP WebSocket bi CORS / SockJS khong tuong thich Flutter Web | 🟡 | **[T3]** Test bang `stomp_dart_client`; fallback polling `GET /ai/status/{taskId}` neu WS khong on dinh |
| Dataset tu suu tam kem chat luong | 🟡 | PM + nguoi 5 review cheo tung cau eval; ground truth phai co trang nguon |
| Dataset Unsloth < 100 mau -> model overfit | 🟡 | **[T5]** Nguoi 5 + Nguoi 3 review cheo tung mau; dung data augmentation; neu < 50 mau -> ha xuong LoRA r=4 |
| Google Colab mat phien khi fine-tune | 🟡 | **[T5]** Checkpoint moi 50 buoc (save_steps=50); luu checkpoint len Google Drive |
| Model GGUF sau SFT khong tuong thich LM Studio | 🟢 | Kiem tra phien ban llama.cpp trong LM Studio; xuat Q4 K M thay vi Q8 0 neu vuot VRAM |
| Khong kip viet luan van | 🔴 | CODE FREEZE T6; viet chuong 1–2 song song tu T2 ngay |
| Demo hong hom bao ve | 🟢 | Quay video du phong T6; compose 1 lenh khoi dong lai |
