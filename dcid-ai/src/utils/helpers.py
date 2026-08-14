"""Trợ lý xử lý hình ảnh và văn bản cho hệ thống DCID AI."""

import base64
import io
import os
import re
from pathlib import Path
from typing import Tuple, Union

from PIL import Image


def ensure_directory(path: Union[str, Path]) -> Path:
    """Tự động tạo thư mục nếu chưa tồn tại."""
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p


def crop_image_region(
    image: Union[Image.Image, bytes],
    bbox: Tuple[float, float, float, float],
    padding: int = 10,
) -> Image.Image:
    """Cắt nhỏ vùng hình ảnh (Visual Bounding Box Chunking) từ PIL Image hoặc raw bytes.

    Args:
        image: Đối tượng PIL Image hoặc bytes ảnh nguyên gốc.
        bbox: Tọa độ chữ nhật (x1, y1, x2, y2) tính bằng pixel.
        padding: Đệm lề (px) xung quanh bbox để không bị chém mất nét chữ/ký hiệu.

    Returns:
        Đối tượng PIL.Image đã được crop độc lập.
    """
    if isinstance(image, bytes):
        pil_img = Image.open(io.BytesIO(image)).convert("RGB")
    else:
        pil_img = image.convert("RGB")

    width, height = pil_img.size
    x1, y1, x2, y2 = bbox

    # Thêm padding an toàn
    crop_x1 = max(0, int(x1) - padding)
    crop_y1 = max(0, int(y1) - padding)
    crop_x2 = min(width, int(x2) + padding)
    crop_y2 = min(height, int(y2) + padding)

    # Nếu bbox quá nhỏ hoặc không hợp lệ, trả về khung vừa đủ
    if crop_x2 <= crop_x1 or crop_y2 <= crop_y1:
        return pil_img

    return pil_img.crop((crop_x1, crop_y1, crop_x2, crop_y2))


def save_crop_image(
    crop_img: Image.Image,
    version_id: str,
    page_no: int,
    crop_idx: int,
    crops_dir: str = "./uploads/crops",
) -> str:
    """Lưu tấm ảnh crop vào đĩa ở thư mục uploads/crops/ và trả về đường dẫn tương đối.

    Đường dẫn này (`image_path`) sẽ được lưu vào payload Qdrant
    để Frontend UI lấy và render trực tiếp tấm ảnh crop lên giao diện.

    Returns:
        Đường dẫn file tương đối (ví dụ: 'uploads/crops/v123_p1_c0.png')
    """
    out_dir = ensure_directory(crops_dir)
    filename = f"{version_id}_p{page_no}_c{crop_idx}.png"
    filepath = out_dir / filename

    crop_img.save(filepath, format="PNG", optimize=True)

    # Chuyển thành đường dẫn tương đối chuẩn cho API / UI Frontend
    rel_path = os.path.join("uploads", "crops", filename).replace("\\", "/")
    return rel_path


def convert_image_to_base64(image: Union[Image.Image, bytes]) -> str:
    """Chuyển đổi PIL Image hoặc bytes thành Data URI Base64 dạng: `data:image/png;base64,...`
    chuẩn để truyền vào API Qwen2-VL-2B.
    """
    if isinstance(image, bytes):
        img_bytes = image
    else:
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_bytes = buffered.getvalue()

    encoded = base64.b64encode(img_bytes).decode("utf-8")
    return f"data:image/png;base64,{encoded}"


def clean_text(text: str) -> str:
    """Làm sạch ký tự rác, chuẩn hóa khoảng trắng thừa."""
    if not text:
        return ""
    # Xóa ký tự null và control chars ngoại trừ \n, \t
    cleaned = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]", "", text)
    # Gom nhiều dòng trống thành tối đa 2 dòng
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()
