# API Contract v1 — `dcid-backend` ↔ `dcid-ai`

> **Nguồn sự thật duy nhất** cho ranh giới BE↔AI. Mọi thay đổi contract phải sửa file này trong cùng PR.
> Người 2 (BE) và người 3 (AI) code đối chiếu trực tiếp từ đây.
> Trạng thái: **v1 — đã chốt**. Đọc kèm [`ERD.md`](ERD.md) · [`ARCHITECTURE.md`](ARCHITECTURE.md) §B4–B5.

---

## 0. Nguyên tắc thiết kế

1. **AI không đụng Postgres.** Chỉ BE ghi DB. AI đọc MinIO, ghi ChromaDB + MinIO, báo kết quả qua callback.
2. **RBAC + version ACTIVE do BE quyết.** Khi query, BE tính sẵn danh sách `allowedVersionIds`
   (từ Postgres: `status=ACTIVE` + `min_role` ≤ vai người hỏi) và truyền sang; AI chỉ lọc Chroma theo danh sách đó.
3. **Auth nội bộ:** mọi request giữa 2 service mang header `X-Internal-Token: <shared-secret>`
   (env `AI_INTERNAL_TOKEN`, giống nhau ở cả 2 bên). Sai/thiếu token → `401/403`.
4. **Ingest bất đồng bộ, query đồng bộ.** `/ai/ingest` trả `202` ngay rồi xử lý nền; `/ai/query` trả kết quả trong request.

Base URL (env): BE = `http://localhost:8080` (`AI` gọi qua `BE_BASE_URL`) · AI = `http://localhost:8000` (`BE` gọi qua `AI_BASE_URL`).

---

## 1. Luồng Ingest

```
BE (sau khi upload MinIO)          AI (FastAPI + worker)
  │ POST /ai/ingest  ──────────────▶ 202 {accepted}
  │                                  OCR → chunk → embed → Chroma
  │                                  render ảnh trang → MinIO
  ◀── POST /api/internal/ingest-callback ──┘
  cập nhật status + persist document_pages
```

### 1.1. `POST {AI}/ai/ingest`  (BE → AI)

```json
{
  "versionId":  "8f14e45f-...",
  "documentId": "c9f0f895-...",
  "storageKey": "documents/{documentId}/v1/original.pdf",
  "langs": ["vi", "en"],
  "metadata": {
    "title": "Manual máy CNC XK-500",
    "machineCode": "CNC-01",
    "category": "SOP",
    "minRole": "OPERATOR"
  }
}
```

| Response | Khi nào |
|---|---|
| `202 {"accepted": true}` | đã nhận job (xử lý nền) |
| `400` | thiếu trường / storageKey không đọc được sớm |
| `401/403` | token sai |

`metadata` được AI **ghi kèm vào Chroma cho từng chunk** (xem §3) — chỉ để lọc/hiển thị, không phải nguồn quyền.

### 1.2. `POST {BE}/api/internal/ingest-callback`  (AI → BE)

```json
{
  "versionId": "8f14e45f-...",
  "status": "READY",              // "READY" | "FAILED"
  "pageCount": 12,
  "pages": [
    { "pageNo": 1, "imageKey": "documents/{documentId}/v1/pages/1.png",
      "width": 1654, "height": 2339, "ocrText": "..." }
  ],
  "error": null                    // bắt buộc khi FAILED
}
```

**BE xử lý (ghi DB):**
- `READY` → xóa `document_pages` cũ của version (idempotent) → insert `pages[]` → set `page_count`,
  `ingested_at` → **auto-publish**: version cũ đang `ACTIVE` của cùng document → `SUPERSEDED`,
  version này → `ACTIVE`. *(Chính sách MVP: callback thành công = publish luôn, không có bước duyệt tay.)*
- `FAILED` → set `status=FAILED` + `error_message`.
- Response: `200`. Version không tồn tại → `404`. Token sai → `403`.

---

## 2. Luồng Query

### 2.1. App → BE: `POST {BE}/api/query` (JWT user)

```json
{ "question": "Điện áp cấp cho servo trục X?", "machineCode": null }
```

BE: tính `allowedVersionIds` theo vai user (+ lọc `machineCode` nếu có) → nếu **rỗng** thì trả
guardrail-locked luôn, **không gọi AI** → ngược lại gọi 2.2 → ghi `query_logs` → trả 2.3.

### 2.2. BE → AI: `POST {AI}/ai/query`

```json
{
  "question": "Điện áp cấp cho servo trục X?",
  "topK": 5,
  "allowedVersionIds": ["8f14e45f-...", "..."],
  "machineCode": null
}
```

AI: retrieve top-k trong Chroma với filter `version_id ∈ allowedVersionIds` → guardrail
(θ cosine < **0.60** → `locked`; câu hỏi chạm *điện áp/áp suất/nhiệt độ/dung sai/momen* →
numeric rule-extraction) → LLM sinh câu trả lời khi không bị khóa.

