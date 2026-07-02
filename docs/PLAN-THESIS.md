# Smart KCN Docs — Kế hoạch Khóa luận 8 tuần (nhóm 5 người)

> **Bối cảnh:** Khóa luận cuối kỳ ngành CNTT, yêu cầu chỉnh chu cả **hệ thống** lẫn **AI**.
> Nhóm 4–5 người · **8 tuần** đến hạn bảo vệ · dữ liệu **tự sưu tầm** (không có công ty đối tác).
> File này **thay thế** [`PLAN-6-WEEKS.md`](PLAN-6-WEEKS.md) (bản định hướng sản phẩm) cho mục tiêu khóa luận.
> Đọc kèm: [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`ERD.md`](ERD.md) · [`FRONTEND.md`](FRONTEND.md).

---

## 1. Đóng khung đề tài (Thesis framing)

### Tên đề tài (đề xuất)
> **"Hệ thống hỏi–đáp tài liệu kỹ thuật cơ khí on-premise ứng dụng RAG đa phương thức,
> với cơ chế kiểm soát ảo giác số liệu"**

*(EN: An On-premise Multimodal RAG System for Mechanical Engineering Documents with Numeric
Hallucination Control)*

### Câu hỏi nghiên cứu (Research Questions)
- **RQ1:** Pipeline OCR→RAG xử lý tài liệu kỹ thuật thực tế (bảng thông số, scan suy giảm,
  đa ngôn ngữ VI/EN) đạt chất lượng truy xuất ra sao so với baseline chunking thô?
- **RQ2:** Cơ chế guardrail lai (confidence-gate + rule-based numeric extraction) giảm tỉ lệ
  ảo giác số liệu xuống mức nào so với LLM sinh tự do?
- **RQ3:** SLM lượng tử hóa chạy CPU (on-premise) đánh đổi chất lượng–độ trễ như thế nào?

### 4 đóng góp để bảo vệ (Contributions)
1. **Hệ thống end-to-end on-premise**: BE Spring Boot (RBAC, audit, storage) + AI service Python
   + app Flutter — chạy không cần cloud/GPU.
2. **Bộ dữ liệu đánh giá tự xây** cho QA tài liệu cơ khí VI/EN: golden set + bộ câu hỏi có đáp án,
   gồm nhóm câu hỏi số liệu và tập scan suy giảm (degradation) — *tự tạo benchmark là một đóng góp*.
3. **Guardrail numeric faithfulness**: so sánh định lượng 3 cấu hình (LLM thuần / confidence-gate /
   hybrid rule-extraction).
4. **Đánh giá thực nghiệm trên phần cứng biên** (CPU Core i5): Recall@k, faithfulness, latency, OCR accuracy.

### Scope: giữ gì, cắt gì

| ✅ GIỮ (ra điểm) | ⛔ CẮT (plumbing, không ra điểm) |
|---|---|
| Pipeline OCR→chunk→embed→retrieve→LLM | Kiosk fullscreen native (dùng web + F11/Chromium `--kiosk` là đủ) |
| Guardrail + benchmark + ablation | CMMS/MES, work-order flow |
| Golden set + eval harness tự động | Versioning workflow đầy đủ (chỉ giữ status cơ bản) |
| BE: auth/RBAC/audit/upload/query (đã có ~60%) | Admin console sâu, biểu đồ |
| Flutter: login + tra cứu + upload + citation | Snap & Ask camera *(chỉ làm nếu dư — demo sugar)* |
| Chương thực nghiệm + phân tích lỗi | Celery/Kafka scale-out |

---

## 2. Chiến lược dữ liệu (không có công ty đối tác)

### Nguồn tài liệu sưu tầm (tuần 1)
| Nguồn | Loại | Ngôn ngữ | Đặc điểm quý |
|---|---|---|---|
| Manual PLC (Siemens S7, Mitsubishi FX) | hướng dẫn vận hành | EN | bảng thông số điện dày đặc |
| Datasheet biến tần, servo, motor (ABB, Delta, Yaskawa) | spec sheet | EN | dung sai, điện áp, momen |
| Catalog vòng bi SKF/NSK, bulong tiêu chuẩn | tra cứu kích thước | EN | bảng tra nhiều chiều |
| Manual máy CNC/máy công cụ bản phân phối VN | HDSD dịch Việt | **VI** | tiếng Việt kỹ thuật thật |
| TCVN/QCVN về an toàn máy, giáo trình cơ khí | tiêu chuẩn/SOP | **VI** | văn phong quy phạm |

