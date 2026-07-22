# Smart KCN Docs — Roadmap (cập nhật 22/07/2026)

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
| **OCR Pre-processing pipeline** (denoising, deskew, siêu phân giải) | Giảm CER VI xuống < 5% |
| **DSPy optimization** (ưu tiên 1 — tối ưu prompt lắp đặt, không cần GPU) | Cải thiện độ chính xác câu trả lời lắp đặt |
| **Unsloth + LoRA SFT** (ưu tiên 2 — fine-tune Qwen 1.5B trên Google Colab, xuất GGUF) | Model chuyên biệt hiểu SOP/BOM/bản vẽ lắp đặt |
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
| **M2b** | OCR Pre-processing + DSPy optimization (tình huống lắp đặt) | ⬜ **T4–T5** | CER VI < 5%, câu trả lời lắp đặt chính xác hơn |
| **M2c** | Unsloth + LoRA SFT — fine-tune Qwen 1.5B chuyên lắp đặt | ⬜ **T5–T6** | Dataset JSONL ≥ 100 mẫu, model GGUF load được LM Studio, đo order_accuracy |
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

### 🟡 T4–T5 — Guardrail + Experiments + OCR Pre-processing + DSPy

#### AI Engineer (Người 3)

**Guardrail thật (pipeline/guardrails.py)**
- `check_confidence(score: float) → bool`: score < 0.60 → locked
- `check_numeric(question: str) → bool`: regex keyword → True
- Khi numeric → trích số liệu trực tiếp từ `chunk.text` (regex đơn vị: V, bar, °C, mm, Nm)

**🆕 [M2b — Lưu ý 1] Tinh chỉnh OCR Pre-processing (`pipeline/ocr.py`)**

Mục tiêu: giảm CER tiếng Việt từ 10.4% → < 5% cho tài liệu kỹ thuật có ký hiệu nhỏ (`μm`, `N·m`, bảng biểu phức tạp).

> ⚠️ **Lưu ý quan trọng:** Chất lượng OCR là nền tảng — CER 10% hiện tại ảnh hưởng trực tiếp đến độ chính xác embedding và truy xuất RAG. Phải làm trước E1/E2.

| Bước | Việc làm | Công cụ | Vị trí code |
|---|---|---|---|
| **Pre-1** | Tăng `RENDER_DPI` lên 300 cho bản vẽ A3/A2/A1 (hiện đang dùng 200 DPI) | PyMuPDF `Matrix(scale)` | `ocr.py:22` — `RENDER_DPI` |
| **Pre-2** | Khử nhiễu (denoising) ảnh scan trước khi PaddleOCR | `cv2.fastNlMeansDenoisingColored()` hoặc `PIL.ImageFilter.SHARPEN` | Thêm hàm `_preprocess_img(img)` trong `ocr.py` |
| **Pre-3** | Deskew (chỉnh nghiêng) tự động cho ảnh scan | `cv2.HoughLinesP` + `warpAffine` | Trong `_preprocess_img()` |
| **Pre-4** | Thử hybrid: PaddleOCR detection + **VietOCR** recognition cho đoạn VI | `pip install vietocr` | Tách nhánh `lang="vi"` trong `_get_engine()` |
| **Pre-5** | Đo CER lại sau từng bước → ghi vào bảng thực nghiệm E5 | `jiwer` CER/WER | `tests/test_ocr_cer.py` |

```python
# Thêm vào ocr.py — hàm tiền xử lý ảnh
def _preprocess_img(img: np.ndarray, dpi: int = RENDER_DPI) -> np.ndarray:
    """Tiền xử lý ảnh: denoising + deskew + sharpening trước khi đẩy vào PaddleOCR.
    Đặc biệt quan trọng với bản vẽ kỹ thuật có ký hiệu nhỏ (μm, N·m) và bảng biểu
    dày đặc — nơi nhiễu ảnh tác động mạnh nhất đến CER tiếng Việt.
    """
    import cv2
    # 1. Denoise: giảm nhiễu muối tiêu (photocopy, scan lần 2)
    denoised = cv2.fastNlMeansDenoisingColored(img, h=10, hColor=10, templateWindowSize=7)
    # 2. Sharpen: tăng nét cho ký hiệu đặc biệt (μ, ±, ·)
    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    sharpened = cv2.filter2D(denoised, -1, kernel)
    # 3. Adaptive threshold (tuỳ chọn — bật cho scan suy giảm)
    return sharpened
```

