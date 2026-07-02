"""Vector index (ChromaDB) — STUB. Collection: kcn_chunks (contract §3)."""

from typing import Any
from uuid import UUID

from app.pipeline.chunk import Chunk

COLLECTION_NAME = "kcn_chunks"


def upsert_chunks(
    version_id: UUID,
    document_id: UUID,
    chunks: list[Chunk],
    embeddings: list[list[float]],
    metadata: dict[str, str],
) -> None:
    """Ghi chunk + embedding vào Chroma, metadata mỗi chunk:
    version_id, document_id, page_no, lang, machine_code, min_role, chunk_index.

    TODO(đợt sau): chromadb PersistentClient, idempotent theo version_id.
    """
    raise NotImplementedError("Chroma upsert chưa triển khai — đợt sau")


def search(
    query_embedding: list[float],
    allowed_version_ids: list[UUID],
    top_k: int = 5,
) -> list[dict[str, Any]]:
    """Truy vấn top-k với filter version_id ∈ allowed_version_ids (contract §2.2).

    TODO(đợt sau): trả [{text, page_no, version_id, score, ...}] sắp theo cosine.
    """
    raise NotImplementedError("Chroma search chưa triển khai — đợt sau")
