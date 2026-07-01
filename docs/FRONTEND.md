# Smart KCN Docs — Frontend & Mobile (đề xuất triển khai)

> Đọc kèm [`ARCHITECTURE.md`](ARCHITECTURE.md) và [`ROADMAP.md`](ROADMAP.md).
> **Quyết định đã chốt:** Web/Kiosk = **Next.js** (repo `dcid-frontend`) · Mobile hiện trường =
> **Flutter native** (repo `dcid-mobile`) · chung một **backend REST + self-JWT**.

---

## 0. Hiện trạng & phạm vi

- `dcid-frontend` là **Next.js 14** nhưng **vẫn thuộc domain cũ** (pages `citizen/*`, `officer/*`,
  auth NextAuth + **Keycloak**) → cần **format** (xem *Phần B*).
- Mobile: làm **app Flutter riêng** cho tablet/điện thoại hiện trường (camera Snap & Ask, native, offline).
- Hai client, **một hợp đồng API** (mục 6) — logic quyền/nghiệp vụ nằm ở backend.

```
dcid-web/
├── dcid-frontend/   Next.js — Web console + Kiosk (Operator/Engineer/QA/Admin)
├── dcid-mobile/     Flutter — App hiện trường (Snap & Ask)          ← TẠO MỚI
├── dcid-backend/    Spring Boot (đã có)
└── dcid-ai/         Python (M1)
```

---

## 1. Phân vai hai client

| Client | Thiết bị | Vai chính | Điểm mạnh |
|---|---|---|---|
| **Next.js (web/kiosk)** | Industrial/Mini PC, màn lớn | QA_ADMIN (upload/versioning), ADMIN (user/audit), Engineer tra cứu tại trạm | màn rộng cho **side-by-side**, quản trị, bàn phím |
| **Flutter (mobile)** | Tablet/điện thoại | OPERATOR & ENGINEER lưu động | **camera Snap & Ask**, offline, rung/haptic, dùng 1 tay/găng tay |

> Cùng hỗ trợ tra cứu + Ask; nhưng **upload/versioning/admin** ưu tiên web, **Snap & Ask lưu động** ưu tiên mobile.

**Đánh đổi đã chấp nhận:** 2 codebase (React + Dart) → cần kỹ năng Flutter; bù lại app native
camera/offline mạnh hơn PWA và phân phối APK nội bộ chủ động.

---

## 2. Web (Next.js) — kiến trúc

- **Tái dùng nguyên stack:** App Router, TailwindCSS, **shadcn/ui**, **TanStack Query**, RHF+Zod,
  Axios (`lib/apiClient`), **next-intl** (UI đa ngôn ngữ), next-themes.
- **Auth self-JWT:** login → `POST /api/auth/login` → lưu token ở **httpOnly cookie** (qua Route Handler);
  `middleware.ts` chặn route theo role đọc từ JWT. *(Có thể giữ NextAuth với **Credentials provider**
  gọi backend login để tái dùng session — xem Phần B.)*
- **Kiosk mode:** Chromium `--kiosk --app=<url>` fullscreen trên Industrial PC.
- Viewer **side-by-side + overlay bbox** bằng canvas/SVG; ảnh trang lấy qua endpoint proxy backend.

---

## 3. Mobile (Flutter) — kiến trúc

**Gói đề xuất:** `dio` (HTTP + interceptor gắn Bearer) · `flutter_riverpod` (state) · `go_router` (điều hướng
+ guard theo role) · `camera`/`image_picker` (Snap & Ask) · `flutter_secure_storage` (lưu JWT an toàn) ·
`cached_network_image` · `hive`/`sqflite` (offline cache) · `intl`/`easy_localization` (đa ngôn ngữ).

