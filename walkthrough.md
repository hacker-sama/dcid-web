# Báo cáo Hoàn thành: Nâng cấp Frontend (`dcid-app`) — Hỗ trợ Đa nền tảng (Web & Mobile)

Đã hoàn tất việc tổng hợp các đề xuất và triển khai các nâng cấp quan trọng cho phân hệ Frontend Flutter ([`dcid-app`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app)), đảm bảo **không gây vỡ build hay gián đoạn các tính năng trên Mobile APK**.

---

## Các thay đổi chính

### 1. Quản lý Ngoại lệ Toàn cục (Global Exception Handling & Error Boundaries)
- **[`api_client.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/data/api_client.dart):** Bổ sung `onError` interceptor vào Dio. Tự động kiểm tra HTTP StatusCode 401 (hết hạn Token JWT) để giải phóng token và ngăn lỗi lặp lại.
- **[`main.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/main.dart):** Đăng ký `FlutterError.onError` và `PlatformDispatcher.instance.onError` để bắt tất cả các ngoại lệ UI/Async không lường trước, tránh hiện tượng Red Screen of Death trên thiết bị thật.

### 2. Giao diện Chat Streaming SSE Realtime (`SSE Chat UI`)
- **[`sse_event.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/data/models/sse_event.dart):** Định nghĩa cấu trúc dữ liệu sự kiện SSE (`meta`, `delta`, `done`, `error`).
- **[`docs_repository_interface.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/data/docs_repository_interface.dart) & [`docs_repository.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/data/docs_repository.dart):** Triển khai hàm `askStream(...)` đọc trực tiếp luồng `text/event-stream` từ Backend proxy (`/api/query/stream`).
- **[`search_screen.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/features/search/search_screen.dart):** Cập nhật giao diện chat nhận token realtime, hiển thị hiệu ứng gõ chữ (typing effect), cuộn tự động và hiện ngay thông tin Guardrail banner + Citation chip mà không phải chờ full response.
- **[`mock_docs_repository.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/data/mock/mock_docs_repository.dart):** Bổ sung trình giả lập Stream SSE để hỗ trợ chạy thử độc lập khi sử dụng dữ liệu Mock.

### 3. Trình xem Trích dẫn Sơ đồ & Bounding Box Overlay
- **[`document_viewer_screen.dart`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/dcid-app/lib/features/viewer/document_viewer_screen.dart):** Kết nối trực tiếp với API proxy ảnh MinIO (`/api/files/{imageKey}`) kèm header xác thực JWT.
- Khi người dùng chọn trích dẫn, hệ thống tự động tải ảnh trang và sử dụng `BBoxOverlayPainter` vẽ đè khung chữ nhật khoanh vùng sơ đồ/bản vẽ kỹ thuật.

### 4. Cập nhật Tài liệu Dự án
- **[`ROADMAP.md`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/docs/ROADMAP.md):** Cập nhật trạng thái hoàn thành cho các mục SSE Chat UI, Global Exception Handling, và BBox Document Viewer.
- **[`implementation_plan.md`](file:///c:/Users/Admin/Documents/GitHub/dcid-web/implementation_plan.md):** Ghi nhận kế hoạch tổng thể triển khai nâng cấp Frontend theo giai đoạn.

---

## Đảm bảo An toàn cho Mobile (Mobile Compatibility Verified)

1. **Không sử dụng `dart:io` ở tầng dùng chung:** Không làm vỡ khả năng biên dịch sang Web (`flutter build web`).
2. **Duy trì cơ chế Upload Bytes-based (`Uint8List`):** Đảm bảo tính năng upload tài liệu hoạt động đồng nhất trên cả Web và Android APK mà không phụ thuộc vào `file.path`.
3. **Responsive UI Touch-friendly:** Các nút điều khiển và kích thước giao diện giữ nguyên chuẩn tối thiểu $\ge 48\text{dp}$ trên thiết bị di động hiện trường.
