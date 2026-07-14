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

import fitz  # PyMuPDF
import numpy as np
from paddleocr import PaddleOCR

logger = logging.getLogger("dcid-ai.ocr")

RENDER_DPI = 200  # đủ nét để OCR mà không quá nặng (A4 ~1650x2340px)


@dataclass
class PageOcr:
    """Kết quả OCR một trang."""

    page_no: int
    text: str
    width: int | None = None
    height: int | None = None
    # TODO(đợt sau): bbox từng dòng/đoạn để crop citation (contract §3 — crops/{p}-{i}.png)
    boxes: list[tuple[float, float, float, float]] = field(default_factory=list)


@lru_cache(maxsize=4)
def _get_engine(lang: str) -> PaddleOCR:
    """Model PaddleOCR theo ngôn ngữ — tạo 1 lần, cache theo process (init ~1-2s khi
    model đã tải, ~30s nếu tải lần đầu từ CDN PaddleX vào ~/.paddlex/official_models).

    enable_mkldnn=False: BẮT BUỘC — paddlepaddle 3.3.0 (CPU) lỗi runtime khi bật mkldnn
    mặc định trên model PP-OCRv6 trên máy dev (NotImplementedError trong
    onednn_instruction.cc khi convert PIR attribute). Tắt mkldnn né được lỗi này,
    đổi lại chậm hơn dùng mkldnn một chút — chấp nhận được cho ingest (async).
    """
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


def extract_pages(pdf_bytes: bytes, langs: list[str]) -> list[PageOcr]:
    """Render từng trang PDF (PyMuPDF) rồi OCR (PaddleOCR). Lỗi PDF hỏng sẽ raise —
    caller (ingest_service) chuyển thành callback FAILED.
    """
    lang = _pick_lang(langs)
    engine = _get_engine(lang)

    pages: list[PageOcr] = []
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    try:
        matrix = fitz.Matrix(RENDER_DPI / 72, RENDER_DPI / 72)
        for i, page in enumerate(doc, start=1):
            pix = page.get_pixmap(matrix=matrix)
            img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(
                pix.height, pix.width, pix.n
            )
            if pix.n == 4:  # RGBA -> RGB (PaddleOCR không cần kênh alpha)
                img = img[:, :, :3]

            lines: list[str] = []
            for res in engine.predict(img):
                lines.extend(res.get("rec_texts", []))

            pages.append(
                PageOcr(
                    page_no=i,
                    text="\n".join(lines),
                    width=pix.width,
                    height=pix.height,
                )
            )
            logger.debug("OCR trang %d: %d dong", i, len(lines))
    finally:
        doc.close()

    return pages
