"""GET /ai/health — không cần token, body đúng contract §3."""

from fastapi.testclient import TestClient


def test_health_ok_without_token(client: TestClient) -> None:
    response = client.get("/ai/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "model_loaded": False}
