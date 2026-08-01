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


def get_object_base64(storage_key: str, max_side: int = 672) -> str:
    """Tải object ảnh từ MinIO và chuyển đổi thành Data URI Base64 JPEG siêu nhẹ.
    Tự động nén/resize cạnh tối đa về 672px và nén JPEG 75% để tiết kiệm token cho Vision LLM (~576 tokens).
    """
    import base64
    import io

    data = get_object(storage_key)

    try:
        from PIL import Image
        img = Image.open(io.BytesIO(data))
        if img.mode in ("RGBA", "P", "LA"):
            img = img.convert("RGB")
        if max(img.width, img.height) > max_side:
            img.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
        
        out_buf = io.BytesIO()
        img.save(out_buf, format="JPEG", quality=75, optimize=True)
        data = out_buf.getvalue()
        mime_type = "image/jpeg"
    except Exception:
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


def get_or_render_page_base64(
    page_img_key: str,
    version_id: str | None = None,
    document_id: str | None = None,
    page_no: int = 1,
) -> str | None:
    """Tải Base64 ảnh trang từ MinIO; nếu chưa có (tài liệu cũ) → tự động lấy PDF gốc, render trang PNG và lưu lại MinIO."""
    import logging
    logger = logging.getLogger("dcid-ai.minio")

    try:
        return get_object_base64(page_img_key)
    except Exception:
        logger.info("Ảnh trang %s chưa có sẵn trong MinIO, tự động dựng từ PDF gốc...", page_img_key)

    pdf_keys_to_try = []
    if document_id:
        pdf_keys_to_try.extend([
            f"documents/{document_id}/v1/original.pdf",
            f"documents/{document_id}/original.pdf",
        ])
    if version_id:
        pdf_keys_to_try.extend([
            f"documents/{version_id}/v1/original.pdf",
            f"documents/{version_id}/original.pdf",
        ])

    pdf_bytes = None
    for k in pdf_keys_to_try:
        try:
            pdf_bytes = get_object(k)
            if pdf_bytes:
                break
        except Exception:
            continue

    if not pdf_bytes:
        return None

    try:
        import fitz
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        page_idx = max(0, page_no - 1)
        if page_idx >= len(doc):
            page_idx = 0
        page = doc[page_idx]

        # Tối ưu kích thước ảnh cho Vision LLM: giới hạn max_dim 672px để tránh vượt quá context size
        rect = page.rect
        max_dim = max(rect.width, rect.height)
        scale = 672.0 / max_dim if max_dim > 672 else 1.0
        mat = fitz.Matrix(scale, scale)
        pix = page.get_pixmap(matrix=mat)
        
        # Nén JPEG chất lượng 75% cho kích thước file siêu nhẹ (~80KB - 120KB)
        jpg_bytes = pix.tobytes("jpg", jpg_quality=75)
        doc.close()

        put_object(page_img_key, jpg_bytes, content_type="image/jpeg")
        logger.info("Đã tự động render và lưu ảnh trang %s (%d bytes) lên MinIO", page_img_key, len(jpg_bytes))

        import base64
        b64 = base64.b64encode(jpg_bytes).decode("utf-8")
        return f"data:image/jpeg;base64,{b64}"
    except Exception as exc:
        logger.warning("Không thể auto-render ảnh trang cho key %s: %s", page_img_key, exc)
        return None



