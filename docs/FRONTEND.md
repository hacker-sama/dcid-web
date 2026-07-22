# Smart KCN Docs — Frontend (Flutter, đa nền tảng)

> Đọc kèm [`ARCHITECTURE.md`](ARCHITECTURE.md) và [`ROADMAP.md`](ROADMAP.md).
> **Quyết định đã chốt (cập nhật 02/07/2026):** **Flutter-only** — MỘT project `dcid-app`, 1 codebase Dart,
> build ra 2 target: **Mobile** (Android — Snap & Ask hiện trường) và **Web** (trình duyệt — Kiosk +
> Admin/QA console, thay cho phương án Windows desktop native ban đầu — xem §0.1). **Bỏ Next.js/React**
> — `dcid-frontend` cũ đã gỡ.

---

## 0. Vì sao Flutter-only

- Team nhỏ (1 dev) → **1 codebase, 1 ngôn ngữ (Dart)**, rẻ & dễ bảo trì.
- Kiosk/Admin và Mobile đều là **touch/UX xưởng** → dùng chung phần lớn code, chỉ đổi layout theo form factor.
- `dcid-frontend` (Next.js) là app **domain cũ**, kiểu gì cũng viết lại → đã gỡ, không "format".

**Đánh đổi đã chấp nhận:** màn **Admin/QA dày dữ liệu** (bảng version, audit, dashboard, viewer PDF) là
điểm yếu tương đối của Flutter → dùng `data_table_2`/`pluto_grid`, `fl_chart`, `pdfx`/Syncfusion; tốn công
hơn React nhưng chấp nhận được ở quy mô này.

### 0.1. Cập nhật: máy tính (kiosk/admin) chạy **Web**, không phải app native Windows

Bản thiết kế đầu tiên của tài liệu này chọn Windows desktop native cho kiosk/admin (lý do khi đó:
tránh CanvasKit nặng, tránh điểm yếu text/accessibility của Flutter Web). Quyết định đã đổi:
**trên nền tảng máy tính, ưu tiên Web** (mở bằng trình duyệt) thay vì đóng gói app `.exe`.

**Lý do đổi:**
- Không cần build/ký/phân phối `.exe` riêng cho từng máy trạm — chỉ cần mở URL nội bộ (LAN), giống
  hệt cách vận hành các hệ thống nội bộ khác trong nhà máy.
- Cập nhật tức thời: deploy 1 lần ở server, mọi kiosk/màn admin tự có bản mới khi tải lại trang —
  không phải cài lại từng máy.
- Vẫn **on-premise/air-gapped được**: web server (Flutter Web build tĩnh) phục vụ trong LAN nhà máy,
  không cần internet, không khác gì app native về mặt bảo mật dữ liệu.
- "Kiosk mode" (fullscreen, khoá thoát) vẫn đạt được ở tầng **trình duyệt/OS**, không cần code trong
  app: Chromium `--kiosk --app=<url>` trỏ tới trang web, hoặc phím F11.
- Trade-off chấp nhận: tải trang lần đầu nặng hơn app native (CanvasKit ~2-3MB) — chấp nhận được
  trong LAN nội bộ, cache trình duyệt sau lần đầu.

**Hệ quả kỹ thuật (đã áp dụng vào code):**
- `lib/core/kiosk.dart` **không còn dùng `dart:io`/`Platform.isWindows`** — mọi platform-check kiểu đó
  làm vỡ `flutter build web`. Hàm kiosk giờ là no-op; fullscreen do trình duyệt/OS lo, không phải app.
- Luồng **upload file đổi từ path-based sang bytes-based**
  (`FilePicker.pickFiles(..., withData: true)` → `Uint8List` → `MultipartFile.fromBytes`): trên web,
  `PlatformFile.path` **luôn `null`** (trình duyệt không lộ đường dẫn hệ thống), nên chỉ cách
  bytes-based mới chạy được trên cả Android lẫn Web bằng cùng 1 code path.
- Thư mục `windows/` trong `dcid-app` được giữ lại (không xoá, không tốn gì) nhưng **không phải
  target chính thức nữa** — không đầu tư thêm tính năng riêng cho nó.

---

## 1. Nền tảng target & chiến lược responsive

Một Flutter project, nhiều target:

| Target build | Thiết bị | Vai chính |
|---|---|---|
| **Android** (APK) | tablet/điện thoại hiện trường | OPERATOR, ENGINEER lưu động — **Snap & Ask** |
| **Web** (`flutter build web`) | trình duyệt trên Industrial/Mini PC | Kiosk tra cứu tại trạm + **Admin/QA console** |
| *(Windows exe — dự phòng)* | thư mục `windows/` vẫn còn, không đầu tư thêm | chỉ dùng nếu sau này cần thật sự offline-native |

