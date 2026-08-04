"""POST /ai/query — mock deterministic, schema đúng contract §2.2."""

from fastapi.testclient import TestClient

VID = "11111111-1111-1111-1111-111111111111"
RESPONSE_KEYS = {"answer", "confidence", "guard", "citations", "latencyMs", "model"}


def _post(client: TestClient, headers: dict[str, str], question: str, allowed: list[str]) -> dict:
    response = client.post(
        "/ai/query",
        json={
            "question": question,
            "topK": 5,
            "allowedVersionIds": allowed,
            "machineCode": None,
        },
        headers=headers,
    )
    assert response.status_code == 200
    return response.json()


def _assert_schema(body: dict) -> None:
    assert set(body) == RESPONSE_KEYS
    assert set(body["guard"]) == {"locked", "numericRule", "reasoningMode"}
    assert isinstance(body["latencyMs"], int)
    assert isinstance(body["model"], str) and len(body["model"]) > 0


def test_locked_when_no_allowed_versions(client: TestClient, auth_headers: dict[str, str]) -> None:
    body = _post(client, auth_headers, "Điện áp servo?", [])
    _assert_schema(body)
    assert body["guard"] == {"locked": True, "numericRule": False, "reasoningMode": False}
    assert body["confidence"] == 0.30
    assert body["answer"] == (
        "Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm."
    )
    assert body["citations"] == []


def test_locked_when_question_says_not_in_docs(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    body = _post(client, auth_headers, "Diều này không có trong tài liệu phải không?", [VID])
    assert body["guard"]["locked"] is True
    # Khi locked=True: citations vẫn được trả để người dùng biết tài liệu nào liên quan,
    # nhưng snippet=None để ngăn rò rỉ nội dung bảo mật.
    for c in body["citations"]:
        assert c["snippet"] is None


def test_numeric_rule_keywords(client: TestClient, auth_headers: dict[str, str]) -> None:
    body = _post(client, auth_headers, "Điện áp cấp cho servo?", [VID])
    _assert_schema(body)
    assert body["guard"] == {"locked": False, "numericRule": True, "reasoningMode": False}
    assert body["confidence"] == 0.75  # score từ mock hit
    assert body["answer"].startswith("[MOCK-NUMERIC]")
    # snippet hiện diện vì không locked
    assert body["citations"][0]["versionId"] == VID
    assert body["citations"][0]["snippet"] == "[mock snippet]"


def test_default_mock_answer(client: TestClient, auth_headers: dict[str, str]) -> None:
    question = "Quy trình bảo dưỡng định kỳ máy CNC?"
    body = _post(client, auth_headers, question, [VID])
    _assert_schema(body)
    assert body["guard"] == {"locked": False, "numericRule": False, "reasoningMode": False}
    assert body["confidence"] == 0.75  # score từ mock hit (0.75)
    assert body["citations"][0]["versionId"] == VID
    assert body["citations"][0]["snippet"] == "[mock snippet]"  # không locked nên snippet hiện diện
