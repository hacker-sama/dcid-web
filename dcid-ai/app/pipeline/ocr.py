"""OCR trang PDF — STUB. Đợt sau: PaddleOCR (VI+EN), render trang bằng poppler."""

from dataclasses import dataclass, field


@dataclass
class PageOcr:
    """Kết quả OCR một trang."""

    page_no: int
    text: str
    width: int | None = None
    height: int | None = None
    # TODO(đợt sau): bbox từng dòng/đoạn để crop citation (contract §3 — crops/{p}-{i}.png)
    boxes: list[tuple[float, float, float, float]] = field(default_factory=list)


def extract_pages(pdf_bytes: bytes, langs: list[str]) -> list[PageOcr]:
    """Render từng trang PDF rồi OCR.

    TODO(đợt sau): poppler (pdf2image) render ảnh → PaddleOCR theo langs (vi/en)
    → upload ảnh trang lên MinIO (documents/{documentId}/v{n}/pages/{p}.png).
    """
    raise NotImplementedError("OCR pipeline chưa triển khai — đợt sau (PaddleOCR)")
