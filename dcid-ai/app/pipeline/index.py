"""Qdrant vector index for the ``kcn_chunks`` RAG collection.

The public functions intentionally keep the previous index module contract so
ingestion and query callers do not need database-specific code.
"""

from __future__ import annotations

import logging
import os
import re
import unicodedata
from functools import lru_cache
from typing import Any
from uuid import NAMESPACE_URL, UUID, uuid5

from app.config import get_settings
from app.pipeline.chunk import Chunk

logger = logging.getLogger("dcid-ai.index")

COLLECTION_NAME = "kcn_chunks"
INDEXED_KEYWORD_FIELDS = ("version_id", "document_id", "machineCode")
SCROLL_BATCH_SIZE = 256
MAX_LEXICAL_CANDIDATES = 4096

# Common conversational words do not help distinguish one technical chunk
# from another. Keeping this list small preserves useful terms such as
# "lap", "dat", "bao tri", while avoiding matches on words like "la/gi".
LEXICAL_STOP_WORDS = {
    "ai", "bao", "cac", "cho", "co", "cua", "duoc", "gi", "hay", "la",
    "mot", "nao", "nhieu", "nhung", "o", "the", "thi", "tren", "va", "voi",
    "what", "which", "the", "this", "that", "is", "are", "of", "to", "for",
}


@lru_cache(maxsize=1)
def _get_client():
    """Return one Qdrant HTTP client per process."""
    try:
        from qdrant_client import QdrantClient
    except ImportError as exc:
        raise RuntimeError(
            "qdrant-client is not installed. Run: pip install qdrant-client>=1.12"
        ) from exc

    settings = get_settings()
    logger.info("Connecting to Qdrant at %s:%s", settings.qdrant_host, settings.qdrant_port)
    return QdrantClient(
        host=settings.qdrant_host,
        port=settings.qdrant_port,
        api_key=settings.qdrant_api_key or None,
        timeout=settings.qdrant_timeout,
    )


@lru_cache(maxsize=1)
def _ensure_collection() -> None:
    """Create the collection and payload indexes idempotently."""
    from qdrant_client import models

    client = _get_client()
    settings = get_settings()

    if not client.collection_exists(COLLECTION_NAME):
        try:
            client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=models.VectorParams(
                    size=settings.qdrant_vector_size,
                    distance=models.Distance.COSINE,
                    on_disk=settings.qdrant_vectors_on_disk,
                ),
                hnsw_config=models.HnswConfigDiff(
                    on_disk=settings.qdrant_hnsw_on_disk,
                ),
                on_disk_payload=settings.qdrant_payload_on_disk,
            )
            logger.info(
                "Created Qdrant collection %s (dim=%d, cosine)",
                COLLECTION_NAME,
                settings.qdrant_vector_size,
            )
        except Exception:
            # The API and worker can start concurrently. Treat a collection
            # created by the other process as success, but preserve real errors.
            if not client.collection_exists(COLLECTION_NAME):
                raise

    info = client.get_collection(COLLECTION_NAME)
    vector_config = info.config.params.vectors
    actual_size = getattr(vector_config, "size", None)
    if actual_size is not None and actual_size != settings.qdrant_vector_size:
        raise RuntimeError(
            f"Qdrant collection {COLLECTION_NAME} has vector size {actual_size}; "
            f"expected {settings.qdrant_vector_size}. Recreate and reindex it."
        )

    payload_schema = getattr(info, "payload_schema", {}) or {}
    for field_name in INDEXED_KEYWORD_FIELDS:
        if field_name in payload_schema:
            continue
        try:
            client.create_payload_index(
                collection_name=COLLECTION_NAME,
                field_name=field_name,
                field_schema=models.PayloadSchemaType.KEYWORD,
                wait=True,
            )
        except Exception as exc:
            # Qdrant returns an error when an identical index already exists.
            # Collection creation is still valid, so keep startup idempotent.
            logger.debug("Payload index %s already exists or was created concurrently: %s", field_name, exc)


