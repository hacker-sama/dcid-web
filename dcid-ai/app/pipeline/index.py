"""Vector index ChromaDB — collection `kcn_chunks` (contract §3).

Client: chromadb.HttpClient → kết nối service `chroma` trong docker-compose.yml
Collection: kcn_chunks (distance: cosine)
ID scheme (idempotent): "{version_id}_{page_no}_{chunk_index}"

Metadata mỗi chunk (theo contract §3 & ROADMAP T2):
  version_id    : str(UUID)   — filter chính khi query
  document_id   : str(UUID)
  page_no       : int
  chunk_index   : int
  + bất kỳ key/value nào trong `metadata` dict từ IngestRequest
    (ví dụ: lang, machine_code, min_role)

Lưu ý Chroma:
- `get_or_create_collection` idempotent — an toàn khi restart.
- metadata value phải là str|int|float|bool (không được None).
- hnsw:space = "cosine" → score trả về là cosine distance [0, 2], cần convert
  thành similarity khi cần: similarity = 1 - distance / 2  (hoặc dùng như thế).
"""

from __future__ import annotations

import logging
from functools import lru_cache
from typing import Any
from uuid import UUID

from app.config import get_settings
from app.pipeline.chunk import Chunk

logger = logging.getLogger("dcid-ai.index")

COLLECTION_NAME = "kcn_chunks"


# ────────────────────────────────────────────────────────────────
# Client singleton
# ────────────────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def _get_client():
    """HttpClient kết nối ChromaDB — singleton per process."""
    try:
        import chromadb  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError(
            "chromadb chưa cài. Chạy: pip install chromadb>=0.5"
        ) from exc

    settings = get_settings()
    logger.info("Kết nối ChromaDB tại %s:%s", settings.chroma_host, settings.chroma_port)
    return chromadb.HttpClient(host=settings.chroma_host, port=settings.chroma_port)


def _get_collection():
    """Lấy (hoặc tạo) collection `kcn_chunks` với distance cosine."""
    import chromadb  # noqa: PLC0415

    client = _get_client()
    return client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )


# ────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────

def upsert_chunks(
    version_id: UUID,
    document_id: UUID,
    chunks: list[Chunk],
    embeddings: list[list[float]],
    metadata: dict[str, str],
) -> None:
    """Ghi chunk + embedding vào Chroma, idempotent theo version_id.

    Args:
        version_id:  UUID phiên bản tài liệu (filter chính khi query).
        document_id: UUID tài liệu gốc.
        chunks:      list Chunk từ pipeline/chunk.py.
        embeddings:  list vector (phải cùng độ dài với `chunks`).
        metadata:    dict bổ sung từ IngestRequest.metadata
                     (ví dụ: {"lang": "en", "machine_code": "S7-1200"}).

    Raises:
        Exception: ChromaDB unreachable hoặc lỗi upsert — caller (ingest_service)
                   bắt và chuyển thành callback FAILED.
    """
    if not chunks:
        logger.warning("upsert_chunks: không có chunk nào — bỏ qua (versionId=%s)", version_id)
        return

    if len(chunks) != len(embeddings):
        raise ValueError(
            f"Số chunks ({len(chunks)}) ≠ số embeddings ({len(embeddings)})"
        )

    collection = _get_collection()

    ids = [f"{version_id}_{c.page_no}_{c.chunk_index}" for c in chunks]

    # Chroma yêu cầu metadata value là scalar (str/int/float/bool)
    metas = [
        {
            "version_id": str(version_id),
            "document_id": str(document_id),
            "page_no": c.page_no,
            "chunk_index": c.chunk_index,
            "bbox": str(c.bbox or ""),
            "image_path": str(getattr(c, "image_path", None) or ""),
            "snippet": str(c.snippet or c.text[:300] or ""),
            **{k: v for k, v in metadata.items() if v is not None},
        }
        for c in chunks
    ]

    collection.upsert(
        ids=ids,
        documents=[c.text for c in chunks],
        embeddings=embeddings,
        metadatas=metas,
    )

    logger.info(
        "Chroma upsert OK: versionId=%s chunks=%d collection=%s",
        version_id, len(chunks), COLLECTION_NAME,
    )


