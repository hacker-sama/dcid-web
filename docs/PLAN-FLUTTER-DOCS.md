# WORK ORDER — Flutter: màn Tài liệu + Upload nối API thật (`dcid-app`)

> **Dành cho agent thực thi độc lập.** Tài liệu tự chứa: đọc xong là code được, không cần ngữ cảnh khác.
> Tham chiếu API duy nhất: mục §3 dưới đây (đã đối chiếu với backend thật — KHÔNG cần đọc code Java).
> Task này là mục T1-#3 trong `docs/PLAN-THESIS.md`.

---

## 1. Bối cảnh (đọc 1 phút)

Monorepo `dcid-web` — đồ án **Smart KCN Docs**: hệ thống hỏi–đáp (RAG) tài liệu kỹ thuật, on-premise.

- `dcid-backend/` (Spring Boot, **chạy được, KHÔNG được sửa**): auth self-JWT, upload tài liệu
  vào MinIO, hỏi–đáp `/api/query`.
- `dcid-app/` (Flutter, **nơi bạn làm việc**): skeleton đã có — login + router role-guard +
  màn Tra cứu/Hỏi **đã nối API thật và hoạt động**. Màn **Documents** hiện là placeholder
  (`lib/features/documents/documents_screen.dart` dùng `FeaturePlaceholder`) — nhiệm vụ của bạn
  là biến nó thành màn thật: **danh sách tài liệu + upload PDF + xem chi tiết version**.
- `dcid-ai/` (Python): **không đụng tới**.

Kiến trúc app hiện có (tuân theo, đừng phát minh pattern mới):
- State: `flutter_riverpod` (`lib/state/providers.dart` — DI qua Provider).
- HTTP: `dio` qua `ApiClient` (`lib/data/api_client.dart`) — tự gắn `Authorization: Bearer <jwt>`.
- Repository: `lib/data/docs_repository.dart` (đang có sẵn `ask()` và `listDocuments()` — trong đó
  `listDocuments()` **đang parse SAI**, xem §4.1).
- Routing: `go_router` (`lib/core/router.dart`), màn Documents đã có route `/documents`.
- Role: `authControllerProvider` → `auth.user.role` (`UserRole` enum trong
  `lib/data/models/user_role.dart`, có sẵn `isAdminLevel` = QA_ADMIN hoặc ADMIN).
- Theme: touch-friendly (nút ≥48dp), nhãn UI **tiếng Việt**.

Môi trường dev: **Windows**, Flutter 3.41.x. Backend chạy ở `http://localhost:8080`
(app đọc qua `--dart-define=API_BASE_URL=...`, mặc định localhost:8080).

---

## 2. Scope

### ✅ PHẢI làm
1. **Fix bug parse** `DocsRepository.listDocuments()` (§4.1).
2. Models mới: `DocumentDetail`, `VersionSummary` (+ mở rộng `DocumentSummary` nếu cần) — parse
   đúng JSON §3, kèm **unit test fromJson**.
3. `DocsRepository`: thêm `uploadDocument(...)` (multipart) và `getDocumentDetail(id)`.
4. **Màn Documents** (`/documents`): danh sách thật — loading / error / empty state, pull-to-refresh,
   mỗi item hiện title, machineCode, category; bấm vào → chi tiết (§5).
5. **Chi tiết tài liệu**: danh sách version với **chip trạng thái** màu theo status
   (PROCESSING=xám/loading, ACTIVE=xanh, FAILED=đỏ kèm errorMessage nếu muốn, SUPERSEDED/OBSOLETE=mờ).
6. **Upload**: nút "+ Tải tài liệu" **chỉ hiện với role QA_ADMIN/ADMIN** (`isAdminLevel`) →
   form: title*, category* (dropdown 6 giá trị §3), machineCode, minRole (dropdown, mặc định OPERATOR),
   description, lang (mặc định `"vi,en"`), **chọn file PDF** → gửi multipart → về danh sách,
   hiện item mới (status PROCESSING) + SnackBar thành công.
