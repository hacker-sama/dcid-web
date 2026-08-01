"""Module Chunker: Cắt nhỏ văn bản (Recursive, Layout-aware) và gắn Metadata image_path."""

import logging
from dataclasses import dataclass
from typing import List, Optional, Tuple

from src.ingestion.ocr_engine import PageOcrResult

logger = logging.getLogger("dcid-ai.chunker")

CHUNK_SIZE = 600
CHUNK_OVERLAP = 100


@dataclass
class Chunk:
    """Đối tượng Chunk lưu trữ văn bản kèm Metadata đầy đủ."""
    chunk_index: int
    page_no: int
    text: str
    bbox: Optional[Tuple[float, float, float, float]] = None
    image_path: Optional[str] = None  # Đường dẫn uploads/crops/ cho UI render
    snippet: Optional[str] = None


def chunk_pages(
    pages: List[PageOcrResult],
    chunk_size: int = CHUNK_SIZE,
    chunk_overlap: int = CHUNK_OVERLAP,
) -> List[Chunk]:
    """Cắt nhỏ văn bản từng trang PDF thành các Chunk vừa kích thước."""
    chunks: List[Chunk] = []
    global_idx = 0

    for page in pages:
        if page.image_crops:
            for crop in page.image_crops:
                if crop.visual_caption:
                    crop_text = (
                        f"[MÔ TẢ SƠ ĐỒ/BẢN VẼ - TRANG {page.page_no}]\n"
                        f"{crop.visual_caption}"
                    )
                    chunks.append(
                        Chunk(
                            chunk_index=global_idx,
                            page_no=page.page_no,
                            text=crop_text,
                            bbox=crop.bbox,
                            image_path=crop.image_path,
                            snippet=crop.visual_caption[:150],
                        )
                    )
                    global_idx += 1

        page_text = page.text.strip()
        if not page_text:
            continue

        paragraphs = [p.strip() for p in page_text.split("\n\n") if p.strip()]
        current_chunk_words: List[str] = []
        current_len = 0

        for para in paragraphs:
            para_len = len(para)
            if current_len + para_len > chunk_size and current_chunk_words:
                chunk_str = "\n\n".join(current_chunk_words)
                chunks.append(
                    Chunk(
                        chunk_index=global_idx,
                        page_no=page.page_no,
                        text=chunk_str,
                        bbox=page.boxes[0] if page.boxes else None,
                        image_path=None,
                        snippet=chunk_str[:150],
                    )
                )
                global_idx += 1
                current_chunk_words = [para]
                current_len = para_len
            else:
                current_chunk_words.append(para)
                current_len += para_len

        if current_chunk_words:
            chunk_str = "\n\n".join(current_chunk_words)
            chunks.append(
                Chunk(
                    chunk_index=global_idx,
                    page_no=page.page_no,
                    text=chunk_str,
                    bbox=page.boxes[0] if page.boxes else None,
                    image_path=None,
                    snippet=chunk_str[:150],
                )
            )
            global_idx += 1

    logger.info("Chunking OK: tao ra %d chunks tu %d trang", len(chunks), len(pages))
    return chunks
