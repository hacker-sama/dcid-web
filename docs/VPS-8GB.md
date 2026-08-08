# Triển khai DCID trên VPS 8 GB RAM (CPU-only)

## Kiến trúc production

Production chạy 9 service: `backend`, `ai`, `ai-worker`, `ai-ocr`, `ollama`,
`chroma`, `postgres`, `redis` và `minio`. Kafka, Zookeeper và Flower không
thuộc stack 8 GB.

Tổng memory limit của các container xấp xỉ 7.47 GiB. Redis cung cấp một
khóa phân tán chung cho OCR, embedding và Ollama, vì vậy các công
việc nặng xử lý lần lượt thay vì cùng tăng RAM.

## Chuẩn bị

- VPS Linux có 4 vCPU, 8 GB RAM và ít nhất 30 GB NVMe trống.
- Docker Engine và Docker Compose v2.
- Swap 4 GB để chống OOM đột ngột. Swap không thay thế RAM.
- Chỉ công khai `8080`; PostgreSQL, Redis, MinIO, Chroma, OCR, AI và
  Ollama chỉ truy cập qua mạng Docker nội bộ.

## Cấu hình bí mật

```bash
cp .env.example .env.production
```

Thay toàn bộ giá trị `change-me` trong `.env.production`. JWT secret phải dài
ít nhất 32 ký tự; `AI_INTERNAL_TOKEN` phải khác mật khẩu người dùng.

## Khởi động

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --build
```

Tải model một lần sau khi Ollama sẵn sàng:

```bash
docker compose exec ollama ollama pull qwen2.5:1.5b
docker compose exec ollama ollama pull qwen2.5vl:3b
```

Kiểm tra:

```bash
docker compose ps
docker stats --no-stream
curl http://127.0.0.1:8080/actuator/health
```

## Quy tắc vận hành

- `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_NUM_PARALLEL=1`, context 2048.
- Celery worker có concurrency 1 và prefetch 1.
- Upload trả `taskId`; OCR/index tiếp tục trong hàng đợi Redis.
- Truy vấn văn bản dùng `qwen2.5:1.5b`; chỉ truy vấn có ảnh hoặc
  cần suy luận không gian mới dùng `qwen2.5vl:3b`.
- Ảnh Vision có cạnh dài tối đa 800 px. PNG được giữ cho bản vẽ;
  ảnh thường chuyển JPEG 90.
- Không chạy ingestion và Vision song song bằng cách tắt resource gate.

## Chẩn đoán

```bash
docker compose logs --tail=200 backend ai ai-worker ai-ocr ollama
docker inspect --format '{{.State.OOMKilled}}' dcid-ollama
```

Khi AI bận quá thời gian chờ, API trả thông báo thân thiện thay vì
để client hiển thị `DioException`.

## Tiêu chí chấp nhận

- Compose production chỉ có 9 service.
- Chỉ cổng `8080` được publish.
- Không container nào có `OOMKilled=true`.
- OCR, embedding và LLM không cùng giữ resource gate.
- Hai model Ollama không cùng loaded.
- Upload vẫn còn trong hàng đợi sau khi trình duyệt đóng.
