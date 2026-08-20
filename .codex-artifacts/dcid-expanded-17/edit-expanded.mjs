import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const source = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-expanded-17\\template-starter.pptx";
const output = "C:\\project\\new\\dcid-web\\DCID_SEM4_Defense_Deck_Expanded_17_Slides.pptx";
const workDir = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-expanded-17";
const renderDir = path.join(workDir, "final-render");
const layoutDir = path.join(workDir, "final-layout");

async function saveBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

const presentation = await PresentationFile.importPptx(await FileBlob.load(source));
await fs.mkdir(renderDir, { recursive: true });
await fs.mkdir(layoutDir, { recursive: true });

const before = await presentation.inspect({
  kind: "slide,textbox,shape,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders",
  maxChars: 300000,
});
const records = before.ndjson.split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line));

function findRecord(slideNumber, kind, text) {
  const matches = records.filter((record) => record.slide === slideNumber && record.kind === kind && record.text === text);
  if (matches.length !== 1) {
    throw new Error(`Expected one match on slide ${slideNumber} for ${kind} text ${JSON.stringify(text)}; found ${matches.length}`);
  }
  return matches[0];
}

function replaceText(slideNumber, oldText, newText) {
  const record = findRecord(slideNumber, "textbox", oldText);
  presentation.resolve(record.id).text.replace(oldText, newText);
}

function replaceBlock(slideNumber, oldText, newText) {
  if (!oldText.includes("\n")) {
    replaceText(slideNumber, oldText, newText);
    return;
  }
  const oldLines = oldText.split("\n");
  const newLines = newText.split("\n");
  if (oldLines.length !== newLines.length) {
    throw new Error(`Line-count mismatch on slide ${slideNumber}: ${JSON.stringify(oldText)}`);
  }
  const record = findRecord(slideNumber, "textbox", oldText);
  const target = presentation.resolve(record.id);
  for (let i = 0; i < oldLines.length; i += 1) target.text.replace(oldLines[i], newLines[i]);
}

function setNotes(slideNumber, text) {
  const record = records.find((item) => item.slide === slideNumber && item.kind === "notes");
  if (!record) throw new Error(`Missing notes on slide ${slideNumber}`);
  const notes = presentation.resolve(record.id);
  notes.setText(text);
  notes.setVisible(true);
}

const footerEdits = [
  [2, "2/12", "2/17"], [3, "3/12", "3/17"], [4, "4/12", "4/17"],
  [5, "5/12", "5/17"], [6, "6/12", "6/17"], [7, "6/12", "7/17"],
  [8, "7/12", "8/17"], [9, "8/12", "9/17"], [10, "8/12", "10/17"],
  [11, "9/12", "11/17"], [12, "9/12", "12/17"], [13, "10/12", "13/17"],
  [14, "10/12", "14/17"], [15, "5/12", "15/17"], [16, "11/12", "16/17"],
  [17, "12/12", "17/17"],
];
for (const edit of footerEdits) replaceText(...edit);

// Slide 7 — technology responsibility map.
[
  ["Mỗi công nghệ giữ một trách nhiệm rõ ràng", "Từng công nghệ khớp với một nhiệm vụ trong luồng"],
  ["LỚP", "NHIỆM VỤ"], ["CÔNG NGHỆ", "THÀNH PHẦN"], ["VÌ SAO DÙNG", "ĐẦU RA"],
  ["Client", "Giao diện"],
  ["Flutter · Riverpod · Dio · SSE/STOMP", "Flutter · Riverpod · Dio"],
  ["Một codebase cho Web kiosk và Android", "Web/Android, state, REST và SSE"],
  ["Governance", "Chính sách"],
  ["Java 21 · Spring Boot · Security · JPA", "Java 21 · Spring Boot · Security"],
  ["RBAC, version, audit, API và single-writer", "JWT/RBAC, lifecycle, audit và proxy"],
  ["AI", "AI API"],
  ["Python · FastAPI · Celery · PyMuPDF · PaddleOCR", "Python · FastAPI · Pydantic"],
  ["OCR, RAG, vision và xử lý nền", "Contract ingest / query / stream"],
  ["Retrieval", "Xử lý nền"],
  ["multilingual-e5 · BM25 · Qdrant", "Celery · Redis"],
  ["Bắt cả ý nghĩa lẫn mã máy / mã lỗi chính xác", "Queue OCR/embed, retry và progress"],
  ["Storage", "Document AI"],
  ["PostgreSQL · MinIO · Redis", "PyMuPDF · PaddleOCR"],
  ["Tách metadata, file nhị phân và hàng đợi", "Text, layout, bảng và bbox crop"],
  ["Ops", "RAG & đáp án"],
  ["Docker Compose · Nginx · GitHub Actions", "e5 · BM25 · Qdrant · Local LLM/VLM"],
  ["Đóng gói, triển khai nội bộ và CI/CD", "Hybrid retrieve → grounded answer"],
].forEach(([oldText, newText]) => replaceBlock(7, oldText, newText));