**Response `200`:**
```json
{
  "answer": "Điện áp cấp cho servo trục X là 200–230 VAC...",
  "confidence": 0.83,
  "guard": { "locked": false, "numericRule": true, "reasoningMode": false },
  "citations": [
    {
      "versionId": "8f14e45f-...",
      "pageNo": 12,
      "bboxKey": "p12_[105.2,230.5,450.8,280.0]",
      "snippet": "### [Đoạn kỹ thuật - Trang 12 | Bbox: 105.2,230.5,450.8,280.0]\nĐiện áp cấp cho servo trục X là 200–230 VAC..."
    }
  ],
  "latencyMs": 2100,
  "model": "deepseek-r1-distill-qwen-1.5b"
}
```

Khi `locked=true`: `answer` = thông báo chuẩn *"Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh
từ bản vẽ đính kèm."*, `citations` vẫn trả top-k để kỹ sư tự xem. `bboxKey` (tọa độ không gian `p{pageNo}_[minX,minY,maxX,maxY]`) / `snippet` (đoạn nội dung gốc được trích dẫn tối đa 300 ký tự) nullable.

### 2.3. BE → App (giữ đúng shape Flutter đang parse & hiển thị Hộp thoại Trích dẫn Không gian):

```json
{
  "data": {
    "answer": "...",
    "confidence": 0.83,
    "guard": { "locked": false, "numericRule": true, "reasoningMode": false },
    "citations": [
      {
        "versionId": "8f14e45f-...",
        "pageNo": 12,
        "bboxKey": "p12_[105.2,230.5,450.8,280.0]",
        "snippet": "### [Đoạn kỹ thuật - Trang 12 | Bbox: 105.2,230.5,450.8,280.0]\nĐiện áp cấp cho servo trục X..."
      }
    ]
  }
}
```

**BE ghi `query_logs`** mỗi lần hỏi: `actor_id, question, matched_version_id` (citation đầu),
`confidence, numeric_rule_hit, locked, answer_preview` (≤500 ký tự), `latency_ms` (đo end-to-end phía BE).

**Lỗi:** AI không phản hồi → BE trả `503 SERVICE_UNAVAILABLE` (không giả vờ có câu trả lời).

---

## 3. Quy ước lưu trữ chung

**MinIO key layout** (bucket `kcn-docs`):
```
documents/{documentId}/v{n}/original.pdf      ← BE ghi khi upload
documents/{documentId}/v{n}/pages/{p}.png     ← AI ghi (ảnh trang)
documents/{documentId}/v{n}/crops/{p}-{i}.png ← AI ghi (bbox crop, stretch)
```

**Chroma** — collection `kcn_chunks`, metadata mỗi chunk:
```
version_id, document_id, page_no, lang, machine_code, min_role, chunk_index
```

**`GET {AI}/ai/health`** → `200 {"status":"ok","model_loaded":true}` — BE/compose dùng làm readiness.

---

## 4. Pydantic sketch cho `dcid-ai` (người 3 copy làm điểm xuất phát)

```python
class IngestRequest(BaseModel):
    versionId: UUID; documentId: UUID; storageKey: str
    langs: list[str] = ["vi", "en"]; metadata: dict[str, str] = {}

class PageInfo(BaseModel):
    pageNo: int; imageKey: str; width: int | None = None
    height: int | None = None; ocrText: str | None = None

class IngestCallback(BaseModel):   # gửi về BE
    versionId: UUID; status: Literal["READY", "FAILED"]
    pageCount: int | None = None; pages: list[PageInfo] = []; error: str | None = None

class QueryRequest(BaseModel):
    question: str; topK: int = 5
    allowedVersionIds: list[UUID]; machineCode: str | None = None

class Guard(BaseModel):    locked: bool = False; numericRule: bool = False
class Citation(BaseModel): versionId: UUID; pageNo: int
                           bboxKey: str | None = None; snippet: str | None = None
class QueryResponse(BaseModel):
    answer: str; confidence: float; guard: Guard
    citations: list[Citation] = []; latencyMs: int | None = None; model: str | None = None
```

---

## 5. Bảng trạng thái version (BE sở hữu, nhắc lại từ ERD)

| Sự kiện | Chuyển trạng thái |
|---|---|
| Upload thành công | `— → PROCESSING` |
| BE gọi `/ai/ingest` thất bại (AI chết) | `PROCESSING → FAILED` |
| Callback `READY` | `PROCESSING → ACTIVE` (+ ACTIVE cũ → `SUPERSEDED`) |
| Callback `FAILED` | `PROCESSING → FAILED` |
| QA đánh dấu hết hiệu lực *(sau MVP)* | `ACTIVE → OBSOLETE` |

---

## 6. Luồng Admin Quản lý Người dùng (Admin User Management)

Dành riêng cho vai trò `ADMIN`. Phục vụ việc khởi tạo, cấp quyền và quản lý tài khoản người dùng nội bộ.

