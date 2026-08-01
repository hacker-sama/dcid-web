"""OCR trang PDF: PyMuPDF (rasterize PDF → ảnh) + PaddleOCR (nhận diện chữ VI+EN).

Kết quả spike (đo bằng CER trên 8 câu VI+EN có số liệu kỹ thuật, xem
docs/PLAN-THESIS.md mục T1):
- Tiếng Anh: CER 0% (100% chính xác) — kể cả số liệu (220V, 6.5 bar, ±0.02mm).
- Tiếng Việt: CER ~10% (89.6% chính xác), robust trước nhiễu/mờ/nghiêng (CER chỉ
  tăng lên ~11%). Lỗi tập trung ở các nguyên âm có 2 dấu chồng (ậ, ệ, ộ, ố, ị, ắ...)
  vì PaddleOCR gộp "vi" vào model "latin" dùng chung ~50 ngôn ngữ, không phải model
  tiếng Việt chuyên biệt. Dưới ngưỡng KPI 95% của dự án nhưng vẫn đủ dùng cho
  retrieval ở M1 (text lỗi dấu vẫn embed/tìm được, chỉ ảnh hưởng hiển thị/trích dẫn
  nguyên văn). TODO(T2+): thử hybrid PaddleOCR-detection + VietOCR-recognition cho
  các đoạn tiếng Việt, hoặc model PP-OCR bản lớn hơn, để kéo CER xuống dưới 5%.
"""

import logging
from dataclasses import dataclass, field
from functools import lru_cache
from typing import Any

logger = logging.getLogger("dcid-ai.ocr")

RENDER_DPI = 200  # đủ nét để OCR mà không quá nặng (A4 ~1650x2340px)
MAX_SIDE_PIXELS = 2400  # giới hạn cạnh tối đa để tránh tạo ảnh quá lớn (6600x9300+) gây tràn RAM và sập OCR khi xử lý bản vẽ lớn (A0/A1/A2/A3)


@dataclass
class PageOcr:
    """Kết quả OCR một trang."""

    page_no: int
    text: str
    width: int | None = None
    height: int | None = None
    boxes: list[tuple[float, float, float, float]] = field(default_factory=list)
    image_bytes: bytes | None = None


@lru_cache(maxsize=4)
def _get_engine(lang: str) -> Any:
    """Model PaddleOCR theo ngôn ngữ — tạo 1 lần, cache theo process (init ~1-2s khi
    model đã tải, ~30s nếu tải lần đầu từ CDN PaddleX vào ~/.paddlex/official_models).

    enable_mkldnn=False: BẮT BUỘC — paddlepaddle 3.3.0 (CPU) lỗi runtime khi bật mkldnn
    mặc định trên model PP-OCRv6 trên máy dev (NotImplementedError trong
    onednn_instruction.cc khi convert PIR attribute). Tắt mkldnn né được lỗi này,
    đổi lại chậm hơn dùng mkldnn một chút — chấp nhận được cho ingest (async).
    """
    from paddleocr import PaddleOCR

    logger.info("Khoi tao PaddleOCR lang=%s (co the tai model lan dau tu CDN)", lang)
    return PaddleOCR(
        lang=lang,
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
        enable_mkldnn=False,
    )


def _pick_lang(langs: list[str]) -> str:
    """PaddleOCR chỉ nhận 1 lang/engine cho mỗi lần predict. "vi" đã bao gồm khả năng
    đọc chữ Latin cơ bản (kể cả tiếng Anh không dấu) nên ưu tiên "vi" nếu có trong
    danh sách ngôn ngữ tài liệu; nếu không có thì dùng ngôn ngữ đầu tiên, mặc định "en".
    """
    if "vi" in langs:
        return "vi"
    return langs[0] if langs else "en"


def _detect_filetype(data: bytes) -> str:
    if data.startswith(b"%PDF-"):
        return "pdf"
    if data.startswith(b"\x89PNG"):
        return "png"
    if data.startswith(b"\xff\xd8\xff"):
        return "jpg"
    return "pdf"


def extract_pages(pdf_bytes: bytes, langs: list[str] | None = None) -> list[PageOcr]:
    """Trích xuất dữ liệu chữ trực tiếp từ PDF (PyMuPDF / fitz) và render ảnh trang PNG.
    Không chạy qua PaddleOCR để tránh làm méo chữ, làm chậm tiến trình và phụ thuộc ngôn ngữ.
    """
    import fitz  # PyMuPDF

    ftype = _detect_filetype(pdf_bytes)
    pages: list[PageOcr] = []
    doc = fitz.open(stream=pdf_bytes, filetype=ftype)
    try:
        for i, page in enumerate(doc, start=1):
            max_side_pt = max(page.rect.width, page.rect.height)
            scale_dpi = RENDER_DPI / 72.0
            scale_max = MAX_SIDE_PIXELS / max_side_pt if max_side_pt > 0 else scale_dpi
            scale = min(scale_dpi, scale_max)
            matrix = fitz.Matrix(scale, scale)

            pix = page.get_pixmap(matrix=matrix)
            lines: list[str] = []
            boxes: list[tuple[float, float, float, float]] = []

            native_text = page.get_text("text").strip()
            if native_text:
                for b in page.get_text("blocks"):
                    if len(b) >= 7 and b[6] == 0:  # text block
                        txt = str(b[4]).strip()
                        if txt:
                            block_lines = txt.split("\n")
                            lines.extend(block_lines)
                            bbox = (round(float(b[0]), 1), round(float(b[1]), 1), round(float(b[2]), 1), round(float(b[3]), 1))
                            boxes.extend([bbox] * len(block_lines))
                if not lines:
                    lines = native_text.split("\n")
            else:
                lines = [f"[Trang {i} chứa hình ảnh / bản vẽ kỹ thuật - xem ảnh đính kèm]"]

            png_bytes = pix.tobytes("png")

            pages.append(
                PageOcr(
                    page_no=i,
                    text="\n".join(lines),
                    width=pix.width,
                    height=pix.height,
                    boxes=boxes,
                    image_bytes=png_bytes,
                )
            )
            logger.info("Trang %d: Trích xuất %d dòng (%d ký tự) trực tiếp từ PDF", i, len(lines), len(native_text))
    finally:
        doc.close()

    return pages