// Slide 10 — detailed asynchronous ingestion.
[
  ["06 · MAIN FLOW", "06 · AI INGESTION"],
  ["Tài liệu được biến thành tri thức có vị trí nguồn", "AI ingest chạy bất đồng bộ, có callback trạng thái"],
  ["UPLOAD", "ACCEPT"], ["PDF vào MinIO\nVersion = PROCESSING", "QA upload\nBackend kiểm quyền"],
  ["EXTRACT", "PERSIST"], ["Native text hoặc\nPaddleOCR 200 DPI", "MinIO + version\nPROCESSING"],
  ["CHUNK", "EXTRACT"], ["Giữ bảng + Bbox\n+ snippet nguồn", "Celery lấy PDF\nPyMuPDF / OCR"],
  ["EMBED", "TRANSFORM"], ["multilingual-e5\nvector 384 chiều", "Chunk + bbox\ne5 embedding"],
  ["INDEX", "COMMIT"], ["Qdrant + payload\ncallback READY", "Qdrant upsert\ncallback READY"],
  ["Điểm khác biệt", "Đảm bảo nhất quán"],
  ["Mỗi chunk giữ page_no + bbox + snippet, nên câu trả lời có thể mở đúng trang và khoanh đúng vùng bằng chứng.", "Backend là nguồn trạng thái: callback READY/FAILED mới kết thúc vòng đời PROCESSING."],
].forEach(([oldText, newText]) => replaceBlock(10, oldText, newText));

// Slide 12 — detailed synchronous query and guardrail flow.
[
  ["06 · MAIN FLOW", "06 · AI QUERY"],
  ["Câu hỏi chỉ đi tới LLM sau khi qua quyền và bằng chứng", "Câu hỏi qua quyền và guardrail trước khi sinh đáp án"],
  ["QUESTION", "REQUEST"], ["Câu hỏi +\nmachine code", "JWT + question\n+ filter"],
  ["RBAC + chỉ\nversion ACTIVE", "Backend lọc\nrole + ACTIVE"],
  ["Dense + BM25\nTop-K evidence", "e5 + BM25\nTop-K chunks"],
  ["Score gate +\nkiểm số liệu", "Score gate +\nnumeric rules"],
  ["Local LLM/VLM\ntrả lời theo context", "Local LLM/VLM\ncontext only"],
  ["PROVE", "RESPONSE"], ["Citation + audit\nhoặc từ chối", "Answer + citation\n+ confidence"],
  ["Khi bằng chứng đủ", "Đường trả lời"],
  ["Trả lời + confidence + citations\n→ người dùng mở trang nguồn để đối chiếu", "AI trả AnswerDTO → Backend ghi query_log\n→ Flutter mở đúng trang và bbox"],
  ["Khi bằng chứng yếu", "Đường từ chối"],
  ["Khóa hoặc gắn nhãn câu trả lời tham khảo\n→ yêu cầu kỹ sư kiểm tra bản vẽ gốc", "locked = true hoặc gắn nhãn tham khảo\n→ kỹ sư kiểm tra tài liệu gốc"],
  ["Thông điệp an toàn: giảm câu trả lời thiếu căn cứ — không tuyên bố AI không bao giờ sai.", "Query chạy đồng bộ; SSE chỉ đổi cách truyền token, không bỏ policy hay guardrail."],
].forEach(([oldText, newText]) => replaceBlock(12, oldText, newText));

// Slide 14 — relational ERD with keys and constraints.
[
  ["PostgreSQL giữ nghiệp vụ; file và vector tách riêng", "ERD quan hệ: version là trục của tài liệu và truy vấn"],
  ["role · status", "PK id · role"],
  ["machine_code · min_role", "PK id · machine_code"],
  ["VERSIONS", "DOC_VERSIONS"], ["status · version_no", "PK id · FK document_id"],
  ["confidence · locked", "FK actor_id · FK version_id"],
  ["actor · action · detail", "actor_id · resource_id"],
  ["PAGES", "DOC_PAGES"], ["page_no · image_key", "FK version_id · page_no"],
  ["GUEST SESSIONS", "GUEST_SESSIONS"], ["token_hash · expires_at", "PK id · expires_at"],
  ["Ngoài PostgreSQL", "Quan hệ mở rộng"],
  ["MINIO · PDF / ảnh", "WORK_ORDERS · FK version_id"],
  ["QDRANT · vector + bbox", "QUERY_LOGS · feedback / note / at"],
  ["REDIS · queue / cache", "GUEST_DOCUMENTS · FK session_id"],
  ["Nguyên tắc: chỉ Backend ghi PostgreSQL", "Khóa ngoại giữ quan hệ; vector chunk không lưu trong PostgreSQL"],
].forEach(([oldText, newText]) => replaceBlock(14, oldText, newText));

