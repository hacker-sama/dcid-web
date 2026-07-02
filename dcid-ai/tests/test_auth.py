"""Token guard: thiếu/sai X-Internal-Token → 401 cho ingest & query."""

import pytest
from fastapi.testclient import TestClient

QUERY_BODY = {
    "question": "test",
    "topK": 5,
    "allowedVersionIds": ["11111111-1111-1111-1111-111111111111"],
    "machineCode": None,
}
INGEST_BODY = {
    "versionId": "11111111-1111-1111-1111-111111111111",
    "documentId": "22222222-2222-2222-2222-222222222222",
    "storageKey": "documents/x/v1/original.pdf",
    "langs": ["vi"],
    "metadata": {},
}


@pytest.mark.parametrize(
    ("path", "body"),
    [("/ai/query", QUERY_BODY), ("/ai/ingest", INGEST_BODY)],
)
def test_missing_token_returns_401(client: TestClient, path: str, body: dict) -> None:
    response = client.post(path, json=body)
    assert response.status_code == 401


@pytest.mark.parametrize(
    ("path", "body"),
    [("/ai/query", QUERY_BODY), ("/ai/ingest", INGEST_BODY)],
)
def test_wrong_token_returns_401(client: TestClient, path: str, body: dict) -> None:
    response = client.post(path, json=body, headers={"X-Internal-Token": "wrong-token"})
    assert response.status_code == 401
