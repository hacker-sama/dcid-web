import json
from unittest.mock import patch
from uuid import uuid4

from app.schemas import QueryRequest
from app.services.query_service import run_query_stream


def _events(lines):
    return [json.loads(line.removeprefix("data: ").strip()) for line in lines]


def _request(question="dien ap servo truc X"):
    return QueryRequest(
        question=question,
        topK=3,
        allowedVersionIds=[uuid4()],
    )


def test_stream_emits_meta_deltas_and_done_in_order():
    version_id = uuid4()
    hit = {
        "text": "Dien ap servo truc X la 220 VAC.",
        "version_id": str(version_id),
        "page_no": 3,
        "chunk_index": 0,
        "score": 0.85,
    }

    with (
        patch("app.services.query_service.index_pipeline.search", return_value=[hit]),
        patch("app.services.query_service.llm_client.get_model_name", return_value="test-model"),
        patch("app.services.query_service.llm_client.generate_answer_stream", return_value=iter(["220 ", "VAC"])),
    ):
        events = _events(run_query_stream(_request()))

    assert [event["event"] for event in events] == ["meta", "delta", "delta", "done"]
    assert events[0]["confidence"] == 0.85
    assert events[0]["guard"]["locked"] is False
    assert events[0]["citations"][0]["versionId"] == str(version_id)
    assert "".join(event.get("text", "") for event in events) == "220 VAC"


def test_stream_returns_best_effort_for_unrelated_low_memory_result(monkeypatch):
    unrelated_hit = {
        "text": "Quy trinh thay dau hop so.",
        "version_id": str(uuid4()),
        "page_no": 1,
        "chunk_index": 0,
        "score": 0.0,
    }
    monkeypatch.setenv("LOW_MEMORY_QUERY_MODE", "true")
    from app.config import get_settings
    get_settings.cache_clear()

    with (
        patch("app.services.query_service.index_pipeline.search_selected_text", return_value=[unrelated_hit]),
        patch("app.services.query_service.llm_client.generate_answer_stream") as llm_stream,
    ):
        events = _events(run_query_stream(_request()))

    assert [event["event"] for event in events] == ["meta", "delta", "done"]
    assert events[0]["guard"]["locked"] is False
    assert events[1]["text"].startswith("**Câu trả lời tham khảo.**")
    assert "%" not in events[1]["text"]
    llm_stream.assert_called_once()
    get_settings.cache_clear()


def test_stream_returns_answer_below_80_percent_with_warning():
    hit = {
        "text": "Tai lieu co noi dung lien quan mot phan.",
        "version_id": str(uuid4()),
        "page_no": 2,
        "chunk_index": 0,
        "score": 0.79,
    }
    raw_tokens = ["Cau tra loi ", "chua du tin cay"]

    with (
        patch("app.services.query_service.index_pipeline.search", return_value=[hit]),
        patch("app.services.query_service.llm_client.get_model_name", return_value="test-model"),
        patch("app.services.query_service.llm_client.generate_answer_stream", return_value=iter(raw_tokens)),
    ):
        events = _events(run_query_stream(_request("noi dung tai lieu la gi")))

    assert [event["event"] for event in events] == ["meta", "delta", "done"]
    assert events[0]["guard"]["locked"] is False
    assert events[0]["confidence"] == 0.79
    published_text = "".join(event.get("text", "") for event in events)
    assert "".join(raw_tokens) in published_text
    assert published_text.startswith("**Câu trả lời tham khảo.**")
    assert "%" not in published_text

def test_stream_reports_llm_error_after_metadata():
    hit = {
        "text": "Dien ap servo truc X la 220 VAC.",
        "version_id": str(uuid4()),
        "page_no": 3,
        "chunk_index": 0,
        "score": 0.85,
    }

    def fail_stream(*_args, **_kwargs):
        from app.clients.llm_client import LLMInferenceError
        raise LLMInferenceError("timeout")
        yield  # pragma: no cover

    with (
        patch("app.services.query_service.index_pipeline.search", return_value=[hit]),
        patch("app.services.query_service.llm_client.get_model_name", return_value="test-model"),
        patch("app.services.query_service.llm_client.generate_answer_stream", side_effect=fail_stream),
    ):
        events = _events(run_query_stream(_request()))

    assert [event["event"] for event in events] == ["meta", "error", "done"]
    assert events[-1]["model"] == "error-llm-inference"
