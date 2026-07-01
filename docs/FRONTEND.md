# Smart KCN Docs — Frontend (Flutter, đa nền tảng)

> Đọc kèm [`ARCHITECTURE.md`](ARCHITECTURE.md) và [`ROADMAP.md`](ROADMAP.md).
> **Quyết định đã chốt:** **Flutter-only** — MỘT project `dcid-app` build ra **cả 3 mặt** từ 1 codebase:
> **Mobile** (Android, Snap & Ask) · **Kiosk** (Windows desktop, fullscreen) · **Admin console**
> (Windows/màn lớn). **Bỏ Next.js/React** — `dcid-frontend` cũ sẽ được gỡ (mục §10).

---

## 0. Vì sao Flutter-only

- Team nhỏ (1 dev) → **1 codebase, 1 ngôn ngữ (Dart)**, rẻ & dễ bảo trì.
- Kiosk và Mobile đều là **touch/UX xưởng** → dùng chung ~90% code, chỉ đổi layout theo form factor.
- `dcid-frontend` (Next.js) là app **domain cũ**, kiểu gì cũng viết lại → gỡ luôn, không "format".
- Kiosk = **Flutter Windows native** (không phải Flutter Web): offline mạnh, khởi động nhanh, truy cập
  phần cứng, tránh điểm yếu Flutter Web (CanvasKit nặng, text/accessibility yếu).

**Đánh đổi đã chấp nhận:** màn **Admin/QA dày dữ liệu** (bảng version, audit, dashboard, viewer PDF) là
điểm yếu tương đối của Flutter → dùng `data_table_2`/`pluto_grid`, `fl_chart`, `pdfx`/Syncfusion; tốn công
hơn React nhưng chấp nhận được ở quy mô này.

---

## 1. Nền tảng target & chiến lược responsive

Một Flutter project, nhiều target:

| Target build | Thiết bị | Vai chính |
|---|---|---|
| **Android** (APK) | tablet/điện thoại hiện trường | OPERATOR, ENGINEER lưu động — **Snap & Ask** |
| **Windows** (exe) | Industrial/Mini PC | Kiosk tra cứu tại trạm + **Admin/QA console** |
| *(Web — tùy chọn sau)* | — | chỉ mở nếu cần truy cập trình duyệt |

- **Responsive/adaptive:** `LayoutBuilder` + breakpoints (hoặc `flutter_adaptive_scaffold`): phone = 1 cột,
  điều hướng dưới; màn lớn/kiosk = master-detail, **side-by-side viewer**, navigation rail.
- **Điều hướng:** `go_router` + guard theo role.
- **Kiosk mode (Windows):** `window_manager`/`bitsdojo_window` → fullscreen, frameless, auto-start,
  chặn thoát; chạy trên Industrial PC như một app chuyên dụng.

---

## 2. Kiến trúc app (`dcid-app`)

**Gói đề xuất:** `dio` (HTTP + interceptor Bearer) · `flutter_riverpod` (state) · `go_router` (routing) ·
`flutter_secure_storage` (JWT — chạy cả Android/Windows) · `camera`/`image_picker` (Snap & Ask) ·
`cached_network_image` · `isar`/`hive` (offline cache đa nền tảng) · `intl`+gen-l10n (đa ngôn ngữ) ·
`fl_chart` (biểu đồ) · `data_table_2`/`pluto_grid` (bảng admin) · `pdfx`/`syncfusion_flutter_pdfviewer` (PDF) ·
`window_manager` (kiosk Windows).

```
dcid-app/  (Flutter)
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── env.dart              # API_BASE_URL theo build flavor
│   │   ├── theme.dart            # touch/glove: target ≥48dp, font lớn, dark
│   │   ├── router.dart           # go_router + role guard
│   │   ├── responsive.dart       # breakpoints phone / kiosk-desktop
│   │   └── kiosk.dart            # window_manager (Windows fullscreen)
│   ├── data/
│   │   ├── api_client.dart       # Dio + interceptor JWT + 401
│   │   ├── auth_repository.dart  # login → secure storage
│   │   └── docs_repository.dart  # query / documents / versions
│   ├── features/
│   │   ├── auth/                 # login, role guard, /me
│   │   ├── search/               # tra cứu + Ask
│   │   ├── snap_ask/             # camera → ảnh + câu hỏi (mobile)
│   │   ├── answer/               # câu trả lời + citation + guardrail banner
│   │   ├── viewer/               # ảnh trang + CustomPaint vẽ bbox; PDF
│   │   └── admin/                # upload, versioning, users, audit (màn lớn)
│   └── l10n/                     # vi, en (mở zh/ja)
├── assets/
├── android/  ├── windows/        # target build
└── pubspec.yaml
```

---

## 3. Bản đồ màn hình theo vai (UI ẩn/hiện theo role)

