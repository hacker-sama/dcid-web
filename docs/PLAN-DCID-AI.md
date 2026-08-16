# WORK ORDER — Dựng khung `dcid-ai` (FastAPI skeleton)

> **Dành cho agent thực thi độc lập.** Tài liệu này tự chứa: đọc xong là code được, không cần
> ngữ cảnh hội thoại nào khác. Nguồn sự thật về API: [`API-CONTRACT.md`](API-CONTRACT.md) (cùng thư mục).
> Nếu thấy contract mâu thuẫn với plan này → **contract thắng**, ghi chú lại, KHÔNG tự sửa contract.
>
> 🛑 **CẬP NHẬT 07/2026**: Kế hoạch dựng skeleton này **đã hoàn thành và vượt mức**. Pipeline hiện tại không còn là skeleton (mock) nữa mà là một Pipeline RAG hoàn chỉnh (với PaddleOCR, Qwen2-VL, ChromaDB, Celery workers) được đặt tại `dcid-ai/src/`. Xem `ROADMAP.md` và `ARCHITECTURE.md` để nắm kiến trúc mới. File này hiện có giá trị lịch sử về quá trình khởi tạo project.

---

## 1. Bối cảnh (đọc 1 phút)

Monorepo `dcid-web` là hệ thống **DCID: Digital Cognitive InDustrial System** — hệ thống hỏi–đáp (RAG) tài liệu kỹ thuật cơ khí,
chạy on-premise. Kiến trúc 2 mặt phẳng:

- `dcid-backend/` (Spring Boot, **ĐÃ XONG phần liên quan**): auth JWT, RBAC, upload PDF vào MinIO,
  gọi AI ingest, nhận callback ghi Postgres, forward query. **KHÔNG được sửa thư mục này.**
- `dcid-ai/` (**CHƯA TỒN TẠI — nhiệm vụ của bạn**): Python FastAPI, sau này chứa OCR/embedding/LLM.
- `dcid-app/` (Flutter): **không đụng tới**.

**Nhiệm vụ đợt này: chỉ dựng SKELETON** — service chạy được, đúng contract, pipeline là **mock**.
OCR/embedding/LLM thật là đợt sau (đã có TODO chờ sẵn). Mục đích: backend + app test tích hợp
2 chiều được ngay.

Môi trường dev: **Windows** (tránh path/lệnh POSIX-only trong code & script), Python 3.11+.
Hạ tầng khi chạy đủ bộ: Postgres/MinIO/Redis qua `docker-compose.yml` ở repo root.

---

## 2. Scope

### ✅ PHẢI làm
1. Project `dcid-ai/` cấu trúc như §3, chạy bằng `uvicorn app.main:app --port 8000`.
2. 3 endpoint đúng contract (§4): `GET /ai/health`, `POST /ai/ingest`, `POST /ai/query`.
3. Xác thực nội bộ: header `X-Internal-Token` (so sánh với env `AI_INTERNAL_TOKEN`) cho
   ingest/query; sai/thiếu → `401`. Khi gọi callback về BE cũng phải gắn header này.
4. Ingest **mock nhưng có giá trị thật**: đọc file PDF thật từ MinIO theo `storageKey`,
   đếm số trang bằng `pypdf`, rồi POST callback về BE. MinIO/PDF lỗi → callback `FAILED`.
5. Query **mock**: trả response đúng schema, nội dung giả lập (§4.3).
6. Stub các module pipeline cho đợt sau: hàm ký tên đầy đủ + `raise NotImplementedError` + TODO.
7. Unit test (pytest) + `Dockerfile` + thêm service `ai` vào `docker-compose.yml` root (§6).
8. `dcid-ai/README.md`: cách chạy, cách test, biến môi trường.

### ⛔ KHÔNG làm đợt này
- KHÔNG cài/viết PaddleOCR, ChromaDB, llama-cpp, sentence-transformers, Celery
  (requirements phải nhẹ — cài dưới 1 phút).
