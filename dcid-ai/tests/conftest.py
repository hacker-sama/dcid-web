"""Fixtures chung. Test KHÔNG phụ thuộc mạng/MinIO thật."""

import pytest
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app

TEST_TOKEN = "change-me-internal-token"  # default trong Settings — test không cần .env


@pytest.fixture()
def client() -> TestClient:
    get_settings.cache_clear()
    return TestClient(app)


@pytest.fixture()
def auth_headers() -> dict[str, str]:
    return {"X-Internal-Token": TEST_TOKEN}
