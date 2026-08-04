"""Tests cho pipeline/chunk.py — không cần model AI, không cần Docker.

Chạy: cd dcid-ai && pytest tests/test_chunk.py -v
"""

import pytest

from app.pipeline.chunk import Chunk, _is_table, _split_blocks, chunk_pages
from app.pipeline.ocr import PageOcr


# ─────────────────────────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────────────────────────

def _page(text: str, page_no: int = 1) -> PageOcr:
    return PageOcr(page_no=page_no, text=text)


# ─────────────────────────────────────────────────────────────────
# _is_table
# ─────────────────────────────────────────────────────────────────

class TestIsTable:
    def test_pipe_table_detected(self):
        block = "| Header A | Header B |\n| --- | --- |\n| Val 1 | Val 2 |"
        assert _is_table(block) is True

    def test_single_pipe_not_table(self):
        # Chỉ 1 dòng pipe → chưa đủ điều kiện "bảng"
        block = "Điện áp | 220V"
        assert _is_table(block) is False

    def test_dash_separator_table(self):
        block = "---\n---\n---"
        assert _is_table(block) is True

    def test_plain_text_not_table(self):
        block = "Đây là đoạn văn bản thông thường không có bảng."
        assert _is_table(block) is False


# ─────────────────────────────────────────────────────────────────
# _split_blocks
# ─────────────────────────────────────────────────────────────────

class TestSplitBlocks:
    def test_two_paragraphs(self):
        text = "Đoạn 1.\n\nĐoạn 2."
        blocks = _split_blocks(text)
        assert len(blocks) == 2

    def test_multiple_blank_lines(self):
        text = "A.\n\n\n\nB."
        blocks = _split_blocks(text)
        assert len(blocks) == 2
        assert blocks[0].strip() == "A."

    def test_single_paragraph(self):
        text = "Chỉ có một đoạn duy nhất."
        blocks = _split_blocks(text)
        assert len(blocks) == 1


# ─────────────────────────────────────────────────────────────────
# chunk_pages — logic cơ bản
# ─────────────────────────────────────────────────────────────────

class TestChunkPages:
    def test_empty_pages(self):
        assert chunk_pages([]) == []

    def test_empty_text_page(self):
        chunks = chunk_pages([_page("")])
        assert chunks == []

    def test_short_text_produces_one_chunk(self):
        text = " ".join(["word"] * 50)  # 50 từ < MAX_WORDS=400
        chunks = chunk_pages([_page(text)])
        assert len(chunks) == 1
        assert chunks[0].page_no == 1
        assert chunks[0].chunk_index == 0

    def test_long_text_splits_into_multiple_chunks(self):
        """600 từ > MAX_WORDS=400 → phải có ít nhất 2 chunk."""
        text = " ".join(["word"] * 600)
        chunks = chunk_pages([_page(text)], max_words=400, overlap_words=50)
        assert len(chunks) >= 2

    def test_chunk_index_is_sequential(self):
        """chunk_index phải tăng liên tục không bị lặp."""
        text = " ".join(["word"] * 900)
        chunks = chunk_pages([_page(text)], max_words=400, overlap_words=50)
        indices = [c.chunk_index for c in chunks]
        assert indices == list(range(len(chunks)))

    def test_table_block_kept_intact(self):
        """Bảng phải là 1 chunk độc lập, không bị trộn với text khác."""
        table = "| Col A | Col B |\n| --- | --- |\n| 220V | 6.5A |"
        text = f"Đây là đoạn giới thiệu.\n\n{table}\n\nĐoạn kết."
        chunks = chunk_pages([_page(text)])
        # Phải có chunk nào đó chứa toàn bộ bảng
        table_chunks = [c for c in chunks if "220V" in c.text and "Col A" in c.text]
        assert len(table_chunks) == 1, "Bảng phải được giữ nguyên trong 1 chunk"

    def test_overlap_shares_words(self):
        """Chunk thứ 2 phải overlap với chunk thứ 1 (chia sẻ từ cuối)."""
        max_words = 20
        overlap = 5
        text = " ".join([f"w{i}" for i in range(50)])
        chunks = chunk_pages([_page(text)], max_words=max_words, overlap_words=overlap)
        assert len(chunks) >= 2
        # Từ cuối chunk 0 phải xuất hiện ở đầu chunk 1
        tail_chunk0 = chunks[0].text.split()[-overlap:]
        head_chunk1 = chunks[1].text.split()[:overlap]
        assert tail_chunk0 == head_chunk1

    def test_multi_page_chunk_index_continuous(self):
        """chunk_index phải liên tục qua nhiều trang."""
        page1 = _page(" ".join(["a"] * 50), page_no=1)
        page2 = _page(" ".join(["b"] * 50), page_no=2)
        chunks = chunk_pages([page1, page2])
        indices = [c.chunk_index for c in chunks]
        assert indices == list(range(len(chunks)))

    def test_chunk_has_correct_page_no(self):
        """chunk.page_no phải trỏ đúng trang trong tài liệu."""
        page1 = _page(" ".join(["a"] * 50), page_no=3)
        chunks = chunk_pages([page1])
        assert all(c.page_no == 3 for c in chunks)

    def test_very_short_chunk_skipped(self):
        """Chunk < MIN_CHUNK_WORDS từ phải bị bỏ qua (trừ table force)."""
        # 5 từ — dưới MIN_CHUNK_WORDS=10
        text = "word1 word2 word3 word4 word5"
        chunks = chunk_pages([_page(text)])
        assert chunks == []
