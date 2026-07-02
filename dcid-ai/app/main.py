"""FastAPI entrypoint. Chạy: uvicorn app.main:app --port 8000"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api import health, ingest, query
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
        "dcid-ai skeleton started | BE_BASE_URL=%s | MINIO_ENDPOINT=%s (secure=%s) | "
        "MINIO_BUCKET=%s | AI_INTERNAL_TOKEN=%s",
        s.be_base_url,
        s.minio_endpoint,
        s.minio_secure,
        s.minio_bucket,
        "<set>" if s.ai_internal_token else "<EMPTY!>",
    )
    yield


app = FastAPI(
    title="dcid-ai",
    description="AI plane cho Smart KCN Docs — skeleton (mock pipeline). Contract: docs/API-CONTRACT.md",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(ingest.router)
app.include_router(query.router)
