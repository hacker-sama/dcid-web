# Smart KCN Docs — Kế hoạch 6 tuần cho team 3–4 người

> ⚠️ **ĐÃ THAY THẾ:** dự án được tái định hướng thành **khóa luận cuối kỳ** — dùng
> [`PLAN-THESIS.md`](PLAN-THESIS.md) (8 tuần, 5 người, có trục thực nghiệm). File này giữ lại
> làm tham chiếu cho định hướng sản phẩm/pilot sau khóa luận.

> Đầu mục thống nhất toàn bộ task **BE + AI + FE + hệ thống**, chia người & lịch tuần.
> Đọc kèm [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`ROADMAP.md`](ROADMAP.md) · [`FRONTEND.md`](FRONTEND.md).

---

## 1. Mục tiêu 6 tuần (MVP vertical slice)

**Định nghĩa Done (demo cuối tuần 6):**
> Đăng nhập → QA **upload 1 PDF** → hệ thống **OCR + index** → kỹ sư **hỏi** → nhận **câu trả lời +
> trích dẫn trang** + **banner guardrail** khi thiếu chắc chắn. Chạy trên 1 máy (docker-compose) +
> app **Flutter Android**.

| ✅ TRONG scope 6 tuần | ⛔ NGOÀI scope (để pilot sau) |
|---|---|
| Self-JWT + RBAC 4 vai (đã có) | CN/JP (chỉ VI + EN) |
| Upload + OCR + embed + RAG + query | Kiosk Windows fullscreen (chỉ build được) |
| Guardrail: ngưỡng cosine + rule số liệu | Celery scale, Kafka events |
| Trích dẫn trang (+ bbox nếu kịp) | CMMS/MES tích hợp |
| Flutter: login, tra cứu/hỏi, upload, list | Versioning workflow đầy đủ |
| Đo latency + Recall@3 trên eval set nhỏ | KPI đầy đủ (95% OCR/500 trang, 0% hallucination) |

**Điểm xuất phát (đã xong):** BE skeleton + self-JWT + audit; `dcid-app` Flutter skeleton
(login/search/ask đã wire). **Chưa có:** `dcid-ai`, domain tài liệu BE, tích hợp.

---

## 2. Team & vai trò

**Phương án 4 người (khuyến nghị):**
| Ký hiệu | Vai | Sở hữu |
|---|---|---|
| **A** | Backend + DevOps | `dcid-backend`, docker-compose, secrets, CI |
| **B** | AI Engineer | `dcid-ai` (OCR, embed, RAG, LLM, guardrails) |
| **C** | Flutter Dev | `dcid-app` (mobile Android + màn admin) |
| **D** | Lead/BA + QA | điều phối, golden set, eval, test, demo; hỗ trợ FE/test |

**Nếu chỉ 3 người:** bỏ D → A kiêm DevOps+điều phối, C kiêm QA/golden set; **cắt bớt**: Snap & Ask,
bbox overlay, màn admin (chỉ còn list + upload), versioning. Mỗi người tự viết test phần mình.

---

## 3. Backlog thống nhất (task list)

> Est = person-days. Dep = phụ thuộc. **Contract-first:** chốt hợp đồng API ngay tuần 1 để 3 luồng chạy song song.

### 🔵 Backend — Owner A
| ID | Task | Est | Tuần | Dep |
|---|---|---|---|---|
| BE-1 | Entity + migration `documents`, `document_versions` | 1.5 | W1 | — |
| BE-2 | `POST /api/documents` upload PDF → MinIO + tạo version | 2 | W1–2 | BE-1, SYS-1 |
| BE-3 | `AiPipelineClient` gọi `POST /ai/ingest` | 1 | W2 | AI-1 |
| BE-4 | `POST /api/internal/ingest-callback` cập nhật status | 1 | W2 | BE-1 |
| BE-5 | `POST /api/query` → forward AI + ghi `query_logs` | 2 | W3 | AI-4 |
| BE-6 | `GET /api/documents` + `GET /api/files/**` (proxy MinIO) | 2 | W3–4 | BE-1 |
| BE-7 | RBAC `@PreAuthorize` theo 4 vai + audit wired | 2 | W5 | BE-5 |
| BE-8 | Versioning tối thiểu (ACTIVE/OBSOLETE) *(stretch)* | 1.5 | W5 | BE-1 |

### 🟢 AI service `dcid-ai` — Owner B
| ID | Task | Est | Tuần | Dep |
|---|---|---|---|---|
| AI-1 | Khung FastAPI + `/ai/health` + Dockerfile | 1 | W1 | — |
| AI-2 | `/ai/ingest`: PaddleOCR (VI+EN) → chunk | 3 | W1–2 | AI-1 |
| AI-3 | Embed e5-small (ONNX) + ChromaDB upsert | 2 | W2 | AI-2 |
| AI-4 | `/ai/query`: retrieve top-k + llama-cpp Qwen2.5 + citation | 3 | W3 | AI-3 |
| AI-5 | Guardrail: ngưỡng cosine < 0.60 + rule số liệu | 2 | W4 | AI-4 |
| AI-6 | Cắt bbox crop → MinIO, trả `bboxKey` *(stretch)* | 2 | W4 | AI-4 |
| AI-7 | Chuyển ingest sang Celery (async) *(stretch)* | 1.5 | W5 | AI-2 |

