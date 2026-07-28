"""Fixtures chung. Test KHÔNG phụ thuộc mạng/MinIO thật."""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app

TEST_TOKEN = "change-me-internal-token"  # default trong Settings — test không cần .env
VID = "11111111-1111-1111-1111-111111111111"

# ── Mock ChromaDB hits — trả về giả lập kết quả search ──────────────────────
_MOCK_HITS_DEFAULT = [
    {
        "text": "Nội dung tài liệu mock.",
        "page_no": 1,
        "version_id": VID,
        "document_id": "22222222-2222-2222-2222-222222222222",
        "chunk_index": 0,
        "bbox": "",
        "snippet": "[mock snippet]",
        "title": "Tài liệu test",
        "category": "Test",
        "score": 0.75,
    }
]

_MOCK_HITS_NUMERIC = [
    {
        **_MOCK_HITS_DEFAULT[0],
        "score": 0.90,
    }
]


def _mock_search_side_effect(query_embedding, allowed_version_ids, top_k=5):
    """Mock ChromaDB search: trả hits giả tùy ngữ cảnh."""
    # Mặc định trả score 0.75 (dùng cho test_default_mock_answer)
    # score 0.90 dùng cho test_numeric_rule_keywords (query embedding không đọ được ở đây, dùng 0.90 nếu allowed rỗng thì mock không cần)
    # Logic tách hits dựa trên đặc điểm query (thông qua embedding mock hoặc state global nếu cần)
    # Ở đây dùng đơn giản: nếu query_embedding là một list giả định, ta có thể kiểm tra.
    # Với test hiện tại, giả sử các query liên quan đến số sẽ kích hoạt _MOCK_HITS_NUMERIC
    # Cách tốt nhất là mock theo side_effect tùy vào đối tượng gọi
    return _MOCK_HITS_DEFAULT


def _mock_generate_answer(system_prompt, user_prompt, history=None, image_base64=None):
    """Mock LLM: trả câu trả lời giả tùy nội dung prompt."""
    # Phát hiện numeric rule từ system_prompt
    sp_lower = system_prompt.lower()
    if "trích xuất chính xác các con số" in sp_lower or "lưu ý thêm" in sp_lower:
        return "[MOCK-NUMERIC] Điện áp cấp cho servo là 24VDC.", "mock-model"
    # Trích xuất câu hỏi từ user_prompt
    import re
    match = re.search(r"Câu hỏi:\s*(.+?)(?:\n|$)", user_prompt)
    question = match.group(1).strip() if match else user_prompt[:80]
    return f"[MOCK] Trả lời cho câu hỏi: {question}", "mock-model"


@pytest.fixture()
def client() -> TestClient:
    get_settings.cache_clear()
    return TestClient(app)


@pytest.fixture()
def auth_headers() -> dict[str, str]:
    return {"X-Internal-Token": TEST_TOKEN}


@pytest.fixture(autouse=True)
def mock_chroma_and_llm(monkeypatch):
    """Autouse: Mock ChromaDB search + LLM cho mọi test — không cần service thật."""
    monkeypatch.setattr("app.pipeline.index.search", _mock_search_side_effect)
    monkeypatch.setattr("app.clients.llm_client.generate_answer", _mock_generate_answer)