- KHÔNG sửa `dcid-backend/`, `dcid-app/`, các file `docs/*` khác.
- KHÔNG đổi tên field/endpoint trong contract (backend đã code khớp từng chữ).
- KHÔNG render ảnh trang PDF (cần poppler — để đợt sau; `imageKey` gửi `null`).

---

## 3. Cấu trúc thư mục bắt buộc

```
dcid-ai/
├── app/
│   ├── __init__.py
│   ├── main.py               # FastAPI app, include routers, log cấu hình lúc start
│   ├── config.py             # pydantic-settings: đọc env (§5)
│   ├── security.py           # dependency kiểm tra X-Internal-Token → 401 nếu sai
│   ├── schemas.py            # Pydantic models — COPY từ API-CONTRACT.md §4, giữ camelCase
│   ├── api/
│   │   ├── __init__.py
│   │   ├── health.py         # GET /ai/health
│   │   ├── ingest.py         # POST /ai/ingest → 202 + BackgroundTasks
│   │   └── query.py          # POST /ai/query → mock đồng bộ
│   ├── clients/
│   │   ├── __init__.py
│   │   ├── minio_client.py   # get_object(storage_key) -> bytes
│   │   └── backend_client.py # post_ingest_callback(payload) — httpx, gắn token
│   ├── pipeline/             # Module xử lý RAG & OCR cấu trúc hóa không gian
│   │   ├── __init__.py
│   │   ├── ocr.py            # def extract_pages(pdf_bytes, langs) -> list[PageOcr] (bóc tách text & boxes Bbox [x0,y0,x1,y1] qua PyMuPDF / PaddleOCR)
│   │   ├── chunk.py          # def chunk_pages(pages) -> list[Chunk] (tính union Bbox, cấu trúc hóa Markdown: ### [Bảng/Đoạn kỹ thuật - Trang X | Bbox: ...], trích xuất snippet)
│   │   ├── embed.py          # def embed_texts(texts) -> list[list[float]] (sử dụng e5-small / sentence-transformers)
│   │   ├── index.py          # def upsert_chunks(...) / def search(...) (lưu trữ vector kèm metadata bbox, snippet vào ChromaDB collection kcn_chunks)
│   │   └── guardrails.py     # THRESHOLD=0.60; def check_numeric(question) -> bool
│   └── services/
│       ├── __init__.py
│       ├── ingest_service.py # run_ingest(req): MinIO → ocr.extract_pages → chunk.chunk_pages → index.upsert_chunks → callback BE
│       └── query_service.py  # run_query(req): index.search → guardrails → llm_client.chat_completion → trả về AnswerDTO kèm bboxKey, snippet
├── tests/
│   ├── test_health.py
│   ├── test_auth.py          # thiếu/sai token → 401
│   ├── test_ingest.py        # 202 + callback payload đúng shape (mock MinIO + httpx)
│   └── test_query.py         # schema response đúng contract (có bboxKey và snippet)
├── requirements.txt          # fastapi, uvicorn[standard], pydantic-settings, httpx, minio, pypdf, pytest, chromadb, sentence-transformers
├── Dockerfile                # python:3.11-slim, uvicorn port 8000
├── .env.example
└── README.md
```

---

## 4. Hành vi từng endpoint (khớp API-CONTRACT.md)

### 4.1. `GET /ai/health` — KHÔNG cần token
```json
{ "status": "ok", "model_loaded": false }
```
(`model_loaded` cố định `false` ở skeleton/lúc mới khởi động.)

### 4.2. `POST /ai/ingest` — cần token, trả `202` ngay
Request (contract §1.1): `versionId, documentId, storageKey, langs, metadata`.

