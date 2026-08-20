from uuid import UUID

from app.clients import ocr_client
from app.pipeline.ocr import PageOcr, _paddle_payload
from app.schemas import QueryRequest
from app.services import query_service


VERSION_ID = UUID("11111111-1111-1111-1111-111111111111")


def _request(question: str) -> QueryRequest:
    return QueryRequest(
        question=question,
        allowedVersionIds=[VERSION_ID],
        imageStorageKey="temp/vision/drawing.png",
    )


def test_paddle_payload_supports_v3_result_shape() -> None:
    assert _paddle_payload({"res": {"rec_texts": ["42.15"]}}) == {
        "rec_texts": ["42.15"]
    }


def test_text_field_question_prefers_ocr_only() -> None:
    assert query_service._prefers_ocr_only("Tên bản vẽ và tỷ lệ là gì?")
    assert not query_service._needs_visual_context("Tên bản vẽ và tỷ lệ là gì?")


def test_spatial_dimension_question_uses_vision() -> None:
    assert not query_service._prefers_ocr_only("Kích thước của cụm camera là bao nhiêu?")
    assert query_service._needs_visual_context("Kích thước của cụm camera là bao nhiêu?")


def test_generic_drawing_analysis_does_not_auto_load_vision() -> None:
    assert not query_service._needs_visual_context("phan tich tai lieu ban ve")


def test_uploaded_image_ocr_only_skips_base64(monkeypatch) -> None:
    monkeypatch.setattr(
        ocr_client,
        "extract_pages",
        lambda *_args, **_kwargs: [PageOcr(page_no=1, text="PROJECT iPhone 16,2\nSCALE 1:1")],
    )
    monkeypatch.setattr(
        "app.clients.minio_client.get_object_base64",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(AssertionError("vision must be skipped")),
    )

    request = _request("Tên bản vẽ và tỷ lệ là gì?")
    image, text, _ocr_confidence = query_service._prepare_uploaded_image(request)

    assert image is None
    assert "SCALE 1:1" in text
    assert "[Thông tin OCR từ ảnh]" in request.question


def test_uploaded_drawing_uses_ocr_and_vision(monkeypatch) -> None:
    monkeypatch.setattr(
        ocr_client,
        "extract_pages",
        lambda *_args, **_kwargs: [PageOcr(page_no=1, text="42.15\n37.5\nR12.3")],
    )
    captured: dict[str, int] = {}

    def fake_image(_key: str, max_side: int) -> str:
        captured["max_side"] = max_side
        return "data:image/jpeg;base64,abc"

    monkeypatch.setattr("app.clients.minio_client.get_object_base64", fake_image)

    request = _request("Kích thước của cụm camera trên bản vẽ là bao nhiêu?")
    image, text, _ocr_confidence = query_service._prepare_uploaded_image(request)

    assert image == "data:image/jpeg;base64,abc"
    assert "42.15" in text
    assert captured["max_side"] == query_service.VISION_IMAGE_MAX_SIDE


def test_ocr_client_calls_sidecar_and_maps_metadata(monkeypatch) -> None:
    class Response:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict:
            return {
                "pages": [
                    {
                        "pageNo": 1,
                        "text": "DIMENSION 42.15 mm",
                        "width": 1280,
                        "height": 720,
                        "boxes": [[18, 65, 508, 113]],
                        "imageKey": "pages/v1/1.png",
                    }
                ]
            }

    captured: dict = {}

    def fake_post(url, *, json, headers, timeout):
        captured.update(url=url, json=json, headers=headers, timeout=timeout)
        return Response()

    monkeypatch.setattr(ocr_client.httpx, "post", fake_post)
    pages = ocr_client.extract_pages(
        "documents/d1/v1/original.pdf",
        ["vi", "en"],
        image_key_prefix="pages/v1",
    )

    assert captured["url"].endswith("/ocr")
    assert captured["json"]["imageKeyPrefix"] == "pages/v1"
    assert pages[0].text == "DIMENSION 42.15 mm"
    assert pages[0].boxes == [(18.0, 65.0, 508.0, 113.0)]
    assert pages[0].image_key == "pages/v1/1.png"