7. `flutter analyze` **0 issue** + `flutter test` xanh (test cũ không được vỡ).

### ⛔ KHÔNG làm
- KHÔNG sửa `dcid-backend/`, `dcid-ai/`, `docs/*` khác, `docker-compose.yml`.
- KHÔNG đụng các feature khác của app (search/auth/admin/viewer) ngoài chỗ bắt buộc (router thêm
  route con nếu cần).
- KHÔNG làm viewer ảnh trang/bbox, KHÔNG làm nút obsolete/versioning action, KHÔNG Snap & Ask.
- KHÔNG thêm package ngoài danh sách §6.

---

## 3. Hợp đồng API (nguồn sự thật — khớp backend từng ký tự)

Mọi response bọc trong `{"data": ..., "meta": null}`. JWT bắt buộc (ApiClient đã tự gắn).

### 3.1. `GET /api/documents?page=0&size=20` — mọi vai
```json
{ "data": {
    "items": [ {
        "id": "uuid", "title": "Manual máy CNC XK-500", "machineCode": "CNC-01",
        "category": "SOP", "minRole": "OPERATOR", "description": null,
        "createdAt": "2026-07-02T03:00:00Z", "updatedAt": "2026-07-02T03:00:00Z" } ],
    "page": 0, "size": 20, "total": 1 },
  "meta": null }
```
⚠️ **Đây là PagedResponse** — items nằm trong `data.items`, KHÔNG phải `data` là List.

### 3.2. `GET /api/documents/{id}` — mọi vai
```json
{ "data": {
    "document": { ...DocumentDTO như 3.1... },
    "versions": [ {
        "id": "uuid", "documentId": "uuid", "versionNo": 1,
        "status": "ACTIVE", "lang": "vi,en", "pageCount": 12,
        "originalFilename": "manual.pdf", "fileSize": 1048576,
        "createdAt": "...", "ingestedAt": "..." } ] } }
```
`status` ∈ `PROCESSING | READY | ACTIVE | SUPERSEDED | OBSOLETE | FAILED`.
`pageCount`/`ingestedAt`/`lang` nullable (null khi đang PROCESSING).

### 3.3. `POST /api/documents` — multipart/form-data — **chỉ QA_ADMIN/ADMIN** (khác → 403)
Field names (chính xác): `title`* · `category`* · `machineCode` · `minRole` · `description` ·
`lang` · `file`* (PDF).
- `category` ∈ `SOP | DRAWING | CIRCUIT | MAINTENANCE_LOG | SAFETY | OTHER`
- `minRole` ∈ `OPERATOR | ENGINEER | QA_ADMIN | ADMIN`

Response `201`: `{"data": {"document": {...}, "versions": [{...status: "PROCESSING" hoặc "FAILED"...}]}}`
(FAILED khi AI service không chạy — **vẫn là upload thành công**, hiển thị bình thường).

Lỗi validation → `422` `{"code":"VALIDATION_FAILED", "message":..., "errors":[{field,message}]}`.

### 3.4. Tài khoản test
`POST /api/auth/login` `{"username":"admin","password":"admin123"}` → role ADMIN (được upload).

---

## 4. Việc cụ thể theo file

### 4.1. `lib/data/docs_repository.dart` — FIX BUG + mở rộng
- `listDocuments()` hiện đọc `res.data!['data'] as List` → **SAI** với 3.1.
  Sửa thành đọc `data['data']['items']` (giữ nguyên signature trả `List<DocumentSummary>`).
- Thêm `Future<DocumentDetail> getDocumentDetail(String id)`.
- Thêm `Future<DocumentDetail> uploadDocument({required String title, required String category,
  String? machineCode, String? minRole, String? description, String? lang,
  required String filePath, required String fileName})` — dùng `dio.FormData.fromMap` +
  `MultipartFile.fromFile`, đúng field names §3.3.

