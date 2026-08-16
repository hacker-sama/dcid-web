# DCID: Digital Cognitive InDustrial System

[![CI](https://github.com/hacker-sama/dcid-web/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/hacker-sama/dcid-web/actions/workflows/ci.yml)
[![Deploy](https://github.com/hacker-sama/dcid-web/actions/workflows/deploy.yml/badge.svg?branch=main)](https://github.com/hacker-sama/dcid-web/actions/workflows/deploy.yml)

Hệ thống trợ lý nhận thức kỹ thuật số & quản trị tri thức công nghiệp **on-premise** (**DCID: Digital Cognitive InDustrial System**).

Monorepo:

| Thư mục | Vai trò |
|---|---|
| [`dcid-backend`](dcid-backend) | Governance/control plane (Spring Boot 3.3, Java 21): Auth/RBAC, quản lý tài liệu & version, API Xóa tài liệu, audit ISO, storage MinIO, WebSocket STOMP. |
| [`dcid-app`](dcid-app) | Frontend **Flutter** đa nền tảng — Web (Kiosk/Admin) + Mobile (Android). Đã có Tra cứu RAG, Upload tài liệu, Xóa tài liệu (AlertDialog xác nhận). |
| [`dcid-ai`](dcid-ai) | AI plane (Python/FastAPI) — OCR/RAG/LLM, Qdrant vector DB, Celery/Redis và SSE Streaming. |


## Các Phân hệ Hệ thống AI Hỏi đáp Local

Hệ thống được thiết kế theo kiến trúc **Dual-Plane Local RAG** độc lập tuyệt đối:

### Phân hệ A — Tra cứu Kho tài liệu chính thức (Official Document Governance)
- **Mục tiêu**: Quản lý các tài liệu quy trình SOP, bản vẽ kỹ thuật, nội quy nhà máy theo chuẩn ISO.
- **Phân quyền RBAC**: So sánh mức độ phân quyền `min_role` (`OPERATOR` < `ENGINEER` < `QA_ADMIN` < `ADMIN`). Tự động lọc bỏ các tài liệu vượt quá cấp bậc người dùng.
- **Quản lý Vòng đời Version**: Upload phiên bản mới (v2, v3...), duyệt phát hành `ACTIVE` (tự động chuyển version active cũ thành `SUPERSEDED`), và đánh dấu lỗi thời `OBSOLETE`.

### Phân hệ B — Hỏi đáp Tài liệu Công khai Ẩn danh (`/ask`)
- **Mục tiêu**: Khách chưa đăng nhập có thể dùng thử hỏi đáp riêng với các file PDF cá nhân tải lên.
- **Bảo mật & Cô lập Dữ liệu**:
  - Không cần JWT Bearer header. Xác thực qua **Session Token** ngẫu nhiên.
  - File tạm lưu tại thư mục riêng `sessions/{sessionId}/` trên MinIO.
  - Vector tạm được cô lập hoàn toàn theo `sessionId` trên Qdrant.
- **Tự động Tiêu hủy (TTL Cleanup Job)**: Tiến trình `@Scheduled` chạy định kỳ 10 phút/lần tự động xóa sạch Vector Qdrant ➔ File MinIO ➔ DB Record của các phiên quá hạn 2 giờ.

---

## Tài liệu

- **[Cài đặt & chạy dự án](docs/SETUP.md)** — hướng dẫn đầy đủ cho người mới clone repo. ← **bắt đầu ở đây**
- **[Kiến trúc dự án](docs/ARCHITECTURE.md)** — sơ đồ tổng thể, luồng nghiệp vụ, data model, API.
- **[ERD & Database](docs/ERD.md)** — schema quan hệ, phân tách Postgres/Qdrant/MinIO, vòng đời version.
- **[API Contract BE↔AI](docs/API-CONTRACT.md)** — nguồn sự thật ranh giới ingest/query/callback.
- **[Bàn giao VPS & phân quyền](docs/VPS-TEAM-HANDOVER.md)** — tài khoản Linux/PostgreSQL, SSH tunnel, thu hồi quyền.
- **[Deploy Runbook](docs/DEPLOY-RUNBOOK.md)** — vận hành CI/CD, deploy thủ công, rollback, xử lý sự cố.
- [Work order: dựng khung dcid-ai](docs/PLAN-DCID-AI.md) — plan tự chứa cho agent thực thi. ✅ đã xong
- [Work order: Flutter màn Tài liệu + Upload](docs/PLAN-FLUTTER-DOCS.md) — plan tự chứa cho agent thực thi. ✅ đã xong
- **[Kế hoạch Khóa luận 8 tuần (nhóm 5 người)](docs/PLAN-THESIS.md)** — đóng khung đề tài, dataset, thực nghiệm, lịch tuần. ← **dùng cái này**
- [Kế hoạch 6 tuần (product)](docs/PLAN-6-WEEKS.md) — bản định hướng sản phẩm, đã thay thế.
- [Roadmap 18 tuần](docs/ROADMAP.md) — 5 milestone, phân công, rủi ro.
- [Frontend (Flutter)](docs/FRONTEND.md) — kiến trúc `dcid-app`, web (kiosk/admin) + mobile.
- [Backend dev guide](dcid-backend/CLAUDE.md) — cách chạy, quy ước, auth.

## Chạy nhanh

Hướng dẫn đầy đủ (yêu cầu công cụ, từng bước, kiểm tra, troubleshooting):
**[docs/SETUP.md](docs/SETUP.md)**. Tóm tắt các luồng khởi chạy chính:

```bash
# 1. Hạ tầng
docker compose up -d postgres minio qdrant ai-ocr redis

# 2. Backend — terminal riêng
cd dcid-backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# Login: POST http://localhost:8080/api/auth/login  {"username":"admin","password":"admin123"}

# 3. AI service — terminal riêng (mở 2 tab)
# Tab 1: API Server
cd dcid-ai && python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt && copy .env.example .env
uvicorn app.main:app --port 8000
# Tab 2: Celery Worker (chạy task nền)
cd dcid-ai && .venv\Scripts\activate
celery -A app.celery_app.celery_app worker --loglevel=info -Q ingest,default

# 4. Frontend — terminal riêng
cd dcid-app && flutter pub get
flutter run -d chrome --web-port=3000 --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080   # web (kiosk/admin)
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080                             # mobile (Android)
```