**🆕 [M2b — Lưu ý 2] Đảm bảo Metadata Bbox trong Chunking (`pipeline/chunk.py`)**

Mục tiêu: Mỗi chunk trong ChromaDB **bắt buộc** phải giữ `page_no` + `bbox` — các bước lắp đặt trong bản vẽ luôn đi kèm chú thích tọa độ cụ thể.

| Hạng mục | Hiện trạng | Cần làm |
|---|---|---|
| `page_no` trong Chunk | ✅ Đã có | Giữ nguyên |
| `bbox` tổng hợp (union Bbox của chunk) | ✅ Đã có dạng `"x0,y0,x1,y1"` | Verify không bị `None` khi OCR native text |
| `bbox` từng dòng (line-level Bbox) | ⬜ Chưa có | Thêm `line_boxes: list[tuple]` vào `Chunk` cho citation viewer |
| Metadata ChromaDB `bbox` field | ✅ Đã upsert | Kiểm tra không bị stringify None → lưu chuỗi rỗng `""` thay vì `"None"` |
| Snippet chunk hiển thị Bbox trong trích dẫn | ✅ Format `### [Đoạn kỹ thuật - Trang X \| Bbox: ...]` | Đảm bảo format nhất quán kể cả khi boxes=[] |

```python
# Kiểm tra và vá vào chunk.py — đảm bảo bbox không bao giờ None/"None"
# Trong _make_chunk(): thay thế dòng hiện tại
final_bbox = f"{min_x:.1f},{min_y:.1f},{max_x:.1f},{max_y:.1f}" if boxes else ""
# Trong index.py upsert metadata:
"bbox": str(c.bbox) if c.bbox else "",  # Không lưu "None" string
```

**🆕 [M2b] DSPy Optimization — Tối ưu Prompt cho Quy trình Lắp đặt**

Tích hợp **DSPy** để tối ưu tự động `prompts.py` cho tình huống lắp đặt từ bản vẽ (thứ tự bước, số liệu kỹ thuật chính xác). Chạy trên LM Studio local — không cần GPU, không thêm hạ tầng.

```bash
pip install dspy-ai>=2.5  # thêm vào requirements.txt
```

Các việc cụ thể:
- Thu thập **30–50 cặp Q&A kỹ thuật thật** từ bộ eval set (đặc biệt nhóm "quy trình/SOP 40%")
- Tạo `app/pipeline/dspy_rag.py` với `InstallationRAG(dspy.Module)`
- Metric tối ưu: `sequence_order_accuracy` (thứ tự bước đúng) + `numeric_faithfulness` (số liệu khớp Bbox)
- Chạy `dspy.BootstrapFewShotWithRandomSearch.compile()` → xuất optimized prompt
- A/B test: so sánh `prompts.py` thủ công vs DSPy-optimized (ghi vào E2 arm 3)

**Thí nghiệm E1** (chunking):
- Arm 1: fixed-size 512 tokens → đo Recall@3
- Arm 2: layout-aware (giữ bảng) → đo Recall@3
- **Arm 3 (mới):** layout-aware + OCR pre-processing (denoised) → đo Recall@3
- Dùng eval harness

**Thí nghiệm E2** (guardrail):
- Arm 1: LLM thuần → đo hallucination rate
- Arm 2: + confidence-gate (θ=0.60)
- Arm 3: + numeric rule-extraction
- **Arm 4 (mới):** + DSPy-optimized prompt cho quy trình lắp đặt
- Dùng eval harness

#### Data/Eval (Người 5)

**Eval set v1 (80–120 câu):**
```
data/eval/questions.csv
  id, question, ground_truth_answer, source_page, doc_filename, category
```
3 nhóm: factual/số liệu (40%), quy trình/SOP — **bao gồm câu hỏi lắp đặt bản vẽ** (40%), ngoài phạm vi (20%)

**Eval harness (cập nhật thêm metric OCR):**
```bash
python eval/run_eval.py --config eval/config.yaml
# In bảng: Recall@3, Recall@5, hallucination_rate, false_answer_rate, latency_p50
# + ocr_cer_clean, ocr_cer_degraded (đo thêm sau OCR pre-processing)
# + installation_step_order_accuracy (% câu lắp đặt đúng thứ tự)
```

#### Flutter (Người 4)