**Mục tiêu:** 15–25 tài liệu, **100–200 trang** đưa vào hệ thống; cân bằng VI/EN ~40/60.

### Tạo tập test "điều kiện nhà máy" (degradation set)
In ~20–30 trang → **scan lại** (nghiêng, mờ, photocopy 2 lần, ghi chú tay, đóng dấu) → tập
`degraded/`. Trong luận văn mô tả đây là **phương pháp mô phỏng suy giảm dữ liệu có kiểm soát**
— đo OCR/retrieval trên cả 2 tập (sạch vs suy giảm) là một thí nghiệm đắt giá.

### Bộ đánh giá (eval set) — người 5 chủ trì, cả nhóm góp
- **80–120 câu hỏi** có đáp án chuẩn (ground truth + trang nguồn), chia 3 nhóm:
  1. **Factual/số liệu** (~40%): "Điện áp cấp cho X?", "Dung sai trục Y?" → chấm *exact-match số* → đo hallucination.
  2. **Quy trình/SOP** (~40%): "Các bước thay dầu máy Z?" → chấm đúng/sai theo rubric.
  3. **Ngoài phạm vi** (~20%): câu không có trong tài liệu → kỳ vọng guardrail **khóa** (đo false-answer rate).
- Lưu dạng CSV/JSON để **harness chạy tự động**, in ra bảng metric mỗi lần đổi cấu hình.

### Ghi rõ giới hạn (limitations — viết thẳng vào luận văn)
Chưa có dữ liệu doanh nghiệp thật; CN/JP để hướng phát triển; quy mô eval set nhỏ.

---

## 3. Phương pháp đánh giá (chương thực nghiệm)

### Metric
| Metric | Đo gì | Mục tiêu |
|---|---|---|
| **Recall@3 / Recall@5** | truy xuất đúng đoạn nguồn | ≥ 85% (eval set tự xây) |
| **Numeric hallucination rate** | % câu số liệu trả sai so với ground truth | → 0% với guardrail |
| **False-answer rate** | % câu ngoài phạm vi mà hệ thống vẫn "chém" | càng thấp càng tốt |
| **Latency p50/p95** | thời gian trả lời trên CPU i5 | < 5s |
| **OCR CER/WER** (spot-check) | chất lượng bóc tách, tập sạch vs suy giảm | báo cáo so sánh |

### Bảng thí nghiệm (ablation) — trái tim của điểm AI
| # | Thí nghiệm | So sánh |
|---|---|---|
| E1 | **Chunking**: fixed-size vs layout/table-aware | Recall@k, answer accuracy |
| E2 | **Guardrail**: LLM thuần vs confidence-gate (θ=0.60) vs + numeric rule | hallucination rate, false-answer rate |
| E3 | **Retrieval**: dense-only (e5) vs hybrid BM25+dense *(nếu kịp)* | Recall@k |
| E4 | **Model/quantization**: Qwen2.5-1.5B Q4 vs Q8 (hoặc 0.5B vs 1.5B) | quality vs latency |
| E5 | **Tập sạch vs suy giảm** | toàn bộ metric |

> Tối thiểu phải có **E1 + E2**; E3–E5 làm nếu còn thời gian, mỗi cái thêm là một mục trong chương thực nghiệm.

---

## 4. Phân công 5 người

