# Smart KCN Docs

Trợ lý kỹ thuật số & quản trị tri thức **on-premise** cho khu công nghiệp (KCN).

Monorepo:

| Thư mục | Vai trò |
|---|---|
| [`dcid-backend`](dcid-backend) | Governance/control plane (Spring Boot 3.3, Java 21): Auth/RBAC, quản lý tài liệu & version, API Xóa tài liệu, audit ISO, storage MinIO, WebSocket STOMP. |
| [`dcid-app`](dcid-app) | Frontend **Flutter** đa nền tảng — Web (Kiosk/Admin) + Mobile (Android). Đã có Tra cứu RAG, Upload tài liệu, Xóa tài liệu (AlertDialog xác nhận). |
| [`dcid-ai`](dcid-ai) | AI plane (Python/FastAPI) — OCR/RAG/LLM. Kiến trúc mô-đun hóa `src/`; Qwen2-VL-2B (Q4_K_M) Visual Bbox Crop & Pure-Text Skip; ChromaDB Persistent Vector DB; Static file server `/uploads`; Celery+Redis; SSE Streaming. |


## Tài liệu

- **[Cài đặt & chạy dự án](docs/SETUP.md)** — hướng dẫn đầy đủ cho người mới clone repo. ← **bắt đầu ở đây**
- **[Kiến trúc dự án](docs/ARCHITECTURE.md)** — sơ đồ tổng thể, luồng nghiệp vụ, data model, API.
- **[ERD & Database](docs/ERD.md)** — schema quan hệ, phân tách Postgres/Chroma/MinIO, vòng đời version.
- **[API Contract BE↔AI](docs/API-CONTRACT.md)** — nguồn sự thật ranh giới ingest/query/callback.
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
docker-compose up -d postgres minio chroma ai-ocr redis

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
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080   # web (kiosk/admin)
flutter run --dart-define=API_BASE_URL=http://localhost:8080                             # mobile (Android)
```