**Citation viewer:**
- Load ảnh trang từ `GET /api/files/{imageKey}`
- Overlay bbox crop (khi bboxKey có trong citation)
- Banner đỏ khi `guard.locked = true`
- Chip "Số liệu trực tiếp" khi `guard.numericRule = true`

---

### 🟠 T5 — Unsloth + LoRA SFT (Ưu tiên 2 — song song với Guardrail/Experiments)

> 🆕 Theo plan đề xuất — thực hiện song song trong T5, không cần thêm tuần.

#### AI Engineer (Người 3) — Unsloth LoRA Fine-tuning

**Mục tiêu**: Fine-tune Qwen 1.5B thành model chuyên biệt hiểu SOP/BOM/quy trình lắp đặt từ bản vẽ. Khi DSPy tối ưu prompt chưa đủ — model vẫn sai quy trình, sai số liệu — Unsloth fine-tune weight thật sự.

**Bước 1 — Xây dataset JSONL (cùng Người 5)**

```jsonl
// training_data/installation_qa.jsonl (cần ≥ 100 mẫu, mục tiêu 300–500)
{"instruction": "Từ bản vẽ [Bbox: 120,340,580,620] trang 3, liệt kê các bước lắp trục chính theo thứ tự.",
 "input": "### [Bảng kỹ thuật - Trang 3 | Bbox: 120.0,340.0,580.0,620.0]\nBước 1: Làm sạch bề mặt trục...",
 "output": "Bước 1: Làm sạch bề mặt trục bằng cồn công nghiệp (Trang 3 | Bbox 120,340)\nBước 2: Tra mỡ bôi trơn loại SKF LGEP 2 vào rãnh then..."}
```

3 loại mẫu cần xây trong dataset:
- **SOP/quy trình** (~50%): liệt kê bước lắp theo thứ tự từ bản vẽ
- **Số liệu kỹ thuật** (~30%): trích xuất chính xác moment xiết, áp suất, dung sai từ Bbox
- **BOM (Bill of Materials)** (~20%): liệt kê chi tiết, mã hiệu, số lượng từ bản vẽ lắp ráp

**Bước 2 — Fine-tune trên Google Colab Free (T4 16GB)**

```bash
# Google Colab — KHÔNG cần GPU local
pip install unsloth

# Fine-tune Qwen 1.5B với LoRA (r=16, alpha=32)
# Training ~2–3 giờ trên T4 GPU với 300 mẫu
# Xuất GGUF (Q8_0 hoặc Q4_K_M)
```

**Bước 3 — Load vào LM Studio thay model gốc**
- Kéo file `.gguf` vào LM Studio → load dưới tên `qwen-1.5b-installation-expert`
- Đổi `LM_STUDIO_MODEL` trong `dcid-ai/.env` → `qwen-1.5b-installation-expert`
- Chạy eval harness → so sánh trước/sau SFT

**Kết quả kỳ vọng sau Unsloth SFT:**

| Metric | Trước SFT | Sau SFT |
|---|---|---|
| Thứ tự bước lắp đặt | Sai ngẫu nhiên | Đúng theo bản vẽ |
| Số liệu kỹ thuật | Bịa (hallucination) | Chỉ trích từ Bbox |
| Thuật ngữ cơ khí VN | Không hiểu | Hiểu "moment xoắn", "dung sai IT6" |
| `installation_step_order_accuracy` | Baseline DSPy | Mục tiêu > 90% |

#### Data/Eval (Người 5) — Chuẩn bị dataset SFT
- Chọn lọc 100–300 mẫu từ eval set + trang bản vẽ thật để đạt điều kiện DONE M2c
- Xác nhận output ground truth với kỹ sư trước khi dùng làm dữ liệu huấn luyện
- Lưu vào `training_data/installation_qa.jsonl`

---

### 🟢 T6 — Đóng băng thí nghiệm + Đánh giá model SFT

