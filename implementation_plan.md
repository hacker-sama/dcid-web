# Kế hoạch Tái cấu trúc dcid-ai: Monolith → Decoupled Async Architecture

## Phân tích Hiện trạng

Sau khi đọc toàn bộ codebase, tôi ghi nhận các điểm quan trọng **khác so với kỳ vọng ban đầu**:

| Thành phần | Hiện trạng thực tế |
|---|---|
| **OCR** | **Đã tách** thành microservice riêng (`ai-ocr` container, `Dockerfile.ocr`, port 8001). `ingest_service.py` gọi OCR qua HTTP client (`ocr_client.py`). |
| **Embed** | **Vẫn nằm trong** `ai` container chính (`app/pipeline/embed.py`), chạy đồng bộ trong `BackgroundTasks`. |
| **Redis** | **Đã có sẵn** trong `docker-compose.yml` (`redis:7`, service `dcid-redis`), **nhưng chưa dùng cho AI pipeline**. Backend Java (Spring) dùng Redis, AI không dùng. |
| **Background Tasks** | Đang dùng **FastAPI `BackgroundTasks`** — giải pháp đơn giản, không có retry, không có persistence, mất task khi restart. |
| **Ingest Flow** | `POST /ai/ingest` → 202 ngay → `BackgroundTasks(run_ingest)` → OCR (HTTP) → chunk → embed → upsert Chroma → callback BE. |
| **Query Flow** | `POST /ai/query` → embed query → search Chroma → guardrail → LLM → response. (**Đồng bộ, không có streaming**). |

> [!IMPORTANT]
> **Phát hiện quan trọng:** Kiến trúc hiện tại **đã có nền tảng tốt** (OCR tách riêng, 202 accepted). Vấn đề chính là:
> 1. `BackgroundTasks` của FastAPI không có persistence/retry — restart container là mất job.
> 2. Embed model (470MB RAM) nạp trong cùng process với API server — chiếm memory, khởi động chậm.
> 3. Không có cơ chế theo dõi tiến độ job (`/status/{task_id}`).
> 4. Query chưa có Streaming SSE — user phải đợi LLM sinh xong mới nhận được gì.

---

## User Review Required

> [!WARNING]
> **Quyết định kiến trúc: Celery vs RQ**
> - **Celery** (đề xuất): Phổ biến hơn, hỗ trợ retry nâng cao, monitoring (Flower UI), routing task theo queue riêng. Phức tạp hơn một chút.
> - **RQ (Redis Queue)**: Nhẹ hơn, ít cấu hình hơn, phù hợp với quy mô nhỏ/vừa. Đơn giản hơn để debug.
>
> **Đề xuất của tôi: dùng Celery** vì hệ thống đã có Kafka (chứng tỏ thiên về kiến trúc event-driven quy mô lớn), và Celery tích hợp tốt với Redis có sẵn.

> [!CAUTION]
> **Breaking Change:** Sau khi refactor, API `/ai/ingest` sẽ trả về thêm `task_id` trong response body. Backend Java (`DocumentService.java`) cần lưu `task_id` này để polling `/ai/status/{task_id}`. Cần phối hợp với team Backend.

---

## Open Questions

> [!IMPORTANT]
> **Q1:** Bạn muốn **Backend Java chủ động polling** `/ai/status/{task_id}` hay muốn **AI tự callback** về BE mỗi khi trạng thái thay đổi (PROCESSING_OCR → PROCESSING_EMBED → READY)?
> - **Polling**: Đơn giản hơn phía AI, Backend chủ động.
> - **Callback Push**: AI chủ động push trạng thái → tốt hơn cho UX realtime, nhưng cần thêm endpoint ở Backend.
>
> **Kế hoạch hiện tại giả định: hỗ trợ cả 2** (cung cấp endpoint polling + callback tùy chọn).

> [!IMPORTANT]
> **Q2:** Streaming SSE cho Query có cần implement ngay không? LLM (LM Studio) hỗ trợ `stream=True` trong OpenAI SDK. Nếu bật, trải nghiệm chat sẽ giống ChatGPT (chữ hiện ra từng từ). Backend và Flutter App cần support SSE để nhận.

---

## Proposed Changes

### Tổng quan Kiến trúc Mới

