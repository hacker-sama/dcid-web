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
import threading
from dataclasses import dataclass, field
from functools import lru_cache
from typing import Any

logger = logging.getLogger("dcid-ai.ocr")

RENDER_DPI = 200  # đủ nét để OCR mà không quá nặng (A4 ~1650x2340px)
MAX_SIDE_PIXELS = 2400  # giới hạn cạnh tối đa để tránh tạo ảnh quá lớn (6600x9300+) gây tràn RAM và sập OCR khi xử lý bản vẽ lớn (A0/A1/A2/A3)
MIN_NATIVE_TEXT_CHARS = 40
MIN_OCR_SCORE = 0.45
MAX_SIDE_PIXELS = min(MAX_SIDE_PIXELS, 1800)
_OCR_LOCK = threading.Lock()


@dataclass
class PageOcr:
    """Kết quả OCR một trang."""

    page_no: int
    text: str
    width: int | None = None
    height: int | None = None
    boxes: list[tuple[float, float, float, float]] = field(default_factory=list)
    image_bytes: bytes | None = None
    image_key: str | None = None


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

    # Mobile models keep OCR memory low enough to coexist with Ollama in Docker.
    rec_model = "latin_PP-OCRv5_mobile_rec" if lang == "vi" else "en_PP-OCRv5_mobile_rec"
    logger.info("Khoi tao PaddleOCR mobile lang=%s rec=%s", lang, rec_model)
    return PaddleOCR(
        text_detection_model_name="PP-OCRv5_mobile_det",
        text_recognition_model_name=rec_model,
        text_recognition_batch_size=1,
        cpu_threads=2,
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


def _paddle_payload(result: Any) -> dict[str, Any]:
    """Return the stable result payload for PaddleOCR 3.x and simple test doubles."""
    value = getattr(result, "json", result)
    if callable(value):
        value = value()
    if isinstance(value, dict) and isinstance(value.get("res"), dict):
        value = value["res"]
    return value if isinstance(value, dict) else {}


def _run_paddle_ocr(pix: Any, langs: list[str]) -> tuple[list[str], list[tuple[float, float, float, float]]]:
    """Run PaddleOCR only for scan/image pages and return filtered text plus pixel bboxes."""
    import numpy as np

    channels = int(getattr(pix, "n", 3))
    image = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, channels)
    if channels == 4:
        image = image[:, :, :3]
    elif channels == 1:
        image = np.repeat(image, 3, axis=2)

    engine = _get_engine(_pick_lang(langs))
    lines: list[str] = []
    boxes: list[tuple[float, float, float, float]] = []

    # Serialize inference so concurrent uploads cannot cause a RAM spike.
    with _OCR_LOCK:
        results = list(engine.predict(image))

    for result in results:
        payload = _paddle_payload(result)
        texts = payload.get("rec_texts") or []
        scores = payload.get("rec_scores") or []
        raw_boxes = payload.get("rec_boxes") or payload.get("rec_polys") or []

        for idx, raw_text in enumerate(texts):
            text = str(raw_text).strip()
            score = float(scores[idx]) if idx < len(scores) else 1.0
            if not text or score < MIN_OCR_SCORE:
                continue
            lines.append(text)

            if idx >= len(raw_boxes):
                continue
            coords = np.asarray(raw_boxes[idx], dtype=float)
            if coords.ndim == 1 and coords.size >= 4:
                x1, y1, x2, y2 = coords[:4]
            elif coords.ndim >= 2 and coords.shape[-1] >= 2:
                x1, y1 = coords[:, 0].min(), coords[:, 1].min()
                x2, y2 = coords[:, 0].max(), coords[:, 1].max()
            else:
                continue
            boxes.append((round(float(x1), 1), round(float(y1), 1), round(float(x2), 1), round(float(y2), 1)))

    return lines, boxes


def extract_pages(pdf_bytes: bytes, langs: list[str] | None = None) -> list[PageOcr]:
    """Hybrid extraction: use embedded PDF text first, PaddleOCR only for scans/images."""
    import fitz  # PyMuPDF

    langs = langs or ["vi", "en"]
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

            native_text = page.get_text("text").strip() if ftype == "pdf" else ""
            used_paddle = len(native_text) < MIN_NATIVE_TEXT_CHARS
            if not used_paddle:
                for b in page.get_text("blocks"):
                    if len(b) >= 7 and b[6] == 0:  # text block
                        txt = str(b[4]).strip()
                        if txt:
                            block_lines = txt.split("\n")
                            lines.extend(block_lines)
                            bbox = (
                                round(float(b[0]) * scale, 1),
                                round(float(b[1]) * scale, 1),
                                round(float(b[2]) * scale, 1),
                                round(float(b[3]) * scale, 1),
                            )
                            boxes.extend([bbox] * len(block_lines))
                if not lines:
                    lines = native_text.split("\n")
            else:
                try:
                    lines, boxes = _run_paddle_ocr(pix, langs)
                except Exception as exc:
                    logger.warning("PaddleOCR thất bại ở trang %d, dùng text có sẵn nếu có: %s", i, exc)
                    lines = native_text.splitlines() if native_text else []

            if not lines:
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
            logger.info(
                "Trang %d: %s %d dòng (%d ký tự)",
                i,
                "PaddleOCR nhận dạng" if used_paddle else "trích text PDF",
                len(lines),
                len("\n".join(lines)),
            )
    finally:
        doc.close()

    return pages
