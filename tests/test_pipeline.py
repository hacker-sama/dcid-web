"""Unit & Integration tests cho DCID AI pipeline."""

import os
import unittest
from PIL import Image

from src.utils import helpers
from src.prompts import prompt_templates
from src.ingestion.ocr_engine import PageOcrResult, ImageCropResult
from src.chunking import chunker
from src.vectordb import vector_store


class TestDCIDPipeline(unittest.TestCase):

    def test_image_crop_and_save(self):
        """Kiểm tra tính năng cắt ảnh và lưu vào uploads/crops/."""
        test_img = Image.new("RGB", (800, 600), color="blue")
        bbox = (100.0, 100.0, 400.0, 300.0)

        cropped = helpers.crop_image_region(test_img, bbox, padding=10)
        self.assertEqual(cropped.size, (320, 220))

        rel_path = helpers.save_crop_image(
            crop_img=cropped,
            version_id="v_test_123",
            page_no=1,
            crop_idx=0,
            crops_dir="./uploads/crops",
        )

        self.assertTrue(rel_path.startswith("uploads/crops/"))
        self.assertTrue(os.path.exists(rel_path))

    def test_chunker_with_image_path(self):
        """Kiểm tra chunker đính kèm image_path cho Frontend UI."""
        crop_res = ImageCropResult(
            crop_idx=0,
            image_path="uploads/crops/v_test_p1_c0.png",
            bbox=(50.0, 50.0, 200.0, 200.0),
            visual_caption="Sơ đồ mạch điện 220V tủ điều khiển.",
        )

        page_res = PageOcrResult(
            page_no=1,
            text="Tài liệu hướng dẫn vận hành máy nén khí.",
            width=1000,
            height=1400,
            image_crops=[crop_res],
            is_pure_text=False,
        )

        chunks = chunker.chunk_pages([page_res])
        self.assertGreater(len(chunks), 0)

        # Kiểm tra xem có chunk visual mang image_path không
        visual_chunk = next((c for c in chunks if c.image_path is not None), None)
        self.assertIsNotNone(visual_chunk)
        self.assertEqual(visual_chunk.image_path, "uploads/crops/v_test_p1_c0.png")
        self.assertIn("Sơ đồ mạch điện 220V", visual_chunk.text)

    def test_prompt_templates(self):
        """Kiểm tra rendering prompt templates."""
        hits = [{
            "title": "Bản vẽ CAD",
            "page_no": 2,
            "bbox": "(10,10,100,100)",
            "image_path": "uploads/crops/sample.png",
            "text": "Nội dung trích xuất từ bản vẽ.",
        }]
        user_prompt = prompt_templates.build_user_prompt("Áp suất máy nén bao nhiêu?", hits)
        self.assertIn('image_path="uploads/crops/sample.png"', user_prompt)
        self.assertIn("Áp suất máy nén bao nhiêu?", user_prompt)


if __name__ == "__main__":
    unittest.main()
