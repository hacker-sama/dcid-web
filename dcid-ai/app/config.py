"""Cấu hình đọc từ biến môi trường (pydantic-settings).

Xem bảng env trong docs/PLAN-DCID-AI.md §5 và dcid-ai/.env.example.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Env-driven settings. Tên biến env viết HOA trùng tên field."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    ai_internal_token: str = "change-me-internal-token"
    be_base_url: str = "http://localhost:8080"
    ocr_service_url: str = "http://ai-ocr:8001"

    minio_endpoint: str = "localhost:9000"
    # Khớp docker-compose.yml (service minio: MINIO_ROOT_USER=minio / MINIO_ROOT_PASSWORD=minio123),
    # không phải "minioadmin" mặc định của image MinIO.
    minio_access_key: str = "minio"
    minio_secret_key: str = "minio123"
    minio_bucket: str = "kcn-docs"
    minio_secure: bool = False

    # ChromaDB — service `chroma` trong docker-compose.yml (port nội bộ 8000)
    chroma_host: str = "localhost"
    chroma_port: int = 8000


@lru_cache
def get_settings() -> Settings:
    """Singleton settings (cache theo process)."""
    return Settings()
