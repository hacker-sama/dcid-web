from uuid import uuid4

from app.pipeline import index

_REAL_SELECTED_SEARCH = index.search_selected_text


def test_selected_text_search_ranks_without_embeddings(monkeypatch):
    payloads = [
        {
            "text": "Huong dan lap dat truc va can chinh dong tam.",
            "version_id": "v1",
            "page_no": 1,
            "chunk_index": 0,
        },
        {
            "text": "Thong so dien ap cua bo dieu khien.",
            "version_id": "v1",
            "page_no": 2,
            "chunk_index": 0,
        },
    ]
    monkeypatch.setattr(index, "_ensure_collection", lambda: None)
    monkeypatch.setattr(index, "_scroll_payloads", lambda _filter: payloads)

    hits = _REAL_SELECTED_SEARCH("cach lap dat truc", [uuid4()], top_k=2)

    assert hits[0]["page_no"] == 1
    assert hits[0]["score"] >= 0.6
    assert len(hits) == 1


def test_selected_text_search_does_not_unlock_unrelated_chunks(monkeypatch):
    payloads = [
        {
            "text": "Quy trinh thay dau boi tron hop so.",
            "version_id": "v1",
            "page_no": 4,
            "chunk_index": 0,
        },
    ]
    monkeypatch.setattr(index, "_ensure_collection", lambda: None)
    monkeypatch.setattr(index, "_scroll_payloads", lambda _filter: payloads)

    hits = _REAL_SELECTED_SEARCH("dien ap servo truc X", [uuid4()])

    assert hits == []
    assert index._lexical_score(index._tokens("dien ap servo truc X"), payloads[0]) == 0.0


def test_selected_text_search_uses_title_metadata(monkeypatch):
    payloads = [
        {
            "text": "220 VAC, 3 pha.",
            "title": "Thong so dien ap servo truc X",
            "version_id": "v1",
            "page_no": 2,
            "chunk_index": 0,
        },
    ]
    monkeypatch.setattr(index, "_ensure_collection", lambda: None)
    monkeypatch.setattr(index, "_scroll_payloads", lambda _filter: payloads)

    hits = _REAL_SELECTED_SEARCH("dien ap servo truc X", [uuid4()])

    assert hits[0]["score"] >= 0.6
