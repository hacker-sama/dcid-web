# Smart KCN Docs

Trợ lý kỹ thuật số & quản trị tri thức **on-premise** cho khu công nghiệp (KCN).

Monorepo:

| Thư mục | Vai trò |
|---|---|
| [`dcid-backend`](dcid-backend) | Governance/control plane (Spring Boot 3.3, Java 21): Auth/RBAC, quản lý tài liệu & version, audit ISO, storage MinIO, tích hợp CMMS/MES. |
| [`dcid-frontend`](dcid-frontend) | Kiosk/Mobile UI (Next.js). |
| _AI service (Python)_ | OCR/RAG/LLM — **tách riêng**, chưa nằm trong repo. Xem kiến trúc. |

## Tài liệu

- **[Kiến trúc dự án (đề xuất)](docs/ARCHITECTURE.md)** — sơ đồ tổng thể, luồng nghiệp vụ, roadmap.
- [Backend dev guide](dcid-backend/CLAUDE.md) — cách chạy, quy ước, auth.

## Chạy nhanh (backend)

```bash
docker-compose up -d postgres redis minio kafka zookeeper
cd dcid-backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# Login: POST http://localhost:8080/api/auth/login  {"username":"admin","password":"admin123"}
```
