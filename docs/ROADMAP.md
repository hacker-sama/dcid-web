# Smart KCN Docs — Kế hoạch triển khai (Implementation Plan)

> Đọc kèm [`ARCHITECTURE.md`](ARCHITECTURE.md). Tài liệu này biến kiến trúc thành **các milestone
> có thể giao được**, ưu tiên **vertical slice** (chạy thông 1 luồng end-to-end) trước khi mở rộng.

---

## 0. Chiến lược tổng thể

1. **Walking skeleton first.** M0 (skeleton + auth) đã xong. M1 dựng **1 lát cắt dọc mỏng**:
   *upload 1 tài liệu → OCR → index → hỏi được + trích dẫn*. Mục tiêu: chứng minh RAG chạy trên
   **CPU** và đo được latency/độ chính xác **sớm**, trước khi đầu tư sâu.
2. **Đo trên dữ liệu thật.** Chuẩn bị golden set (500 trang) + bộ câu hỏi đánh giá ngay từ M1 để
   bám KPI (OCR ≥95%, Recall@3 ≥92%, latency <5s, hallucination số liệu = 0%).
3. **Mỗi bảng = 1 Flyway migration; mỗi tính năng = 1 vertical slice** (entity → migration → repo →
   service (stub trước) → controller + `@PreAuthorize` → test).

### Cấu trúc monorepo (đề xuất)
```
dcid-web/
├── dcid-backend/     ✅ Spring Boot — governance/control plane (đã có)
├── dcid-frontend/    🟡 Next.js — Web console + Kiosk (cần format)
├── dcid-mobile/      ⬜ Flutter — app hiện trường Snap & Ask (SẼ TẠO ở M2–M4)
├── dcid-ai/          ⬜ Python (FastAPI + Celery) — AI plane (SẼ TẠO ở M1)
└── docs/             ✅ ARCHITECTURE.md, ROADMAP.md, FRONTEND.md
```

---

## 1. Milestones

| # | Tên | Phase (BC) | Tuần | Kết quả "done" |
|---|---|---|---|---|
| **M0** | Nền tảng + Auth | — | ✅ | Backend skeleton, self-JWT, RBAC, audit, docker-compose |
| **M1** | Vertical slice RAG | P1–P2 | 3–8 | Upload 1 PDF → hỏi được + trích dẫn, chạy CPU |
| **M2** | Đa ngôn ngữ + Guardrails | P2 | 6–9 | EN/CN/JP/VI, bbox crop, rule số liệu, ngưỡng 0.60 |
| **M3** | Governance & Admin | P3 | 9–11 | Versioning, RBAC đầy đủ, audit viewer, CMMS/MES API |
| **M4** | Kiosk/Mobile UI | P4 | 12–14 | Snap & Ask, side-by-side, tối ưu chạm/găng tay |
| **M5** | Pilot & UAT + Hardening | P5 | 15–18 | Chạy thật 1 chuyền, đạt KPI, đóng gói edge |

---

## 2. Chi tiết công việc theo milestone

### M1 — Vertical slice RAG (khử rủi ro lõi)
**Backend (`dcid-backend`)**
- [ ] Entity + migration: `documents`, `document_versions` (status `PROCESSING/READY`).
- [ ] `POST /api/documents` (QA_ADMIN): nhận PDF → lưu MinIO → tạo version → gọi AI ingest.
- [ ] `AiPipelineClient` (REST) + `POST /api/internal/ingest-callback` (token nội bộ).
- [ ] `POST /api/query` (ENGINEER/OPERATOR): forward sang AI, ghi `query_logs`.

**AI service (`dcid-ai` — tạo mới)**
- [ ] Khung FastAPI + Celery(worker) + Redis broker; `GET /ai/health`.
- [ ] `POST /ai/ingest`: PaddleOCR (VI/EN trước) → chunk → **e5-small (ONNX)** embed → **ChromaDB** upsert.
- [ ] `POST /ai/query`: retrieve top-k → **Qwen2.5-1.5B (GGUF/llama.cpp)** sinh câu trả lời + citation.
- [ ] Guardrail tối thiểu: cosine threshold.

**Frontend (`dcid-frontend`)**
- [ ] Màn upload tài liệu; màn hỏi–đáp hiển thị câu trả lời + trang trích dẫn.

**Đo lường:** latency query trên Core i5, độ đúng top-3 trên ~20 câu hỏi mẫu.

### M2 — Đa ngôn ngữ + Guardrails đầy đủ
- [ ] PaddleOCR **EN/CN/JP/VI** + **TSR** (bóc bảng thông số).
- [ ] Cắt & lưu **bounding-box crop** vào MinIO; trả kèm câu trả lời (khoanh đỏ số liệu).
- [ ] **Rule-based numeric extraction**: truy vấn chạm *điện áp/áp suất/nhiệt độ/dung sai* → trích
      chuỗi số liệu trực tiếp từ metadata gốc, không để LLM tự sinh.
- [ ] Cosine < 0.60 → **khóa câu trả lời tự động** + cảnh báo đỏ "Yêu cầu kỹ sư xác minh".
- [ ] `query_logs` đầy đủ: user, query, doc version, confidence, guard-hit.

### M3 — Governance & Admin
- [ ] **Versioning workflow**: `ACTIVE/SUPERSEDED/OBSOLETE`; upload version mới → cũ superseded;
      QA đánh dấu obsolete; retrieval chỉ trả version ACTIVE.
