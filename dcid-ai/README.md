# dcid-ai — AI plane

FastAPI service cho **Smart KCN Docs**. Đúng contract [`docs/API-CONTRACT.md`](../docs/API-CONTRACT.md).
**Kiến trúc mô-đun hóa `src/` mới nhất** tích hợp RAG Đa phương thức (Multimodal Vision LLM - Qwen2-VL 2B) + ChromaDB Persistent Vector DB + Celery/Redis Workers + SSE Streaming.

## Chạy local (Windows, Python 3.11+)

```bash
cd dcid-ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Swagger UI: http://localhost:8000/docs

## Test

```bash
.venv\Scripts\python -m unittest discover -s tests
```

## Endpoints

| Endpoint | Token? | Hành vi |
|---|---|---|
| `GET /api/health` / `GET /ai/health` | Không | Health check service status & vector DB |
| `POST /api/ingest` / `POST /ai/ingest` | Có | `202` async ingestion (PyMuPDF, PaddleOCR, Visual Bbox Crop, Qwen2-VL 2B, ChromaDB vector store) |
| `POST /api/query` / `POST /ai/query` | Có | Truy vấn RAG + Guardrails + LM Studio LLM RAG inference |
| `POST /api/query/stream` / `POST /ai/query/stream` | Có | Streaming Response SSE trả từng token theo thời gian thực |
| `DELETE /api/documents/{document_id}` / `DELETE /ai/documents/{document_id}` | Có | Xóa toàn bộ vector chunks trong ChromaDB và dọn dẹp các file ảnh crop `uploads/crops/` |

## Cấu trúc Dự án

```
dcid-ai/
├── config.yaml          # Centralized configuration (models, paths, chromadb, chunking)
├── main.py              # FastAPI main entrypoint (port 8000)
├── requirements.txt     # Python dependencies
├── uploads/             # Static file uploads & cropped image regions (/uploads/crops/)
├── chroma_db/           # ChromaDB Persistent Local Database
├── src/                 # Modular AI Pipeline architecture
│   ├── api/             # REST API routes (/api/*) & Pydantic schemas
│   ├── chunking/        # Layout-aware Chunker with image_path metadata
│   ├── embeddings/      # SentenceTransformer (multilingual-e5-small)
│   ├── ingestion/       # PDF loader, PyMuPDF, PaddleOCR, Visual Bbox Crop & Pure-Text Vision Skip
│   ├── llm/             # OpenAI-compatible client wrapper (Qwen2-VL 2B / Main Text LLM)
│   ├── prompts/         # Task-tuned prompts for Qwen2-VL 2B & RAG System Prompts
│   ├── retrieval/       # Semantic retriever & citation builder
│   ├── utils/           # Image crop, base64 conversion & helper utilities
│   └── vectordb/        # ChromaDB Persistent Client & CRUD operations
└── tests/               # Automated unit & integration test suite
```

