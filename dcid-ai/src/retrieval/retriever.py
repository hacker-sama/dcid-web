"""Module Retriever: Hybrid Search / Semantic Search kết hợp Qdrant."""

import logging
from typing import Any, Dict, List, Optional, Tuple

from src.embeddings import embedder
from src.vectordb import vector_store

logger = logging.getLogger("dcid-ai.retriever")


def retrieve_context(
    question: str,
    allowed_version_ids: List[str],
    top_k: int = 5,
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Tạo embedding cho câu hỏi và truy vấn top_k chunks tương đồng từ Qdrant."""
    logger.info("Retrieve context cho cau hoi: '%.60s' top_k=%d", question, top_k)

    query_vec = embedder.embed_query(question)
    hits = vector_store.search_chunks(
        query_embedding=query_vec,
        allowed_version_ids=allowed_version_ids,
        top_k=top_k,
    )

    citations: List[Dict[str, Any]] = []
    for hit in hits:
        citations.append({
            "pageNo": hit.get("page_no"),
            "versionId": hit.get("version_id"),
            "documentId": hit.get("document_id"),
            "bbox": hit.get("bbox", ""),
            "imagePath": hit.get("image_path", ""),
            "snippet": hit.get("snippet", ""),
            "score": hit.get("score", 0.0),
        })

    return hits, citations
