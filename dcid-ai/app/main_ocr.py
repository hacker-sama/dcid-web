"""FastAPI entrypoint cho service ai-ocr (chuyên chạy PaddleOCR/PyMuPDF).
Chạy: uvicorn app.main_ocr:app --host 0.0.0.0 --port 8001
"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import APIRouter, Depends, FastAPI
from pydantic import BaseModel

from app.clients import minio_client
from app.config import get_settings
from app.pipeline import ocr
from app.security import require_internal_token

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("dcid-ai-ocr")


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    s = get_settings()
    logger.info(
        "dcid-ai-ocr started | MINIO_ENDPOINT=%s | MINIO_BUCKET=%s",
        s.minio_endpoint,
        s.minio_bucket,
    )
    try:
        logger.info("Preloading PaddleOCR models at startup...")
        # The Vietnamese recognizer also covers Latin/English technical labels.
        # Other languages remain lazy-loaded to keep the sidecar memory bounded.
        ocr._get_engine("vi")
        logger.info("PaddleOCR Vietnamese/Latin model preloaded OK.")
    except Exception as e:
        logger.error("Failed to preload PaddleOCR: %s", e)
    yield


app = FastAPI(
    title="dcid-ai-ocr",
    description="Dedicated OCR worker service for DCID.",
    version="0.1.0",
    lifespan=lifespan,
)

router = APIRouter(tags=["ocr"], dependencies=[Depends(require_internal_token)])


class OcrRequest(BaseModel):
    storageKey: str
    langs: list[str] = ["vi", "en"]
    imageKeyPrefix: str | None = None


class PageOcrDto(BaseModel):
    pageNo: int
    text: str
    width: int | None = None
    height: int | None = None
    boxes: list[tuple[float, float, float, float]] = []
    imageKey: str | None = None


class OcrResponse(BaseModel):
    pages: list[PageOcrDto]
    pageCount: int


@router.post("/ocr", response_model=OcrResponse)
def run_ocr(req: OcrRequest) -> OcrResponse:
    logger.info("Nhận job OCR: storageKey=%s langs=%s", req.storageKey, req.langs)
    pdf_bytes = minio_client.get_object(req.storageKey)
    pages = ocr.extract_pages(pdf_bytes, req.langs)
    dtos: list[PageOcrDto] = []
    for page in pages:
        image_key = None
        if req.imageKeyPrefix and page.image_bytes:
            image_key = f"{req.imageKeyPrefix.rstrip('/')}/{page.page_no}.png"
            minio_client.put_object(image_key, page.image_bytes, content_type="image/png")
        dtos.append(
            PageOcrDto(
                pageNo=page.page_no,
                text=page.text,
                width=page.width,
                height=page.height,
                boxes=page.boxes,
                imageKey=image_key,
            )
        )
    logger.info("Hoàn thành OCR: %d trang", len(dtos))
    return OcrResponse(pages=dtos, pageCount=len(dtos))


@app.get("/ai/health")
def health() -> dict:
    return {"status": "ok", "service": "ai-ocr"}


app.include_router(router)
