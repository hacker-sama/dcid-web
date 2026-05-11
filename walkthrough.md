# Báo cáo Cập nhật Backend Shared Infrastructure

Dưới đây là tài liệu tổng hợp toàn bộ các thay đổi và class infrastructure dùng chung đã được implement thành công trong task `feat/CDS-02 backend shared infrastructure`.

## 1. Xử lý Lỗi Toàn cục (GlobalExceptionHandler)
- **File**: [GlobalExceptionHandler.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/exception/GlobalExceptionHandler.java)
- Xử lý các exception phổ biến như `MethodArgumentNotValidException`, `ConstraintViolationException` trả về HTTP 422 với danh sách lỗi chi tiết từng field.
- Xử lý các exception nghiệp vụ `NotFoundException` (404), `ForbiddenException` (403), `ConflictException` (409), `PolicyViolationException` (422).
- Thêm header `Retry-After: 3600` cho `RateLimitException` (HTTP 429).
- Tích hợp `MDC.get("traceId")` vào tất cả các `ErrorResponse` để frontend có thể nhận và hiển thị ID lỗi cho người dùng.
- Catch-all `Throwable` trả về HTTP 500, log toàn bộ stack trace nhưng không để lộ ra ngoài response.

## 2. Truy vết Request (RequestTracingFilter)
- **File**: [RequestTracingFilter.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/filter/RequestTracingFilter.java)
- Đọc header `X-Trace-Id`. Nếu không có, hệ thống tự động sinh ra một mã UUID.
- Đẩy traceId, method, path vào `MDC` (Mapped Diagnostic Context) để dễ dàng theo dõi log.
- Trả về header `X-Trace-Id` trên mọi response.
- Xóa `MDC` trong block `finally` sau khi hoàn tất chuỗi filter để tránh rò rỉ bộ nhớ.
- Log lại thời gian xử lý request (ms).

## 3. Dịch vụ lưu trữ (MinioService)
- **File**: [MinioService.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/service/MinioService.java)
- Bổ sung hàm tự khởi tạo bucket qua `@PostConstruct` (`ensureBucketExists()`).
- Triển khai đầy đủ các hàm: `upload()`, `getPresignedUrl()` với expiry mặc định là 3600s, và `delete()`. Bắt lỗi `RuntimeException` thay vì để `// TODO`.

## 4. Gửi nhận sự kiện Kafka
- **ApplicationEventProducer**: 
  - File: [ApplicationEventProducer.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/messaging/ApplicationEventProducer.java)
  - Thực hiện gửi message bằng `KafkaTemplate`. Bắt lỗi và chỉ log.error, đảm bảo không crash main request nếu Kafka gặp sự cố.
- **ApplicationEventConsumer**:
  - File: [ApplicationEventConsumer.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/messaging/ApplicationEventConsumer.java)
  - Đăng ký `@KafkaListener` lắng nghe topic từ cấu hình.
  - Xử lý lỗi với try-catch không ném exception ngược lên để tránh retry loop.
  - Phân loại event `APPLICATION_SUBMITTED`, `STATUS_CHANGED` và gọi trực tiếp vào `NotificationService`.

## 5. Security & Context (SecurityContextHelper)
- **File**: [SecurityContextHelper.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/security/SecurityContextHelper.java)
- Được viết lại để đọc thôngil tin `Authentication` dạng `JwtAuthenticationToken`.
- Lấy claim `sub` để trả về ID người dùng hiện tại, `email` trả về email.
- Trích xuất roles từ `GrantedAuthority` sau khi loại bỏ tiền tố `ROLE_`.

## 6. Audit Logging (AuditLogService)
- **File**: [AuditLogService.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/service/AuditLogService.java)
- Triển khai phương thức ghi log qua `@Async` để không làm chậm request của user.
- Lấy `actorId` và `actorRole` từ `SecurityContextHelper`.
- Đọc `ipAddress` (IP người dùng) qua `RequestContextHolder` (từ `X-Forwarded-For` hoặc Remote Addr).
- Dùng `ObjectMapper` để serialize chi tiết log thành JSON string. Lưu vào database thông qua Repository.

## 7. Bổ sung Service Notification
- **File**: [NotificationService.java](file:///c:/project/new/dcid-web/dcid-backend/src/main/java/vn/dcid/service/NotificationService.java)
- Tạo thêm các stub methods (`notifySubmitted`, `notifyStatusChanged`) để compiler có thể tham chiếu thành công từ `ApplicationEventConsumer`.

---

> [!NOTE]
> Tất cả code đã được kiểm tra tính đúng đắn và commit lên nhánh **`feat/CDS-02-backend-shared-infrastructure`**. Bạn có thể chia sẻ trực tiếp file báo cáo này với các thành viên khác trong team để mọi người đều nắm được cách thức gọi các thành phần Infrastructure dùng chung.