| # | Vai | Trách nhiệm chính | Sản phẩm trong luận văn |
|---|---|---|---|
| **1** | **PM + chủ bút** | Điều phối, chốt API contract T1, gỡ vướng; **viết chương 1–2 từ T2**; tổng hợp kết quả, slide bảo vệ | Chương 1 (giới thiệu), 2 (cơ sở lý thuyết + related work), tổng hợp |
| **2** | **Backend** | Hoàn thiện phần còn lại: `AiPipelineClient` + `ingest-callback`, `POST /api/query` + `query_logs`, `GET /api/files/**`; RBAC + audit. **Dừng ở đó** | Chương 3 (kiến trúc hệ thống — phần BE) |
| **3** | **AI Engineer** | `dcid-ai`: OCR (PaddleOCR VI+EN) → chunk → embed (e5) → Chroma → LLM (llama.cpp); guardrail; chạy toàn bộ **E1–E2 (E3–E5 nếu kịp)** | Chương 3 (pipeline AI) + Chương 4 (thực nghiệm) |
| **4** | **Flutter** | App gọn: login, tra cứu + answer + citation + banner guardrail, upload QA, viewer trang nguồn. Xong sớm → phụ người 5 chấm eval | Chương 3 (ứng dụng) + demo bảo vệ |
| **5** | **Data & Eval (QA/DevOps)** | Sưu tầm tài liệu + degradation set + **eval set 80–120 câu** + **harness đo tự động**; docker-compose thêm `dcid-ai`/`chroma`; CI nhẹ | Chương 4 (dataset + phương pháp đo) |

**Nguyên tắc:** người 3 và 5 là **đường găng học thuật** — cả nhóm ưu tiên hỗ trợ khi họ vướng.

---

## 5. Lịch 8 tuần

| Tuần | Cột mốc | 1 – PM/Bút | 2 – BE | 3 – AI | 4 – Flutter | 5 – Data/Eval |
|---|---|---|---|---|---|---|
| **T1** | Chốt contract + dataset kickoff | Outline luận văn ⬜, API contract ✅ | `AiPipelineClient` + callback ✅ | Khung `dcid-ai` ✅, spike PaddleOCR ⬜ | Màn Documents/Upload ✅ | Sưu tầm tài liệu đợt 1 ⬜ |
| **T2** | Skeleton khép kín | **Viết chương 1–2** | `POST /api/query` + `query_logs` | Ingest: OCR→chunk→embed→Chroma | Nối upload API thật | Degradation set + draft eval set |
| **T3** | **Ingest E2E chạy thông** | Chương 2 (related work) | `GET /api/files` proxy | Query: retrieve + LLM + citation | Màn tra cứu + answer UI | Eval set v1 + harness v1 |
| **T4** | **Query E2E + baseline đầu tiên** | Review kết quả baseline | RBAC + audit hoàn chỉnh | **Chạy baseline (E1 arm 1)** + đo latency | Banner guardrail + citation viewer | Harness tự động in metric |
| **T5** | Guardrail + cải tiến | Chương 3 (hệ thống) draft | Hỗ trợ AI/FE, bugfix | Guardrail + **E2**; chunking cải tiến **E1 arm 2** | Viewer trang nguồn | Chấm nhóm câu SOP (rubric) |
| **T6** | **Đóng băng thí nghiệm** | Chương 4 draft từ số liệu | Freeze BE, hỗ trợ đo | Chốt E1–E2 (+E3/E4 nếu kịp), phân tích lỗi | Freeze app, quay video demo dự phòng | Tổng hợp bảng metric cuối |
| **T7** | **Code freeze — chỉ viết** | Ghép chương, chương 5 (kết luận) | Viết phần BE | Viết phần thực nghiệm | Viết phần ứng dụng | Viết phần dataset |
| **T8** | Nộp + tập bảo vệ | Hoàn thiện quyển + slide | Demo dry-run | Phản biện thử (Q&A kỹ thuật) | Demo dry-run | Kiểm tra số liệu nhất quán |

### 📌 Cập nhật tiến độ T1 (02/07/2026)

**Đã xong (vượt tiến độ — một phần việc T2/T3 đã hoàn thành sớm):**
- ✅ `docs/API-CONTRACT.md` chốt v1 (ingest/callback/query, token nội bộ, allowedVersionIds).
- ✅ BE trọn vai trò trong contract: upload→MinIO→trigger ingest, `AiPipelineClient`,
  `/api/internal/ingest-callback` (ghi `document_pages` + auto-publish ACTIVE),
  `POST /api/query` + ghi `query_logs` *(vốn là việc T2)* — build + test xanh.
