# Cài đặt và chạy dự án

Tài liệu này phản ánh cấu hình hiện tại của DCID Web ngày 08/08/2026.
Dự án chạy hoàn toàn local/on-premise bằng Docker và Ollama; không cần
khởi động LM Studio.

## 1. Kiến trúc hiện tại

Stack Docker production gồm đúng 9 service:

| Service | Vai trò | Cổng development |
|---|---|---:|
| `backend` | Spring Boot: auth, RBAC, tài liệu, proxy AI | 8080 |
| `ai` | FastAPI: RAG, truy vấn và SSE | 8000 |
| `ai-worker` | Celery worker: OCR, chunk, embedding, index | không publish |
| `ai-ocr` | PaddleOCR sidecar | 8002 |
| `ollama` | Model chữ và Vision | 11434 |
| `chroma` | Vector database | 8001 |
| `postgres` | Dữ liệu nghiệp vụ | 5433 |
| `redis` | Celery queue, cache và khóa tài nguyên AI | 6379 |
| `minio` | PDF, ảnh trang và ảnh upload | 9000 |

Kafka, Zookeeper và Flower đã được loại khỏi stack 8 GB.

Hai model Ollama:

- `qwen2.5:1.5b`: câu hỏi văn bản/RAG.
- `qwen2.5vl:3b`: hình ảnh và bản vẽ cần suy luận không gian.

Hệ thống chỉ giữ một model trong RAM và chỉ chạy một tác vụ AI nặng
tại một thời điểm. OCR, embedding và Ollama dùng chung khóa Redis để
không tăng RAM cùng lúc.

## 2. Yêu cầu máy

### Chạy toàn bộ bằng Docker

- Docker Desktop/Engine và Docker Compose v2.
- Tối thiểu 4 CPU, khuyến nghị 8 CPU trở lên.
- Docker được cấp tối thiểu 7.57 GB RAM.
- Ổ đĩa trống tối thiểu 20 GB trước khi build; khuyến nghị 30 GB.
- Trên VPS 8 GB nên có 4 GB swap.

### Chạy thủ công để phát triển

- JDK 21. Không khuyến nghị chạy test bằng JDK 25 do phiên bản Byte Buddy
  hiện tại chưa hỗ trợ.
- Python 3.11 hoặc 3.12.
- Flutter 3.35 trở lên.
- Maven hoặc Maven Wrapper trong `dcid-backend`.

Trên Windows, bật Developer Mode nếu build Android/Windows có plugin cần symlink.

## 3. Clone dự án

```bash
git clone <repo-url> dcid-web
cd dcid-web
```

Mọi lệnh Docker bên dưới phải chạy từ thư mục gốc `dcid-web`.

## 4. Chạy development bằng Docker

Đây là cách đơn giản và ít sai cấu hình nhất.

### 4.1. Kiểm tra Docker và dung lượng

```powershell
docker version
docker compose version
docker system df
Get-PSDrive C
```

Nếu Docker Desktop chưa chạy, mở Docker Desktop và chờ Engine hiển thị
`Running`.

### 4.2. Build từng image

Với máy có dung lượng hạn chế, build tuần tự:

```powershell
docker compose build backend
docker compose build ai
docker compose build ai-worker
docker compose build ai-ocr
```

Không build bốn image song song trên máy chỉ còn khoảng 20 GB trống.

### 4.3. Khởi động hạ tầng và tải model

```powershell
docker compose up -d postgres redis minio chroma ollama
docker compose ps
```

Tải hai model. Chỉ cần thực hiện một lần; model được lưu trong volume
`ollama_data`:

```powershell
docker compose exec ollama ollama pull qwen2.5:1.5b
docker compose exec ollama ollama pull qwen2.5vl:3b
docker compose exec ollama ollama list
```

### 4.4. Khởi động toàn bộ backend/AI

```powershell
docker compose up -d backend ai-ocr ai ai-worker
docker compose ps
docker stats --no-stream
```

Kỳ vọng có 9 container `Up`. Trong development, các cổng hạ tầng được
publish ra localhost để debug.

### 4.5. Kiểm tra API

```powershell
curl.exe http://localhost:8080/api/health
curl.exe http://localhost:8000/ai/health
curl.exe http://localhost:11434/api/tags
```

Swagger:

