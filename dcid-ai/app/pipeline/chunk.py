"""Chunking văn bản OCR — STUB."""

from dataclasses import dataclass

from app.pipeline.ocr import PageOcr


@dataclass
class Chunk:
    """Một chunk văn bản kèm vị trí nguồn (để citation)."""

    text: str
    page_no: int
    chunk_index: int


def chunk_pages(pages: list[PageOcr]) -> list[Chunk]:
    """Cắt text OCR thành chunk chồng lấn.

    TODO(đợt sau): chunk theo đoạn/kích thước token, giữ page_no + chunk_index
    cho metadata Chroma (contract §3).
    """
    raise NotImplementedError("Chunking chưa triển khai — đợt sau")