- ✅ Skeleton `dcid-ai` đúng work order (`docs/PLAN-DCID-AI.md`): 3 endpoint, token guard
  constant-time, ingest đọc PDF thật từ MinIO + pypdf, mock query deterministic,
  **12/12 pytest pass** (kiểm chứng độc lập trong venv sạch), Dockerfile + compose service `ai`.
- ✅ ERD + migrations V1–V4, entities/repositories (nền của T1 BE).
- ✅ **Màn Documents/Upload Flutter** đúng work order (`docs/PLAN-FLUTTER-DOCS.md`): list + detail +
  upload multipart, fix xong bug parse `DocsRepository.listDocuments()`. Verify thật bằng SDK:
  `flutter pub get` / `analyze` (0 issue) / `test` (6/6 pass) / `flutter build web` (build thành công).
- ✅ **Pivot kiến trúc FE (02/07/2026): "máy tính" chạy Web, không phải app native Windows** —
  xem [`FRONTEND.md`](FRONTEND.md) §0.1. Đã sửa `core/kiosk.dart` (bỏ `dart:io`/`Platform`, vốn vỡ
  build web) và luồng upload (path-based → **bytes-based**, vì `PlatformFile.path` luôn null trên
  web) — cả hai đã verify bằng `flutter build web` thật, không chỉ đoán.
- ✅ **E2E đã chạy thật (02/07/2026), Docker bật:** `docker-compose up -d postgres minio` →
  backend + `dcid-ai` chạy native → login → upload PDF 3 trang → ingest thật (đọc MinIO, đếm trang
  bằng pypdf) → callback → `GET /api/documents/{id}` trả `status: ACTIVE, pageCount: 3` đúng khớp →
  `/api/query` trả lời đúng logic guardrail mock. Audit log ghi thành công. Toàn bộ backend test
  (`mvnw test`) + AI test (12/12 pytest) vẫn xanh sau các fix.
  **Phát hiện & sửa 3 bug hạ tầng/code thật** khi verify (chi tiết: `docs/SETUP.md` §6):
  1. `docker-compose.yml` thiếu `ports:` cho `postgres` → trúng nhầm PostgreSQL cài sẵn trên máy
     dev → đổi map sang host port `5433`.
  2. Spring `RestClient` (JDK HttpClient) mặc định thử HTTP/2, `uvicorn` chỉ nói HTTP/1.1 → request
     ingest hỏng giữa chừng → ép `HTTP_1_1` tường minh trong `AiClientConfig`.
  3. Default MinIO creds trong `dcid-ai` (`minioadmin`) không khớp thật (`minio`/`minio123`) → sửa
     `config.py` + `.env.example`.
  Tiện thể sửa thêm 1 bug độc lập phát hiện qua log: `AuditLog.detail` (JSONB) thiếu
  `@JdbcTypeCode(SqlTypes.JSON)` khiến **mọi lần ghi audit log đều lỗi** (kể cả khi `detail=null`) —
  đã fix, audit log giờ ghi được.

**Còn lại của T1 (làm nốt trước khi vào T2):**
1. ⬜ **Người 1** — Outline luận văn (mục lục 5 chương + phân công viết) → file `docs/THESIS-OUTLINE.md`.
2. ⬜ **Người 3** — Spike PaddleOCR: cài thử, OCR 2–3 trang mẫu VI+EN, ghi nhận thời gian/chất lượng
   (quyết định sớm PaddleOCR vs EasyOCR trước khi code pipeline thật ở T2).
3. ⬜ **Người 5** — Sưu tầm tài liệu đợt 1 (mục §2): 15–25 tài liệu VI/EN, bắt đầu degradation set.

**3 luật cứng:**
1. **T4 phải có số liệu baseline** — nếu chưa, cắt ngay E3–E5 và mọi stretch.
2. **T7 code freeze tuyệt đối** — mọi commit sau T6 chỉ là bugfix demo.
3. Chương 1–2 viết **song song từ T2**, không dồn cuối.