def _point_id(version_id: UUID | str, page_no: int, chunk_index: int) -> str:
    """Build a deterministic Qdrant-compatible UUID for idempotent upserts."""
    key = f"dcid:{version_id}:{page_no}:{chunk_index}"
    return str(uuid5(NAMESPACE_URL, key))


def _filter(
    allowed_version_ids: list[UUID] | list[str],
    machine_code: str | None = None,
):
    from qdrant_client import models

    must = [
        models.FieldCondition(
            key="version_id",
            match=models.MatchAny(any=[str(value) for value in allowed_version_ids]),
        )
    ]
    if machine_code:
        must.append(
            models.FieldCondition(
                key="machineCode",
                match=models.MatchValue(value=machine_code),
            )
        )
    return models.Filter(must=must)


def _clean_metadata(metadata: dict[str, Any]) -> dict[str, Any]:
    cleaned: dict[str, Any] = {}
    for key, value in metadata.items():
        if value is None:
            continue
        if isinstance(value, (str, int, float, bool)):
            cleaned[key] = value
        else:
            cleaned[key] = str(value)

    # The backend has historically sent both spellings. Store the canonical
    # camelCase field used by the query filter while retaining the original.
    if "machine_code" in cleaned and "machineCode" not in cleaned:
        cleaned["machineCode"] = cleaned["machine_code"]
    return cleaned


def _payload_to_hit(payload: dict[str, Any], score: float) -> dict[str, Any]:
    return {
        "text": payload.get("text", ""),
        "page_no": payload.get("page_no"),
        "version_id": payload.get("version_id"),
        "document_id": payload.get("document_id"),
        "chunk_index": payload.get("chunk_index"),
        "bbox": payload.get("bbox", ""),
        "image_path": payload.get("image_path", ""),
        "snippet": payload.get("snippet", ""),
        "title": payload.get("title", ""),
        "category": payload.get("category", ""),
        "score": round(max(0.0, min(1.0, float(score))), 4),
    }


def upsert_chunks(
    version_id: UUID,
    document_id: UUID,
    chunks: list[Chunk],
    embeddings: list[list[float]],
    metadata: dict[str, Any],
) -> None:
    """Upsert chunk vectors and payloads into Qdrant."""
    if not chunks:
        logger.warning("upsert_chunks: no chunks; skipping versionId=%s", version_id)
        return
    if len(chunks) != len(embeddings):
        raise ValueError(f"Chunk count ({len(chunks)}) differs from embedding count ({len(embeddings)})")

    settings = get_settings()
    for vector in embeddings:
        if len(vector) != settings.qdrant_vector_size:
            raise ValueError(
                f"Embedding dimension {len(vector)} does not match Qdrant dimension "
                f"{settings.qdrant_vector_size}"
            )

    from qdrant_client import models

    _ensure_collection()
    extra = _clean_metadata(metadata)
    points = []
    for chunk, vector in zip(chunks, embeddings):
        payload = {
            **extra,
            "text": chunk.text,
            "version_id": str(version_id),
            "document_id": str(document_id),
            "page_no": int(chunk.page_no),
            "chunk_index": int(chunk.chunk_index),
            "bbox": str(chunk.bbox or ""),
            "image_path": str(getattr(chunk, "image_path", None) or ""),
            "snippet": str(chunk.snippet or chunk.text[:300] or ""),
            "chunk_id": f"{version_id}_{chunk.page_no}_{chunk.chunk_index}",
        }
        points.append(
            models.PointStruct(
                id=_point_id(version_id, chunk.page_no, chunk.chunk_index),
                vector=vector,
                payload=payload,
            )
        )

    _get_client().upsert(
        collection_name=COLLECTION_NAME,
        points=points,
        wait=True,
    )
    try:
        from app.pipeline.bm25 import invalidate_cache
        invalidate_cache(str(version_id))
    except Exception:
        pass
    logger.info("Qdrant upsert OK: versionId=%s chunks=%d", version_id, len(points))