### 6.1. `GET /api/admin/users` (Lấy danh sách người dùng)
- **Query Params**: `page` (int, default 0), `size` (int, default 20), `role` (optional: `OPERATOR|ENGINEER|QA_ADMIN|ADMIN`), `search` (optional: theo username/fullName/email).
- **Response `200`**:
  ```json
  {
    "data": {
      "content": [
        {
          "id": "c9f0f895-...",
          "username": "engineer1",
          "fullName": "Nguyễn Văn A",
          "email": "nva@kcn.vn",
          "role": "ENGINEER",
          "isActive": true,
          "createdAt": "2026-07-26T10:00:00Z",
          "updatedAt": "2026-07-26T10:00:00Z"
        }
      ],
      "page": 0,
      "size": 20,
      "totalElements": 1,
      "totalPages": 1
    }
  }
  ```

### 6.2. `POST /api/admin/users` (Tạo tài khoản người dùng mới)
- **Request Body**:
  ```json
  {
    "username": "operator2",
    "password": "Password123!",
    "fullName": "Trần Văn B",
    "email": "tvb@kcn.vn",
    "role": "OPERATOR"
  }
  ```
- **Response `201`**: Tra về `UserProfileDTO` của user mới tạo.

### 6.3. `PUT /api/admin/users/{id}` (Cập nhật thông tin/vai trò người dùng)
- **Request Body**:
  ```json
  {
    "fullName": "Trần Văn B (Updated)",
    "email": "tvb_new@kcn.vn",
    "role": "ENGINEER"
  }
  ```
- **Response `200`**: Tra về `UserProfileDTO` đã cập nhật.

### 6.4. `PUT /api/admin/users/{id}/password` (Đổi / Reset mật khẩu người dùng)
- **Request Body**:
  ```json
  {
    "newPassword": "NewPassword123!"
  }
  ```
- **Response `200`**: `{"data": true, "message": "Password updated successfully"}`

### 6.5. `PATCH /api/admin/users/{id}/status` (Khóa / Kích hoạt tài khoản)
- **Request Body**:
  ```json
  {
    "isActive": false
  }
  ```
- **Response `200`**: Tra về `UserProfileDTO` đã cập nhật trạng thái `isActive`.

---

## 7. Phân hệ B — API Hỏi đáp Công khai (Public Anonymous Guest Session APIs)

Các API này phục vụ khách chưa đăng nhập trải nghiệm hỏi đáp với tài liệu tạm. Không yêu cầu JWT Bearer header.

### 7.1. `POST /api/public/sessions` (Tạo phiên tạm mới)
- **Header**: Không yêu cầu.
- **Response `201`**:
  ```json
  {
    "data": {
      "sessionId": "a1b2c3d4-...",
      "sessionToken": "a3f5b7c89...",
      "expiresAt": "2026-08-10T18:00:00Z"
    }
  }
  ```

### 7.2. `POST /api/public/sessions/{sessionId}/documents` (Upload PDF tạm)
- **Header**: `X-Session-Token: <sessionToken>`
- **Form Data**: `file` (Multipart PDF file, <= 25MB)
- **Response `201`**: Tra về `GuestDocumentDTO` (trạng thái `PROCESSING`).

### 7.3. `GET /api/public/sessions/{sessionId}/documents/{documentId}/status` (Polling OCR/Index)
- **Header**: `X-Session-Token: <sessionToken>`
- **Response `200`**: Tra về `GuestDocumentDTO` (`status`: `PROCESSING|READY|FAILED`, `pageCount`: int).

### 7.4. `POST /api/public/sessions/{sessionId}/query` (Hỏi đáp RAG phiên tạm)
- **Header**: `X-Session-Token: <sessionToken>`
- **Request Body**: `{"question": "Nội dung câu hỏi..."}`
- **Response `200`**: Tra về `AnswerDTO` kèm thông tin trích dẫn (`citations`).

### 7.5. `DELETE /api/public/sessions/{sessionId}` (Khách chủ động hủy phiên)
- **Header**: `X-Session-Token: <sessionToken>`
- **Response `200`**: Tiêu hủy toàn bộ File MinIO & Vector Qdrant của phiên ngay lập tức.

---

## 8. API Quản lý Vòng đời Phiên bản Tài liệu Chính thức (Phân hệ A)

Yêu cầu JWT Bearer header với vai trò `QA_ADMIN` hoặc `ADMIN`.

### 8.1. `POST /api/documents/{id}/versions` (Upload phiên bản mới v2, v3...)
- **Form Data**: `file` (PDF), `lang` (vi/en), `changelog` (nội dung thay đổi).
- **Response `201`**: Đẩy file vào MinIO `documents/{id}/v{nextVersion}/original.pdf`, tạo bản ghi trạng thái `PROCESSING` và kích hoạt AI Ingest.

### 8.2. `POST /api/documents/{id}/versions/{versionId}/publish` (Phát hành phiên bản ACTIVE)
- **Response `200`**: Chuyển target version sang `ACTIVE`. Tự động chuyển version active cũ của cùng documentId sang `SUPERSEDED`.

### 8.3. `POST /api/documents/{id}/versions/{versionId}/obsolete` (Đánh dấu lỗi thời OBSOLETE)
- **Response `200`**: Chuyển target version sang `OBSOLETE`. AI RAG ngừng trích dẫn version này.


