# dcid-ai — AI plane

FastAPI service cho **Smart KCN Docs**. Đúng contract [`docs/API-CONTRACT.md`](../docs/API-CONTRACT.md).
**OCR đã thật** (PaddleOCR + PyMuPDF, xem `app/pipeline/ocr.py`); embedding/index/LLM/guardrail
vẫn là **mock** — sẽ thay vào các stub còn lại trong `app/pipeline/` (đợt sau).

> **Kết quả spike OCR (chi tiết: `docs/PLAN-THESIS.md` mục T1):** tiếng Anh CER 0% (100% chính
> xác, kể cả số liệu kỹ thuật). Tiếng Việt CER ~10% (89.6%) — PaddleOCR gộp `lang="vi"` vào model
> dùng chung ~50 ngôn ngữ Latin, mất chủ yếu nguyên âm có 2 dấu chồng (ậ, ệ, ộ...). Dưới KPI 95%
> của dự án nhưng đủ dùng cho retrieval; TODO(E1/E2): thử hybrid với VietOCR hoặc model lớn hơn.

## Chạy local (Windows, Python 3.11+)

```bash
cd dcid-ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --port 8000
```

> **Lần đầu cài:** `paddlepaddle`/`paddleocr` khá nặng (~300-500MB tải về) và
> `requirements.txt` có dòng `--extra-index-url` riêng cho bản CPU của PaddlePaddle —
> `pip install -r requirements.txt` tự xử lý, không cần làm gì thêm. **Lần đầu chạy ingest**
> (không phải lúc `pip install`), PaddleOCR tự tải thêm model nhận diện (~150MB) từ CDN PaddleX
> vào `~/.paddlex/official_models` — cần mạng, mất khoảng 15-30s, các lần sau dùng cache.

Swagger UI: http://localhost:8000/docs

## Test

```bash
pytest
```

Test không cần mạng/MinIO/backend thật — kể cả OCR cũng được mock trong unit test
(`ingest_service.ocr.extract_pages` bị monkeypatch; model PaddleOCR thật quá nặng cho test suite
nhanh, chỉ chạy qua kiểm chứng E2E thủ công).

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

| Endpoint | Token? | Hành vi |
|---|---|---|
| `GET /ai/health` | Không | `{"status":"ok","model_loaded":false}` |
| `POST /ai/ingest` | Có | `202` ngay → nền: tải PDF từ MinIO (`app/clients/minio_client.py`), rasterize từng trang (PyMuPDF) + OCR thật (PaddleOCR, `app/pipeline/ocr.py`), POST callback `READY`/`FAILED` kèm `ocrText` từng trang về `{BE_BASE_URL}/api/internal/ingest-callback` |
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
├── services/          # ingest_service (OCR thật, xem app/pipeline/ocr.py)
└── pipeline/
    ├── ocr.py         # THẬT: PyMuPDF rasterize + PaddleOCR (enable_mkldnn=False — xem docstring)
    └── chunk.py, embed.py, index.py, guardrails.py   # STUB đợt sau
```

## Đợt sau (chưa làm)

chunk → multilingual-e5-small (ONNX) → ChromaDB → llama-cpp-python (Qwen2.5-1.5B Q4_K_M) +
guardrail θ=0.60 + numeric rule. Riêng OCR: cân nhắc hybrid PaddleOCR + VietOCR để cải thiện
độ chính xác tiếng Việt (xem ghi chú CER ở đầu file này).
Chi tiết: `docs/ARCHITECTURE.md` §B2, `docs/PLAN-THESIS.md`.