### 🟣 Flutter `dcid-app` — Owner C
| ID | Task | Est | Tuần | Dep |
|---|---|---|---|---|
| FE-1 | Màn Documents (list) + Upload (QA) → BE | 2.5 | W1–2 | BE-2 |
| FE-2 | Hoàn thiện Tra cứu/Ask + answer + citation UI | 2 | W3 | BE-5 |
| FE-3 | Viewer: ảnh trang + overlay bbox (CustomPaint) | 2.5 | W4 | BE-6, AI-6 |
| FE-4 | Refine role UI + session/expiry + error states | 1.5 | W5 | — |
| FE-5 | Snap & Ask (camera → `/api/query` multipart) *(stretch)* | 2 | W5–6 | BE-5 |
| FE-6 | Build Android + smoke trên thiết bị; demo | 1.5 | W6 | — |

### ⚙️ Hệ thống/DevOps — Owner A (+ D)
| ID | Task | Est | Tuần | Dep |
|---|---|---|---|---|
| SYS-1 | docker-compose thêm `dcid-ai` + `chromadb` | 1 | W1 | — |
| SYS-2 | `.env.example` + secrets (APP_JWT_SECRET, token nội bộ) | 0.5 | W1 | — |
| SYS-3 | Seed users 4 vai + bucket tài liệu mẫu | 0.5 | W2 | SYS-1 |
| SYS-4 | CI nhẹ: build BE + `flutter analyze` + lint AI | 1 | W2 | — |
| SYS-5 | Backup/restore notes + đóng gói demo | 1 | W6 | — |

### 🟠 QA/PM — Owner D
| ID | Task | Est | Tuần | Dep |
|---|---|---|---|---|
| PM-0 | Điều phối, standup, backlog, demo | xuyên suốt | W1–6 | — |
| QA-1 | Thu thập **golden set** VI+EN (50–100 trang thật) | 3 | W1–2 | — |
| QA-2 | **Eval set**: bộ câu hỏi + đáp án kỳ vọng | 2 | W2–3 | QA-1 |
| QA-3 | Test tích hợp mỗi milestone (ingest/query) | xuyên suốt | W3–6 | — |
| QA-4 | Đo **KPI-lite**: OCR spot-check, Recall@3, latency | 2 | W5–6 | QA-2 |

---

## 4. Lịch 6 tuần (swimlane)

| Tuần | A — Backend/DevOps | B — AI | C — Flutter | D — PM/QA |
|---|---|---|---|---|
| **W1** Nền tảng + **chốt API contract** | BE-1, SYS-1, SYS-2 | AI-1, AI-2 (spike OCR) | FE-1 (UI docs/upload, dùng mock) | PM-0, QA-1 |
| **W2** Ingest end-to-end | BE-2, BE-3, BE-4, SYS-3, SYS-4 | AI-2 xong, AI-3 | FE-1 nối API thật | QA-1/2, hỗ trợ CI |
| **W3** Query/RAG end-to-end | BE-5, BE-6 (bắt đầu) | **AI-4** (query+LLM) | FE-2 (answer/citation) | QA-2, QA-3 (test ingest) |
| **W4** Guardrail + bbox | BE-6 xong (file proxy) | AI-5, AI-6 (bbox) | FE-3 (viewer+bbox) | QA-3 (test query), đo latency |
| **W5** RBAC/audit + hardening | BE-7, BE-8 | AI-7 / tinh chỉnh | FE-4, FE-5 (Snap&Ask) | QA-4 (KPI), test RBAC |
| **W6** UAT + Demo + buffer | hardening, SYS-5 | bugfix, tinh chỉnh model | FE-6 (build+demo), FE-5 xong | UAT, báo cáo KPI, demo |

**Cột mốc tích hợp:** cuối **W2** = ingest chạy thông · cuối **W3** = hỏi–đáp chạy thông ·
cuối **W4** = có guardrail + trích dẫn · **W6** = demo + đo KPI-lite.

---

## 5. Đường găng (critical path) & rủi ro

**Critical path:** `AI-2 → AI-3 → AI-4 → BE-5 → FE-2` (ingest → embed → query → forward → UI).
Trễ AI = trễ cả chuỗi → ưu tiên B, và **chốt API contract tuần 1** để FE/BE làm với **mock** trước.

| Rủi ro | Giảm thiểu |
|---|---|
| Latency LLM/OCR trên CPU vượt 5s | Đo **ngay W3** trên Core i5; Q4_K_M, giới hạn context; nếu cần đổi SLM nhỏ hơn |
| Cài đặt PaddleOCR/llama.cpp tốn thời gian | Dành spike W1; đóng Docker sớm; pin version |
| FE chờ BE/AI | Contract-first + mock server; FE làm UI trước, nối API sau |
| Team ramp Dart/Python | Chia rõ 1 người/stack; dùng lib sẵn, tránh custom nặng |
| Scope phình | Các task *(stretch)* (bbox, Snap&Ask, Celery, versioning) **cắt trước** nếu trễ |

---

## 6. Nghi thức làm việc (light)

- **Standup** ngắn 2–3 lần/tuần; **demo nội bộ** cuối mỗi tuần theo cột mốc.
- **Nhánh/PR:** feature branch → PR review chéo; `main` luôn build được.
- **CI (SYS-4):** BE `./mvnw test`, FE `flutter analyze && flutter test`, AI lint/test.
- **Board:** dùng bảng task theo ID ở §3 (Trello/Jira/GitHub Projects).

---

## 7. Đầu ra cuối 6 tuần

- Demo end-to-end chạy được (compose + Flutter Android) theo Định nghĩa Done §1.
- Báo cáo **KPI-lite**: latency đo được (<5s mục tiêu), Recall@3 trên eval set, OCR spot-check VI+EN,
  guardrail lock hoạt động.
- Mã nguồn 3 service + docs cập nhật → sẵn sàng bước vào **Pilot/UAT** (M5 của roadmap 18 tuần).