---

## 6. Cấu trúc quyển luận văn (đề xuất)

1. **Giới thiệu** — bài toán tra cứu tài liệu kỹ thuật, downtime, yêu cầu on-premise; RQ1–3. *(người 1)*
2. **Cơ sở lý thuyết & công trình liên quan** — RAG, OCR/TSR, SLM/quantization, hallucination
   control, các hệ QA tài liệu doanh nghiệp. *(người 1, cả nhóm góp)*
3. **Thiết kế & xây dựng hệ thống** — kiến trúc 2 mặt phẳng, ERD, pipeline AI, guardrail,
   app Flutter, bảo mật RBAC/audit. *(người 2, 3, 4)*
4. **Dữ liệu & Thực nghiệm** — dataset + degradation, eval set, metric, E1–E2(+), bảng kết quả,
   phân tích lỗi. *(người 3, 5 — chương quan trọng nhất)*
5. **Kết luận & hướng phát triển** — limitation (dữ liệu thật, CN/JP, kiosk/CMMS = future work).

---

## 7. Rủi ro & đối sách (bản khóa luận)

| Rủi ro | Mức | Đối sách |
|---|---|---|
| **Viết không kịp** (rủi ro #1 của khóa luận nhóm) | 🔴 | Chương 1–2 từ T2; T7 code-freeze; người 1 own tiến độ quyển |
| AI setup lâu (PaddleOCR/llama.cpp trên máy nhóm) | 🔴 | Spike ngay T1, đóng Docker, pin version; nếu kẹt → đổi EasyOCR/ctransformers |
| Latency CPU > 5s | 🟡 | Đo tại T4; giảm context/top-k, đổi Q4→nhỏ hơn; *tệ nhất*: báo cáo trung thực trade-off (vẫn là kết quả!) |
| Eval set chất lượng kém → số liệu vô nghĩa | 🟡 | Người 5 + PM review chéo từng câu hỏi; ground truth phải kèm trang nguồn |
| Thành viên bận/rớt tiến độ | 🟡 | Mỗi tuần có cột mốc kiểm được; stretch cắt theo thứ tự E5→E4→E3→Snap&Ask |
| Demo hỏng hôm bảo vệ | 🟢 | Quay **video demo dự phòng** ở T6; compose 1 lệnh dựng lại |

---

## 8. Điểm xuất phát (đã xong — không tính lại vào 8 tuần)

*(Cập nhật 02/07/2026 — xem chi tiết §5 "Cập nhật tiến độ T1" ở trên.)*

- ✅ BE: skeleton + self-JWT + RBAC 4 vai + audit; ERD + migration V1–V4; entities/repositories;
  upload/list/detail documents + MinIO; `AiPipelineClient`; `/api/internal/ingest-callback`
  (ghi `document_pages` + auto-publish ACTIVE); `POST /api/query` + `query_logs`. Build + test xanh.
- ✅ AI: skeleton `dcid-ai` (FastAPI) chạy đúng contract — health/ingest/query, token guard,
  ingest đọc PDF thật từ MinIO, mock query deterministic. 12/12 pytest pass, Docker sẵn.
- ✅ FE: `dcid-app` Flutter — login, router role-guard, màn Tra cứu/Ask, màn **Tài liệu** (list/detail/upload)
  đã nối API thật. **2 target chính thức: Web (kiosk/admin) + Android (mobile)** — xem pivot ở
  [`FRONTEND.md`](FRONTEND.md) §0.1. Verify bằng SDK thật: `analyze` 0 issue, `test` 6/6 pass,
  `flutter build web` build thành công.
- ✅ Docs: kiến trúc, ERD, API contract, frontend (đã cập nhật pivot web), roadmap.
- ⬜ Chưa có: pipeline AI thật (OCR/embed/LLM/guardrail — vẫn là mock), dataset, eval harness,
  outline + quyển luận văn.

> Việc còn lại của T1 xem danh sách 4 mục ở §5 phía trên (outline luận văn, spike PaddleOCR,
> sưu tầm tài liệu, chạy E2E khi có Docker).