- Backend: <http://localhost:8080/swagger-ui.html>
- AI: <http://localhost:8000/docs>

Đăng nhập development mặc định:

```text
username: admin
password: admin123
```

Không sử dụng tài khoản/mật khẩu mặc định này trong production.

## 5. Chạy Flutter Web

```powershell
cd dcid-app
flutter pub get
flutter run -d chrome --web-port=3000 `
  --dart-define=USE_MOCK_DATA=false `
  --dart-define=API_BASE_URL=http://localhost:8080
```

PowerShell dùng dấu backtick `` ` `` để xuống dòng. Có thể viết thành một dòng.

Android emulator chạy cùng máy thường phải dùng:

```powershell
flutter run `
  --dart-define=USE_MOCK_DATA=false `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Thiết bị Android thật phải dùng IP LAN của máy chạy backend, không dùng
`localhost`.

### Kiểm tra chỉ mục tài liệu sau khi Docker được tạo lại

ChromaDB được lưu trong named volume `chroma_data` tại `/data`. Không đổi mount
này về đường dẫn cũ `/chroma/.chroma/index`, vì Chroma 1.x không ghi dữ liệu ở
đó. Nếu PostgreSQL còn tài liệu `ACTIVE` nhưng AI luôn trả độ tin cậy `0%`, hãy
kiểm tra số chunk trong Chroma trước khi tái ingest tài liệu.

## 6. Chạy backend/AI ngoài Docker

Chỉ dùng phần này khi cần debug code. Trước tiên khởi động hạ tầng:

```powershell
docker compose up -d postgres redis minio chroma ollama ai-ocr
```

### Backend

```powershell
cd dcid-backend
mvn spring-boot:run "-Dspring-boot.run.profiles=dev"
```

Trên Linux/macOS có thể dùng Maven Wrapper:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Backend local kết nối PostgreSQL tại `localhost:5433`.

### AI API

```powershell
cd dcid-ai
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Thiết lập các biến cho service chạy ngoài Docker:

```powershell
$env:AI_INTERNAL_TOKEN="change-me-internal-token"
$env:MINIO_ENDPOINT="localhost:9000"
$env:CHROMA_HOST="localhost"
$env:CHROMA_PORT="8001"
$env:REDIS_URL="redis://localhost:6379/0"
$env:OCR_SERVICE_URL="http://localhost:8002"
$env:LM_STUDIO_BASE_URL="http://localhost:11434/v1"
$env:LM_STUDIO_MODEL="qwen2.5:1.5b"
$env:VISION_MODEL="qwen2.5vl:3b"
$env:AI_RESOURCE_GATE_ENABLED="true"
$env:AI_RESOURCE_GATE_FAIL_OPEN="false"
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Mở terminal khác cho worker:

```powershell
cd dcid-ai
.\.venv\Scripts\Activate.ps1
$env:REDIS_URL="redis://localhost:6379/0"
$env:MINIO_ENDPOINT="localhost:9000"
$env:CHROMA_HOST="localhost"
$env:CHROMA_PORT="8001"
$env:OCR_SERVICE_URL="http://localhost:8002"
$env:AI_RESOURCE_GATE_ENABLED="true"
$env:AI_RESOURCE_GATE_FAIL_OPEN="false"
celery -A app.celery_app.celery_app worker `
  --loglevel=info --pool=solo --concurrency=1 `
  --prefetch-multiplier=1 -Q ingest,default
```

Trên Windows, worker Celery nên dùng `--pool=solo`.

## 7. Chạy production/VPS 8 GB

Tạo file secret, tuyệt đối không commit:

```bash
cp .env.example .env.production
```

Thay tất cả giá trị `change-me`, đặc biệt:

```dotenv
POSTGRES_PASSWORD=<mat-khau-manh>
APP_JWT_SECRET=<chuoi-ngau-nhien-it-nhat-32-ky-tu>
APP_BOOTSTRAP_ADMIN_PASSWORD=<mat-khau-admin>
MINIO_ROOT_PASSWORD=<mat-khau-minio>
AI_INTERNAL_TOKEN=<token-noi-bo-ngau-nhien>
CORS_ALLOWED_ORIGINS=https://ten-mien-cua-ban
LLM_MODEL=qwen2.5:1.5b
VISION_MODEL=qwen2.5vl:3b
AI_RESOURCE_GATE_ENABLED=true
AI_RESOURCE_GATE_FAIL_OPEN=false
AI_RESOURCE_LOCK_WAIT_SECONDS=330
```

