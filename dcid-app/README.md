# dcid-app — Smart KCN Docs (Flutter)

Frontend đa nền tảng cho Smart KCN Docs: **Kiosk (Windows) + Mobile (Android)** từ một codebase.
Xem kiến trúc đầy đủ ở [`../docs/FRONTEND.md`](../docs/FRONTEND.md).

## Chạy

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080
flutter analyze && flutter test
```

> **Windows:** bật **Developer Mode** (`start ms-settings:developers`) để build có plugin (symlink).

## Cấu trúc `lib/`

```
core/     env, theme (touch/glove), router (go_router + role guard), responsive, kiosk (Windows)
data/     api_client (Dio + Bearer JWT), auth_repository, docs_repository, models/
state/    providers (Riverpod DI), auth_controller (Notifier<AuthState>)
features/ auth · shell (adaptive nav) · search (Ask) · snap_ask · viewer · documents · admin · common
```

## Trạng thái skeleton

| Đã có (khung chạy được) | Stub (điền theo milestone) |
|---|---|
| Login self-JWT (`/api/auth/login` → secure storage) | Snap & Ask (camera) — M4 |
| Router + role guard (OPERATOR/ENGINEER/QA_ADMIN/ADMIN) | Viewer bản vẽ + bbox — M2–M4 |
| Shell điều hướng adaptive (rail/bottom nav) | Documents/upload/versioning — M1–M3 |
| Màn Tra cứu + Ask (`/api/query`) + guardrail banner | Admin/audit — M3 |

## Dependency thêm sau (theo milestone)

`camera`/`image_picker` (M4) · `pdfx` hoặc `syncfusion_flutter_pdfviewer` (M2) ·
`data_table_2`/`pluto_grid` + `fl_chart` (M3) · `isar`/`hive` (offline) · `window_manager` (kiosk M4).