```
dcid-mobile/  (Flutter)
├── lib/
│   ├── main.dart
│   ├── core/            # env, theme (touch/glove), router (go_router), di
│   ├── data/
│   │   ├── api_client.dart      # Dio + interceptor JWT + 401 refresh
│   │   ├── auth_repository.dart  # login → secure storage
│   │   └── docs_repository.dart  # query / documents
│   ├── features/
│   │   ├── auth/         # login, role guard
│   │   ├── search/       # tra cứu + Ask
│   │   ├── snap_ask/     # camera → gửi ảnh + câu hỏi
│   │   ├── viewer/       # ảnh trang + CustomPaint vẽ bbox
│   │   └── answer/       # câu trả lời + citation + guardrail banner
│   └── l10n/            # vi, en (mở zh/ja)
├── assets/
└── pubspec.yaml
```

- **Auth:** login → nhận JWT → `flutter_secure_storage`; Dio interceptor gắn `Authorization: Bearer`.
- **Snap & Ask:** `camera`/`image_picker` chụp → upload multipart tới `POST /api/query` (kèm ảnh) →
  backend forward `dcid-ai` (OCR ad-hoc + retrieve).
- **Side-by-side/bbox:** `Stack` + `CustomPaint` vẽ khoanh đỏ theo toạ độ chuẩn hoá.
- **Guardrail UI:** `locked=true` → banner đỏ, ẩn câu trả lời tự sinh (giống web).
- **Offline:** cache tài liệu vừa xem (Hive/sqflite); hàng đợi khi mất mạng.
- **UX xưởng:** nút ≥ 48dp, chữ lớn, theme tối, haptic khi cảnh báo.

---

## 4. Bản đồ màn hình theo vai (áp cho cả 2 client, UI ẩn/hiện theo role)

| Vai | Màn hình |
|---|---|
| **Chung** | login, 403, chọn ngôn ngữ, hồ sơ (`/me`) |
| **OPERATOR** | tra cứu **SOP & cảnh báo an toàn**; Search + Ask; **Snap & Ask** (mobile); xem tài liệu + citation |
| **ENGINEER** | + **bản vẽ / sơ đồ mạch / nhật ký bảo trì**; **side-by-side viewer** |
| **QA_ADMIN** | **upload** tài liệu; **quản lý version** (ACTIVE/SUPERSEDED/OBSOLETE) — *ưu tiên web* |
| **ADMIN** | quản lý user/role; **audit log viewer** — *ưu tiên web* |

> Chốt chặn thật ở backend `@PreAuthorize`; UI chỉ ẩn/hiện cho gọn.

---

## 5. Luồng UX đặc thù (cả 2 client)

- **Snap & Ask** (mobile mạnh nhất): camera → ảnh + câu hỏi → answer + citation.
- **Side-by-side + overlay khoanh đỏ bbox** số liệu (kỹ sư "mắt thấy tai nghe").
- **Guardrail:** cosine < 0.60 → banner đỏ "Yêu cầu kỹ sư xác minh", ẩn câu trả lời tự sinh.
- **Luôn hiển thị nguồn:** tên tài liệu + version + số trang kèm mọi câu trả lời.

---

## 6. Hợp đồng API dùng chung (web + mobile)

`POST /api/auth/login` · `GET /api/auth/me` · `POST /api/query` *(hỗ trợ multipart khi Snap & Ask)* ·
`GET /api/documents` · `POST /api/documents` · `POST /api/documents/{id}/versions` ·
`POST /api/documents/{versionId}/obsolete` · `GET /api/admin/audit-logs` ·
`GET /api/files/...` (proxy ảnh/crop từ MinIO, có auth). Base URL qua env
(`NEXT_PUBLIC_API_URL` / `API_BASE_URL`).

---

## 7. Triển khai

| Client | Cách deploy |
|---|---|
| **Web/Kiosk** | Docker (đã có `Dockerfile`) phục vụ từ Edge; Industrial PC chạy Chromium **kiosk mode** |
| **Mobile** | Build **APK** → **phân phối nội bộ** (air-gapped): MDM nội bộ / cài tay / internal store. Camera native (không vướng ràng buộc HTTPS như PWA) |

Cả hai trỏ tới backend qua LAN; offline cache phía client cho tài liệu vừa xem.

---

## 8. Vị trí trong roadmap

