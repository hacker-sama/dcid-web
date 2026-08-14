"""Unit checks for the Qdrant index adapter that do not require a live server."""

from uuid import UUID

import pytest

from app.config import get_settings
from app.pipeline import index
from app.pipeline.chunk import Chunk

_REAL_SEARCH = index.search
_REAL_SELECTED_SEARCH = index.search_selected_text


def test_point_id_is_deterministic_and_qdrant_compatible():
    version_id = UUID("11111111-1111-1111-1111-111111111111")
    first = index._point_id(version_id, 2, 3)
    second = index._point_id(version_id, 2, 3)
    assert first == second
    assert UUID(first)
    assert first != index._point_id(version_id, 2, 4)


def test_metadata_normalizes_machine_code_filter_field():
    payload = index._clean_metadata({"machine_code": "CNC-01", "empty": None})
    assert payload["machine_code"] == "CNC-01"
    assert payload["machineCode"] == "CNC-01"
    assert "empty" not in payload


def test_empty_version_filter_does_not_contact_qdrant():
    assert _REAL_SEARCH([0.0] * 384, [], top_k=5) == []
    assert _REAL_SELECTED_SEARCH("test", [], top_k=5) == []


def test_embedding_dimension_is_checked_before_upsert(monkeypatch):
    get_settings.cache_clear()
    chunk = Chunk(page_no=1, chunk_index=0, text="sample", bbox=None, snippet="sample")
    monkeypatch.setattr(index, "_ensure_collection", lambda: pytest.fail("must not contact Qdrant"))

    with pytest.raises(ValueError, match="Embedding dimension"):
        index.upsert_chunks(
            version_id=UUID("11111111-1111-1111-1111-111111111111"),
            document_id=UUID("22222222-2222-2222-2222-222222222222"),
            chunks=[chunk],
            embeddings=[[0.0] * 10],
            metadata={},
        )
