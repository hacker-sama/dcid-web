"""Module Embedding: Tạo vector embedding với model local (SentenceTransformers)."""

import logging
from functools import lru_cache
from typing import List

logger = logging.getLogger("dcid-ai.embedder")

MODEL_NAME = "intfloat/multilingual-e5-small"
PASSAGE_PREFIX = "passage: "
QUERY_PREFIX = "query: "


@lru_cache(maxsize=1)
def _get_model():
    """Load model SentenceTransformer (singleton per process)."""
    from sentence_transformers import SentenceTransformer

    logger.info("Loading local embedding model: %s ...", MODEL_NAME)
    return SentenceTransformer(MODEL_NAME)


def embed_texts(texts: List[str]) -> List[List[float]]:
    """Embed danh sách đoạn văn (passage chunks) với prefix 'passage: '."""
    if not texts:
        return []
    model = _get_model()
    prefixed = [PASSAGE_PREFIX + t for t in texts]
    embeddings = model.encode(prefixed, normalize_embeddings=True, show_progress_bar=False)
    return [vec.tolist() for vec in embeddings]


def embed_query(question: str) -> List[float]:
    """Embed câu hỏi người dùng với prefix 'query: '."""
    model = _get_model()
    prefixed = QUERY_PREFIX + question
    vec = model.encode([prefixed], normalize_embeddings=True, show_progress_bar=False)
    return vec[0].tolist()
