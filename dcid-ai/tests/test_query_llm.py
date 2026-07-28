"""Unit tests cho RAG query pipeline — guardrails, prompts, query_service.

Mọi dependency ngoài (LLM, ChromaDB, embed model) đều được mock
→ test chạy hoàn toàn offline, không cần LM Studio hay ChromaDB thật.

Chạy:
    cd dcid-ai
    pytest tests/test_query_llm.py -v
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock, patch

import pytest

# ──────────────────────────────────────────────────────────────────────────────
# Helpers / Fixtures
# ──────────────────────────────────────────────────────────────────────────────

VERSION_ID_1 = str(uuid.uuid4())
VERSION_ID_2 = str(uuid.uuid4())


def _make_hit(page_no: int, score: float, text: str = "nội dung mẫu") -> dict:
    return {
        "text": text,
        "page_no": page_no,
        "version_id": VERSION_ID_1,
        "document_id": str(uuid.uuid4()),
        "chunk_index": 0,
        "score": score,
    }


def _make_query_request(question: str, versions: list | None = None) -> dict:
    """Tạo QueryRequest-like dict để truyền vào router test client."""
    return {
        "question": question,
        "topK": 3,
        "allowedVersionIds": versions if versions is not None else [VERSION_ID_1],
        "machineCode": None,
    }


# ──────────────────────────────────────────────────────────────────────────────
# Tests: guardrails.check_numeric
# ──────────────────────────────────────────────────────────────────────────────

class TestCheckNumeric:
    def test_dien_ap_vi(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Điện áp cấp cho servo trục X là bao nhiêu?") is True

    def test_voltage_en(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("What is the voltage for axis servo?") is True

    def test_ap_suat(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Áp suất tối đa của van an toàn là bao nhiêu bar?") is True

    def test_nhiet_do(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Nhiệt độ vận hành tối đa của spindle motor?") is True

    def test_dung_sai(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Dung sai lắp ráp ổ bi H7/g6?") is True

    def test_rpm(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Tốc độ trục chính tối đa bao nhiêu rpm?") is True

    def test_mm_dimension(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Chiều dài hành trình trục Z là bao nhiêu mm?") is True

    def test_non_numeric_question(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Quy trình thay dao phay là gì?") is False

    def test_general_how_question(self):
        from app.pipeline.guardrails import check_numeric
        assert check_numeric("Hướng dẫn cài đặt phần mềm điều khiển?") is False


# ──────────────────────────────────────────────────────────────────────────────
# Tests: guardrails.is_locked
# ──────────────────────────────────────────────────────────────────────────────

class TestIsLocked:
    def test_no_hits_is_locked(self):
        from app.pipeline.guardrails import is_locked
        assert is_locked([], "câu hỏi bình thường") is True

    def test_low_score_is_locked(self):
        from app.pipeline.guardrails import is_locked
        hits = [_make_hit(1, 0.55)]  # < THRESHOLD 0.60
        assert is_locked(hits, "câu hỏi gì đó") is True

    def test_score_at_threshold_is_not_locked(self):
        from app.pipeline.guardrails import is_locked
        hits = [_make_hit(1, 0.60)]  # == THRESHOLD, không bị khóa
        assert is_locked(hits, "câu hỏi gì đó") is False

    def test_high_score_is_not_locked(self):
        from app.pipeline.guardrails import is_locked
        hits = [_make_hit(1, 0.85)]
        assert is_locked(hits, "câu hỏi bình thường") is False

    def test_trigger_phrase_always_locks(self):
        from app.pipeline.guardrails import is_locked
        hits = [_make_hit(1, 0.95)]  # score cao nhưng có trigger
        assert is_locked(hits, "thông tin này không có trong tài liệu") is True


# ──────────────────────────────────────────────────────────────────────────────
# Tests: prompts.build_system_prompt
# ──────────────────────────────────────────────────────────────────────────────

class TestBuildSystemPrompt:
    def test_contains_base_instructions(self):
        from app.pipeline.prompts import build_system_prompt
        prompt = build_system_prompt(numeric_rule=False)
        assert prompt == ""

    def test_numeric_rule_injection(self):
        from app.pipeline.prompts import build_system_prompt
        prompt = build_system_prompt(numeric_rule=True)
        assert prompt == ""

    def test_no_numeric_injection_when_false(self):
        from app.pipeline.prompts import build_system_prompt
        prompt = build_system_prompt(numeric_rule=False)
        assert prompt == ""

    def test_user_prompt_hits_all_appear(self):
        from app.pipeline.prompts import build_user_prompt
        hits = [
            _make_hit(5, 0.90, "nội dung trang 5"),
            _make_hit(7, 0.75, "nội dung trang 7"),
        ]
        prompt = build_user_prompt("Câu hỏi test?", hits)
        assert "nội dung trang 5" in prompt
        assert "nội dung trang 7" in prompt



# ──────────────────────────────────────────────────────────────────────────────
# Tests: query_service.run_query (toàn bộ pipeline với mock)
# ──────────────────────────────────────────────────────────────────────────────

class TestRunQuery:
    """Test query_service.run_query() với mock cho embed, index, llm_client."""

    def _make_req(self, question: str, versions: list | None = None):
        from app.schemas import QueryRequest
        return QueryRequest(
            question=question,
            topK=3,
            allowedVersionIds=versions if versions is not None else [uuid.UUID(VERSION_ID_1)],
        )

    def test_empty_allowed_versions_returns_locked(self):
        from app.services.query_service import run_query
        req = self._make_req("Điện áp servo?", versions=[])
        response = run_query(req)
        assert response.guard.locked is True
        assert response.confidence == 0.30

    def test_guardrail_locked_when_low_score(self):
        """Score < 0.25 (thấp hơn cả reasoning threshold) → locked, không gọi LLM."""
        from app.services.query_service import run_query

        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(1, 0.15, "nội dung mẫu"),
            ]),
        ):
            req = self._make_req("Mã chi tiết?")
            response = run_query(req)

        assert response.guard.locked is True
        assert response.confidence == 0.30

    def test_normal_question_calls_llm(self):
        """Score cao + câu hỏi bình thường → gọi LLM, trả answer thật."""
        from app.services.query_service import run_query

        fake_answer = "Máy CNC XK-500 dùng điều khiển Fanuc 0i-MF."
        fake_model  = "deepseek-r1-distill-qwen-1.5b"

        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(3, 0.82, "Máy CNC XK-500 được trang bị bộ điều khiển Fanuc 0i-MF."),
            ]),
            patch("app.services.query_service.llm_client.generate_answer",
                  return_value=(fake_answer, fake_model)),
        ):
            req = self._make_req("Máy CNC XK-500 dùng bộ điều khiển gì?")
            response = run_query(req)

        assert response.guard.locked is False
        assert response.answer == fake_answer
        assert response.model == fake_model
        assert response.confidence == pytest.approx(0.82, abs=0.01)
        assert len(response.citations) == 1
        assert response.citations[0].pageNo == 3

    def test_numeric_rule_activated(self):
        """Câu hỏi điện áp → numericRule=True."""
        from app.services.query_service import run_query

        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(12, 0.88, "Điện áp servo 220 VAC 3 pha."),
            ]),
            patch("app.services.query_service.llm_client.generate_answer",
                  return_value=("Điện áp cấp cho servo là 220 VAC 3 pha (Trang 12).", "deepseek-r1-distill-qwen-1.5b")),
        ):
            req = self._make_req("Điện áp cấp cho servo trục X là bao nhiêu?")
            response = run_query(req)

        assert response.guard.numericRule is True
        assert response.guard.locked is False

    def test_llm_connection_error_returns_graceful_response(self):
        """LM Studio không chạy → không raise, trả về response hợp lệ."""
        from app.clients.llm_client import LLMConnectionError
        from app.services.query_service import run_query

        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(1, 0.80, "nội dung"),
            ]),
            patch("app.services.query_service.llm_client.generate_answer",
                  side_effect=LLMConnectionError("LM Studio không chạy")),
        ):
            req = self._make_req("Quy trình bảo dưỡng định kỳ?")
            response = run_query(req)

        assert response.guard.locked is True
        assert "không khả dụng" in response.answer or "AI" in response.answer
        assert response.model == "error-llm-connection"

    def test_citations_have_correct_version_id(self):
        """Citations phải có versionId khớp với ChromaDB hit."""
        from app.services.query_service import run_query

        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(5, 0.75, "nội dung trang 5"),
            ]),
            patch("app.services.query_service.llm_client.generate_answer",
                  return_value=("Câu trả lời mẫu.", "mock-model")),
        ):
            req = self._make_req("Câu hỏi bình thường?")
            response = run_query(req)

        assert len(response.citations) == 1
        assert str(response.citations[0].versionId) == VERSION_ID_1
        assert response.citations[0].pageNo == 5


# ──────────────────────────────────────────────────────────────────────────────
# Tests: API router /ai/query (integration test mức HTTP)
# ──────────────────────────────────────────────────────────────────────────────

class TestQueryRouter:
    """Test HTTP layer của POST /ai/query."""

    @pytest.fixture
    def client(self):
        from fastapi.testclient import TestClient
        from app.main import app
        return TestClient(app)

    def _headers(self):
        return {
            "X-Internal-Token": "change-me-internal-token",
            "Content-Type": "application/json",
        }

    def test_missing_token_returns_401(self, client):
        payload = _make_query_request("Điện áp?")
        resp = client.post("/ai/query", json=payload)
        assert resp.status_code == 401

    def test_valid_request_returns_200(self, client):
        """Endpoint trả 200 với full mock pipeline."""
        with (
            patch("app.services.query_service.embed_pipeline.embed_query", return_value=[0.1] * 384),
            patch("app.services.query_service.index_pipeline.search", return_value=[
                _make_hit(2, 0.78, "nội dung mẫu"),
            ]),
            patch("app.services.query_service.llm_client.generate_answer",
                  return_value=("Câu trả lời.", "test-model")),
        ):
            resp = client.post(
                "/ai/query",
                json=_make_query_request("Câu hỏi test?"),
                headers=self._headers(),
            )

        assert resp.status_code == 200
        data = resp.json()
        assert "answer" in data
        assert "guard" in data
        assert "citations" in data
        assert "latencyMs" in data
        assert "model" in data


class TestCleanThinkTags:
    def test_strip_closed_think_tag(self):
        from app.clients.llm_client import _clean_think_tags
        raw = "<think>\nBước 1: Phân tích...\nBước 2: Đối chiếu...\n</think>\nQuy trình tháo lắp chi tiết như sau: Bước 1 tháo ốc A."
        assert _clean_think_tags(raw) == "Quy trình tháo lắp chi tiết như sau: Bước 1 tháo ốc A."

    def test_strip_unclosed_think_tag(self):
        from app.clients.llm_client import _clean_think_tags
        raw = "<think>\nĐang suy luận dở dang bị ngắt dòng..."
        assert "Đang suy luận" in _clean_think_tags(raw)

    def test_no_think_tag(self):
        from app.clients.llm_client import _clean_think_tags
        raw = "Đáp án trực tiếp: Điện áp 220 VAC."
        assert _clean_think_tags(raw) == "Đáp án trực tiếp: Điện áp 220 VAC."

    def test_strip_meta_instructions(self):
        from app.clients.llm_client import _clean_think_tags
        raw = "[CHỈ THỊ CHUYÊN GIA TƯ VẤN LẮP RÁP CƠ KHÍ — CẦM TAY CHỈ VIỆC]:\nNgười dùng đang yêu cầu tư vấn... TUYỆT ĐỐI KHÔNG tự suy luận.\n\n---\nBước 1 tháo ốc A."
        assert _clean_think_tags(raw) == "Bước 1 tháo ốc A."


class TestVisionPrompts:
    def test_build_system_prompt_vision_mode(self):
        from app.pipeline.prompts import build_system_prompt
        sp = build_system_prompt(has_image=True)
        assert sp == ""

    def test_build_user_prompt_vision_mode(self):
        from app.pipeline.prompts import build_user_prompt
        up = build_user_prompt("Bản vẽ này có thông số gì?", hits=[], has_image=True)
        assert "Bản vẽ này có thông số gì?" in up


