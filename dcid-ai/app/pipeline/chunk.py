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
    """Một chunk văn bản kèm vị trí nguồn (dùng để sinh metadata Chroma & citation)."""

    text: str
    page_no: int
    chunk_index: int  # index toàn document (không reset theo trang)


# ────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────

def chunk_pages(
    pages: list[PageOcr],
    max_words: int = MAX_WORDS,
    overlap_words: int = OVERLAP_WORDS,
) -> list[Chunk]:
    """Chia toàn bộ `pages` thành `list[Chunk]`.

    Args:
        pages: kết quả OCR từ `ocr.extract_pages()`.
        max_words: số từ tối đa / chunk sliding-window.
        overlap_words: số từ lặp lại giữa 2 chunk liền kề.

    Returns:
        Danh sách Chunk đã được đánh `chunk_index` liên tục toàn document.
    """
    chunks: list[Chunk] = []
    chunk_idx = 0
    # Sliding-window carry-over giữa các trang (context không bị cắt ở ranh giới trang)
    carry_words: list[str] = []

    for page in pages:
        text = (page.text or "").strip()
        if not text:
            continue

        blocks = _split_blocks(text)

        for block in blocks:
            block = block.strip()
            if not block:
                continue

            if _is_table(block):
                # ── Bảng: flush carry trước, rồi đưa toàn bộ bảng thành 1 chunk ──
                if carry_words:
                    c = _make_chunk(carry_words, page.page_no, chunk_idx)
                    if c:
                        chunks.append(c)
                        chunk_idx += 1
                    carry_words = []

                c = _make_chunk(block.split(), page.page_no, chunk_idx, force=True)
                if c:
                    chunks.append(c)
                    chunk_idx += 1

            else:
                # ── Text thường: nối vào carry, cắt theo sliding-window ──
                carry_words.extend(block.split())

                while len(carry_words) >= max_words:
                    window = carry_words[:max_words]
                    c = _make_chunk(window, page.page_no, chunk_idx)
                    if c:
                        chunks.append(c)
                        chunk_idx += 1
                    # Overlap: giữ lại `overlap_words` từ cuối để chunk sau có context
                    carry_words = carry_words[max_words - overlap_words:]

    # ── Flush phần còn lại ──────────────────────────────────────
    if carry_words:
        # Lấy page_no của trang cuối cùng có text
        last_page = next((p.page_no for p in reversed(pages) if (p.text or "").strip()), 1)
        c = _make_chunk(carry_words, last_page, chunk_idx)
        if c:
            chunks.append(c)

    return chunks


# ────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────

def _split_blocks(text: str) -> list[str]:
    """Tách text thành block bằng dòng trắng (≥1 blank line).

    Mỗi block là 1 đoạn văn hoặc 1 bảng liên tục.
    """
    return re.split(r"\n{2,}", text)


def _is_table(block: str) -> bool:
    """Trả True nếu block trông như bảng (pipe-delimited hoặc dashes separator).

    Điều kiện: ít nhất 2 dòng trong block chứa pattern bảng.
    """
    matching_lines = sum(1 for line in block.splitlines() if _TABLE_ROW_RE.search(line))
    return matching_lines >= 2


def _make_chunk(
    words: list[str],
    page_no: int,
    chunk_index: int,
    force: bool = False,
) -> Chunk | None:
    """Tạo Chunk từ danh sách từ; trả None nếu chunk quá ngắn (trừ khi force=True)."""
    if not force and len(words) < MIN_CHUNK_WORDS:
        return None
    return Chunk(
        text=" ".join(words),
        page_no=page_no,
        chunk_index=chunk_index,
    )