// Slide 15 — database ownership and topology.
[
  ["03 · ARCHITECTURE", "07 · DATABASE DESIGN"],
  ["Dual-plane tách quản trị nghiệp vụ khỏi xử lý AI", "Mỗi loại dữ liệu có một nguồn sự thật riêng"],
  ["FLUTTER CLIENTS\nWeb kiosk · Admin · Android", "API CLIENTS\nFlutter · Admin · tích hợp"],
  ["GOVERNANCE PLANE", "BACKEND · SINGLE WRITER"],
  ["Spring Boot 3.3 · Java 21", "Spring Boot · JPA · Flyway"],
  ["Auth / RBAC\nDocument & version lifecycle\nGuest session & TTL\nAudit · API · file proxy", "Ghi metadata & trạng thái\nRBAC trước mọi truy cập\nProxy file có JWT\nAudit mọi thay đổi"],
  ["AI INTELLIGENCE PLANE", "AI · INDEXER & READER"],
  ["FastAPI · Celery · Local LLM/VLM", "FastAPI · Celery · RAG"],
  ["OCR / vision\nChunk + embedding\nHybrid retrieval\nGuardrail + grounded answer", "Đọc PDF từ MinIO\nGhi vector + payload\nĐọc evidence Top-K\nCallback READY / FAILED"],
  ["PostgreSQL\nnghiệp vụ", "PostgreSQL\nsource of truth"],
  ["MinIO\nPDF / ảnh", "MinIO\nPDF · page · crop"],
  ["Qdrant\nvector", "Qdrant\nchunk · vector · bbox"],
  ["Redis\nqueue / cache", "Redis\nqueue · cache · TTL"],
].forEach(([oldText, newText]) => replaceBlock(15, oldText, newText));

setNotes(7, [
  "Đi theo từng hàng từ giao diện tới RAG để nhấn mạnh: mỗi công nghệ tồn tại vì một trách nhiệm cụ thể, không phải để làm phong phú stack.",
  "",
  "[Sources]",
  "- C:/project/new/dcid-web/docs/ARCHITECTURE.md (B2, B6)",
  "- C:/project/new/dcid-web/dcid-ai/README.md",
].join("\n"));

setNotes(10, [
  "Luồng ingest trả 202 sớm. Celery xử lý OCR/chunk/embed; Backend chỉ chuyển trạng thái khi nhận callback READY hoặc FAILED.",
  "",
  "[Sources]",
  "- C:/project/new/dcid-web/docs/ARCHITECTURE.md (4.1, B5)",
  "- C:/project/new/dcid-web/docs/API-CONTRACT.md (ingest contract)",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V2__documents.sql",
].join("\n"));

setNotes(12, [
  "Nhấn mạnh hai nhánh: đủ bằng chứng thì trả đáp án có citation; thiếu bằng chứng thì locked hoặc yêu cầu kiểm tra tài liệu gốc.",
  "",
  "[Sources]",
  "- C:/project/new/dcid-web/docs/ARCHITECTURE.md (4.2, B5)",
  "- C:/project/new/dcid-web/docs/API-CONTRACT.md (query contract)",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V3__query_logs.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V6__query_feedback.sql",
].join("\n"));

setNotes(14, [
  "Đọc ERD theo trục documents → document_versions → document_pages. Query log nối người dùng với version được match; guest session là nhánh truy vấn ẩn danh.",
  "",
  "[Sources]",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V1__init.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V2__documents.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V3__query_logs.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V4__work_orders.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V5__guest_sessions.sql",
  "- C:/project/new/dcid-web/dcid-backend/src/main/resources/db/migration/V6__query_feedback.sql",
].join("\n"));

setNotes(15, [
  "Phân biệt nguồn sự thật: PostgreSQL giữ nghiệp vụ, MinIO giữ file/bằng chứng, Qdrant giữ chỉ mục vector, Redis chỉ giữ trạng thái tạm và hàng đợi.",
  "",
  "[Sources]",
  "- C:/project/new/dcid-web/docs/ARCHITECTURE.md (2, 3, B7)",
  "- C:/project/new/dcid-web/docs/API-CONTRACT.md",
].join("\n"));

const verified = await presentation.inspect({
  kind: "slide,textbox,shape,image,table,chart,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders",
  maxChars: 400000,
});
await fs.writeFile(path.join(workDir, "final-inspect.ndjson"), verified.ndjson, "utf8");

for (const [index, slide] of presentation.slides.items.entries()) {
  const stem = `slide-${String(index + 1).padStart(2, "0")}`;
  await saveBlob(path.join(renderDir, `${stem}.png`), await presentation.export({ slide, format: "png", scale: 1 }));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(layoutDir, `${stem}.layout.json`), await layout.text(), "utf8");
}

await saveBlob(
  path.join(workDir, "final-montage.webp"),
  await presentation.export({ format: "webp", montage: true, scale: 1 }),
);

const pptx = await PresentationFile.exportPptx(presentation);
await pptx.save(output);
console.log(`Created ${output}`);
