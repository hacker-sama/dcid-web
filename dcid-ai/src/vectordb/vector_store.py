"""Quản lý ChromaDB Vector Store dạng Persistent Local DB (thư mục chroma_db/)."""

import logging
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict, List, Optional

import chromadb
from chromadb.config import Settings

from src.chunking.chunker import Chunk

logger = logging.getLogger("dcid-ai.vector_store")

COLLECTION_NAME = "dcid_document_chunks"
LOCAL_DB_DIR = "./chroma_db"


@lru_cache(maxsize=1)
def get_chroma_client():
    """Khởi tạo ChromaDB Persistent Client lưu DB vào đĩa ở thư mục ./chroma_db/."""
    db_path = Path(LOCAL_DB_DIR)
    db_path.mkdir(parents=True, exist_ok=True)
    logger.info("Khoi tao ChromaDB Local Persistent Client tai: %s", db_path.resolve())
    return chromadb.PersistentClient(
        path=str(db_path),
        settings=Settings(anonymized_telemetry=False),
    )


def get_collection():
    """Lấy hoặc tạo collection ChromaDB với không gian khoảng cách cosine."""
    client = get_chroma_client()
    return client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )


def upsert_chunks(
    version_id: str,
    document_id: str,
    chunks: List[Chunk],
    embeddings: List[List[float]],
    extra_metadata: Optional[Dict[str, Any]] = None,
) -> None:
    """Upsert các Chunk vào ChromaDB kèm theo Metadata (bao gồm image_path)."""
    if not chunks:
        logger.warning("upsert_chunks: Danh sach chunk rong.")
        return

    if len(chunks) != len(embeddings):
        raise ValueError(f"So chunks ({len(chunks)}) khac so embeddings ({len(embeddings)})")

    collection = get_collection()
    extra_meta = extra_metadata or {}

    ids: List[str] = []
    documents: List[str] = []
    metadatas: List[Dict[str, Any]] = []

    for c in chunks:
        chunk_id = f"{version_id}_p{c.page_no}_c{c.chunk_index}"
        ids.append(chunk_id)
        documents.append(c.text)

        meta = {
            "version_id": str(version_id),
            "document_id": str(document_id),
            "page_no": int(c.page_no),
            "chunk_index": int(c.chunk_index),
            "bbox": str(c.bbox or ""),
            "image_path": str(c.image_path or ""),
            "snippet": str(c.snippet or c.text[:200]),
        }

        for k, v in extra_meta.items():
            if v is not None:
                meta[k] = str(v) if not isinstance(v, (int, float, bool)) else v

        metadatas.append(meta)

    collection.upsert(
        ids=ids,
        documents=documents,
        embeddings=embeddings,
        metadatas=metadatas,
    )

    logger.info("ChromaDB upsert OK: version_id=%s chunks=%d", version_id, len(chunks))


def search_chunks(
    query_embedding: List[float],
    allowed_version_ids: List[str],
    top_k: int = 5,
) -> List[Dict[str, Any]]:
    """Truy vấn top-K chunks tương đồng nhất từ ChromaDB."""
    collection = get_collection()

    where: Dict[str, Any]
    if len(allowed_version_ids) == 1:
        where = {"version_id": str(allowed_version_ids[0])}
    else:
        where = {"version_id": {"$in": [str(v) for v in allowed_version_ids]}}

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        where=where,
        include=["documents", "metadatas", "distances"],
    )

    hits: List[Dict[str, Any]] = []
    docs = results.get("documents", [[]])[0]
    metas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    for doc, meta, dist in zip(docs, metas, distances):
        similarity = max(0.0, 1.0 - dist)
        hits.append({
            "text": doc,
            "page_no": meta.get("page_no"),
            "version_id": meta.get("version_id"),
            "document_id": meta.get("document_id"),
            "chunk_index": meta.get("chunk_index"),
            "bbox": meta.get("bbox", ""),
            "image_path": meta.get("image_path", ""),
            "snippet": meta.get("snippet", ""),
            "score": round(similarity, 4),
        })

    return hits


def delete_document_chunks(
    document_id: Optional[str] = None,
    version_id: Optional[str] = None,
) -> int:
    """Xóa toàn bộ chunks của document_id hoặc version_id trong ChromaDB và dọn dẹp file crops."""
    import os
    collection = get_collection()
    where: Dict[str, Any] = {}
    if document_id:
        where["document_id"] = str(document_id)
    elif version_id:
        where["version_id"] = str(version_id)
    else:
        return 0

    try:
        results = collection.get(where=where, include=["metadatas"])
        metas = results.get("metadatas", []) or []
        crop_files_deleted = 0
        for meta in metas:
            if meta and isinstance(meta, dict):
                img_path = meta.get("image_path")
                if img_path and os.path.exists(img_path):
                    try:
                        os.remove(img_path)
                        crop_files_deleted += 1
                    except Exception as exc:
                        logger.warning("Không thể xóa file crop %s: %s", img_path, exc)

        collection.delete(where=where)
        logger.info(
            "Đã xóa chunks ChromaDB (where=%s) và %d file crops.",
            where, crop_files_deleted,
        )
        return len(metas)
    except Exception as exc:
        logger.error("Lỗi khi xóa chunks ChromaDB cho where=%s: %s", where, exc)
        return 0

