# Smart KCN Docs — Kiến trúc dự án (đề xuất)

> Trợ lý kỹ thuật số & quản trị tri thức **on-premise** cho khu công nghiệp.
> Tài liệu này là bản đề xuất kiến trúc thực tế, bám theo Business Case và **tái sử dụng tối đa**
> hạ tầng Spring Boot sẵn có trong repo.

---

## 1. Nguyên tắc thiết kế (Design principles)

1. **Tách 2 mặt phẳng (two-plane split).** AI inference vốn là Python (PaddleOCR, embeddings ONNX,
   ChromaDB, llama.cpp/GGUF). Spring Boot **không** chạy được các mô hình này. Vì vậy:
   - **Governance/Control plane** → Spring Boot (repo này).
   - **AI plane** → dịch vụ Python (FastAPI + Celery), tách riêng.
   Ranh giới nói chuyện qua **REST nội bộ** (HTTP, cùng mạng LAN nhà máy).
2. **100% on-premise / air-gapped.** Không gọi API cloud thương mại. Auth tự chủ (self-JWT),
   không phụ thuộc IdP ngoài.
3. **Edge-friendly.** LLM/OCR chạy trên CPU tại Edge Device; server trung tâm chỉ giữ
   DB + object storage + vector store + governance.
4. **Zero-tolerance với số liệu.** Guardrail (confidence threshold + rule-based) nằm ở AI plane,
   nhưng **audit và bằng chứng (bounding-box crop)** được lưu và phục vụ bởi Spring Boot.
5. **Không "ốc đảo dữ liệu".** Mọi thứ có API để CMMS/MES tích hợp.

---

## 2. Sơ đồ tổng thể

```mermaid
flowchart TB
    subgraph Edge["🏭 Edge Device / Kiosk (CPU, phân xưởng)"]
        UI["Next.js Kiosk/Mobile UI\n(Snap & Ask, side-by-side)"]
        AISVC["AI Service (Python, FastAPI + Celery)\nPaddleOCR · e5-small(ONNX) · llama.cpp(Qwen2.5-1.5B)\nRAG retrieval + Guardrails"]
        CHROMA[("ChromaDB\nvector store")]
    end

    subgraph Central["🖥️ Central Server (x86)"]
        BE["Spring Boot — Governance/Control plane\nAuthN/RBAC · Doc & Version lifecycle\nAudit(ISO) · CMMS/MES API · Orchestration"]
        PG[("PostgreSQL\nusers, audit, doc metadata, versions")]
        MINIO[("MinIO\nPDF gốc + bounding-box crops")]
        REDIS[("Redis\ncache / rate-limit / broker")]
        KAFKA[("Kafka (tùy chọn)\nevent / audit stream")]
    end

    CMMS["CMMS / MES\n(Work Orders)"]

    UI -->|"REST + JWT"| BE
    UI -->|"hỏi đáp (query)"| AISVC
    AISVC -->|"metadata, quyền, log"| BE
    AISVC --> CHROMA
    BE --> PG
    BE --> MINIO
    BE --> REDIS
    BE -.-> KAFKA
    AISVC -->|"đọc file gốc"| MINIO
    CMMS <-->|"REST: đẩy Work Order + deep-link trang tài liệu"| BE
```

---

## 3. Thành phần & trách nhiệm

| Thành phần | Công nghệ | Trách nhiệm chính |
|---|---|---|
| **Governance plane** | Spring Boot 3.3, Java 21 | Auth/RBAC, quản lý tài liệu + version, audit ISO, storage MinIO, tích hợp CMMS/MES, điều phối job AI |
| **AI plane** | Python, FastAPI, Celery | OCR (PaddleOCR), embedding (e5-small ONNX), retrieval (ChromaDB), LLM (Qwen2.5-1.5B GGUF qua llama.cpp), guardrails |
| **Vector store** | ChromaDB | Semantic search trên chunk + metadata (trang, ngôn ngữ, version) |
| **Relational DB** | PostgreSQL 16 | users, roles, document/version metadata, query_logs, audit_logs, work_orders |
| **Object storage** | MinIO | PDF gốc, ảnh trang, **bounding-box crop** (bằng chứng số liệu) |
| **Cache/Broker** | Redis 7 | cache, rate-limit, (tùy chọn) Celery broker |
| **Event bus** | Kafka (tùy chọn) | phát sự kiện ingest/audit bất đồng bộ |
| **Frontend** | Next.js (thư mục `dcid-frontend`) | Kiosk/Mobile UI, Snap & Ask, đối chiếu bản vẽ |

**Ranh giới rõ ràng:** AI plane **không** giữ quyền/RBAC/audit gốc — nó gọi Spring Boot để kiểm tra
quyền và ghi log. Spring Boot **không** chạy model — nó gọi AI plane để OCR/embed/query.

---

## 4. Luồng nghiệp vụ chính

### 4.1. Ingestion (số hóa tài liệu)
```
QA/Admin upload PDF (Spring Boot)
  → lưu file gốc vào MinIO, tạo bản ghi Document + DocumentVersion (Postgres, status=PROCESSING)
  → phát job sang AI Service (REST/queue)
      → PaddleOCR bóc tách text + bảng (TSR) + toạ độ (bbox), đa ngôn ngữ EN/CN/JP/VI
      → chunk theo cấu trúc + gắn metadata (page, bbox, lang, version)
      → embed (e5-small ONNX) → upsert vào ChromaDB
      → cắt & lưu bounding-box crops vào MinIO
  → callback báo Spring Boot: status=READY (hoặc FAILED)
  → ghi audit_log
```