- [ ] **RBAC** `@PreAuthorize` trên toàn bộ endpoint theo 4 vai; lọc kết quả theo quyền.
- [ ] **Audit viewer** (ADMIN): `GET /api/admin/audit-logs` (dựng lại từ `AuditLogService`).
- [ ] **Rate limit** upload/query qua `RateLimitFilter` (Redis) — bật lại đúng endpoint.
- [ ] **CMMS/MES**: `POST /api/integration/work-orders` nhận Work Order → tạo deep-link tới đúng trang.

### M4 — Kiosk/Mobile UI hiện trường
- [ ] **Snap & Ask** (chụp ảnh → hỏi), **side-by-side** bản vẽ, nút to, thao tác găng tay.
- [ ] Auth + UI theo role (Operator chỉ thấy SOP/an toàn; Engineer thấy bản vẽ/log).

### M5 — Pilot & UAT + Hardening
- [ ] Deploy **1 dây chuyền trọng điểm**; thu feedback kỹ sư; hiệu chỉnh.
- [ ] **Đo KPI**: OCR ≥95% (500 trang), Recall@3 ≥92%, latency <5s, hallucination số liệu = 0%.
- [ ] Load test; backup/restore Postgres+MinIO+Chroma; quản lý secret; **đóng gói offline** cho edge.

---

## 3. Hợp đồng tích hợp (API contract) — bản rút gọn

**Backend (public, JWT):** `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/documents`,
`POST /api/documents/{id}/versions`, `POST /api/query`, `GET /api/documents`,
`POST /api/integration/work-orders`, `GET /api/admin/audit-logs`.

**Backend ↔ AI (nội bộ, token):**
| Hướng | Endpoint | Payload chính |
|---|---|---|
| BE → AI | `POST /ai/ingest` | versionId, storageKey, langs |
| BE → AI | `POST /ai/query` | userId, role, question, filters(version, machine) |
| AI → BE | `POST /api/internal/ingest-callback` | versionId, status, pages, error? |

Response `query`: `{ answer, citations[{page,bboxKey,docVersion}], confidence, guard: {locked, numericRule} }`.

---

## 4. Tech stack chốt (đề xuất)

| Lớp | Chọn | Ghi chú |
|---|---|---|
| Backend | Spring Boot 3.3 / Java 21 | đã có |
| AI service | FastAPI + Celery + Redis | Python 3.11 |
| OCR | PaddleOCR (mobile, multi-lang) + TSR | |
| Embedding | multilingual-e5-small (ONNX qua `optimum`) | |
| Vector DB | ChromaDB (persistent, trên edge) | |
| LLM serving | **llama-cpp-python** (Qwen2.5-1.5B Q4_K_M) ✅ *đã chốt* | nhúng thẳng, dễ đóng gói offline cho edge |
| Frontend | Next.js (đã có) | |

---

## 5. Phân công (map với 5 nhân sự trong Business Case)

| Vai | Chịu trách nhiệm chính |
|---|---|
| PM/BA | KPI, golden set, nghiệp vụ ISO, nghiệm thu từng milestone |
| AI Engineer | `dcid-ai`: OCR, chunking, embed, LLM, guardrails, đo KPI |
| Backend Dev | `dcid-backend`: domain, `AiPipelineClient`, RBAC, audit, CMMS/MES |
| FE/Mobile Dev | `dcid-frontend`: Kiosk UI, Snap & Ask, side-by-side |
| QA/QC | test dữ liệu kỹ thuật, load test, đo hallucination |

---

## 6. Rủi ro chính & giảm thiểu

| Rủi ro | Giảm thiểu |
|---|---|
| OCR kém trên bản mờ/nhòe/viết tay/dấu đỏ | Khảo sát mẫu ở P0; fine-tune/tiền xử lý ảnh; Human-in-the-loop khi confidence thấp |
| LLM latency trên CPU vượt 5s | Q4_K_M, giới hạn context, cache, đo sớm ở M1; cân nhắc SLM nhỏ hơn |
| Chất lượng đa ngôn ngữ (CN/JP) | Tách pipeline theo lang; đánh giá riêng từng ngôn ngữ |
| Sai số liệu kỹ thuật (zero-tolerance) | Rule-based extraction + khóa câu trả lời + bbox bằng chứng |
| Bảng thông số phức tạp | TSR chuyên dụng; chunking giữ cấu trúc bảng |

---

## 7. Quyết định đã chốt / còn mở

**Đã chốt:**
1. ✅ **Monorepo** — AI service đặt ở thư mục `dcid-ai/`.
2. ✅ **Ngôn ngữ M1** — VI + EN trước; CN/JP mở ở M2.
3. ✅ **LLM serving** — `llama-cpp-python` (Qwen2.5-1.5B Q4_K_M).

**Còn mở (không chặn M1, chốt trước Pilot):**
4. **Dữ liệu pilot**: chọn 2–3 chuyền/loại máy để lấy mẫu (P0).
5. **Deploy pilot**: full-stack trên 1 Edge, hay Central + Edge tách?

---

## 8. Thứ tự thực thi M1 (khi bắt đầu code)

**Sprint 1 (M1):**
1. Backend: entity + migration `documents`/`document_versions` + `POST /api/documents` (lưu MinIO).
2. Khung `dcid-ai` (FastAPI + `/ai/health` + `/ai/ingest` + `/ai/query`) với PaddleOCR + e5 + Chroma.
3. Nối `AiPipelineClient` + `POST /api/internal/ingest-callback`.
4. FE: 2 màn (upload, hỏi–đáp).

> Trạng thái hiện tại: **chưa code** — đang duyệt plan + kiến trúc.
> Kiến trúc chi tiết đầy đủ (module `dcid-ai`, data model, API, deploy) xem [`ARCHITECTURE.md`](ARCHITECTURE.md).