Trả `202 {"accepted": true}` rồi chạy nền qua `BackgroundTasks`:
1. Tải `storageKey` từ MinIO (bucket từ env, mặc định `kcn-docs`).
2. Gọi `ocr.extract_pages()` để bóc tách chữ và tọa độ `boxes` (`[x0, y0, x1, y1]`).
3. Gọi `chunk.chunk_pages()` tạo các `Chunk` cấu trúc hóa Markdown kèm `bbox` và `snippet`.
4. Gọi `index.upsert_chunks()` lập chỉ mục vào ChromaDB (`kcn_chunks`).
5. POST về `{BE_BASE_URL}/api/internal/ingest-callback` (kèm token):
```json
{
  "versionId": "<uuid>",
  "status": "READY",
  "pageCount": <n>,
  "pages": [
    {
      "pageNo": 1,
      "imageKey": null,
      "width": 1190,
      "height": 1684,
      "ocrText": "### [Đoạn kỹ thuật - Trang 1 | Bbox: 100,200,450,280]\nNội dung..."
    }
  ],
  "error": null
}
```
6. Bất kỳ lỗi nào (MinIO chết, PDF hỏng, BE không phản hồi) → gửi callback `{"status": "FAILED", "error": "<mô tả>"}`.

### 4.3. `POST /ai/query` — cần token, đồng bộ
Request (contract §2.2): `question, topK, allowedVersionIds, machineCode`.

Logic thực thi pipeline & suy luận AI Model Local:
- `allowedVersionIds` rỗng **hoặc** kết quả truy vấn ChromaDB có độ tương đồng `< 0.60` (`guardrails.py`) → `locked=true`, `confidence=0.30`, `answer="Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm."`, `citations=[]`.
- Câu hỏi chứa từ khóa số liệu `điện áp|áp suất|nhiệt độ|dung sai|momen|volt|voltage` → `numericRule=true`.
- Gửi Prompt tổng hợp (chỉ thị + các chunk `snippet` kèm tọa độ `Bbox` + câu hỏi) sang AI Model Local (`LM Studio` - `deepseek-r1-distill-qwen-1.5b`) qua `llm_client.py`.
- `llm_client.py` cấu hình tối ưu `temperature=0.2`, `top_p=0.9`, đồng thời gửi `repetition_penalty=1.2` qua `extra_body` (kèm cơ chế tự động thử lại/Retry Fallback nếu model local từ chối nhận parameter này).
- Trả về danh sách `citations` với `bboxKey="p{pageNo}_[{bbox}]"` và `snippet` (đoạn nội dung gốc), giúp người dùng xem trực tiếp trên **Hộp thoại Trích Dẫn Không Gian** của Flutter App.
- Luôn kèm `latencyMs` (đo bằng `time.perf_counter`), `model="deepseek-r1-distill-qwen-1.5b"`.

---

## 5. Biến môi trường (`app/config.py` + `.env.example`)

| Env | Default | Ghi chú |
|---|---|---|
| `AI_INTERNAL_TOKEN` | `change-me-internal-token` | PHẢI trùng backend (`app.ai.internal-token`) |
| `BE_BASE_URL` | `http://localhost:8080` | trong compose: `http://backend:8080` |
| `MINIO_ENDPOINT` | `localhost:9000` | trong compose: `minio:9000`; kèm `MINIO_SECURE=false` |
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | `minioadmin`/`minioadmin` | compose dùng `minio`/`minio123` |
| `MINIO_BUCKET` | `kcn-docs` | khớp backend |
| `AI_OCR_URL` | `http://ai-ocr:8001` | Service OCR bóc tách hình ảnh chuyên dụng |
| `CHROMA_HOST` / `CHROMA_PORT` | `localhost` / `8001` | trong compose: `chroma:8000` |
| `LM_STUDIO_URL` | `http://host.docker.internal:1234/v1` | URL kết nối AI Model Local (Qwen 1.5B) |
| `LM_STUDIO_MODEL` | `deepseek-r1-distill-qwen-1.5b` | Tên model local |
| `LM_STUDIO_TEMP` / `LM_STUDIO_TOP_P` | `0.2` / `0.9` | Cấu hình nhiệt độ và độ tập trung |
| `LM_STUDIO_REP_PENALTY` | `1.2` | Hệ số chống lặp từ (gửi trong `extra_body` + retry fallback) |

---

## 6. Docker

`dcid-ai/Dockerfile`: `python:3.11-slim` → copy requirements → pip install → copy app →
`CMD uvicorn app.main:app --host 0.0.0.0 --port 8000`.

