"""Qdrant vector store used by the legacy top-level API."""

from __future__ import annotations

import logging
import os
from functools import lru_cache
from typing import Any, Dict, List, Optional
from uuid import NAMESPACE_URL, uuid5

from qdrant_client import QdrantClient, models

from src.chunking.chunker import Chunk

logger = logging.getLogger("dcid-ai.vector_store")
COLLECTION_NAME = "kcn_chunks"
VECTOR_SIZE = int(os.getenv("QDRANT_VECTOR_SIZE", "384"))


@lru_cache(maxsize=1)
def get_qdrant_client() -> QdrantClient:
    return QdrantClient(
        host=os.getenv("QDRANT_HOST", "localhost"),
        port=int(os.getenv("QDRANT_PORT", "6333")),
        api_key=os.getenv("QDRANT_API_KEY") or None,
        timeout=float(os.getenv("QDRANT_TIMEOUT", "30")),
    )


def _ensure_collection() -> None:
    client = get_qdrant_client()
    if not client.collection_exists(COLLECTION_NAME):
        client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=models.VectorParams(
                size=VECTOR_SIZE,
                distance=models.Distance.COSINE,
                on_disk=True,
            ),
            hnsw_config=models.HnswConfigDiff(on_disk=True),
            on_disk_payload=True,
        )
    for field in ("version_id", "document_id", "machineCode"):
        try:
            client.create_payload_index(
                collection_name=COLLECTION_NAME,
                field_name=field,
                field_schema=models.PayloadSchemaType.KEYWORD,
                wait=True,
            )
        except Exception:
            pass


def _id(version_id: str, page_no: int, chunk_index: int) -> str:
    return str(uuid5(NAMESPACE_URL, f"dcid:{version_id}:{page_no}:{chunk_index}"))


def upsert_chunks(
    version_id: str,
    document_id: str,
    chunks: List[Chunk],
    embeddings: List[List[float]],
    extra_metadata: Optional[Dict[str, Any]] = None,
) -> None:
    if not chunks:
        return
    if len(chunks) != len(embeddings):
        raise ValueError("Chunk and embedding counts differ")
    _ensure_collection()
    extra = {key: value for key, value in (extra_metadata or {}).items() if value is not None}
    if "machine_code" in extra and "machineCode" not in extra:
        extra["machineCode"] = extra["machine_code"]
    points = []
    for chunk, vector in zip(chunks, embeddings):
        if len(vector) != VECTOR_SIZE:
            raise ValueError(f"Embedding dimension {len(vector)} != {VECTOR_SIZE}")
        payload = {
            **extra,
            "text": chunk.text,
            "version_id": str(version_id),
            "document_id": str(document_id),
            "page_no": int(chunk.page_no),
            "chunk_index": int(chunk.chunk_index),
            "bbox": str(chunk.bbox or ""),
            "image_path": str(chunk.image_path or ""),
            "snippet": str(chunk.snippet or chunk.text[:300]),
        }
        points.append(models.PointStruct(
            id=_id(version_id, chunk.page_no, chunk.chunk_index),
            vector=vector,
            payload=payload,
        ))
    get_qdrant_client().upsert(COLLECTION_NAME, points=points, wait=True)


def search_chunks(
    query_embedding: List[float],
    allowed_version_ids: List[str],
    top_k: int = 5,
) -> List[Dict[str, Any]]:
    if not allowed_version_ids:
        return []
    _ensure_collection()
    result = get_qdrant_client().query_points(
        collection_name=COLLECTION_NAME,
        query=query_embedding,
        query_filter=models.Filter(must=[models.FieldCondition(
            key="version_id",
            match=models.MatchAny(any=[str(value) for value in allowed_version_ids]),
        )]),
        limit=top_k,
        with_payload=True,
        with_vectors=False,
    )
    hits = []
    for point in result.points:
        payload = point.payload or {}
        hits.append({
            "text": payload.get("text", ""),
            "page_no": payload.get("page_no"),
            "version_id": payload.get("version_id"),
            "document_id": payload.get("document_id"),
            "chunk_index": payload.get("chunk_index"),
            "bbox": payload.get("bbox", ""),
            "image_path": payload.get("image_path", ""),
            "snippet": payload.get("snippet", ""),
            "score": round(max(0.0, min(1.0, float(point.score))), 4),
        })
    return hits


def delete_document_chunks(
    document_id: Optional[str] = None,
    version_id: Optional[str] = None,
) -> int:
    key = "document_id" if document_id else "version_id" if version_id else None
    value = document_id or version_id
    if not key or not value:
        return 0
    try:
        _ensure_collection()
        query_filter = models.Filter(must=[models.FieldCondition(
            key=key,
            match=models.MatchValue(value=str(value)),
        )])
        count = get_qdrant_client().count(COLLECTION_NAME, count_filter=query_filter, exact=True).count
        get_qdrant_client().delete(
            COLLECTION_NAME,
            points_selector=models.FilterSelector(filter=query_filter),
            wait=True,
        )
        return int(count)
    except Exception as exc:
        logger.error("Qdrant delete failed for %s=%s: %s", key, value, exc)
        return 0
