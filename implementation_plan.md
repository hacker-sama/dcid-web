# Kế hoạch nâng cấp True Vision Multimodal (VLM) cho Phân tích Bản vẽ Kỹ thuật

Hiện tại, hệ thống `dcid-ai` chỉ mới bóc tách **Text + Tọa độ Bbox** từ file ảnh/PDF thông qua OCR rồi nối chữ vào prompt. Điều này khiến mô hình AI (LLM) không thực sự "nhìn" thấy các hình vẽ, sơ đồ hay đường nối kỹ thuật trên bản vẽ.

Kế hoạch này sẽ nâng cấp `dcid-ai` hỗ trợ chuẩn **OpenAI Multimodal Vision API (`image_url` base64)**. Khi người dùng hỏi về một hình ảnh bản vẽ (qua `imageStorageKey` hoặc trang PDF), hệ thống sẽ gửi **trực tiếp dữ liệu điểm ảnh (pixels)** cho các mô hình Vision (VLM) như **`Qwen2-VL`** hoặc **`Llama-3.2-Vision`** trên LM Studio để AI thực sự "nhìn thấy và phân tích" bản vẽ.

---

## User Review Required

> [!IMPORTANT]
> **Yêu cầu đối với LM Studio:**
> Để tính năng phân tích hình ảnh thực sự hoạt động trên máy local/máy giám khảo, model nạp trên LM Studio phải là **Vision Model (VLM)**.
> - **Khuyến nghị cho máy yếu/vừa:** `Qwen2-VL-2B-Instruct` (cần ~2GB RAM) hoặc `Qwen2-VL-7B-Instruct` (cần ~5GB RAM).
> - Nếu sử dụng model thuần Text (như Qwen2.5-3B-Instruct cũ), hệ thống sẽ tự động fallback về chế độ OCR Text như hiện tại để không gây crash ứng dụng.

---

## Proposed Changes

### Tầng AI Service (`dcid-ai`)

#### [MODIFY] [minio_client.py](file:///c:/project/new/dcid-web/dcid-ai/app/clients/minio_client.py)
- Thêm hàm `get_object_base64(storage_key: str)` để lấy dữ liệu ảnh từ MinIO và chuyển đổi thành chuỗi Data URI Base64 (`data:image/png;base64,...`).

#### [MODIFY] [llm_client.py](file:///c:/project/new/dcid-web/dcid-ai/app/clients/llm_client.py)
- Cập nhật hàm `generate_answer` và `generate_answer_stream` hỗ trợ định dạng `content` đa phương thức của OpenAI:
  ```json
  [
    {"type": "text", "text": "Câu hỏi + Context..."},
    {"type": "image_url", "image_url": {"url": "data:image/png;base64,..."}}
  ]
  ```

#### [MODIFY] [query_service.py](file:///c:/project/new/dcid-web/dcid-ai/app/services/query_service.py)
- Khi request có `imageStorageKey` (ảnh chụp hoặc bản vẽ upload trực tiếp):
  1. Vẫn thực hiện OCR để lấy text tra cứu RAG nếu cần.
  2. Tải ảnh từ MinIO qua `minio_client` -> Base64.
  3. Đóng gói cả Text Context và Base64 Image vào `user_prompt` để gửi cho LM Studio Vision Model.

---

## Verification Plan

### Automated Tests
- Chạy thử nghiệm unit test kiểm tra hàm encode Base64 và cấu trúc payload gửi sang LM Studio:
  `python -m unittest discover -s tests` (nếu có).

### Manual Verification
1. Nạp model `Qwen2-VL-2B-Instruct` hoặc `Qwen2-VL-7B-Instruct` trên LM Studio.
2. Dùng App Flutter / Postman tải lên một hình ảnh bản vẽ kỹ thuật có sơ đồ/hình vẽ.
3. Đặt câu hỏi về chi tiết hình vẽ.
4. Kiểm tra trên log `dcid-ai`: Đảm bảo log xác nhận đã gửi `image_url` base64 sang LM Studio và nhận được câu trả lời phân tích chuẩn xác từ Vision Model.
