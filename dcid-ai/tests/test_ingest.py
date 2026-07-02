"""POST /ai/ingest — 202 + callback payload đúng shape (mock MinIO + backend client).

TestClient chạy BackgroundTasks đồng bộ ngay sau response → assert được callback.
"""

import io

from fastapi.testclient import TestClient
from pypdf import PdfWriter

from app.schemas import IngestCallback
from app.services import ingest_service

VERSION_ID = "11111111-1111-1111-1111-111111111111"
INGEST_BODY = {
    "versionId": VERSION_ID,
    "documentId": "22222222-2222-2222-2222-222222222222",
    "storageKey": "documents/x/v1/original.pdf",
    "langs": ["vi"],
    "metadata": {"title": "Manual test"},
}


def _make_pdf(num_pages: int) -> bytes:
    writer = PdfWriter()
    for _ in range(num_pages):
        writer.add_blank_page(width=595, height=842)
    buf = io.BytesIO()
    writer.write(buf)
    return buf.getvalue()


def test_ingest_success_sends_ready_callback(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    sent: list[IngestCallback] = []
    monkeypatch.setattr(
        ingest_service.minio_client, "get_object", lambda storage_key: _make_pdf(3)
    )
    monkeypatch.setattr(
        ingest_service.backend_client, "post_ingest_callback", sent.append
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)

    assert response.status_code == 202
    assert response.json() == {"accepted": True}

    assert len(sent) == 1
    cb = sent[0]
    assert str(cb.versionId) == VERSION_ID
    assert cb.status == "READY"
    assert cb.pageCount == 3
    assert cb.error is None
    assert len(cb.pages) == 3
    first = cb.pages[0]
    assert first.pageNo == 1
    assert first.imageKey is None
    assert first.width is None and first.height is None
    assert first.ocrText == "[skeleton] chưa OCR"
    # camelCase khớp contract từng ký tự
    payload = cb.model_dump()
    assert set(payload) == {"versionId", "status", "pageCount", "pages", "error"}
    assert set(payload["pages"][0]) == {"pageNo", "imageKey", "width", "height", "ocrText"}


def test_ingest_minio_error_sends_failed_callback(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    def boom(storage_key: str) -> bytes:
        raise ConnectionError("MinIO unreachable")

    sent: list[IngestCallback] = []
    monkeypatch.setattr(ingest_service.minio_client, "get_object", boom)
    monkeypatch.setattr(
        ingest_service.backend_client, "post_ingest_callback", sent.append
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)

    assert response.status_code == 202
    assert len(sent) == 1
    cb = sent[0]
    assert cb.status == "FAILED"
    assert cb.pageCount is None
    assert cb.pages == []
    assert cb.error is not None and "MinIO unreachable" in cb.error


def test_ingest_callback_failure_does_not_crash(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    """BE không phản hồi → chỉ log, service vẫn trả 202 và không raise."""

    def callback_boom(payload: IngestCallback) -> None:
        raise ConnectionError("backend down")

    monkeypatch.setattr(
        ingest_service.minio_client, "get_object", lambda storage_key: _make_pdf(1)
    )
    monkeypatch.setattr(
        ingest_service.backend_client, "post_ingest_callback", callback_boom
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)
    assert response.status_code == 202  # không exception nào thoát ra ngoài
