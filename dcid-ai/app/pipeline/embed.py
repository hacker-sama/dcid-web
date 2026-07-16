"""Embedding văn bản — multilingual-e5-small (sentence-transformers, CPU).

Model: intfloat/multilingual-e5-small
- Size: ~470 MB (download lần đầu từ HuggingFace Hub vào ~/.cache/huggingface)
- Output: 384-dim L2-normalized float32 vector
- Prefix chuẩn e5: "passage: " cho đoạn văn, "query: " cho câu hỏi
- Chạy hoàn toàn on-premise CPU (không cần GPU)

Thiết kế:
- Model được lazy-load lần đầu gọi embed_texts() → singleton (lru_cache)
- Tách hàm embed_query() riêng cho pipeline query (T3) để tiện dùng prefix "query: "
"""

from __future__ import annotations

import logging
from functools import lru_cache

logger = logging.getLogger("dcid-ai.embed")

MODEL_NAME = "intfloat/multilingual-e5-small"
PASSAGE_PREFIX = "passage: "
QUERY_PREFIX = "query: "


@lru_cache(maxsize=1)
def _get_model():
    """Load model 1 lần duy nhất (lazy, singleton per process).

    Import sentence_transformers bên trong để tránh import-time crash khi
    package chưa cài (chỉ fail tại runtime khi thật sự cần embed).
    """
    try:
        from sentence_transformers import SentenceTransformer  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError(
            "sentence-transformers chưa cài. Chạy: pip install sentence-transformers>=3.0"
        ) from exc

    logger.info("Đang load model embed: %s (lần đầu có thể mất vài phút tải về)", MODEL_NAME)
    model = SentenceTransformer(MODEL_NAME)
    logger.info("Model %s đã sẵn sàng.", MODEL_NAME)
    return model


# ────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────

def embed_texts(texts: list[str]) -> list[list[float]]:
    """Embed danh sách *passage* (từ chunk văn bản tài liệu).

    Tự động thêm prefix "passage: " theo đặc tả E5.

    Args:
        texts: list text thuần (chưa có prefix).

    Returns:
        list vector float32 chuẩn hoá L2, mỗi vector dài 384.
    """
    if not texts:
        return []
    model = _get_model()
    prefixed = [PASSAGE_PREFIX + t for t in texts]
    embeddings = model.encode(prefixed, normalize_embeddings=True, show_progress_bar=False)
    return [vec.tolist() for vec in embeddings]


def embed_query(question: str) -> list[float]:
    """Embed 1 câu hỏi (dùng trong pipeline query ở T3).

    Tự động thêm prefix "query: " theo đặc tả E5.

    Args:
        question: câu hỏi người dùng.

    Returns:
        Vector float32 chuẩn hoá L2, dài 384.
    """
    model = _get_model()
    prefixed = QUERY_PREFIX + question
    vec = model.encode([prefixed], normalize_embeddings=True, show_progress_bar=False)
    return vec[0].tolist()