def search(
    query_embedding: list[float],
    allowed_version_ids: list[UUID],
    top_k: int = 5,
    machine_code: str | None = None,
) -> list[dict[str, Any]]:
    """Truy vấn top-k chunk với filter version_id ∈ allowed_version_ids."""
    collection = _get_collection()

    # Chroma where filter: version_id phải nằm trong danh sách cho phép
    where_clauses: list[dict[str, Any]] = []
    
    if len(allowed_version_ids) == 1:
        where_clauses.append({"version_id": str(allowed_version_ids[0])})
    else:
        where_clauses.append({"version_id": {"$in": [str(v) for v in allowed_version_ids]}})
        
    if machine_code:
        where_clauses.append({"machineCode": machine_code})
        
    where = {"$and": where_clauses} if len(where_clauses) > 1 else where_clauses[0]

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        where=where,
        include=["documents", "metadatas", "distances"],
    )

    hits: list[dict[str, Any]] = []
    docs = results.get("documents", [[]])[0]
    metas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    for doc, meta, dist in zip(docs, metas, distances):
        # Chuyển cosine distance [0,2] → similarity [1, -1]; clip về [0,1]
        similarity = max(0.0, 1.0 - dist)
        hits.append(
            {
                "text": doc,
                "page_no": meta.get("page_no"),
                "version_id": meta.get("version_id"),
                "document_id": meta.get("document_id"),
                "chunk_index": meta.get("chunk_index"),
                "bbox": meta.get("bbox", ""),
                "image_path": meta.get("image_path", ""),
                "snippet": meta.get("snippet", ""),
                "title": meta.get("title", ""),
                "category": meta.get("category", ""),
                "score": round(similarity, 4),
            }
        )

    # Đã sắp xếp theo distance tăng dần → similarity giảm dần (tốt nhất trước)
    return hits


def search_selected_text(
    question: str,
    allowed_version_ids: list[UUID],
    top_k: int = 5,
    machine_code: str | None = None,
) -> list[dict[str, Any]]:
    """Rank chunks from explicitly selected documents without loading an embed model."""
    import re
    import unicodedata

    collection = _get_collection()
    version_values = [str(value) for value in allowed_version_ids]
    version_filter: dict[str, Any]
    if len(version_values) == 1:
        version_filter = {"version_id": version_values[0]}
    else:
        version_filter = {"version_id": {"$in": version_values}}

    clauses = [version_filter]
    if machine_code:
        clauses.append({"machineCode": machine_code})
    where = {"$and": clauses} if len(clauses) > 1 else clauses[0]

    results = collection.get(where=where, include=["documents", "metadatas"])

    def tokens(value: str) -> set[str]:
        normalized = unicodedata.normalize("NFKD", value.lower())
        plain = "".join(char for char in normalized if not unicodedata.combining(char))
        return {token for token in re.findall(r"\w+", plain) if len(token) > 1}

    question_tokens = tokens(question)
    hits: list[dict[str, Any]] = []
    for doc, meta in zip(results.get("documents", []), results.get("metadatas", [])):
        overlap = len(question_tokens & tokens(doc or ""))
        # The user explicitly selected these versions, so a generic summary
        # request must still pass the relevance guardrail.
        score = min(0.95, 0.65 + overlap * 0.05)
        hits.append(
            {
                "text": doc,
                "page_no": meta.get("page_no"),
                "version_id": meta.get("version_id"),
                "document_id": meta.get("document_id"),
                "chunk_index": meta.get("chunk_index"),
                "bbox": meta.get("bbox", ""),
                "image_path": meta.get("image_path", ""),
                "snippet": meta.get("snippet", ""),
                "title": meta.get("title", ""),
                "category": meta.get("category", ""),
                "score": round(score, 4),
            }
        )

    hits.sort(key=lambda item: (-item["score"], item.get("page_no") or 0, item.get("chunk_index") or 0))
    return hits[:top_k]