Xác thực cấu hình trước khi chạy:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml config --quiet
```

Build và khởi động:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml build backend
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml build ai
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml build ai-worker
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml build ai-ocr
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Production chỉ publish cổng `8080`; PostgreSQL, Redis, MinIO, Chroma, OCR, AI và
Ollama chỉ truy cập qua Docker network.

Xem thêm [VPS-8GB.md](VPS-8GB.md).

## 8. Kiểm tra end-to-end

1. Đăng nhập bằng tài khoản admin.
2. Upload một PDF nhỏ.
3. Xem trạng thái chuyển `PROCESSING_OCR` → `PROCESSING_EMBED` → `READY`.
4. Chọn tài liệu và gửi câu hỏi văn bản.
5. Xác nhận model phản hồi là `qwen2.5:1.5b`.
6. Hỏi về vị trí/kích thước trên bản vẽ.
7. Xác nhận Vision chỉ nạp `qwen2.5vl:3b` khi có nhu cầu hình ảnh.
8. Kiểm tra trích dẫn đúng trang và tài liệu đã chọn.

Theo dõi log và RAM:

```powershell
docker compose logs --tail=200 backend ai ai-worker ai-ocr ollama
docker stats --no-stream
docker inspect --format '{{.State.OOMKilled}}' dcid-ollama
```

## 9. Dừng và khởi động lại

Dừng container nhưng giữ nguyên dữ liệu:

```powershell
docker compose stop
```

Khởi động lại:

```powershell
docker compose start
```

Xóa container/network nhưng giữ volume:

```powershell
docker compose down
```

Không chạy `docker compose down -v` nếu muốn giữ PostgreSQL, MinIO, Chroma
và model Ollama.

## 10. Xử lý sự cố thường gặp

### Docker Engine chưa chạy

```text
failed to connect to docker API
```

Mở Docker Desktop, chờ Engine `Running`, sau đó chạy `docker version`.

### Ổ C sắp hết dung lượng

Kiểm tra:

```powershell
docker system df -v
Get-PSDrive C
```

Dọn build cache không xóa container/volume:

```powershell
docker builder prune --filter "until=24h"
docker image prune
```

Không dùng `docker system prune --volumes` vì có thể làm mất dữ liệu.

### AI trả thông báo đang bận

OCR, embedding hoặc model khác đang giữ resource gate. Hệ thống sẽ xử lý
tuần tự. Kiểm tra:

```powershell
docker compose logs --tail=100 ai ai-worker
docker compose exec redis redis-cli GET dcid:ai:heavy
```

Không tắt `AI_RESOURCE_GATE_ENABLED` trên máy/VPS 8 GB.

### Upload đứng ở `PROCESSING`

```powershell
docker compose ps
docker compose logs --tail=200 ai-worker ai-ocr redis minio
```

Xác nhận `ai-worker`, `ai-ocr`, Redis và MinIO đều `Up`.

### Ollama không có model

```powershell
docker compose exec ollama ollama list
docker compose exec ollama ollama pull qwen2.5:1.5b
docker compose exec ollama ollama pull qwen2.5vl:3b
```

### Lỗi 403 hoặc AI không kết nối

- Kiểm tra `AI_INTERNAL_TOKEN` giống nhau giữa backend và AI.
- Production phải dùng cùng `MINIO_ROOT_PASSWORD` cho MinIO, backend, AI,
  worker và OCR.
- Flutter phải chạy với `USE_MOCK_DATA=false`.
- `CORS_ALLOWED_ORIGINS` phải khớp chính xác origin của frontend.

## 11. Tài liệu liên quan

- [VPS-8GB.md](VPS-8GB.md): giới hạn RAM và quy tắc vận hành.
- [ARCHITECTURE.md](ARCHITECTURE.md): kiến trúc tổng thể.
- [API-CONTRACT.md](API-CONTRACT.md): hợp đồng backend/AI.
- [FRONTEND.md](FRONTEND.md): cấu hình Flutter.
- [ERD.md](ERD.md): cơ sở dữ liệu PostgreSQL.