| Milestone | Web (Next.js) | Mobile (Flutter) |
|---|---|---|
| *Trước M1* | **Format `dcid-frontend`** (Phần B) | — |
| **M1** (thin) | login + Search/Ask + Upload (QA) — đủ chứng minh vertical slice | *(chưa; dùng web để test lõi)* |
| **M2–M3** | versioning, admin, audit viewer | **khởi tạo `dcid-mobile`**: login + Search/Ask |
| **M4** (đầy đủ) | side-by-side + bbox, kiosk | **Snap & Ask**, side-by-side + bbox, offline |

> Chiến lược: **web trước để khoá lõi RAG (M1)**, Flutter vào cuộc từ M2–M4 khi API đã ổn định →
> tránh sửa app native nhiều lần.

---
---

# Phần B — Kế hoạch "format" `dcid-frontend` (chưa code)

> Mục tiêu: đưa Next.js app về **khung sạch KCN + self-JWT**, giữ hạ tầng tái dùng — tương tự cách đã làm với backend.

### B1. XÓA (domain e-gov cũ)
- [ ] `app/citizen/**` (dashboard, applications, appointments, notifications, procedures…)
- [ ] `app/officer/**` (dashboard, applications, procedures, reports, users, audit-log)
- [ ] `components/citizen/**`, `components/officer/**`
- [ ] `hooks/` của các domain trên (useApplications, useProcedures, useAppointments…)
- [ ] Route/type/query-key tương ứng trong `constants/`, `types/`
- [ ] Chuỗi i18n cũ trong `messages/*.json`

### B2. ĐỔI AUTH: Keycloak → self-JWT
- [ ] Bỏ Keycloak provider trong `app/api/auth/[...nextauth]/route.ts`
- [ ] **Phương án khuyến nghị:** giữ **NextAuth** nhưng dùng **Credentials provider** gọi
      `POST /api/auth/login` → lưu JWT vào session (httpOnly cookie), tái dùng `middleware.ts` + `useSession`.
      *(Phương án nhẹ thay thế: bỏ hẳn NextAuth, tự lưu JWT ở httpOnly cookie qua Route Handler.)*
- [ ] Gỡ biến môi trường `KEYCLOAK_*`; rà lại `NEXTAUTH_*` theo phương án chọn
- [ ] `lib/apiClient.ts`: gắn `Authorization: Bearer <jwt>`, xử lý 401 (logout/redirect)

### B3. ĐỔI RBAC & điều hướng
- [ ] Vai `citizen/officer` → **`OPERATOR / ENGINEER / QA_ADMIN / ADMIN`**
- [ ] Gộp route theo nhóm `app/(app)/...` + layout guard theo role (đọc từ JWT)
- [ ] `middleware.ts`: chặn theo role mới

### B4. GIỮ (hạ tầng tái dùng)
- [ ] `components/ui/**` (shadcn), `lib/`, Tailwind config, `next-intl` scaffolding, providers
- [ ] Mẫu hook TanStack Query, `constants/query-keys` pattern

### B5. THÊM (khung KCN tối thiểu)
- [ ] `app/(auth)/login` (self-JWT) · `app/403`
- [ ] `app/(app)/search` (tra cứu + Ask) · `app/(app)/documents` (QA upload/versioning) · `app/(app)/admin`
- [ ] `hooks/useAuth`, `useAskQuery`, `useDocuments`
- [ ] Cập nhật `dcid-frontend/CLAUDE.md` cho khớp (bỏ mô tả Keycloak/citizen/officer)

### B6. Cây thư mục mục tiêu (sau format)
```
app/(auth)/login · app/403 · app/(app)/{search, ask/[id], documents, admin} · app/layout.tsx
components/{search, viewer, upload, shared, ui}
hooks/{useAuth, useAskQuery, useDocuments, useAuditLogs}
lib/apiClient.ts · constants/{routes, query-keys} · messages/{vi,en}.json · middleware.ts
```

> Đây là **plan, chưa thực thi**. Khi bạn duyệt, có thể chạy "format FE" tương tự backend
> (xóa domain cũ + chuyển self-JWT) trước khi vào M1.