| Vai | Màn hình | Ưu tiên surface |
|---|---|---|
| **Chung** | login, 403, chọn ngôn ngữ, hồ sơ (`/me`) | mọi target |
| **OPERATOR** | tra cứu **SOP & cảnh báo an toàn**; Search + Ask; **Snap & Ask** | mobile |
| **ENGINEER** | + **bản vẽ / sơ đồ mạch / nhật ký bảo trì**; **side-by-side viewer** | mobile + kiosk |
| **QA_ADMIN** | **upload** tài liệu; **quản lý version** (ACTIVE/SUPERSEDED/OBSOLETE) | kiosk/desktop (màn lớn) |
| **ADMIN** | quản lý user/role; **audit log viewer** | kiosk/desktop |

> Chốt chặn quyền thật ở backend `@PreAuthorize`; UI chỉ ẩn/hiện cho gọn.

---

## 4. Luồng UX đặc thù hiện trường

- **Snap & Ask** (mobile): `camera`/`image_picker` chụp → upload multipart tới `POST /api/query` (kèm ảnh)
  → backend forward `dcid-ai` → answer + citation.
- **Side-by-side + overlay bbox:** `Stack` + `CustomPaint` vẽ khoanh đỏ theo toạ độ chuẩn hoá
  (dựa `width/height` trong `document_pages`).
- **Guardrail UI:** `locked=true` (cosine < 0.60) → **banner đỏ** "Yêu cầu kỹ sư xác minh", ẩn câu trả lời tự sinh.
- **Touch/glove:** target ≥ 48dp, chữ lớn, ít gõ phím, theme tối, haptic khi cảnh báo.
- **Luôn hiển thị nguồn:** tên tài liệu + version + số trang kèm mọi câu trả lời.

---

## 5. Auth self-JWT (đa nền tảng)

- Login → `POST /api/auth/login` → JWT lưu ở **`flutter_secure_storage`** (Keystore Android / DPAPI Windows).
- `Dio` interceptor gắn `Authorization: Bearer <jwt>`; 401 → logout/redirect.
- Role đọc từ JWT → `go_router` guard + ẩn/hiện menu.

---

## 6. Hợp đồng API dùng chung

`POST /api/auth/login` · `GET /api/auth/me` · `POST /api/query` *(multipart khi Snap & Ask)* ·
`GET /api/documents` · `POST /api/documents` · `POST /api/documents/{id}/versions` ·
`POST /api/documents/{versionId}/obsolete` · `GET /api/admin/audit-logs` ·
`GET /api/files/...` (proxy ảnh/crop từ MinIO, có auth). Base URL qua build flavor (`API_BASE_URL`).

---

## 7. Triển khai

| Target | Cách deploy |
|---|---|
| **Android** | build **APK** → phân phối nội bộ (air-gapped): MDM nội bộ / cài tay. Camera native |
| **Windows (kiosk)** | build **exe** → cài trên Industrial PC, `window_manager` fullscreen + auto-start |

- Offline: cache tài liệu vừa xem (Isar/Hive); hàng đợi khi mất mạng.
- Cả hai trỏ tới backend qua LAN (`API_BASE_URL` theo môi trường).

---

## 8. Vị trí trong roadmap

| Milestone | `dcid-app` (Flutter) |
|---|---|
| *Trước M1* | **Gỡ `dcid-frontend` (Next.js)** — §10 |
| **M1** (thin) | khởi tạo `dcid-app`: **login (self-JWT) + Search/Ask + Upload** (đủ demo vertical slice, chạy Android hoặc Windows) |
| **M2–M3** | versioning, admin/QA console (màn lớn), audit viewer |
| **M4** (đầy đủ) | **Snap & Ask** (camera), side-by-side + bbox, **kiosk Windows fullscreen**, offline |

> Vì chỉ 1 codebase, không còn tách "web trước / mobile sau" — làm thẳng trên `dcid-app`,
> ưu tiên chạy target tiện nhất ở M1 (Android hoặc Windows) rồi hoàn thiện dần.

---

## 9. Rủi ro riêng của hướng Flutter-only & giảm thiểu

| Rủi ro | Giảm thiểu |
|---|---|
| Admin/bảng biểu dày dữ liệu kém "webby" | `data_table_2`/`pluto_grid` + `fl_chart`; giữ admin gọn, phân trang server-side |
| Viewer PDF/chọn text | thử `pdfx`/Syncfusion **sớm ở M2**; nếu cần chỉ hiển thị ảnh trang + bbox |
| Kỹ năng Dart của team | 1 người học Dart trước M1; dùng Material sẵn có, tránh custom nặng |
| Camera trên desktop | Snap & Ask ưu tiên Android; kiosk Windows chủ yếu tra cứu/admin |

---

## 10. Xử lý `dcid-frontend` (Next.js) cũ

- **Gỡ khỏi repo** (còn trong git history nếu cần tra cứu): xóa thư mục `dcid-frontend/`.
- Cập nhật `README.md` (bỏ dòng frontend Next.js), thêm `dcid-app` (Flutter).
- **Không "format"** app Next.js nữa (kế hoạch format trước đây đã hủy do đổi hướng).

> Trạng thái: **plan, chưa thực thi**. Khi bạn duyệt, mình có thể (a) gỡ `dcid-frontend`, và/hoặc
> (b) tạo khung `dcid-app` Flutter (login + Search/Ask + Upload) cho M1.
