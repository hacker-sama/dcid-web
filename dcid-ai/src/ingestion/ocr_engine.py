"""Module OCR Engine: PyMuPDF rasterize, PaddleOCR text extraction, Visual Bounding Box Chunking, và Pure-Text Vision Skip cho Qwen2-VL 2B."""

import io
import logging
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple

import fitz  # PyMuPDF
import numpy as np
from PIL import Image

from src.llm import llm_client
from src.prompts import prompt_templates
from src.utils import helpers

logger = logging.getLogger("dcid-ai.ocr_engine")

RENDER_DPI = 200
MAX_SIDE_PIXELS = 2400
MIN_DRAWING_AREA = 10000  # px^2 threshold để phân biệt vẽ vector/sơ đồ thật với đường gạch chân nhỏ


@dataclass
class ImageCropResult:
    """Kết quả crop một vùng sơ đồ / hình ảnh."""
    crop_idx: int
    image_path: str  # Đường dẫn tới uploads/crops/ file
    bbox: Tuple[float, float, float, float]
    visual_caption: str  # Mô tả từ Qwen2-VL 2B


@dataclass
class PageOcrResult:
    """Kết quả OCR & Visual Ingestion của 1 trang PDF."""
    page_no: int
    text: str
    width: int
    height: int
    boxes: List[Tuple[float, float, float, float]] = field(default_factory=list)
    image_crops: List[ImageCropResult] = field(default_factory=list)
    is_pure_text: bool = True


def _detect_page_drawings_and_images(
    page: fitz.Page,
    width: int,
    height: int,
) -> Tuple[bool, List[Tuple[float, float, float, float]]]:
    """Phát hiện xem trang có chứa hình ảnh / bản vẽ vector / sơ đồ không.

    Returns:
        (has_visual_content, list_of_bboxes)
    """
    image_list = page.get_images(full=True)
    drawings = page.get_drawings()

    bboxes: List[Tuple[float, float, float, float]] = []

    # 1. Thu thập Bbox các ảnh bitmap nhúng trong PDF
    for img_info in image_list:
        xref = img_info[0]
        for img_rect in page.get_image_rects(xref):
            scale_x = width / page.rect.width if page.rect.width > 0 else 1.0
            scale_y = height / page.rect.height if page.rect.height > 0 else 1.0
            bx = (
                round(img_rect.x0 * scale_x, 1),
                round(img_rect.y0 * scale_y, 1),
                round(img_rect.x1 * scale_x, 1),
                round(img_rect.y1 * scale_y, 1),
            )
            bboxes.append(bx)

    # 2. Kiểm tra các đường vẽ vector (Sơ đồ CAD / Khối / Bảng biểu)
    total_drawing_area = 0.0
    for drw in drawings:
        r = drw.get("rect")
        if r:
            area = r.width * r.height
            total_drawing_area += area
            if area >= MIN_DRAWING_AREA:
                scale_x = width / page.rect.width if page.rect.width > 0 else 1.0
                scale_y = height / page.rect.height if page.rect.height > 0 else 1.0
                bx = (
                    round(r.x0 * scale_x, 1),
                    round(r.y0 * scale_y, 1),
                    round(r.x1 * scale_x, 1),
                    round(r.y1 * scale_y, 1),
                )
                bboxes.append(bx)

    has_visual = (len(image_list) > 0) or (total_drawing_area >= MIN_DRAWING_AREA)
    return has_visual, bboxes


def process_pdf_pages(
    pdf_bytes: bytes,
    version_id: str,
    enable_vision: bool = True,
    skip_pure_text_pages: bool = True,
) -> List[PageOcrResult]:
    """Xử lý Ingestion cho file PDF: PyMuPDF rasterize, OCR chữ, crop sơ đồ và gọi Qwen2-VL-2B."""
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    results: List[PageOcrResult] = []

    try:
        for i, page in enumerate(doc, start=1):
            max_side_pt = max(page.rect.width, page.rect.height)
            scale_dpi = RENDER_DPI / 72.0
            scale_max = MAX_SIDE_PIXELS / max_side_pt if max_side_pt > 0 else scale_dpi
            scale = min(scale_dpi, scale_max)
            matrix = fitz.Matrix(scale, scale)

            pix = page.get_pixmap(matrix=matrix)
            width, height = pix.width, pix.height

            pil_page_img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

            lines: List[str] = []
            boxes: List[Tuple[float, float, float, float]] = []

            native_text = page.get_text("text").strip()
            if len(native_text) > 30:
                lines = native_text.split("\n")
                for b in page.get_text("blocks"):
                    if len(b) >= 7 and b[6] == 0:
                        bbox = (
                            round(float(b[0]) * scale, 1),
                            round(float(b[1]) * scale, 1),
                            round(float(b[2]) * scale, 1),
                            round(float(b[3]) * scale, 1),
                        )
                        boxes.append(bbox)
            else:
                try:
                    from paddleocr import PaddleOCR
                    engine = PaddleOCR(lang="vi", use_angle_cls=False, enable_mkldnn=False)
                    img_np = np.array(pil_page_img)
                    ocr_res = engine.ocr(img_np, cls=False)
                    if ocr_res and ocr_res[0]:
                        for line in ocr_res[0]:
                            box_poly, (text_str, score) = line
                            lines.append(text_str)
                            poly_arr = np.array(box_poly)
                            boxes.append((
                                round(float(np.min(poly_arr[:, 0])), 1),
                                round(float(np.min(poly_arr[:, 1])), 1),
                                round(float(np.max(poly_arr[:, 0])), 1),
                                round(float(np.max(poly_arr[:, 1])), 1),
                            ))
                except Exception as ocr_err:
                    logger.warning("PaddleOCR fallback bypass cho trang %d: %s", i, ocr_err)
                    lines = [native_text]

            has_visual, visual_bboxes = _detect_page_drawings_and_images(page, width, height)
            image_crops: List[ImageCropResult] = []

            if enable_vision and has_visual and visual_bboxes:
                logger.info("Trang %d: Phat hien %d khu vuc so do/hinh anh -> Kich hoat Visual Worker Qwen2-VL 2B", i, len(visual_bboxes))

                for crop_idx, bx in enumerate(visual_bboxes[:3]):
                    crop_img = helpers.crop_image_region(pil_page_img, bx, padding=15)
                    rel_image_path = helpers.save_crop_image(
                        crop_img=crop_img,
                        version_id=version_id,
                        page_no=i,
                        crop_idx=crop_idx,
                    )
                    base64_str = helpers.convert_image_to_base64(crop_img)

                    caption = llm_client.generate_vision_caption(
                        image_base64=base64_str,
                        prompt=prompt_templates.PROMPT_QWEN_VL_CAPTION,
                    )

                    image_crops.append(
                        ImageCropResult(
                            crop_idx=crop_idx,
                            image_path=rel_image_path,
                            bbox=bx,
                            visual_caption=caption,
                        )
                    )
            elif enable_vision and skip_pure_text_pages:
                logger.info("Trang %d: Tai lieu THUAN VAN BAN (Pure-Text) -> SKIP goi Qwen2-VL 2B (Tiet kiem latency)", i)

            results.append(
                PageOcrResult(
                    page_no=i,
                    text="\n".join(lines),
                    width=width,
                    height=height,
                    boxes=boxes,
                    image_crops=image_crops,
                    is_pure_text=not (has_visual and visual_bboxes),
                )
            )
    finally:
        doc.close()

    return results
