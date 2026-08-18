"""POST /ai/ingest — 202 + callback payload đúng shape (mock MinIO + OCR + backend client).

TestClient chạy Celery task đồng bộ (eager mode) -> assert được callback.
OCR (PaddleOCR) được mock — model thật nặng/cần mạng lần đầu, không phù hợp unit test.
"""

import io

from fastapi.testclient import TestClient
from pypdf import PdfWriter

from app.pipeline.ocr import PageOcr
from app.schemas import IngestCallback
from app.workers import embed_worker

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


def _fake_extract_pages(pdf_bytes: bytes, langs: list[str]) -> list[PageOcr]:
    """Giả lập OCR: 1 PageOcr / trang PDF (đếm qua pypdf, không gọi model thật)."""
    from pypdf import PdfReader

    n = len(PdfReader(io.BytesIO(pdf_bytes)).pages)
    return [
        PageOcr(page_no=i, text=f"[fake ocr] trang {i}", width=1653, height=2339)
        for i in range(1, n + 1)
    ]


def test_ingest_success_sends_ready_callback(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    sent: list[IngestCallback] = []
    monkeypatch.setattr("celery.Task.update_state", lambda *args, **kwargs: None)
    monkeypatch.setattr(
        embed_worker.ocr_client,
        "extract_pages",
        lambda storage_key, langs, **_kwargs: _fake_extract_pages(_make_pdf(3), langs),
    )
    monkeypatch.setattr(
        embed_worker.index_pipeline,
        "upsert_chunks",
        lambda *args, **kwargs: 3,
    )
    monkeypatch.setattr(
        embed_worker.embed_pipeline,
        "embed_texts",
        lambda texts: [[0.1] * 384 for _ in texts],
    )
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_callback", sent.append
    )
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_status", lambda payload: None
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)

    assert response.status_code == 202
    assert response.json()["accepted"] is True

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
    assert first.width == 1653 and first.height == 2339
    assert first.ocrText == "[fake ocr] trang 1"
    # camelCase khớp contract từng ký tự
    payload = cb.model_dump()
    assert set(payload) == {"versionId", "status", "pageCount", "pages", "error"}
    assert set(payload["pages"][0]) == {"pageNo", "imageKey", "width", "height", "ocrText"}


def test_ingest_minio_error_sends_failed_callback(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    def boom(storage_key: str, langs: list[str], **_kwargs) -> list[PageOcr]:
        raise ValueError("Corrupt PDF file")

    sent: list[IngestCallback] = []
    monkeypatch.setattr("celery.Task.update_state", lambda *args, **kwargs: None)
    monkeypatch.setattr(embed_worker.ocr_client, "extract_pages", boom)
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_callback", sent.append
    )
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_status", lambda payload: None
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)

    assert response.status_code == 202
    assert len(sent) == 1
    cb = sent[0]
    assert cb.status == "FAILED"
    assert cb.pageCount is None
    assert cb.pages == []
    assert cb.error is not None and "Corrupt PDF file" in cb.error


def test_ingest_callback_failure_does_not_crash(
    client: TestClient, auth_headers: dict[str, str], monkeypatch
) -> None:
    """BE không phản hồi → chỉ log, service vẫn trả 202 và không raise."""

    def callback_boom(payload: IngestCallback) -> None:
        raise ConnectionError("backend down")

    monkeypatch.setattr("celery.Task.update_state", lambda *args, **kwargs: None)
    monkeypatch.setattr(
        embed_worker.ocr_client,
        "extract_pages",
        lambda storage_key, langs, **_kwargs: _fake_extract_pages(_make_pdf(1), langs),
    )
    monkeypatch.setattr(
        embed_worker.index_pipeline,
        "upsert_chunks",
        lambda *args, **kwargs: 1,
    )
    monkeypatch.setattr(
        embed_worker.embed_pipeline,
        "embed_texts",
        lambda texts: [[0.1] * 384 for _ in texts],
    )
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_callback", callback_boom
    )
    monkeypatch.setattr(
        embed_worker.backend_client, "post_ingest_status", lambda payload: None
    )

    response = client.post("/ai/ingest", json=INGEST_BODY, headers=auth_headers)
    assert response.status_code == 202