### 4.2. `lib/data/models/` — models mới (+ test)
- `DocumentSummary`: thêm field nếu thiếu (đã có id/title/machineCode/category — đủ dùng, chỉ sửa nếu cần).
- `document_detail.dart`: `DocumentDetail { DocumentSummary document; List<VersionSummary> versions; }`
  và `VersionSummary { id, versionNo, status, lang?, pageCount?, originalFilename?, createdAt?, ingestedAt? }`
  với `fromJson` null-safe theo §3.2.
- **Unit test** trong `test/`: parse fixture JSON của 3.1 (PagedResponse) và 3.2 — cái này bắt được
  đúng bug đã fix.

### 4.3. `lib/features/documents/` — UI
- `documents_screen.dart`: bỏ `FeaturePlaceholder`; `FutureProvider`/`AsyncNotifier` (Riverpod) load
  danh sách; `RefreshIndicator`; empty state "Chưa có tài liệu"; error state có nút Thử lại;
  FAB/nút upload chỉ khi `isAdminLevel`.
- `document_detail_screen.dart` (mới): nhận `documentId`, load 3.2, hiện thông tin + list version
  với chip trạng thái màu. Đăng ký route con trong `lib/core/router.dart`
  (vd `/documents/:id`, nằm trong ShellRoute hiện có).
- `upload_document_sheet.dart` (mới — bottom sheet hoặc dialog): form §2-mục-6, validate title/category/file
  bắt buộc, nút gửi disable khi đang upload, báo lỗi 422/403 thân thiện tiếng Việt.

### 4.4. Chọn file
Thêm package **`file_picker`** (hoạt động Android + Windows), giới hạn `type: FileType.custom,
allowedExtensions: ['pdf']`.

---

## 5. Điều hướng
`/documents` (list) → tap item → `/documents/:id` (detail). Upload mở từ FAB trên list.
Sau upload thành công: đóng sheet, refresh list, SnackBar "Đã tải lên — đang xử lý OCR".

---

## 6. Dependency được phép thêm
Chỉ **`file_picker`** (`flutter pub add file_picker`). Không thêm gì khác
(json_serializable/freezed/retrofit… đều KHÔNG — codebase đang viết fromJson tay, giữ nhất quán).

---

## 7. Kiểm chứng & Definition of Done

```bash
cd dcid-app
flutter pub get
flutter analyze          # PHẢI: No issues found
flutter test             # PHẢI: xanh 100% (test cũ + test model mới)
```

**Manual (nếu backend chạy được trên máy):**
```bash
# terminal 1 (repo root): docker-compose up -d postgres minio  →  cd dcid-backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# terminal 2: cd dcid-app && flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```
1. Login `admin/admin123` → tab Tài liệu → danh sách rỗng hiển thị đúng empty state.
2. Upload 1 PDF → quay về list thấy item mới; mở chi tiết thấy version `PROCESSING` hoặc `FAILED`
   (FAILED là bình thường khi dcid-ai không chạy).
3. `flutter analyze`/`test` chạy lại vẫn xanh.

**Báo cáo trung thực:** liệt kê từng lệnh đã chạy + kết quả; bước manual nào không chạy được
(không Docker, không thiết bị…) phải nói rõ "chưa kiểm chứng", không được nói đã chạy.

---

## 8. Prompt khởi động gợi ý (paste cho agent thực thi)

> Đọc kỹ `docs/PLAN-FLUTTER-DOCS.md` trong repo này rồi thực hiện đúng work order: fix bug parse
> trong `DocsRepository.listDocuments()`, thêm models + repository methods, dựng màn Documents
> (list/detail/upload multipart) trong `dcid-app` theo §2–§6. Chỉ làm mục "PHẢI làm", tuyệt đối
> không đụng mục "KHÔNG làm" (đặc biệt: không sửa dcid-backend/dcid-ai). Xong chạy toàn bộ lệnh
> kiểm chứng §7 và báo cáo trung thực từng kết quả, kể cả bước không chạy được và lý do.