```
POST /ai/ingest
    │
    ▼  (202 ngay + task_id)
FastAPI API Server  ──push──▶  Redis Queue (Celery Broker)
                                     │
              ┌──────────────────────┤
              │                      │
    ┌─────────▼──────────┐  ┌───────▼───────────┐
    │   embed_worker     │  │  (ocr đã tách sẵn) │
    │ (Celery Worker)    │  │  ai-ocr container  │
    │ - chunk_pages()    │  └───────────────────-┘
    │ - embed_texts()    │
    │ - upsert_chroma()  │
    │ - callback BE      │
    └────────────────────┘

POST /ai/query  →  (sync + optional SSE streaming)
GET /ai/status/{task_id}  →  Celery task state from Redis
```

---

### Phase 1 — Hạ tầng Queue (Celery + Redis)

#### [MODIFY] [requirements.txt](file:///c:/project/new/dcid-web/dcid-ai/requirements.txt)
Thêm các dependency:
```
celery[redis]>=5.3,<6.0
redis>=5.0,<6.0
flower>=2.0,<3.0     # optional: Celery monitoring UI
```

#### [MODIFY] [config.py](file:///c:/project/new/dcid-web/dcid-ai/app/config.py)
Thêm settings cho Celery/Redis:
```python
# Redis / Celery broker (service `redis` trong docker-compose)
redis_url: str = "redis://redis:6379/0"
celery_task_soft_time_limit: int = 600   # 10 phút (1 PDF lớn)
celery_task_time_limit: int = 900        # 15 phút hard limit
```

#### [NEW] [celery_app.py](file:///c:/project/new/dcid-web/dcid-ai/app/celery_app.py)
File khởi tạo Celery singleton — tách riêng để tránh circular import:
```python
# app/celery_app.py
from celery import Celery
from app.config import get_settings

def make_celery() -> Celery:
    s = get_settings()
    app = Celery(
        "dcid-ai",
        broker=s.redis_url,
        backend=s.redis_url,
        include=["app.workers.embed_worker"],
    )
    app.conf.update(
        task_serializer="json",
        result_serializer="json",
        task_soft_time_limit=s.celery_task_soft_time_limit,
        task_time_limit=s.celery_task_time_limit,
        task_acks_late=True,      # chỉ ack khi task hoàn thành — tránh mất job
        worker_prefetch_multiplier=1,  # xử lý 1 task/worker — tránh OOM với embed model
    )
    return app

celery_app = make_celery()
```

---

### Phase 2 — Background Workers

#### [NEW] `app/workers/` directory

#### [NEW] [embed_worker.py](file:///c:/project/new/dcid-web/dcid-ai/app/workers/embed_worker.py)
Celery Task thay thế `ingest_service.run_ingest()`. Nhận serializable args (UUID strings, không phải Pydantic object):

```python
# app/workers/embed_worker.py
import logging
from app.celery_app import celery_app
from app.pipeline import chunk as chunk_pipeline
from app.pipeline import embed as embed_pipeline
from app.pipeline import index as index_pipeline
from app.clients import ocr_client, backend_client
from app.schemas import IngestCallback, IngestRequest, PageInfo
from uuid import UUID

logger = logging.getLogger("dcid-ai.workers.embed")

@celery_app.task(
    bind=True,
    name="dcid_ai.tasks.run_ingest",
    max_retries=3,
    default_retry_delay=60,   # retry sau 60s nếu lỗi tạm thời
    autoretry_for=(Exception,),
    retry_backoff=True,
)
def run_ingest_task(
    self,
    version_id: str,
    document_id: str,
    storage_key: str,
    langs: list[str],
    metadata: dict,
) -> dict:
    """Celery Task thay thế BackgroundTasks: OCR → Chunk → Embed → Upsert → Callback."""
    # Cập nhật state để /status có thể theo dõi
    self.update_state(state="PROCESSING_OCR", meta={"step": "OCR"})
    page_results = ocr_client.extract_pages(storage_key, langs)

    self.update_state(state="PROCESSING_EMBED", meta={"step": "Embed", "pages": len(page_results)})
    chunks = chunk_pipeline.chunk_pages(page_results)
    texts = [c.text for c in chunks]
    embeddings = embed_pipeline.embed_texts(texts)

    self.update_state(state="PROCESSING_INDEX", meta={"step": "Upsert ChromaDB"})
    index_pipeline.upsert_chunks(
        version_id=UUID(version_id),
        document_id=UUID(document_id),
        chunks=chunks,
        embeddings=embeddings,
        metadata=metadata,
    )

    # Callback về BE
    callback = IngestCallback(
        versionId=UUID(version_id),
        status="READY",
        pageCount=len(page_results),
        pages=[PageInfo(pageNo=p.page_no, width=p.width, height=p.height, ocrText=p.text) for p in page_results],
    )
    backend_client.post_ingest_callback(callback)

    return {"status": "READY", "pages": len(page_results), "chunks": len(chunks)}
```

