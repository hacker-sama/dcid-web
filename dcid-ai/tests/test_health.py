"""GET /ai/health — không cần token, body đúng contract §3."""

from fastapi.testclient import TestClient


def test_health_ok_without_token(client: TestClient) -> None:
    response = client.get("/ai/health")
    assert response.status_code == 200
    body = response.json()
    # Chỉ kiểm tra schema — model_loaded phụ thuộc môi trường (LM Studio có chạy hay không)
    assert body["status"] == "ok"
    assert isinstance(body["model_loaded"], bool)
