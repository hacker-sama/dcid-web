"""Entrypoint chính chạy Server FastAPI cho DCID AI Service."""

import logging
from pathlib import Path

import uvicorn
import yaml
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from src.api.routes import router as api_router

# Setup Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("dcid-ai.main")

# Load Config
config_path = Path("config.yaml")
if config_path.exists():
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
else:
    cfg = {}

app_cfg = cfg.get("app", {})
paths_cfg = cfg.get("paths", {})

app = FastAPI(
    title=app_cfg.get("name", "DCID AI Service"),
    version=app_cfg.get("version", "1.0.0"),
    description="DCID AI RAG & Vision-Language Processing Service with Qwen2-VL-2B & ChromaDB",
)

# Thêm CORS middleware cho phép Frontend kết nối
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Đăng ký REST API router
app.include_router(api_router)

# Mount thư mục /uploads để Frontend UI truy cập trực tiếp file ảnh crop (image_path)
uploads_dir = Path(paths_cfg.get("uploads_dir", "./uploads"))
crops_dir = Path(paths_cfg.get("crops_dir", "./uploads/crops"))
uploads_dir.mkdir(parents=True, exist_ok=True)
crops_dir.mkdir(parents=True, exist_ok=True)

app.mount("/uploads", StaticFiles(directory=str(uploads_dir)), name="uploads")


@app.get("/")
def root():
    return {
        "service": app_cfg.get("name", "DCID AI Service"),
        "status": "running",
        "docs_url": "/docs",
        "health_url": "/api/health",
    }


if __name__ == "__main__":
    host = app_cfg.get("host", "0.0.0.0")
    port = app_cfg.get("port", 8000)
    logger.info("Khoi chay DCID AI FastAPI Server tai http://%s:%d", host, port)
    uvicorn.run("main:app", host=host, port=port, reload=True)
