"""Client MinIO tối giản: tải object PDF theo storageKey (contract §3 — key layout)."""

from minio import Minio

from app.config import get_settings


def _make_client() -> Minio:
    s = get_settings()
    return Minio(
        endpoint=s.minio_endpoint,
        access_key=s.minio_access_key,
        secret_key=s.minio_secret_key,
        secure=s.minio_secure,
    )


def get_object(storage_key: str) -> bytes:
    """Tải toàn bộ object từ bucket cấu hình (mặc định kcn-docs).

    Raises:
        Exception: mọi lỗi MinIO (kết nối, NoSuchKey, ...) để service layer
            chuyển thành callback FAILED.
    """
    s = get_settings()
    client = _make_client()
    response = client.get_object(s.minio_bucket, storage_key)
    try:
        return response.read()
    finally:
        response.close()
        response.release_conn()
