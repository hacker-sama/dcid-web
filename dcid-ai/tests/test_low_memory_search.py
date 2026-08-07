from uuid import uuid4

from app.pipeline import index


class _Collection:
    def get(self, **kwargs):
        return {
            "documents": [
                "Huong dan lap dat truc va can chinh dong tam.",
                "Thong so dien ap cua bo dieu khien.",
            ],
            "metadatas": [
                {"version_id": "v1", "page_no": 1, "chunk_index": 0},
                {"version_id": "v1", "page_no": 2, "chunk_index": 0},
            ],
        }


def test_selected_text_search_ranks_without_embeddings(monkeypatch):
    monkeypatch.setattr(index, "_get_collection", lambda: _Collection())

    hits = index.search_selected_text("cach lap dat truc", [uuid4()], top_k=2)

    assert hits[0]["page_no"] == 1
    assert hits[0]["score"] >= 0.6