- **Responsive/adaptive:** `LayoutBuilder` + breakpoints (hoặc `flutter_adaptive_scaffold`): phone = 1 cột,
  điều hướng dưới; màn lớn/kiosk = master-detail, **side-by-side viewer**, navigation rail.
- **Điều hướng:** `go_router` + guard theo role.
- **Kiosk mode (Web):** không code trong app — dùng trình duyệt/OS: Chromium
  `--kiosk --app=<url-nội-bộ>` trỏ tới bản build web, hoặc F11 fullscreen thường.

---

## 2. Kiến trúc app (`dcid-app`)

**Gói đề xuất:** `dio` (HTTP + interceptor Bearer) · `flutter_riverpod` (state) · `go_router` (routing) ·
`flutter_secure_storage` (JWT — hỗ trợ cả web lẫn Android) · `file_picker` (upload, **bytes-based** —
bắt buộc trên web vì `path` luôn null) · `camera`/`image_picker` (Snap & Ask, mobile) ·
`cached_network_image` · `isar`/`hive` (offline cache mobile) · `intl`+gen-l10n (đa ngôn ngữ) ·
`fl_chart` (biểu đồ) · `data_table_2`/`pluto_grid` (bảng admin) · `pdfx`/`syncfusion_flutter_pdfviewer` (PDF).

```
dcid-app/  (Flutter)
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── env.dart              # API_BASE_URL theo build flavor
│   │   ├── theme.dart            # touch/glove: target ≥48dp, font lớn, dark
│   │   ├── router.dart           # go_router + role guard
│   │   ├── responsive.dart       # breakpoints phone / kiosk-desktop
│   │   └── kiosk.dart            # no-op (kiosk mode do trình duyệt/OS đảm nhiệm — §0.1)
│   ├── data/
│   │   ├── api_client.dart       # Dio + interceptor JWT + 401
│   │   ├── auth_repository.dart  # login → secure storage
│   │   └── docs_repository.dart  # query / documents / versions (upload: bytes-based)
│   ├── features/
│   │   ├── auth/                 # login, role guard, /me
│   │   ├── search/               # tra cứu + Ask
│   │   ├── snap_ask/             # camera → ảnh + câu hỏi (mobile)
│   │   ├── answer/                # câu trả lời + citation + guardrail banner
│   │   ├── documents/             # danh sách/chi tiết/upload tài liệu (web-first)
│   │   ├── viewer/                # ảnh trang + CustomPaint vẽ bbox; PDF
│   │   └── admin/                 # users, audit (màn lớn — web)
│   └── l10n/                     # vi, en (mở zh/ja)
├── assets/
├── android/  ├── web/             # 2 target chính thức
└── pubspec.yaml
```

---

## 3. Bản đồ màn hình theo vai (UI ẩn/hiện theo role)

| Vai | Màn hình | Ưu tiên surface |
|---|---|---|
| **Chung** | login, 403, chọn ngôn ngữ, hồ sơ (`/me`) | mọi target |
| **OPERATOR** | tra cứu **SOP & cảnh báo an toàn**; Search + Ask; **Snap & Ask** | mobile |
| **ENGINEER** | + **bản vẽ / sơ đồ mạch / nhật ký bảo trì**; **side-by-side viewer** | mobile + kiosk |
| **QA_ADMIN** | **upload** tài liệu; **quản lý version** (ACTIVE/SUPERSEDED/OBSOLETE) | web (màn lớn) |
| **ADMIN** | quản lý user/role; **audit log viewer** | web (màn lớn) |

> Chốt chặn quyền thật ở backend `@PreAuthorize`; UI chỉ ẩn/hiện cho gọn.

---

## 4. Luồng UX đặc thù hiện trường

- **Snap & Ask** (mobile): `camera`/`image_picker` chụp → upload multipart tới `POST /api/query` (kèm ảnh)
  → backend forward `dcid-ai` → answer + citation.
- **Side-by-side & Hộp thoại Trích dẫn Không Gian (`AlertDialog`):** Mỗi kết quả tra cứu hiển thị danh sách nhãn trích dẫn (`Trang X [Bbox]`). Khi click vào nhãn trích dẫn, hệ thống mở Hộp thoại hiển thị chính xác **Tọa độ Bbox (`p{pageNo}_[minX,minY,maxX,maxY]`)** kèm **đoạn văn bản gốc (`snippet` tối đa 300 ký tự)** được AI tham chiếu.
- **Guardrail UI & Reasoning `<think>`:** `locked=true` (cosine < 0.60) → **banner đỏ** "Yêu cầu kỹ sư xác minh", ẩn câu trả lời tự sinh. Tự động lọc và hiển thị nội dung suy luận `<think>` trong thẻ gập (accordion/details) gọn gàng.
- **Touch/glove:** target ≥ 48dp, chữ lớn, ít gõ phím, theme tối, haptic khi cảnh báo.
- **Luôn hiển thị nguồn:** tên tài liệu + version + số trang + tọa độ Bbox + đoạn trích dẫn kèm mọi câu trả lời.

