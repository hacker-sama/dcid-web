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

    # ── Local LLM (Ollama OpenAI-compatible API) ──────────────────────────────
    # Giữ tên biến LM_STUDIO_* để tương thích ngược với các file .env cũ.
    # Docker Compose ghi đè URL thành http://ollama:11434/v1.
    lm_studio_base_url: str = "http://localhost:11434/v1"
    lm_studio_api_key: str = "ollama"
    lm_studio_model: str = "qwen2.5vl:3b"
    llm_temperature: float = 0.2          # Cấu hình suy luận tối ưu theo sơ đồ (Low Temperature: 0.2)
    llm_top_p: float = 0.9               # Cấu hình suy luận tối ưu theo sơ đồ (Top-P: 0.9)
    llm_repetition_penalty: float = 1.2  # Cấu hình suy luận tối ưu theo sơ đồ (High Repetition Penalty: 1.2)
    llm_frequency_penalty: float = 0.0
    llm_presence_penalty: float = 0.0
    llm_max_tokens: int = 2048
    # Giới hạn context phía ứng dụng để kiểm soát RAM và độ trễ của Ollama.
    llm_context_window: int = 4096
    llm_context_safety_tokens: int = 256
    llm_timeout: float = 120.0

    # ── Redis / Celery (async task queue) ─────────────────────────────────────
    # service `redis` trong docker-compose.yml (port nội bộ 6379)
    # Khi dev local: redis://localhost:6379/0
    redis_url: str = "redis://redis:6379/0"
    # Soft limit: SoftTimeLimitExceeded exception được raise để task có thể cleanup
    celery_task_soft_time_limit: int = 600   # 10 phút — đủ cho PDF 100+ trang
    # Hard limit: worker bị kill nếu vượt quá (tránh zombie process)
    celery_task_time_limit: int = 900        # 15 phút hard limit


@lru_cache
def get_settings() -> Settings:
    """Singleton settings (cache theo process)."""
    return Settings()
