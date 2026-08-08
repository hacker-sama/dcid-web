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
    # Use the lighter text model for OCR/RAG; load the VLM only for image requests.
    lm_studio_model: str = "qwen2.5:1.5b"
    vision_model: str = "qwen2.5vl:3b"
    llm_temperature: float = 0.2          # Cấu hình suy luận tối ưu theo sơ đồ (Low Temperature: 0.2)
    llm_top_p: float = 0.9               # Cấu hình suy luận tối ưu theo sơ đồ (Top-P: 0.9)
    llm_repetition_penalty: float = 1.2  # Cấu hình suy luận tối ưu theo sơ đồ (High Repetition Penalty: 1.2)
    llm_frequency_penalty: float = 0.0
    llm_presence_penalty: float = 0.0
    llm_max_tokens: int = 1024
    # Giới hạn context phía ứng dụng để kiểm soát RAM và độ trễ của Ollama.
    llm_context_window: int = 2048
    llm_context_safety_tokens: int = 256
    # CPU cold-start for a 3B vision model can exceed two minutes.
    llm_timeout: float = 300.0
    # Avoid loading the ~700 MiB SentenceTransformer in the query API. Ingest
    # still creates embeddings; selected-document queries use lexical ranking.
    low_memory_query_mode: bool = True

    # ── Redis / Celery (async task queue) ─────────────────────────────────────
    # service `redis` trong docker-compose.yml (port nội bộ 6379)
    # Khi dev local: redis://localhost:6379/0
    redis_url: str = "redis://redis:6379/0"
    # Serialize OCR, embedding and LLM inference across containers so their
    # memory peaks cannot overlap on the 8 GiB deployment target.
    ai_resource_gate_enabled: bool = True
    ai_resource_gate_fail_open: bool = False
    ai_resource_lock_name: str = "dcid:ai:heavy"
    ai_resource_lock_wait_seconds: int = 330
    ai_resource_lock_lease_seconds: int = 180
    # Soft limit: SoftTimeLimitExceeded exception được raise để task có thể cleanup
    celery_task_soft_time_limit: int = 600   # 10 phút — đủ cho PDF 100+ trang
    # Hard limit: worker bị kill nếu vượt quá (tránh zombie process)
    celery_task_time_limit: int = 900        # 15 phút hard limit


@lru_cache
def get_settings() -> Settings:
    """Singleton settings (cache theo process)."""
    return Settings()
