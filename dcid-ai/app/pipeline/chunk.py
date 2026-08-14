"""Chunking văn bản OCR — layout-aware (T2).

Thuật toán:
- Tách text thành các *block* (đoạn/bảng) bằng blank line.
- Block bảng (pipe | hoặc dấu phân cách dashes/─) → giữ nguyên 1 chunk (không cắt giữa bảng).
- Block text thường → sliding window MAX_WORDS từ, overlap OVERLAP_WORDS từ.

Tham số mặc định được chọn để 1 chunk ≈ 400–512 tokens (multilingual-e5-small max 512).
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from app.pipeline.ocr import PageOcr

# ────────────────────────────────────────────────────────────────
# Tham số chunking
# ────────────────────────────────────────────────────────────────
MAX_WORDS = 400       # 1 chunk tối đa ~400 từ  ≈ ~512 token BPE (safe margin)
OVERLAP_WORDS = 60    # overlap giữa 2 chunk liền kề (context bridge)
MIN_CHUNK_WORDS = 10  # bỏ chunk quá ngắn (header rỗng, số trang…)

# Pattern nhận dạng dòng bảng: chứa ít nhất 2 ký tự `|` HOẶC toàn `─ ─`
_TABLE_ROW_RE = re.compile(r"(\|.*\|)|(^[-─+|]{3,}$)", re.MULTILINE)


@dataclass
class Chunk:
    """Một chunk văn bản kèm vị trí nguồn và cấu trúc không gian (dùng để sinh metadata Qdrant & citation)."""

    text: str
    page_no: int
    chunk_index: int  # index toàn document (không reset theo trang)
    bbox: str | None = None  # Tọa độ gộp [min_x, min_y, max_x, max_y] của các bbox trong chunk
    snippet: str | None = None  # Tóm tắt / câu đầu cho trích dẫn (300 ký tự)


# ────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────

def chunk_pages(
    pages: list[PageOcr],
    max_words: int = MAX_WORDS,
    overlap_words: int = OVERLAP_WORDS,
) -> list[Chunk]:
    """Chia toàn bộ `pages` thành `list[Chunk]` kèm cấu trúc không gian (layout & Bbox)."""
    chunks: list[Chunk] = []
    chunk_idx = 0
    carry_words: list[str] = []
    carry_page: int = 1
    carry_boxes: list[tuple[float, float, float, float]] = []

    for page in pages:
        text = (page.text or "").strip()
        if not text:
            continue

        page_boxes = page.boxes or []
        blocks = _split_blocks(text)

        for block in blocks:
            block = block.strip()
            if not block:
                continue

            # Lấy union bbox cho trang hiện tại nếu có
            page_bbox_str = None
            if page_boxes:
                min_x = min(b[0] for b in page_boxes)
                min_y = min(b[1] for b in page_boxes)
                max_x = max(b[2] for b in page_boxes)
                max_y = max(b[3] for b in page_boxes)
                page_bbox_str = f"{min_x:.1f},{min_y:.1f},{max_x:.1f},{max_y:.1f}"

            if _is_table(block):
                # ── Bảng: flush carry trước, rồi đưa toàn bộ bảng thành 1 chunk có cấu trúc ──
                if carry_words:
                    c = _make_chunk(carry_words, carry_page, chunk_idx, boxes=carry_boxes)
                    if c:
                        chunks.append(c)
                        chunk_idx += 1
                    carry_words = []
                    carry_boxes = []

                # Cấu trúc hóa Markdown bảng kèm tọa độ không gian (Bbox)
                structured_text = f"### [Bảng kỹ thuật - Trang {page.page_no} | Bbox: {page_bbox_str or 'N/A'}]\n{block}"
                c = _make_chunk(structured_text.split(), page.page_no, chunk_idx, force=True, boxes=page_boxes, raw_structured=structured_text)
                if c:
                    chunks.append(c)
                    chunk_idx += 1

            else:
                # ── Text thường: nối vào carry, cắt theo sliding-window ──
                words = block.split()
                if not carry_words:
                    carry_page = page.page_no
                carry_words.extend(words)
                if page_boxes:
                    carry_boxes.extend(page_boxes)

                while len(carry_words) >= max_words:
                    window = carry_words[:max_words]
                    c = _make_chunk(window, carry_page, chunk_idx, boxes=carry_boxes)
                    if c:
                        chunks.append(c)
                        chunk_idx += 1
                    carry_words = carry_words[max_words - overlap_words:]
                    # Giữ lại overlap boxes tương ứng
                    if carry_boxes and len(carry_boxes) >= max_words:
                        carry_boxes = carry_boxes[max_words - overlap_words:]

    # ── Flush phần còn lại ──────────────────────────────────────
    if carry_words:
        last_page = next((p.page_no for p in reversed(pages) if (p.text or "").strip()), 1)
        c = _make_chunk(carry_words, last_page, chunk_idx, boxes=carry_boxes)
        if c:
            chunks.append(c)

    return chunks


# ────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────

def _split_blocks(text: str) -> list[str]:
    """Tách text thành block bằng dòng trắng (≥1 blank line)."""
    return re.split(r"\n{2,}", text)


def _is_table(block: str) -> bool:
    """Trả True nếu block trông như bảng (pipe-delimited hoặc dashes separator)."""
    matching_lines = sum(1 for line in block.splitlines() if _TABLE_ROW_RE.search(line))
    return matching_lines >= 2


def _make_chunk(
    words: list[str],
    page_no: int,
    chunk_index: int,
    force: bool = False,
    boxes: list[tuple[float, float, float, float]] | None = None,
    raw_structured: str | None = None,
) -> Chunk | None:
    """Tạo Chunk từ danh sách từ kèm tọa độ Bbox tổng hợp và đoạn snippet tóm tắt."""
    if not force and len(words) < MIN_CHUNK_WORDS:
        return None

    if raw_structured:
        text = raw_structured
    else:
        raw_text = " ".join(words)
        # Gom nhóm cấu trúc hóa theo không gian / trang
        bbox_str = "N/A"
        if boxes:
            min_x = min(b[0] for b in boxes)
            min_y = min(b[1] for b in boxes)
            max_x = max(b[2] for b in boxes)
            max_y = max(b[3] for b in boxes)
            bbox_str = f"{min_x:.1f},{min_y:.1f},{max_x:.1f},{max_y:.1f}"
        text = f"### [Đoạn kỹ thuật - Trang {page_no} | Bbox: {bbox_str}]\n{raw_text}"

    # Tính toán union bbox cho metadata
    final_bbox = None
    if boxes:
        min_x = min(b[0] for b in boxes)
        min_y = min(b[1] for b in boxes)
        max_x = max(b[2] for b in boxes)
        max_y = max(b[3] for b in boxes)
        final_bbox = f"{min_x:.1f},{min_y:.1f},{max_x:.1f},{max_y:.1f}"

    # Snippet trích dẫn (250-300 ký tự không lấy header ###)
    clean_snippet = re.sub(r"^###\s*\[.*?\]\s*\n*", "", text).strip()
    snippet = clean_snippet[:300] if clean_snippet else text[:300]

    return Chunk(
        text=text,
        page_no=page_no,
        chunk_index=chunk_index,
        bbox=final_bbox,
        snippet=snippet,
    )
