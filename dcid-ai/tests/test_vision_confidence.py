from unittest.mock import patch
from uuid import UUID

import pytest

from app.pipeline.ocr import PageOcr
from app.schemas import QueryRequest
from app.services.query_service import run_query


def _request(question: str) -> QueryRequest:
    return QueryRequest(
        question=question,
        allowedVersionIds=[],
        imageStorageKey="temp/vision/drawing.png",
    )


def _combined_request(question: str) -> QueryRequest:
    return QueryRequest(
        question=question,
        allowedVersionIds=[UUID("11111111-1111-1111-1111-111111111111")],
        imageStorageKey="temp/vision/drawing.png",
    )


def _run_with_image(question: str, ocr_text: str, answer: str):
    with (
        patch(
            "app.clients.ocr_client.extract_pages",
            return_value=[PageOcr(page_no=1, text=ocr_text)],
        ),
        patch(
            "app.clients.minio_client.get_object_base64",
            return_value="data:image/jpeg;base64,abc",
        ),
        patch(
            "app.services.query_service.llm_client.generate_answer",
            return_value=(answer, "vision-test-model"),
        ),
    ):
        return run_query(_request(question))


def test_snap_answer_uses_ocr_and_pixel_evidence_for_confidence() -> None:
    response = _run_with_image(
        "Kích thước cụm camera là bao nhiêu?",
        "CAMERA MODULE\n42.15\nUNIT mm\nDRAWING A-102",
        "Kích thước cụm camera là 42.15 mm.",
    )

    assert response.guard.locked is False
    assert response.confidence >= 0.80
    assert response.answer == "Kích thước cụm camera là 42.15 mm."


def test_snap_numeric_conflict_returns_answer_with_warning() -> None:
    response = _run_with_image(
        "Kích thước cụm camera là bao nhiêu?",
        "CAMERA MODULE\n42.15\nUNIT mm\nDRAWING A-102",
        "Kích thước cụm camera là 48 mm.",
    )

    assert response.guard.locked is False
    assert response.confidence <= 0.39
    assert "Kích thước cụm camera là 48 mm." in response.answer
    assert "chưa được OCR/tài liệu xác nhận" in response.answer


def test_snap_vision_only_confidence_is_nonzero_but_conservative() -> None:
    response = _run_with_image(
        "Kích thước cụm camera là bao nhiêu?",
        "[Trang 1 chứa hình ảnh / bản vẽ kỹ thuật - xem ảnh đính kèm]",
        "Kích thước cụm camera là 42.15 mm.",
    )

    assert response.guard.locked is False
    assert response.confidence == pytest.approx(0.55)
    assert "Kích thước cụm camera là 42.15 mm." in response.answer
    assert response.answer.startswith("**Câu trả lời tham khảo.**")
    assert "%" not in response.answer


def test_ocr_content_does_not_change_question_classification() -> None:
    response = _run_with_image(
        "Phân tích bản vẽ này.",
        "CAMERA MODULE\n42.15 mm\nDRAWING A-102",
        "Bản vẽ mô tả cụm camera và kích thước lắp đặt.",
    )

    assert response.guard.numericRule is False


def test_snap_and_retrieved_document_agreement_raises_confidence() -> None:
    hit = {
        "text": "Kích thước danh nghĩa của cụm camera là 42.15 mm.",
        "version_id": "11111111-1111-1111-1111-111111111111",
        "page_no": 3,
        "score": 0.82,
    }
    with (
        patch(
            "app.clients.ocr_client.extract_pages",
            return_value=[PageOcr(page_no=1, text="CAMERA MODULE\n42.15\nUNIT mm")],
        ),
        patch(
            "app.clients.minio_client.get_object_base64",
            return_value="data:image/jpeg;base64,abc",
        ),
        patch("app.services.query_service.index_pipeline.search", return_value=[hit]),
        patch(
            "app.services.query_service.llm_client.generate_answer",
            return_value=("Kích thước cụm camera là 42.15 mm.", "vision-test-model"),
        ),
    ):
        response = run_query(_combined_request("Kích thước cụm camera là bao nhiêu?"))

    assert response.guard.locked is False
    assert 0.84 <= response.confidence <= 0.95
    assert len(response.citations) == 1


def test_snap_and_retrieved_document_numeric_conflict_warns() -> None:
    hit = {
        "text": "Kích thước danh nghĩa của cụm camera là 48 mm.",
        "version_id": "11111111-1111-1111-1111-111111111111",
        "page_no": 3,
        "score": 0.94,
    }
    with (
        patch(
            "app.clients.ocr_client.extract_pages",
            return_value=[PageOcr(page_no=1, text="CAMERA MODULE\n42.15\nUNIT mm")],
        ),
        patch(
            "app.clients.minio_client.get_object_base64",
            return_value="data:image/jpeg;base64,abc",
        ),
        patch("app.services.query_service.index_pipeline.search", return_value=[hit]),
        patch(
            "app.services.query_service.llm_client.generate_answer",
            return_value=("Kích thước cụm camera là 42.15 mm.", "vision-test-model"),
        ),
    ):
        response = run_query(_combined_request("Kích thước cụm camera là bao nhiêu?"))

    assert response.guard.locked is False
    assert response.confidence <= 0.39
    assert "Kích thước cụm camera là 42.15 mm." in response.answer
    assert "chưa được OCR/tài liệu xác nhận" in response.answer