def search(
    query_embedding: list[float],
    allowed_version_ids: list[UUID],
    top_k: int = 5,
    machine_code: str | None = None,
) -> list[dict[str, Any]]:
    """Return top-k cosine-similar chunks restricted to selected versions."""
    if not allowed_version_ids:
        return []
    _ensure_collection()
    result = _get_client().query_points(
        collection_name=COLLECTION_NAME,
        query=query_embedding,
        query_filter=_filter(allowed_version_ids, machine_code),
        limit=top_k,
        with_payload=True,
        with_vectors=False,
    )
    return [_payload_to_hit(point.payload or {}, point.score) for point in result.points]


def search_hybrid(
    query_embedding: list[float] | None,
    question: str,
    allowed_version_ids: list[UUID],
    top_k: int = 5,
    machine_code: str | None = None,
    alpha: float = 0.70,
) -> list[dict[str, Any]]:
    """Combine dense semantic vectors and BM25 exact lexical matching with score fusion."""
    if not allowed_version_ids:
        return []

    try:
        from app.pipeline.bm25 import search_bm25
    except ImportError:
        if query_embedding:
            return search(query_embedding, allowed_version_ids, top_k, machine_code)
        return search_selected_text(question, allowed_version_ids, top_k, machine_code)

    dense_hits: list[dict[str, Any]] = []
    if query_embedding:
        try:
            dense_hits = search(
                query_embedding=query_embedding,
                allowed_version_ids=allowed_version_ids,
                top_k=top_k * 2,
                machine_code=machine_code,
            )
        except Exception as exc:
            logger.warning("Dense search in hybrid retrieval failed: %s", exc)

    bm25_hits: list[dict[str, Any]] = []
    try:
        bm25_hits = search_bm25(
            question=question,
            allowed_version_ids=allowed_version_ids,
            top_k=top_k * 2,
            machine_code=machine_code,
        )
    except Exception as exc:
        logger.warning("BM25 search in hybrid retrieval failed: %s", exc)

    if not dense_hits and not bm25_hits:
        return []
    if not dense_hits:
        return bm25_hits[:top_k]
    if not bm25_hits:
        return dense_hits[:top_k]

    fused: dict[str, dict[str, Any]] = {}
    for hit in dense_hits:
        key = f"{hit.get('version_id')}_{hit.get('page_no')}_{hit.get('chunk_index')}"
        h = dict(hit)
        h["dense_score"] = hit.get("score", 0.0)
        h["bm25_score"] = 0.0
        fused[key] = h

    for hit in bm25_hits:
        key = f"{hit.get('version_id')}_{hit.get('page_no')}_{hit.get('chunk_index')}"
        if key in fused:
            fused[key]["bm25_score"] = hit.get("score", 0.0)
            if hit.get("bm25_raw_score") is not None:
                fused[key]["bm25_raw_score"] = hit["bm25_raw_score"]
        else:
            h = dict(hit)
            h["dense_score"] = 0.0
            h["bm25_score"] = hit.get("score", 0.0)
            fused[key] = h

    for h in fused.values():
        d_s = h.get("dense_score", 0.0)
        b_s = h.get("bm25_score", 0.0)
        if d_s > 0 and b_s > 0:
            combined = alpha * d_s + (1.0 - alpha) * b_s
            combined = min(0.99, combined + 0.04)
        else:
            combined = d_s if d_s > 0 else b_s
        h["score"] = round(max(0.0, min(1.0, combined)), 4)

    result = list(fused.values())
    result.sort(key=lambda item: (-item["score"], item.get("page_no") or 0, item.get("chunk_index") or 0))
    return result[:top_k]


def _tokens(value: str) -> set[str]:
    normalized = unicodedata.normalize("NFKD", value.lower())
    plain = "".join(char for char in normalized if not unicodedata.combining(char))
    return {
        token
        for token in re.findall(r"\w+", plain)
        if len(token) > 1 and token not in LEXICAL_STOP_WORDS
    }