- Chốt bảng kết quả E1–E2 (+ E3/E4 nếu kịp)
- **M2c:** So sánh định lượng 3 cấu hình LLM: `DeepSeek-R1 gốc` vs `DSPy-optimized` vs `Unsloth-SFT`
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
| 2 | **Rasterize: RENDER_DPI=200 → 300 (T4)** | A4 đủ nét; nâng lên 300 DPI cho bản vẽ A3/A2/A1 có ký hiệu nhỏ (μm, N·m, bảng kỹ thuật dày đặc) |
| 3 | **enable_mkldnn=False** | paddlepaddle 3.3.0 lỗi oneDNN/PIR runtime khi mkldnn=True |
| 4 | **LLM: LM Studio (REST API) + DeepSeek R1 Distill Qwen 1.5B Q8_0** | Tách inference engine sang LM Studio local, hỗ trợ reasoning `<think>`, không phụ thuộc C++ binding trong container |
| 5 | **Embed: multilingual-e5-small ONNX** | <400MB, multilingual, chạy CPU |
| 6 | **Vector DB: ChromaDB** | Persistent trên edge, dễ đóng gói offline |
| 7 | **Frontend: Flutter Web + Android** | 1 codebase, target chính: Web kiosk + Android mobile |
| 8 | **Upload: bytes-based (không path)** | `PlatformFile.path = null` trên Flutter Web |
| 9 | **Guardrail threshold: cosine < 0.60** | Theo contract API-CONTRACT.md §2.2 |
| 10 | **OCR Pre-processing: denoising + deskew (T4)** | CER VI 10.4% dưới KPI 95%; tiền xử lý bằng OpenCV giảm nhiễu scan trước PaddleOCR |
| 11 | **Chunking metadata: bbox bắt buộc không NULL (T4)** | Bước lắp đặt bản vẽ cần tọa độ Bbox chính xác để citation viewer và eval harness hoạt động đúng |
| 12 | **DSPy BootstrapFewShot — Ưu tiên 1 (T4–T5)** | Tối ưu prompt quy trình lắp đặt tự động từ 30–50 ví dụ Q&A; chạy trên LM Studio local, không cần GPU, không thay đổi hạ tầng |
| 13 | **Unsloth + LoRA SFT — Ưu tiên 2 (T5–T6)** | Fine-tune weight thật sự khi DSPy chưa đủ; chạy trên Google Colab Free (T4 GPU 16GB), xuất GGUF → load lại LM Studio; không cần GPU local |

---

## Rủi ro còn lại

| Rủi ro | Mức | Đối sách |
|---|---|---|
| OCR VI CER 10% dưới KPI 95% | 🟡 | **[T4]** Bật OCR pre-processing (denoising + deskew) + thử VietOCR hybrid; đo CER lại sau từng bước; báo cáo trung thực trade-off nếu vẫn không đạt |
| Bbox metadata bị None/"None" → citation viewer vỡ | 🟡 | **[T4]** Patch `chunk.py` + `index.py` đảm bảo bbox luôn là chuỗi toạ độ hoặc chuỗi rỗng `""`; thêm test case bbox_not_none vào unit test |
| DSPy compile chạy chậm trên CPU (>30 phút) | 🟡 | **[T4]** Giới hạn `max_bootstrapped_demos=3`, `num_candidates=10`; nếu vượt T5 → cắt DSPy, giữ kết quả prompt thủ công làm baseline |
| Ký hiệu kỹ thuật (μm, N·m, ±) bị OCR nhận sai | 🟡 | **[T4]** Tăng DPI lên 300, bật sharpen kernel; đo CER riêng trên câu có ký hiệu đặc biệt |
| Latency LLM > 5s trên CPU | 🟡 | Đo tại T3; giảm top-k/context; đổi 0.5B nếu cần |
| Dataset tự sưu tầm kém chất lượng | 🟡 | PM + người 5 review chéo từng câu eval; ground truth phải có trang nguồn |
| Dataset Unsloth < 100 mẫu → model overfit | 🟡 | **[T5]** Người 5 + Người 3 review chéo từng mẫu; dùng data augmentation nếu thiếu; nếu < 50 mẫu → hạ xuống LoRA r=4 |
| Google Colab mất phiên khi fine-tune | 🟡 | **[T5]** Checkpoint mỗi 50 bước (save_steps=50); lưu checkpoint lên Google Drive tránh mất tiến trình |
| Model GGUF sau SFT không tương thích LM Studio | 🟢 | Kiểm tra phiên bản llama.cpp trong LM Studio; xuất Q4 K M thay vì Q8 0 nếu vượt VRAM |
| Không kịp viết luận văn | 🔴 | CODE FREEZE T6; viết chương 1–2 song song từ T2 ngay |
| Demo hỏng hôm bảo vệ | 🟢 | Quay video dự phòng T6; compose 1 lệnh khởi động lại |
