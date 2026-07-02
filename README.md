# Smart KCN Docs

Trợ lý kỹ thuật số & quản trị tri thức **on-premise** cho khu công nghiệp (KCN).

Monorepo:

| Thư mục | Vai trò |
|---|---|
| [`dcid-backend`](dcid-backend) | Governance/control plane (Spring Boot 3.3, Java 21): Auth/RBAC, quản lý tài liệu & version, audit ISO, storage MinIO, tích hợp CMMS/MES. |
| [`dcid-app`](dcid-app) | Frontend **Flutter** đa nền tảng — Kiosk (Windows) + Mobile (Android), Snap & Ask. |
| _`dcid-ai` (Python)_ | OCR/RAG/LLM — **tách riêng**, sẽ tạo ở M1. Xem kiến trúc. |

## Tài liệu

- **[Kiến trúc dự án](docs/ARCHITECTURE.md)** — sơ đồ tổng thể, luồng nghiệp vụ, data model, API.
- **[ERD & Database](docs/ERD.md)** — schema quan hệ, phân tách Postgres/Chroma/MinIO, vòng đời version.
- **[API Contract BE↔AI](docs/API-CONTRACT.md)** — nguồn sự thật ranh giới ingest/query/callback.
- [Work order: dựng khung dcid-ai](docs/PLAN-DCID-AI.md) — plan tự chứa cho agent thực thi.
- **[Kế hoạch Khóa luận 8 tuần (nhóm 5 người)](docs/PLAN-THESIS.md)** — đóng khung đề tài, dataset, thực nghiệm, lịch tuần. ← **dùng cái này**
- [Kế hoạch 6 tuần (product)](docs/PLAN-6-WEEKS.md) — bản định hướng sản phẩm, đã thay thế.
- [Roadmap 18 tuần](docs/ROADMAP.md) — 5 milestone, phân công, rủi ro.
- [Frontend (Flutter)](docs/FRONTEND.md) — kiến trúc `dcid-app`, kiosk/mobile.
- [Backend dev guide](dcid-backend/CLAUDE.md) — cách chạy, quy ước, auth.

## Chạy nhanh

**Backend**
```bash
docker-compose up -d postgres redis minio kafka zookeeper
cd dcid-backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# Login: POST http://localhost:8080/api/auth/login  {"username":"admin","password":"admin123"}
```

**Frontend (Flutter)**
```bash
cd dcid-app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080   # Android/Windows
```
