# dcid-app — DCID: Digital Cognitive InDustrial System (Flutter)

Frontend đa nền tảng cho hệ thống DCID: Digital Cognitive InDustrial System, 1 codebase Dart, 2 target:
**Mobile (Android — Snap & Ask hiện trường)** và **Web (trình duyệt — Kiosk + Admin/QA console)**.
Xem kiến trúc đầy đủ + lý do chọn Web thay vì app desktop native ở
[`../docs/FRONTEND.md`](../docs/FRONTEND.md) §0.1.

## Chạy

```bash
flutter pub get
flutter analyze && flutter test

# Mobile
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080

# Web (kiosk/admin) — cố định port để khớp CORS backend (mặc định cho phép localhost:3000)
flutter run -d chrome --web-port=3000 --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080

# Build web production
flutter build web --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://<backend-lan-ip>:8080
```

> **Android:** build APK cần bật **Developer Mode** trên máy dev Windows
> (`start ms-settings:developers`) để plugin symlink hoạt động. Không cần cho target `web`.

## Cấu trúc `lib/`

```
core/     env, theme (touch/glove), router (go_router + role guard), responsive, kiosk (no-op — §0.1)
data/     api_client (Dio + Bearer JWT), auth_repository, docs_repository (upload: bytes-based), models/
state/    providers (Riverpod DI), auth_controller, documents_providers
features/ auth · shell (adaptive nav) · search (Ask) · snap_ask · viewer · documents · admin · common
```

## Trạng thái skeleton

| Đã có (khung chạy được, verify bằng `flutter build web` + APK) | Stub (điền theo milestone) |
|---|---|
| Login self-JWT (`/api/auth/login` → secure storage) | Snap & Ask (camera) — M4 |
| Router + role guard (OPERATOR/ENGINEER/QA_ADMIN/ADMIN) | Viewer bản vẽ + bbox — M2–M4 |
| Shell điều hướng adaptive (rail/bottom nav) | Admin/audit — M3 |
| Màn Tra cứu + Ask (`/api/query`) + guardrail banner | |
| Màn Tài liệu: danh sách + chi tiết (version + status chip) + upload (multipart, bytes-based) | |

## Dependency thêm sau (theo milestone)

`camera`/`image_picker` (M4, mobile) · `pdfx` hoặc `syncfusion_flutter_pdfviewer` (M2) ·
`data_table_2`/`pluto_grid` + `fl_chart` (M3) · `isar`/`hive` (offline, mobile).

## Lưu ý platform quan trọng

- **Không import `dart:io`** trong code dùng chung (`core/`, `data/`, `features/`) — target `web`
  không biên dịch được với `dart:io`. Nếu cần phân nhánh theo nền tảng, dùng
  `kIsWeb` (`package:flutter/foundation.dart`).
- **Upload file luôn dùng bytes**, không dùng `path` — trên web, `PlatformFile.path` luôn `null`.
  Xem `lib/features/documents/upload_document_sheet.dart` + `DocsRepository.uploadDocument`.
