"""FastAPI entrypoint. Chạy: uvicorn app.main:app --port 8000"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api import health, ingest, query, status
from app.config import get_settings
from src.api.routes import router as new_api_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("dcid-ai")


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    """Log cấu hình lúc start (không log secret)."""
    s = get_settings()
    logger.info(
        "dcid-ai started | BE_BASE_URL=%s | MINIO_ENDPOINT=%s (secure=%s) | "
        "MINIO_BUCKET=%s | QDRANT=%s:%s | REDIS=%s | AI_INTERNAL_TOKEN=%s",
        s.be_base_url,
        s.minio_endpoint,
        s.minio_secure,
        s.minio_bucket,
        s.qdrant_host,
        s.qdrant_port,
        s.redis_url,
        "<set>" if s.ai_internal_token else "<EMPTY!>",
    )
    yield


app = FastAPI(
    title="dcid-ai",
    description="AI plane cho Smart KCN Docs — Decoupled Async Architecture (Celery + Redis). Contract: docs/API-CONTRACT.md",
    version="0.2.0",
    lifespan=lifespan,
)

# CORS Middleware cho phép Frontend UI kết nối
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount thư mục /uploads để Frontend UI truy cập trực tiếp file ảnh crop (image_path)
uploads_dir = Path("./uploads")
crops_dir = Path("./uploads/crops")
uploads_dir.mkdir(parents=True, exist_ok=True)
crops_dir.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(uploads_dir)), name="uploads")

# Include cả router cũ (app.api) và router mới (src.api)
app.include_router(health.router)
app.include_router(ingest.router)
app.include_router(query.router)
app.include_router(status.router)
app.include_router(new_api_router)
