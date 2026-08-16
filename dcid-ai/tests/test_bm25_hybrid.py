"""Tests for BM25 Lexical Ranking & Hybrid Search."""

from uuid import uuid4

from app.pipeline import bm25
from app.pipeline import index as index_pipeline


def test_bm25_tokenizer():
    text = "Điện áp cấp cho servo trục X là 220 VAC, áp suất 6.5 bar (Model XK-500)"
    tokens = bm25.tokenize(text)
    assert "220" in tokens
    assert "vac" in tokens
    assert "6.5" in tokens
    assert "bar" in tokens
    assert "xk-500" in tokens or "xk" in tokens


def test_bm25_okapi_scoring():
    corpus = [
        bm25.tokenize("Quy trình thay dầu bôi trơn máy ép thủy lực định kỳ"),
        bm25.tokenize("Thông số điện áp 220V và dòng định mức động cơ servo XK-500"),
        bm25.tokenize("Bản vẽ sơ đồ lắp ráp vòng bi SKF 6204 cho trục chính"),
    ]
    engine = bm25.BM25Okapi(corpus)

    scores_oil = engine.get_scores(bm25.tokenize("thay dầu máy ép"))
    assert scores_oil[0] > scores_oil[1]
    assert scores_oil[0] > scores_oil[2]

    scores_servo = engine.get_scores(bm25.tokenize("điện áp 220V servo"))
    assert scores_servo[1] > scores_servo[0]
    assert scores_servo[1] > scores_servo[2]


def test_bm25_cache_invalidation():
    version_id = uuid4()
    bm25._VERSION_PAYLOAD_CACHE[str(version_id)] = [{"text": "demo"}]
    bm25._VERSION_TOKENIZED_CACHE[str(version_id)] = [["demo"]]

    assert str(version_id) in bm25._VERSION_PAYLOAD_CACHE

    bm25.invalidate_cache(str(version_id))
    assert str(version_id) not in bm25._VERSION_PAYLOAD_CACHE

    bm25._VERSION_PAYLOAD_CACHE[str(version_id)] = [{"text": "demo2"}]
    bm25.invalidate_cache(None)
    assert len(bm25._VERSION_PAYLOAD_CACHE) == 0


def test_search_hybrid_empty():
    res = index_pipeline.search_hybrid(
        query_embedding=None,
        question="điện áp",
        allowed_version_ids=[],
    )
    assert res == []
