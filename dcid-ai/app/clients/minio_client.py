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


def get_object_base64(storage_key: str) -> str:
    """Tải object ảnh từ MinIO và chuyển đổi thành Data URI Base64 (dùng cho Vision LLM API)."""
    import base64
    import mimetypes

    data = get_object(storage_key)
    mime_type, _ = mimetypes.guess_type(storage_key)
    if not mime_type or not mime_type.startswith("image/"):
        mime_type = "image/png"
    b64 = base64.b64encode(data).decode("utf-8")
    return f"data:{mime_type};base64,{b64}"


def put_object(storage_key: str, data: bytes, content_type: str = "image/png") -> None:
    """Tải dữ liệu bytes (ảnh trang PDF) lên MinIO bucket."""
    import io
    s = get_settings()
    client = _make_client()
    client.put_object(
        s.minio_bucket,
        storage_key,
        io.BytesIO(data),
        length=len(data),
        content_type=content_type,
    )


