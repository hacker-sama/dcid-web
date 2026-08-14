"""Compatibility adapter for the Qdrant index used by the legacy API routes."""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional
from uuid import UUID

from app.pipeline import index as qdrant_index
from src.chunking.chunker import Chunk

logger = logging.getLogger("dcid-ai.vector_store")
COLLECTION_NAME = qdrant_index.COLLECTION_NAME


def upsert_chunks(
    version_id: str,
    document_id: str,
    chunks: List[Chunk],
    embeddings: List[List[float]],
    extra_metadata: Optional[Dict[str, Any]] = None,
) -> None:
    qdrant_index.upsert_chunks(
        version_id=UUID(str(version_id)),
        document_id=UUID(str(document_id)),
        chunks=chunks,
        embeddings=embeddings,
        metadata=extra_metadata or {},
    )


def search_chunks(
    query_embedding: List[float],
    allowed_version_ids: List[str],
    top_k: int = 5,
) -> List[Dict[str, Any]]:
    return qdrant_index.search(
        query_embedding=query_embedding,
        allowed_version_ids=allowed_version_ids,
        top_k=top_k,
    )


def delete_document_chunks(
    document_id: Optional[str] = None,
    version_id: Optional[str] = None,
) -> int:
    return qdrant_index.delete_document_chunks(
        document_id=document_id,
        version_id=version_id,
    )
