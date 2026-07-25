# Walkthrough — dcid-ai Decoupled Async Architecture

## Tổng quan

Đã hoàn thành tái cấu trúc `dcid-ai` từ FastAPI BackgroundTasks (monolith) sang kiến trúc **Celery + Redis + SSE Streaming**.

---

## Files thay đổi

### 📦 Phase 1 — Queue Infrastructure (3 files)

| File | Action | Nội dung |
|------|--------|---------|
| [requirements.txt](file:///c:/project/new/dcid-web/dcid-ai/requirements.txt) | MODIFY | Thêm `celery[redis]>=5.3`, `redis>=5.0`, `flower>=2.0` |
| [config.py](file:///c:/project/new/dcid-web/dcid-ai/app/config.py) | MODIFY | Thêm `redis_url`, `celery_task_soft_time_limit` (600s), `celery_task_time_limit` (900s) |
| [celery_app.py](file:///c:/project/new/dcid-web/dcid-ai/app/celery_app.py) | **NEW** | Celery singleton: reliability config (`task_acks_late=True`, `prefetch_multiplier=1`), routing `ingest` queue |

### 🔧 Phase 2 — Background Workers (2 files)

| File | Action | Nội dung |
|------|--------|---------|
| [workers/__init__.py](file:///c:/project/new/dcid-web/dcid-ai/app/workers/__init__.py) | **NEW** | Package marker |
| [embed_worker.py](file:///c:/project/new/dcid-web/dcid-ai/app/workers/embed_worker.py) | **NEW** | Celery Task `run_ingest_task` — thay thế `BackgroundTasks` cũ. Callback push tại mỗi bước: `PROCESSING_OCR → PROCESSING_EMBED → PROCESSING_INDEX → READY/FAILED`. Retry 3 lần với exponential backoff cho lỗi hạ tầng. Soft/Hard timeout handling. |

### 🌐 Phase 3 — API Layer (5 files)

| File | Action | Nội dung |
|------|--------|---------|
| [schemas.py](file:///c:/project/new/dcid-web/dcid-ai/app/schemas.py) | MODIFY | Thêm `IngestStatusPush` (per-step callback), `TaskStatusResponse`. Cập nhật `IngestAccepted` có `taskId` |
| [ingest.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/ingest.py) | MODIFY | Bỏ `BackgroundTasks`, dùng `run_ingest_task.delay()`. Trả `taskId` trong response |
| [status.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/status.py) | **NEW** | `GET /ai/status/{task_id}` — polling trạng thái Celery (fallback khi cần) |
| [main.py](file:///c:/project/new/dcid-web/dcid-ai/app/main.py) | MODIFY | Đăng ký `status` router, log thêm REDIS_URL khi startup |
| [backend_client.py](file:///c:/project/new/dcid-web/dcid-ai/app/clients/backend_client.py) | MODIFY | Thêm `post_ingest_status()` — gọi `POST /api/internal/ingest-status` tại mỗi bước |

### ⚡ Phase 4 — Streaming SSE (3 files)

| File | Action | Nội dung |
|------|--------|---------|
| [llm_client.py](file:///c:/project/new/dcid-web/dcid-ai/app/clients/llm_client.py) | MODIFY | Thêm `generate_answer_stream()` — generator yield từng token delta từ LM Studio (OpenAI `stream=True`) |
| [query_service.py](file:///c:/project/new/dcid-web/dcid-ai/app/services/query_service.py) | MODIFY | Thêm `run_query_stream()` — generator SSE events theo chuẩn RFC 8895. Gửi `meta` event (citations/guard) TRƯỚC khi stream text |
| [query.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/query.py) | MODIFY | Thêm `POST /ai/query/stream` → `StreamingResponse` với headers chống Nginx buffering |

### 🐳 Phase 5 — Docker Compose (1 file)

| File | Action | Nội dung |
|------|--------|---------|
| [docker-compose.yml](file:///c:/project/new/dcid-web/docker-compose.yml) | MODIFY | Thêm `redis_data` volume, expose Redis port `6379`, thêm `REDIS_URL` env cho `ai` service, thêm **`ai-worker`** container (Celery), thêm **`ai-flower`** container (monitoring UI port `5555`) |

---

## Kiến trúc mới (Luồng xử lý)

### Ingest Flow (Upload tài liệu)
```
BE  →  POST /ai/ingest  →  API Server (202 + taskId ngay)
                                │
                          run_ingest_task.delay()
                                │
                          Redis Queue (ingest queue)
                                │
                          ai-worker container
                                │
              ┌─────────────────┼──────────────────┐
              ↓                 ↓                  ↓
          OCR (HTTP)      callback push       callback push
        ai-ocr:8001    PROCESSING_EMBED    PROCESSING_INDEX
              │                 │                  │
          Chunk+Embed     ChromaDB Upsert    callback READY/FAILED
              │                                    │
              └───────────────→ BE callback ←───────┘
```

### Query Flow (Chat - hai mode)
```
Mode 1 (Sync):   POST /ai/query  →  JSON response (đợi LLM xong)
Mode 2 (Stream): POST /ai/query/stream  →  SSE stream:
                    event: meta   ← citations + confidence + guard (ngay lập tức)
                    event: delta  ← từng token text từ LLM
                    event: delta  ← ...
                    event: done   ← latencyMs + model name
```

---

## API mới / thay đổi

| Endpoint | Method | Thay đổi |
|----------|--------|---------|
| `POST /ai/ingest` | POST | Response nay có thêm `taskId` |
| `GET /ai/status/{taskId}` | GET | **Endpoint mới** — polling Celery state |
| `POST /ai/query/stream` | POST | **Endpoint mới** — SSE streaming chat |

---

## SSE Event Protocol cho `/ai/query/stream`

```
# 1. Meta event đến ngay khi ChromaDB search xong
data: {"event":"meta","citations":[...],"confidence":0.87,"guard":{"locked":false,...}}

# 2. Delta events đến dần dần từ LLM
data: {"event":"delta","text":"Áp suất làm việc"}
data: {"event":"delta","text":" tối đa của van là"}
data: {"event":"delta","text":" 10 bar."}

# 3. Done event khi hoàn tất
data: {"event":"done","latencyMs":3420,"model":"deepseek-r1-distill-qwen-1.5b"}

# Nếu lỗi:
data: {"event":"error","message":"LM Studio chưa chạy..."}
data: {"event":"done","latencyMs":120,"model":"error-llm-connection"}
```

---

## Lưu ý Deploy

### Cài packages mới trong venv
```bash
cd dcid-ai
pip install celery[redis]>=5.3 redis>=5.0 flower>=2.0
```

### Docker Compose (rebuild image)
```bash
docker compose build ai ai-worker ai-flower
docker compose up -d
```

### Kiểm tra Celery Worker hoạt động
```bash
# Xem logs worker
docker compose logs -f ai-worker

# Flower monitoring UI
# Mở browser: http://localhost:5555
```

### Test SSE stream bằng cURL
```bash
curl -N -X POST http://localhost:8000/ai/query/stream \
  -H "Content-Type: application/json" \
  -H "X-Internal-Token: change-me-internal-token" \
  -d '{
    "question": "Áp suất làm việc tối đa của van là bao nhiêu?",
    "allowedVersionIds": ["<uuid>"],
    "topK": 5
  }'
```

---

## ⚠️ Việc cần làm ở Backend Java

Backend team cần implement endpoint mới để nhận callback push từ AI worker:

```
POST /api/internal/ingest-status
Body: {
  "versionId": "uuid",
  "status": "PROCESSING_OCR" | "PROCESSING_EMBED" | "PROCESSING_INDEX" | "READY" | "FAILED",
  "step": "OCR" | "EMBED" | "INDEX" | ...,
  "pageCount": 45,      // available khi status >= PROCESSING_EMBED
  "chunkCount": 123,    // available khi status = PROCESSING_INDEX
  "error": null | "message"
}
```

Backend dùng `versionId` để update trạng thái document version trong DB → Flutter App hiển thị progress bar realtime.
