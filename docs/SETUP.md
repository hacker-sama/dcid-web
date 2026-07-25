# Cài đặt & chạy dự án (Getting Started)

> Hướng dẫn cho người **mới clone repo**. Phản ánh đúng trạng thái hiện tại (16/07/2026) —
> xem [§5](#5-cái-gì-chạy-được--cái-gì-còn-mock) để biết rõ phần nào là thật, phần nào còn mock.
> **Toàn bộ luồng dưới đây đã chạy thật và verify end-to-end** (login → upload PDF → OCR qua `ai-ocr` →
> chunking → embedding → index ChromaDB → version ACTIVE với đúng số trang → hỏi–đáp), không phải suy đoán từ code.

---

## 0. Tổng quan nhanh

Monorepo gồm 4 service chính + hạ tầng dùng chung:

```
dcid-backend/   Spring Boot (Java 21)  — auth, RBAC, upload tài liệu, hỏi–đáp, audit    :8080
dcid-ai/        FastAPI (Python)       — orchestrator RAG (chunk, embed E5, ChromaDB)   :8000
dcid-ai-ocr/    FastAPI (Python/Uvicorn)— worker bóc tách chữ chuyên dụng (PaddleOCR)    :8001
dcid-app/       Flutter                — web (kiosk/admin) + Android (mobile)            :3000 (web dev)
```

Hạ tầng (Docker): **PostgreSQL** (bắt buộc) · **MinIO** (bắt buộc để upload) · **ChromaDB** (bắt buộc cho vector RAG) · Redis, Kafka, Zookeeper (đã cấu hình sẵn).

---

## 1. Yêu cầu công cụ

| Công cụ | Phiên bản tối thiểu | Đã verify trên máy dev với |
|---|---|---|
| **JDK** | 21+ | JDK 24 (build dùng `--release 21`, không sao) |
| **Python** | 3.11+ | Python 3.12.10 |
| **Flutter** | 3.35+ (kèm Dart ≥ 3.11) | Flutter 3.41.9 |
| **Docker Desktop** | bất kỳ bản còn hỗ trợ | Docker 29.4.2 |
| **Git** | — | — |

Không cần cài Maven/uvicorn/Flutter SDK riêng theo cách thủ công phức tạp — repo đã có Maven Wrapper
(`./mvnw`), và Python/Flutter dùng công cụ chuẩn.

**Windows:** để `flutter build`/`flutter run` cho Android hoạt động (plugin cần symlink), bật
**Developer Mode**: chạy `start ms-settings:developers` rồi bật toggle. Không cần bước này nếu chỉ
chạy target **web**.

---

## 2. Clone & tổng quan thư mục

```bash
git clone <repo-url> dcid-web
cd dcid-web
```

```
dcid-web/
├── dcid-backend/   ./mvnw ...      (xem dcid-backend/CLAUDE.md)
├── dcid-ai/        pip / uvicorn   (xem dcid-ai/README.md)
├── dcid-app/       flutter ...     (xem dcid-app/README.md)
├── docker-compose.yml
└── docs/           kiến trúc, ERD, API contract, roadmap...
```

---

## 3. Khởi động từng phần

### 3.1. Hạ tầng (Docker)

Mở **Docker Desktop** trước (Windows/Mac cần app chạy nền), sau đó từ **repo root**:

```bash
# Cách 1: Khởi động toàn bộ hạ tầng + service OCR và ChromaDB cho local dev
docker-compose up -d postgres minio chroma ai-ocr

# Cách 2 (Khuyến nghị để kiểm chứng full e2e nhanh nhất): Khởi động toàn bộ cả backend và ai
docker-compose up -d
```

> Cần `postgres` + `minio` + `chroma` + `ai-ocr` để chạy đủ tính năng hiện có (auth, upload, OCR, chunk, embed, query). Nếu chọn chạy local dev (`dcid-backend` và `dcid-ai` chạy ngoài container bằng lệnh ở mục 3.2 và 3.3), bạn chỉ cần up 4 container hạ tầng trên.

Kiểm tra đã lên:
```bash
docker ps
# kỳ vọng thấy dcid-postgres và dcid-minio, STATUS "Up"
```

### 3.2. Backend (`dcid-backend`) — port 8080

```bash
cd dcid-backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Lần đầu chạy: Flyway tự áp migration (`V1`–`V4`), và **tự seed tài khoản admin**
(`admin` / `admin123`) nếu bảng `users` đang rỗng.

> ⚠️ **Khác với `dcid-ai`, Spring Boot KHÔNG tự đọc file `.env`.** `dcid-backend/.env.example`
> chỉ là tài liệu tham khảo — muốn override giá trị nào thì `export` biến môi trường đó trước khi
> chạy `./mvnw`, hoặc truyền `-D<property>=<value>`. Mặc định trong `application.yml` đã khớp sẵn
> với `docker-compose up -d postgres minio`, nên **không cần export gì** cho luồng dev thông thường.

Verify:
```bash
curl http://localhost:8080/api/health
# {"status":"UP",...}

curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
# → {"data":{"token":"<jwt>","tokenType":"Bearer",...}}
```
Swagger UI: http://localhost:8080/swagger-ui.html

> **Postgres chạy ở host port `5433`, không phải `5432`** — cố ý, để tránh đụng độ với một
> PostgreSQL cài sẵn trên máy dev (rất hay gặp trên Windows). `POSTGRES_URL` mặc định trong
> `application.yml`/`.env.example` đã trỏ đúng `5433`, không cần chỉnh gì nếu dùng
> `docker-compose up -d postgres minio chroma ai-ocr` như trên.

### 3.3. AI service (`dcid-ai`) — port 8000

Terminal mới:
```bash
cd dcid-ai
python -m venv .venv
.venv\Scripts\activate          # Windows. macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env          # macOS/Linux: cp .env.example .env
uvicorn app.main:app --port 8000
```

Verify:
```bash
curl http://localhost:8000/ai/health
# {"status":"ok","model_loaded":false}
```
Swagger UI: http://localhost:8000/docs

> ⚠️ **`AI_INTERNAL_TOKEN` phải giống nhau** giữa `dcid-ai/.env` và biến môi trường của backend
> (`AI_INTERNAL_TOKEN`, mặc định `change-me-internal-token` ở cả hai bên — khớp sẵn nếu bạn không
> đổi gì). Sai token → backend nhận `503` khi ingest/query vì AI trả `401`.

### 3.4. Frontend (`dcid-app`) — Flutter

Terminal mới:
```bash
cd dcid-app
flutter pub get
```

**Web** (khuyến nghị cho máy tính — kiosk/admin, xem [`FRONTEND.md`](FRONTEND.md) §0.1):
```bash
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080
```
Cố định port **3000** để khớp CORS mặc định của backend (`CORS_ALLOWED_ORIGINS=http://localhost:3000`).

**Android** (thiết bị/emulator đã kết nối):
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```
> Nếu chạy trên **thiết bị thật/emulator riêng** (không phải cùng máy với backend), đổi
> `API_BASE_URL` thành IP LAN của máy chạy backend (`http://<ip-máy>:8080`), không dùng `localhost`.

Đăng nhập bằng `admin` / `admin123`.

---

## 4. Kiểm tra end-to-end (đủ cả 4 service chính + hạ tầng)

1. Mở app (web hoặc Android) → đăng nhập `admin` / `admin123`.
2. Vào tab **Tài liệu** → nút "Tải tài liệu" → chọn 1 file PDF bất kỳ → điền Tiêu đề + Loại tài liệu → Tải lên.
3. Backend lưu PDF vào MinIO, gọi `dcid-ai` ingest → `dcid-ai` gọi `ai-ocr` (PaddleOCR + PyMuPDF) bóc tách chữ → `chunk.py` cắt đoạn layout-aware → `embed.py` nhúng vector `multilingual-e5-small` → `index.py` upsert vào **ChromaDB** (`kcn_chunks`) → gọi callback về backend đổi status sang **ACTIVE** (vài chục giây tùy CPU).
4. Bấm vào tài liệu vừa tạo → thấy version với chip trạng thái **ACTIVE** và đúng số trang PDF.
5. Vào tab **Tra cứu**, hỏi thử một câu chứa "điện áp" → nhận câu trả lời mock kèm trích dẫn
   (xem §5 — câu trả lời hiện là dữ liệu giả lập deterministic, RAG retrieval & LLM thật sẽ nối ở T3).

**Đã verify bằng lệnh thật (curl & smoke_test_t2.py), toàn bộ chuỗi 1→5 chạy đúng:** upload PDF
→ backend lưu MinIO + gọi ingest → `dcid-ai` + `ai-ocr` bóc tách chữ + đếm trang → chunking + embedding + upsert ChromaDB → callback → `GET /api/documents/{id}` trả `status: "ACTIVE"` → `/api/query` trả lời đúng logic mock. Audit log ghi đúng `DOCUMENT_UPLOAD` lẫn `DOCUMENT_INGESTED`.

---

## 5. Cái gì chạy được / cái gì còn mock

| Phần | Trạng thái |
|---|---|
| Auth (self-JWT), RBAC 4 vai, audit log | ✅ Thật |
| Upload PDF → MinIO → tạo version | ✅ Thật |
| Ingest pipeline (OCR + Chunking + Embedding + ChromaDB index) | ✅ Thật — PaddleOCR 3.7 + PyMuPDF + layout-aware chunking + `multilingual-e5-small` + `ChromaDB` (`kcn_chunks`) |
| `document_pages` (ảnh trang, bbox) | 🟡 `ocrText` đã thật; `imageKey`/bbox vẫn placeholder (chưa render/upload ảnh trang) |
| Hỏi–đáp `/api/query` | 🟡 **Mock deterministic** — trả lời giả theo từ khóa (xem `dcid-ai/app/api/query.py`), chưa nối LLM Qwen2.5-1.5B (T3) |
| Guardrail (ngưỡng tin cậy, trích số liệu) | 🟡 Mock — logic thật (θ=0.60, rule-extraction) sẽ cài ở T4 |
| Kiosk fullscreen, Snap & Ask (camera) | ⬜ Chưa làm (M4) |
| Redis / Kafka | Cấu hình sẵn, **chưa có tính năng nào thực sự dùng** — an toàn khi bỏ qua lúc dev |

Chi tiết lộ trình: [`PLAN-THESIS.md`](PLAN-THESIS.md) §5 (bảng cột mốc 8 tuần).

---

## 6. Troubleshooting

Đã tìm và sửa 3 bug thật khi verify E2E lần đầu (đều đã fix trong code/config hiện tại — liệt kê
ở đây để hiểu nếu bạn checkout một commit cũ hơn, hoặc gặp biến thể tương tự):

| Triệu chứng | Nguyên nhân thật đã gặp | Đã xử lý bằng |
|---|---|---|
| Backend lỗi `FATAL: password authentication failed for user "dcid"` dù container Postgres đúng | `docker-compose.yml` thiếu `ports:` cho service `postgres` → `localhost:5432` trúng vào **PostgreSQL cài sẵn khác trên máy** (rất hay gặp trên Windows), không phải container | `docker-compose.yml` map `5433:5432`; default `POSTGRES_URL` đã trỏ `5433` |
| Upload thành công nhưng version `FAILED` ngay lập tức | Spring `RestClient` (JDK HttpClient) mặc định thử nâng cấp **HTTP/2**, nhưng `uvicorn` chỉ nói HTTP/1.1 → request bị hỏng, FastAPI nhận body rỗng | `AiClientConfig` ép `HttpClient.Version.HTTP_1_1` tường minh |
| Version `FAILED` với lỗi liên quan MinIO khi `dcid-ai` đọc file | Default `MINIO_ACCESS_KEY`/`SECRET_KEY` trong `dcid-ai` là `minioadmin`/`minioadmin`, không khớp `minio`/`minio123` thật của container | Sửa default trong `dcid-ai/app/config.py` + `.env.example` |

Các tình huống khác:

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| `docker-compose up` báo lỗi kết nối daemon | Docker Desktop chưa mở | Mở Docker Desktop, đợi icon chuyển "Running", chạy lại |
| Backend lỗi auth Postgres dù đã map đúng port | Volume cũ (`dcid-web_postgres_data`) còn dữ liệu từ trước khi có fix port | `docker-compose down -v` rồi `up -d postgres minio` lại (⚠️ mất dữ liệu cũ trong volume) |
| Upload xong version cứ `PROCESSING` mãi/không lên `ACTIVE` | `dcid-ai` không chạy, hoặc `AI_INTERNAL_TOKEN` hai bên không khớp | Kiểm `curl :8000/ai/health`; xem log backend có dòng lỗi gọi AI không; version sẽ chuyển `FAILED` nếu AI không phản hồi được — kiểm `errorMessage` trong `GET /api/documents/{id}` |
| Flutter web: lỗi CORS trong console trình duyệt | Port Flutter dev khác `3000`, hoặc backend origin config khác | Chạy `flutter run -d chrome --web-port=3000`, hoặc set `CORS_ALLOWED_ORIGINS` cho backend đúng origin đang dùng |
| `flutter run` Android báo lỗi symlink/plugin | Chưa bật Developer Mode (Windows) | `start ms-settings:developers` → bật, chạy lại |
| `flutter pub get` cảnh báo "Building with plugins requires symlink support" | Như trên | Không chặn `analyze`/`test`/`build web`, chỉ ảnh hưởng build native (Android/Windows) |
| Backend `mvnw` tải rất chậm lần đầu | Lần đầu tải Maven + toàn bộ dependency | Bình thường, các lần sau nhanh nhờ cache `~/.m2` |
| Chữ tiếng Việt hiển thị lỗi khi test bằng `curl -F`/`python -m json.tool` trên Windows | Console Windows (codepage cp1252) không hiển thị được UTF-8, **không phải bug backend** | Ghi response ra file rồi mở bằng editor UTF-8, hoặc test qua Swagger UI/Flutter app thay vì gõ tiếng Việt trực tiếp vào lệnh `curl` trên Git Bash |

---

## 7. Tài liệu liên quan

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — kiến trúc tổng thể 2 mặt phẳng, sơ đồ, data model.
- [`ERD.md`](ERD.md) — schema Postgres chi tiết.
- [`API-CONTRACT.md`](API-CONTRACT.md) — hợp đồng ingest/query/callback giữa backend ↔ AI.
- [`FRONTEND.md`](FRONTEND.md) — kiến trúc Flutter, quyết định Web thay vì app native cho desktop.
- [`PLAN-THESIS.md`](PLAN-THESIS.md) — kế hoạch 8 tuần, phân công, trạng thái từng mục.
- `dcid-backend/CLAUDE.md`, `dcid-ai/README.md`, `dcid-app/README.md` — hướng dẫn chi tiết riêng từng service.