#### [NEW] [__init__.py](file:///c:/project/new/dcid-web/dcid-ai/app/workers/__init__.py)
File trống để make it a package.

---

### Phase 3 — Cập nhật API Layer

#### [MODIFY] [ingest.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/ingest.py)
Thay `BackgroundTasks` bằng Celery `.delay()`. Trả về `task_id`:
```python
@router.post("/ingest", response_model=IngestAccepted, status_code=202)
def ingest(req: IngestRequest) -> IngestAccepted:
    task = run_ingest_task.delay(
        version_id=str(req.versionId),
        document_id=str(req.documentId),
        storage_key=req.storageKey,
        langs=req.langs,
        metadata=req.metadata,
    )
    return IngestAccepted(accepted=True, taskId=task.id)
```

#### [MODIFY] [schemas.py](file:///c:/project/new/dcid-web/dcid-ai/app/schemas.py)
Cập nhật `IngestAccepted` thêm `taskId`:
```python
class IngestAccepted(BaseModel):
    accepted: bool = True
    taskId: str | None = None   # Celery task ID — dùng cho /ai/status/{taskId}
```

#### [NEW] [status.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/status.py)
Endpoint mới để polling tiến độ:
```python
# GET /ai/status/{task_id}
@router.get("/status/{task_id}")
def get_task_status(task_id: str):
    from celery.result import AsyncResult
    result = AsyncResult(task_id)
    return {
        "taskId": task_id,
        "state": result.state,   # PENDING | PROCESSING_OCR | PROCESSING_EMBED | SUCCESS | FAILURE
        "info": result.info if isinstance(result.info, dict) else str(result.info),
    }
```

#### [MODIFY] [main.py](file:///c:/project/new/dcid-web/dcid-ai/app/main.py)
Đăng ký router mới `status`:
```python
from app.api import health, ingest, query, status
app.include_router(status.router)
```

---

### Phase 4 — Query Streaming (Optional nhưng Recommended)

#### [MODIFY] [query.py](file:///c:/project/new/dcid-web/dcid-ai/app/api/query.py)
Thêm endpoint `/ai/query/stream` với `StreamingResponse` (SSE):
```python
from fastapi.responses import StreamingResponse

@router.post("/query/stream")
def query_stream(req: QueryRequest):
    """Streaming variant — trả về Server-Sent Events, chữ hiện từng từ."""
    return StreamingResponse(
        query_service.run_query_stream(req),
        media_type="text/event-stream",
    )
```

#### [MODIFY] [llm_client.py](file:///c:/project/new/dcid-web/dcid-ai/app/clients/llm_client.py)
Thêm hàm `generate_answer_stream()` dùng `stream=True` trong OpenAI SDK:
```python
def generate_answer_stream(system_prompt: str, user_prompt: str):
    """Generator: yield từng token text khi LM Studio stream về."""
    client = _get_client()
    s = get_settings()
    with client.chat.completions.stream(
        model=s.lm_studio_model,
        messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": user_prompt}],
        temperature=s.llm_temperature,
        max_tokens=s.llm_max_tokens,
    ) as stream:
        for event in stream:
            delta = event.choices[0].delta.content or ""
            if delta:
                yield delta
```

---

### Phase 5 — Docker Compose Update

#### [MODIFY] [docker-compose.yml](file:///c:/project/new/dcid-web/docker-compose.yml)

Thêm service `ai-worker` (Celery Worker) và expose Redis port ra host (để dev debug):