Thêm vào `docker-compose.yml` **ở repo root** (chỉ thêm block này, không sửa gì khác —
backend đã có sẵn `AI_BASE_URL: http://ai:8000`):
```yaml
    ai:
      build:
        context: ./dcid-ai
        dockerfile: Dockerfile
      container_name: dcid-ai
      environment:
        AI_INTERNAL_TOKEN: change-me-internal-token
        BE_BASE_URL: http://backend:8080
        MINIO_ENDPOINT: minio:9000
        MINIO_ACCESS_KEY: minio
        MINIO_SECRET_KEY: minio123
        MINIO_BUCKET: kcn-docs
      depends_on:
        - minio
      ports:
        - "8000:8000"
      restart: unless-stopped
```

---

## 7. Kiểm chứng & tiêu chí nghiệm thu (Definition of Done)

Chạy lần lượt, tất cả phải pass:

```bash
cd dcid-ai
pip install -r requirements.txt          # < 1 phút, không package nặng
pytest                                    # xanh 100%
uvicorn app.main:app --port 8000          # khởi động không lỗi
```

```bash
# 1. Health (không token)
curl http://localhost:8000/ai/health
# → 200 {"status":"ok","model_loaded":false}

# 2. Token guard
curl -X POST http://localhost:8000/ai/query -H "Content-Type: application/json" -d "{}"
# → 401

# 3. Query mock (token đúng)
curl -X POST http://localhost:8000/ai/query \
  -H "Content-Type: application/json" -H "X-Internal-Token: change-me-internal-token" \
  -d '{"question":"Điện áp cấp cho servo?","topK":5,"allowedVersionIds":["11111111-1111-1111-1111-111111111111"],"machineCode":null}'
# → 200, numericRule=true, đúng schema contract §2.2

# 4. Ingest (không cần BE chạy — service không được crash khi callback fail)
curl -X POST http://localhost:8000/ai/ingest \
  -H "Content-Type: application/json" -H "X-Internal-Token: change-me-internal-token" \
  -d '{"versionId":"11111111-1111-1111-1111-111111111111","documentId":"22222222-2222-2222-2222-222222222222","storageKey":"documents/x/v1/original.pdf","langs":["vi"],"metadata":{}}'
# → 202 {"accepted":true}; log hiển thị callback FAILED (MinIO không có file) — service vẫn sống
```

**E2E (nếu Docker khả dụng):** `docker-compose up -d postgres minio backend ai` → login lấy JWT
(`POST /api/auth/login`, admin/admin123) → upload PDF qua `POST /api/documents` → sau vài giây
`GET /api/documents/{id}` thấy version `status=ACTIVE` và `pageCount` đúng số trang PDF.
(Nếu môi trường không có Docker: ghi rõ trong báo cáo là bước E2E chưa chạy, không được nói đã chạy.)

**Chất lượng code:** type hints đầy đủ; không hardcode secret; field names camelCase khớp contract
từng ký tự; test không phụ thuộc mạng/MinIO thật (mock).

---

## 8. Đợt sau (KHÔNG làm bây giờ — chỉ để hiểu hướng)

Pipeline thật thay dần vào các stub: PaddleOCR (VI+EN) → chunk → `multilingual-e5-small` (ONNX)
→ ChromaDB → `LM Studio API` (`deepseek-r1-distill-qwen-1.5b`) + guardrail θ=0.60 + numeric rule.
Thiết kế chi tiết: `docs/ARCHITECTURE.md` §B2, kế hoạch: `docs/PLAN-THESIS.md`.

---

## 9. Prompt khởi động gợi ý (paste cho agent thực thi)

> Đọc kỹ `docs/PLAN-DCID-AI.md` và `docs/API-CONTRACT.md` trong repo này, rồi thực hiện đúng
> work order: dựng skeleton `dcid-ai/` (FastAPI) theo cấu trúc §3, hành vi §4, env §5, Docker §6.
> Chỉ làm mục "PHẢI làm", tuyệt đối không đụng mục "KHÔNG làm". Xong chạy toàn bộ lệnh kiểm chứng
> §7 và báo cáo kết quả từng lệnh một cách trung thực (kể cả bước nào không chạy được và vì sao).
