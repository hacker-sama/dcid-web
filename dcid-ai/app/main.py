"""FastAPI entrypoint. Chạy: uvicorn app.main:app --port 8000"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api import health, ingest, query, status
from app.config import get_settings

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
        "MINIO_BUCKET=%s | CHROMA=%s:%s | REDIS=%s | AI_INTERNAL_TOKEN=%s",
        s.be_base_url,
        s.minio_endpoint,
        s.minio_secure,
        s.minio_bucket,
        s.chroma_host,
        s.chroma_port,
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

app.include_router(health.router)
app.include_router(ingest.router)
app.include_router(query.router)
app.include_router(status.router)