### 4.2. Truy vấn + Guardrail (Human-in-the-loop)
```
Kỹ sư hỏi (UI) → AI Service:
  retrieve top-k từ ChromaDB (lọc theo quyền/role + version hiện hành)
  IF cosine_similarity < 0.60  → KHÓA câu trả lời sinh tự động,
                                  trả cảnh báo đỏ "Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm"
  IF query chạm 'điện áp/áp suất/nhiệt độ/dung sai'
                               → trích số liệu trực tiếp từ metadata gốc (rule-based), không để LLM "chế"
  ELSE → LLM sinh câu trả lời kèm trích dẫn (page + bbox crop từ MinIO)
AI Service → Spring Boot: ghi query_log (user, timestamp, query, doc version, confidence, có/không hallucination-guard)
```

### 4.3. Versioning workflow
- Upload version mới → version cũ chuyển `SUPERSEDED`; đánh dấu `OBSOLETE` thủ công (QA/Admin).
- Retrieval **luôn** ưu tiên version `ACTIVE`; version obsolete bị loại khỏi kết quả.

### 4.4. Tích hợp CMMS/MES
- CMMS đẩy **Work Order** qua REST → Spring Boot tạo bản ghi + **deep-link** tới đúng trang tài liệu
  sửa chữa của loại máy đó, trả link truy cập tức thì cho kỹ sư.

---

## 5. Mô hình dữ liệu (định hướng)

**Đã có (baseline `V1__init.sql`):** `users`, `audit_logs`.

**Sẽ thêm (mỗi bảng = 1 Flyway migration mới):**
- `documents` — machine/line, category, ngôn ngữ, trạng thái.
- `document_versions` — version, storage_key (MinIO), status (`PROCESSING/READY/ACTIVE/SUPERSEDED/OBSOLETE`), checksum.
- `document_pages` — trang, ảnh, kích thước (để map bbox).
- `query_logs` — user, query, doc_version, confidence, có kèm answer/citation.
- `work_orders` — id CMMS, machine, document deep-link, trạng thái.

> Vector + chunk sống ở **ChromaDB** (không nhồi vào Postgres); Postgres chỉ giữ metadata quan hệ.

---

## 6. Bảo mật · RBAC · Audit

- **Self-JWT (HS256):** login → token; filter xác thực Bearer, gắn `ROLE_<role>`.
- **RBAC 4 vai** (`UserRole`): `OPERATOR` (chỉ SOP/an toàn), `ENGINEER` (bản vẽ, sơ đồ, log bảo trì),
  `QA_ADMIN` (upload, obsolete, duyệt version), `ADMIN` (quản trị hệ thống).
  Áp bằng `@PreAuthorize("hasRole('...')")` (method security đã bật).
- **Audit ISO:** `AuditLog` (actor, action, resource, timestamp, ip, detail JSONB) — bất biến, phục vụ truy vết.

---

## 7. Topology triển khai

- **Central Server (1 máy x86 phổ thông):** Postgres + MinIO + Redis + (Kafka) + Spring Boot.
- **Edge Device (Mini/Industrial PC, Core i5/RAM 8GB):** Next.js UI + AI Service + ChromaDB cục bộ.
  → LLM/OCR chạy cục bộ, không cần GPU server; dữ liệu nhạy cảm không rời nhà máy.
- Nhiều Edge có thể chia sẻ 1 Central; hoặc chạy full-stack trên 1 Edge cho pilot.

---

## 8. Ranh giới Spring Boot ↔ AI service (contract — *chưa code, sẽ làm sau*)

Khi bắt đầu tích hợp, đề xuất một interface `AiPipelineClient` trong Spring Boot với hợp đồng REST:

| Method | Endpoint (AI service) | Ý nghĩa |
|---|---|---|
| `ingest(versionId, storageKey, langs)` | `POST /ai/ingest` | kích hoạt OCR→chunk→embed→index |
| `query(userId, role, question, filters)` | `POST /ai/query` | RAG + guardrail, trả answer + citations + confidence |
| `health()` | `GET /ai/health` | readiness của model |

Callback AI → Spring Boot: `POST /api/internal/ingest-callback` (bảo vệ bằng token nội bộ).

> Quyết định thiết kế hiện tại: **chưa dựng** interface/stub này — xem §9 roadmap.

---

## 9. Roadmap ánh xạ với repo & Business Case

| Phase (BC) | Việc | Trạng thái trong repo |
|---|---|---|
| — | Reset skeleton + self-JWT + RBAC + audit | ✅ **Đã xong** (lần format này) |
| P1–P2 | AI Core & OCR & RAG (Python) | ⬜ Repo riêng / service Python |
| P3 | Backend Governance: Document/Version/Query/WorkOrder + Admin | ⬜ Thêm domain vào Spring Boot (theo §5) |
| P3 | `AiPipelineClient` + ingest callback | ⬜ Theo §8 |
| P4 | Kiosk/Mobile UI (Snap & Ask, side-by-side) | 🟡 `dcid-frontend` (Next.js) — cần chỉnh |
| P5 | Pilot & UAT 01 dây chuyền | ⬜ |

---

## 10. Đã thực hiện trong lần "format" này

- Xóa toàn bộ domain e-government cũ (citizen/officer: Application, Procedure, Appointment,
  Notification, CitizenProfile, OfficerProfile...), migrations V1–V6, messaging & websocket domain.
- Thay **Keycloak/OAuth2** → **self-issued JWT + RBAC nội bộ** (login/me hoạt động thật, seed admin).
- Giữ lại hạ tầng tái dùng: config, common, exception, security, filter, MinIO, Redis, Kafka, audit,
  OpenAPI, global exception handling.
- Baseline schema mới `V1__init.sql` (users + audit_logs). `.gitignore` + gỡ `target/` khỏi git.
- Build xanh: `./mvnw -DskipTests test-compile` + unit test health.

Chi tiết vận hành backend: xem `dcid-backend/CLAUDE.md`.
