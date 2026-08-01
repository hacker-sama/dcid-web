"""Document Loader đọc file từ thư mục uploads/."""

import logging
from pathlib import Path
from typing import Tuple, Union

logger = logging.getLogger("dcid-ai.loader")


def load_file_bytes(filepath: Union[str, Path]) -> Tuple[bytes, str]:
    """Đọc file từ đường dẫn và trả về bytes + loại file (extension)."""
    p = Path(filepath)
    if not p.exists():
        raise FileNotFoundError(f"Không tìm thấy file: {filepath}")

    ext = p.suffix.lower().lstrip(".")
    with open(p, "rb") as f:
        data = f.read()

    logger.info("Load file OK: %s (%d bytes, format=%s)", p.name, len(data), ext)
    return data, ext