def _lexical_score(question_tokens: set[str], payload: dict[str, Any]) -> float:
    """Return a guardrail-compatible relevance score without embeddings.

    The old low-memory path assigned every chunk a base score of 0.65, even
    with zero shared terms. Since the standard guardrail threshold is 0.60,
    unrelated documents could reach the LLM. This score is zero for no match
    and scales with query-term coverage for predictable threshold behaviour.
    """
    if not question_tokens:
        return 0.0

    searchable = " ".join(
        str(payload.get(field, "") or "")
        for field in ("text", "title", "category", "machineCode")
    )
    matched = question_tokens & _tokens(searchable)
    if not matched:
        return 0.0

    coverage = len(matched) / len(question_tokens)
    # 47% query coverage reaches the normal 0.60 guardrail threshold. A
    # complete lexical match approaches, but never claims, perfect certainty.
    return min(0.95, 0.30 + 0.65 * coverage)


def _scroll_payloads(query_filter, *, limit: int = MAX_LEXICAL_CANDIDATES) -> list[dict[str, Any]]:
    payloads: list[dict[str, Any]] = []
    offset = None
    client = _get_client()
    while len(payloads) < limit:
        batch_size = min(SCROLL_BATCH_SIZE, limit - len(payloads))
        points, offset = client.scroll(
            collection_name=COLLECTION_NAME,
            scroll_filter=query_filter,
            limit=batch_size,
            offset=offset,
            with_payload=True,
            with_vectors=False,
        )
        payloads.extend(point.payload or {} for point in points)
        if offset is None or not points:
            break
    if len(payloads) == limit:
        logger.warning("Lexical candidate limit reached (%d chunks)", limit)
    return payloads


def search_selected_text(
    question: str,
    allowed_version_ids: list[UUID],
    top_k: int = 5,
    machine_code: str | None = None,
) -> list[dict[str, Any]]:
    """Rank selected-document chunks lexically without loading the embed model."""
    if not allowed_version_ids:
        return []
    _ensure_collection()
    question_tokens = _tokens(question)
    hits: list[dict[str, Any]] = []
    for payload in _scroll_payloads(_filter(allowed_version_ids, machine_code)):
        score = _lexical_score(question_tokens, payload)
        if score > 0.0:
            hits.append(_payload_to_hit(payload, score))

    hits.sort(key=lambda item: (-item["score"], item.get("page_no") or 0, item.get("chunk_index") or 0))
    return hits[:top_k]


def delete_document_chunks(
    document_id: str | None = None,
    version_id: str | None = None,
) -> int:
    """Delete indexed chunks by document/version and clean local crop files."""
    key = "document_id" if document_id else "version_id" if version_id else None
    value = document_id or version_id
    if not key or not value:
        return 0

    try:
        from qdrant_client import models
        _ensure_collection()
        query_filter = models.Filter(
            must=[models.FieldCondition(key=key, match=models.MatchValue(value=str(value)))]
        )
        count = _get_client().count(
            collection_name=COLLECTION_NAME,
            count_filter=query_filter,
            exact=True,
        ).count

        for payload in _scroll_payloads(query_filter):
            image_path = payload.get("image_path")
            if image_path and os.path.exists(str(image_path)):
                try:
                    os.remove(str(image_path))
                except OSError as exc:
                    logger.warning("Could not delete crop %s: %s", image_path, exc)

        _get_client().delete(
            collection_name=COLLECTION_NAME,
            points_selector=models.FilterSelector(filter=query_filter),
            wait=True,
        )
        try:
            from app.pipeline.bm25 import invalidate_cache
            invalidate_cache(version_id or None)
        except Exception:
            pass
        logger.info("Deleted %d Qdrant chunks for %s=%s", count, key, value)
        return int(count)
    except Exception as exc:
        logger.error("Failed to delete Qdrant chunks for %s=%s: %s", key, value, exc)
        return 0