```yaml
# Thêm vào volumes:
redis_data: {}   # persist Celery results

# Cập nhật redis service:
redis:
  image: redis:7
  container_name: dcid-redis
  command: ["redis-server", "--save", "900 1", "--loglevel", "warning"]
  volumes:
    - redis_data:/data
  ports:
    - "6379:6379"    # thêm dòng này để dev local kết nối debug
  restart: unless-stopped

# Thêm service mới:
ai-worker:
  build:
    context: ./dcid-ai
    dockerfile: Dockerfile
  container_name: dcid-ai-worker
  command: ["celery", "-A", "app.celery_app.celery_app", "worker", "--loglevel=info", "--concurrency=2"]
  environment:
    AI_INTERNAL_TOKEN: change-me-internal-token
    BE_BASE_URL: http://backend:8080
    OCR_SERVICE_URL: http://ai-ocr:8001
    REDIS_URL: redis://redis:6379/0
    MINIO_ENDPOINT: minio:9000
    MINIO_ACCESS_KEY: minio
    MINIO_SECRET_KEY: minio123
    MINIO_BUCKET: kcn-docs
    CHROMA_HOST: chroma
    CHROMA_PORT: 8000
  depends_on:
    - redis
    - minio
    - chroma
    - ai-ocr
  restart: unless-stopped

# Optional: Flower monitoring UI
ai-flower:
  build:
    context: ./dcid-ai
    dockerfile: Dockerfile
  container_name: dcid-ai-flower
  command: ["celery", "-A", "app.celery_app.celery_app", "flower", "--port=5555"]
  environment:
    REDIS_URL: redis://redis:6379/0
  ports:
    - "5555:5555"
  depends_on:
    - redis
  restart: unless-stopped
```

#### [MODIFY] `ai` service trong [docker-compose.yml](file:///c:/project/new/dcid-web/docker-compose.yml)
Thêm `REDIS_URL` env và `depends_on: redis` cho service `ai`:
```yaml
ai:
  environment:
    ...
    REDIS_URL: redis://redis:6379/0   # thêm dòng này
  depends_on:
    - minio
    - chroma
    - ai-ocr
    - redis    # thêm redis dependency
```

---

## Tóm tắt File Changes

| Action | File | Mô tả |
|--------|------|--------|
| MODIFY | `requirements.txt` | Thêm `celery[redis]`, `redis`, `flower` |
| MODIFY | `app/config.py` | Thêm `redis_url`, `celery_task_*_time_limit` |
| **NEW** | `app/celery_app.py` | Khởi tạo Celery singleton |
| **NEW** | `app/workers/__init__.py` | Package marker |
| **NEW** | `app/workers/embed_worker.py` | Celery Task thay thế BackgroundTasks |
| MODIFY | `app/api/ingest.py` | Dùng Celery `.delay()`, bỏ `BackgroundTasks` |
| **NEW** | `app/api/status.py` | `GET /ai/status/{task_id}` endpoint |
| MODIFY | `app/schemas.py` | Thêm `taskId` vào `IngestAccepted` |
| MODIFY | `app/main.py` | Đăng ký `status` router |
| MODIFY | `app/api/query.py` | Thêm `/query/stream` endpoint (SSE) |
| MODIFY | `app/clients/llm_client.py` | Thêm `generate_answer_stream()` |
| MODIFY | `docker-compose.yml` | Thêm `ai-worker`, `ai-flower` services, `redis` port, `redis_data` volume |

**Tổng: 5 file mới, 7 file sửa đổi**. File pipeline hiện có (`ocr.py`, `embed.py`, `index.py`, `chunk.py`) **giữ nguyên hoàn toàn** — worker chỉ gọi vào chúng.

---

## Verification Plan

### Automated Tests
```bash
# Test Celery task dispatch (unit test với mock)
pytest dcid-ai/tests/test_ingest_task.py -v

# Test status endpoint
pytest dcid-ai/tests/test_status_api.py -v

# Smoke test toàn bộ pipeline
python scripts/smoke_test_t2.py
```

### Manual Verification
1. Khởi động stack: `docker compose up -d`
2. Upload tài liệu PDF → kiểm tra response có `taskId`.
3. Polling `GET /ai/status/{taskId}` → trạng thái chuyển: `PENDING → PROCESSING_OCR → PROCESSING_EMBED → SUCCESS`.
4. Mở Flower UI tại `http://localhost:5555` → quan sát task queue trực quan.
5. Thử tắt `ai-worker` giữa chừng → restart → task tiếp tục (không mất — do `task_acks_late=True`).
6. Test `/ai/query/stream` qua cURL: `curl -N -X POST http://localhost:8000/ai/query/stream ...` → chữ hiện ra từng từ.
