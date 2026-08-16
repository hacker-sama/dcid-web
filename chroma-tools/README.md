# ChromaDB Tools & Inspector

Thư mục dành riêng để kiểm tra, giám sát, tải tài liệu và xác minh dữ liệu vector trong **ChromaDB (`kcn_chunks`)** của hệ thống **DCID: Digital Cognitive InDustrial System**.

## Danh sách công cụ

### 1. Kiểm tra trạng thái ChromaDB (`chroma_status.py`)
Kiểm tra tình trạng kết nối ChromaDB, đếm tổng số chunk đang lưu trữ, và đối chiếu tự động với danh sách tài liệu từ Backend (PostgreSQL).

```bash
python chroma-tools/chroma_status.py
```

### 2. Tải lên và Xác minh trực tiếp vào ChromaDB (`upload_and_verify.py`)
Công cụ tự động tải 1 file PDF qua cổng chính (`:8080`), theo dõi tiến trình OCR/Chunking/Embedding (`PROCESSING` → `ACTIVE`), và **kiểm tra trực tiếp trong collection `kcn_chunks` của ChromaDB** để xem chính xác từng đoạn văn bản (`chunk`) đã được nạp vào chưa.

```bash
# Tải tài liệu mẫu tự động tạo (để test nhanh):
python chroma-tools/upload_and_verify.py

# Tải file PDF của anh/chị và kiểm tra ngay:
python chroma-tools/upload_and_verify.py --file đường/dẫn/đến/file.pdf --title "Tài liệu kỹ thuật KCN"
```

### 3. Xem và tìm kiếm chunk trong ChromaDB (`inspect_chunks.py`)
Tra cứu chi tiết nội dung từng chunk, lọc theo `doc_id` hoặc `version_id`.

```bash
# Xem toàn bộ các chunk đang có:
python chroma-tools/inspect_chunks.py

# Lọc các chunk của một tài liệu cụ thể:
python chroma-tools/inspect_chunks.py --doc-id <UUID>
```