---

## 5. Auth self-JWT (đa nền tảng)

- Login → `POST /api/auth/login` → JWT lưu ở **`flutter_secure_storage`** (Keystore Android /
  IndexedDB-backed storage trên web).
- `Dio` interceptor gắn `Authorization: Bearer <jwt>`; 401 → logout/redirect.
- Role đọc từ JWT → `go_router` guard + ẩn/hiện menu.
- **CORS (chỉ áp dụng target Web):** trình duyệt gọi thẳng backend qua HTTP, nên origin của trang
  web phải nằm trong `app.cors.allowed-origins` của `dcid-backend` (mặc định `http://localhost:3000`).
  Khi chạy `flutter run -d chrome`, cố định port bằng `--web-port=3000`, hoặc thêm origin thực tế vào
  `CORS_ALLOWED_ORIGINS` (backend) cho môi trường deploy.

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
| **Web (kiosk/admin)** | `flutter build web` → static files, phục vụ bằng web server nội bộ (nginx/Caddy trong LAN, hoặc cùng container với backend). Industrial PC mở bằng Chromium `--kiosk --app=<url>` |

- Offline: cache tài liệu vừa xem (Isar/Hive trên mobile; service worker/PWA cache cho web nếu cần sau).
- Cả hai trỏ tới backend qua LAN (`API_BASE_URL` theo môi trường, truyền lúc build bằng
  `--dart-define=API_BASE_URL=...`).
- Web build **không cần internet lúc chạy** — phục vụ file tĩnh từ server nội bộ, vẫn đúng tinh thần
  on-premise/air-gapped của dự án.

---

## 8. Vị trí trong roadmap

| Milestone | `dcid-app` (Flutter) |
|---|---|
| *Trước M1* | **Gỡ `dcid-frontend` (Next.js)** — đã xong |
| **M1** (thin) | khởi tạo `dcid-app`: **login (self-JWT) + Search/Ask + Upload** — ✅ đã xong, verify được trên cả Android build lẫn `flutter build web` |
| **M2–M3** | versioning, admin/QA console (màn lớn — web), audit viewer |
| **M4** (đầy đủ) | **Snap & Ask** (camera, mobile), side-by-side + bbox, **kiosk web fullscreen** (trình duyệt), offline (mobile) |

> Vì chỉ 1 codebase, không còn tách "web trước / mobile sau" theo nghĩa 2 dự án — làm thẳng trên
> `dcid-app`, chạy song song 2 target (`flutter run -d chrome` / `-d <android-device>`).

---

## 9. Rủi ro riêng của hướng Flutter-only & giảm thiểu

| Rủi ro | Giảm thiểu |
|---|---|
| Admin/bảng biểu dày dữ liệu kém "webby" | `data_table_2`/`pluto_grid` + `fl_chart`; giữ admin gọn, phân trang server-side |
| Viewer PDF/chọn text | thử `pdfx`/Syncfusion **sớm ở M2**; nếu cần chỉ hiển thị ảnh trang + bbox |
| Kỹ năng Dart của team | 1 người học Dart trước M1; dùng Material sẵn có, tránh custom nặng |
| Camera trên desktop/web | Snap & Ask ưu tiên Android; web/kiosk chủ yếu tra cứu/admin (không cần camera) |
| `dart:io` lọt vào code dùng chung → vỡ `flutter build web` | Không import `dart:io`/`Platform` ở tầng chia sẻ (`core/`, `data/`); nếu cần phân nhánh nền tảng, dùng `kIsWeb` (package:flutter/foundation.dart), không dùng `dart:io` |
| CanvasKit tải nặng lần đầu (web) | chấp nhận trong LAN nội bộ; cache trình duyệt sau lần đầu; không phải vấn đề vì máy trạm cố định |

---

## 10. Xử lý `dcid-frontend` (Next.js) cũ

- **Gỡ khỏi repo** (còn trong git history nếu cần tra cứu): xóa thư mục `dcid-frontend/`.
- Cập nhật `README.md` (bỏ dòng frontend Next.js), thêm `dcid-app` (Flutter).
- **Không "format"** app Next.js nữa (kế hoạch format trước đây đã hủy do đổi hướng).

> Trạng thái: **plan, chưa thực thi**. Khi bạn duyệt, mình có thể (a) gỡ `dcid-frontend`, và/hoặc
> (b) tạo khung `dcid-app` Flutter (login + Search/Ask + Upload) cho M1.
