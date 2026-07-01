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
- [Kế hoạch triển khai](docs/ROADMAP.md) — 5 milestone, phân công, rủi ro.
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
