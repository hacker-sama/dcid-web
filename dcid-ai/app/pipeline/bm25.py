"""BM25 Lexical Ranking Engine with High-Performance In-Memory Version Caching.

Provides exact keyword, code, technical unit, and parameter matching
alongside dense semantic retrieval.
"""

from __future__ import annotations

import logging
import math
import re
import unicodedata
from typing import Any
from uuid import UUID

logger = logging.getLogger("dcid-ai.bm25")

# Common conversational stopwords (Vietnamese and English)
BM25_STOP_WORDS = {
    "ai", "bao", "cac", "cho", "co", "cua", "duoc", "gi", "hay", "la",
    "mot", "nao", "nhieu", "nhung", "o", "the", "thi", "tren", "va", "voi",
    "what", "which", "the", "this", "that", "is", "are", "of", "to", "for",
    "in", "on", "at", "by", "an", "and", "or",
}

# Per-version cache: version_id -> list of raw payloads from Qdrant
_VERSION_PAYLOAD_CACHE: dict[str, list[dict[str, Any]]] = {}
# Per-version cache: version_id -> list of tokenized word lists for BM25
_VERSION_TOKENIZED_CACHE: dict[str, list[list[str]]] = {}


def tokenize(text: str) -> list[str]:
    """Tokenize technical Vietnamese/English text while preserving machine codes & numbers."""
    if not text:
        return []
    normalized = unicodedata.normalize("NFKD", text.lower())
    # Keep alphanumeric characters, dots, dashes for technical codes
    plain = "".join(char for char in normalized if not unicodedata.combining(char))
    tokens = re.findall(r"[\w.-]+", plain)
    return [
        token.strip(".-")
        for token in tokens
        if len(token.strip(".-")) > 1 and token.strip(".-") not in BM25_STOP_WORDS
    ]


class BM25Okapi:
    """Standard Okapi BM25 implementation optimized for Python execution."""

    def __init__(self, corpus: list[list[str]], k1: float = 1.5, b: float = 0.75):
        self.k1 = k1
        self.b = b
        self.corpus_size = len(corpus)
        self.avgdl = sum(len(doc) for doc in corpus) / max(1, self.corpus_size)
        self.doc_lengths = [len(doc) for doc in corpus]
        self.doc_freqs: list[dict[str, int]] = []
        self.idf: dict[str, float] = {}
        self._initialize(corpus)

    def _initialize(self, corpus: list[list[str]]) -> None:
        df: dict[str, int] = {}
        for doc in corpus:
            frequencies: dict[str, int] = {}
            for word in doc:
                frequencies[word] = frequencies.get(word, 0) + 1
            self.doc_freqs.append(frequencies)
            for word in frequencies:
                df[word] = df.get(word, 0) + 1

        for word, freq in df.items():
            # Standard Lucene/BM25 IDF formula with smoothing
            self.idf[word] = math.log(1.0 + (self.corpus_size - freq + 0.5) / (freq + 0.5))

    def get_scores(self, query: list[str]) -> list[float]:
        scores = [0.0] * self.corpus_size
        for term in query:
            if term not in self.idf:
                continue
            idf_val = self.idf[term]
            for idx, doc_freq in enumerate(self.doc_freqs):
                if term not in doc_freq:
                    continue
                tf = doc_freq[term]
                numerator = idf_val * tf * (self.k1 + 1.0)
                denominator = tf + self.k1 * (1.0 - self.b + self.b * (self.doc_lengths[idx] / max(1.0, self.avgdl)))
                scores[idx] += numerator / max(0.0001, denominator)
        return scores


def invalidate_cache(version_id: str | None = None) -> None:
    """Invalidate cache for a specific version or clear all caches."""
    if version_id:
        _VERSION_PAYLOAD_CACHE.pop(str(version_id), None)
        _VERSION_TOKENIZED_CACHE.pop(str(version_id), None)
        logger.debug("BM25 cache invalidated for version_id=%s", version_id)
    else:
        _VERSION_PAYLOAD_CACHE.clear()
        _VERSION_TOKENIZED_CACHE.clear()
        logger.debug("BM25 entire cache cleared")


def _get_version_chunks(version_id: str) -> tuple[list[dict[str, Any]], list[list[str]]]:
    """Retrieve and cache payloads + tokenized tokens for a single version_id."""
    v_str = str(version_id)
    if v_str in _VERSION_PAYLOAD_CACHE and v_str in _VERSION_TOKENIZED_CACHE:
        return _VERSION_PAYLOAD_CACHE[v_str], _VERSION_TOKENIZED_CACHE[v_str]

    from app.pipeline import index as index_pipeline
    from qdrant_client import models

    query_filter = models.Filter(
        must=[models.FieldCondition(key="version_id", match=models.MatchValue(value=v_str))]
    )
    payloads = index_pipeline._scroll_payloads(query_filter)
    tokenized_docs: list[list[str]] = []

    for p in payloads:
        combined_text = " ".join([
            str(p.get("title") or ""),
            str(p.get("text") or ""),
            str(p.get("machineCode") or p.get("machine_code") or ""),
            str(p.get("category") or ""),
        ])
        tokenized_docs.append(tokenize(combined_text))

    _VERSION_PAYLOAD_CACHE[v_str] = payloads
    _VERSION_TOKENIZED_CACHE[v_str] = tokenized_docs
    logger.debug("Cached %d chunks for version_id=%s in BM25 index", len(payloads), v_str)
    return payloads, tokenized_docs


def search_bm25(
    question: str,
    allowed_version_ids: list[UUID | str],
    top_k: int = 5,
    machine_code: str | None = None,
    k1: float = 1.5,
    b: float = 0.75,
) -> list[dict[str, Any]]:
    """Run fast BM25 ranking across cached chunks of the allowed versions."""
    if not allowed_version_ids:
        return []

    from app.pipeline import index as index_pipeline

    all_payloads: list[dict[str, Any]] = []
    all_tokens: list[list[str]] = []

    for v_id in allowed_version_ids:
        p_list, t_list = _get_version_chunks(str(v_id))
        all_payloads.extend(p_list)
        all_tokens.extend(t_list)

    if not all_payloads or not all_tokens:
        return []

    # Optional machineCode filtering
    if machine_code:
        filtered_payloads = []
        filtered_tokens = []
        for p, t in zip(all_payloads, all_tokens):
            p_mcode = str(p.get("machineCode") or p.get("machine_code") or "")
            if p_mcode == str(machine_code):
                filtered_payloads.append(p)
                filtered_tokens.append(t)
        all_payloads = filtered_payloads
        all_tokens = filtered_tokens
        if not all_payloads:
            return []

    query_tokens = tokenize(question)
    if not query_tokens:
        return []

    bm25 = BM25Okapi(all_tokens, k1=k1, b=b)
    raw_scores = bm25.get_scores(query_tokens)

    max_score = max(raw_scores) if raw_scores else 0.0
    if max_score <= 0.0:
        return []

    hits: list[dict[str, Any]] = []
    for payload, score in zip(all_payloads, raw_scores):
        if score > 0.0:
            # Scale score to [0.30, 0.98] to align with guardrail confidence expectations
            normalized_score = min(0.98, max(0.30, 0.40 + 0.58 * (score / max_score)))
            hit = index_pipeline._payload_to_hit(payload, normalized_score)
            hit["bm25_raw_score"] = round(score, 4)
            hits.append(hit)

    hits.sort(key=lambda h: (-h["score"], h.get("page_no") or 0, h.get("chunk_index") or 0))
    return hits[:top_k]
