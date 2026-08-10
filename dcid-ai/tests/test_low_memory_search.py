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
