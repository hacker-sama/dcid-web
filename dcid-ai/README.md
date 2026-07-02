# dcid-ai — AI plane (skeleton)

FastAPI service cho **Smart KCN Docs**. Đợt này là **skeleton**: đúng contract
[`docs/API-CONTRACT.md`](../docs/API-CONTRACT.md), pipeline là **mock** — OCR/embedding/LLM thật
sẽ thay vào các stub trong `app/pipeline/` (đợt sau).

## Chạy local (Windows, Python 3.11+)

```bash
cd dcid-ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --port 8000
```

Swagger UI: http://localhost:8000/docs

## Test

```bash
pytest
```

Test không cần mạng/MinIO/backend thật (mock toàn bộ I/O).

## Biến môi trường

| Env | Default | Ghi chú |
|---|---|---|
| `AI_INTERNAL_TOKEN` | `change-me-internal-token` | PHẢI trùng backend (`app.ai.internal-token`) |
| `BE_BASE_URL` | `http://localhost:8080` | trong compose: `http://backend:8080` |
| `MINIO_ENDPOINT` | `localhost:9000` | trong compose: `minio:9000` |
| `MINIO_ACCESS_KEY` | `minioadmin` | compose: `minio` |
| `MINIO_SECRET_KEY` | `minioadmin` | compose: `minio123` |
| `MINIO_BUCKET` | `kcn-docs` | khớp backend |
| `MINIO_SECURE` | `false` | `true` nếu MinIO chạy TLS |

## Endpoints (contract v1)

| Endpoint | Token? | Hành vi skeleton |
|---|---|---|
| `GET /ai/health` | Không | `{"status":"ok","model_loaded":false}` |
| `POST /ai/ingest` | Có | `202` ngay → nền: tải PDF từ MinIO, đếm trang bằng `pypdf`, POST callback `READY`/`FAILED` về `{BE_BASE_URL}/api/internal/ingest-callback` |
| `POST /ai/query` | Có | Mock deterministic: guardrail lock / numeric rule / mock answer (xem `app/api/query.py`) |

Token = header `X-Internal-Token`, sai/thiếu → `401`. Callback về BE cũng gắn header này.

## Thử nhanh bằng curl

```bash
curl http://localhost:8000/ai/health

curl -X POST http://localhost:8000/ai/query ^
  -H "Content-Type: application/json" -H "X-Internal-Token: change-me-internal-token" ^
  -d "{\"question\":\"Điện áp cấp cho servo?\",\"topK\":5,\"allowedVersionIds\":[\"11111111-1111-1111-1111-111111111111\"],\"machineCode\":null}"
```

## Docker

```bash
# từ repo root — service `ai` đã khai báo trong docker-compose.yml
docker-compose up -d minio backend ai
```

## Cấu trúc

```
app/
├── main.py            # FastAPI app + log cấu hình lúc start
├── config.py          # pydantic-settings
├── security.py        # X-Internal-Token guard
├── schemas.py         # Pydantic models (camelCase, khớp contract §4)
├── api/               # health / ingest / query routers
├── clients/           # minio_client, backend_client (callback)
├── services/          # ingest_service (mock: pypdf đếm trang)
└── pipeline/          # STUB đợt sau: ocr, chunk, embed, index, guardrails
```

## Đợt sau (không làm ở skeleton)

PaddleOCR (VI+EN) → chunk → multilingual-e5-small (ONNX) → ChromaDB →
llama-cpp-python (Qwen2.5-1.5B Q4_K_M) + guardrail θ=0.60 + numeric rule.
Chi tiết: `docs/ARCHITECTURE.md` §B2, `docs/PLAN-THESIS.md`.
