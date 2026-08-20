import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const source = "C:/project/new/dcid-web/.codex-artifacts/dcid-uml-render/template-starter.pptx";
const output = "C:/project/new/dcid-web/DCID_SEM4_Defense_Deck_UML_Rendered.pptx";
const workDir = "C:/project/new/dcid-web/.codex-artifacts/dcid-uml-render";
const diagramDir = path.join(workDir, "diagrams");
const renderDir = path.join(workDir, "final-render");
const layoutDir = path.join(workDir, "final-layout");

async function saveBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

const presentation = await PresentationFile.importPptx(await FileBlob.load(source));
await fs.mkdir(renderDir, { recursive: true });
await fs.mkdir(layoutDir, { recursive: true });

const before = await presentation.inspect({
  kind: "slide,textbox,shape,image,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders",
  maxChars: 500000,
});
const records = before.ndjson.split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line));

function findText(slideNumber, text) {
  const matches = records.filter((r) => r.slide === slideNumber && r.kind === "textbox" && r.text === text);
  if (matches.length !== 1) throw new Error(`Expected one textbox on slide ${slideNumber}: ${text}; found ${matches.length}`);
  return matches[0];
}

function replaceText(slideNumber, oldText, newText) {
  const record = findText(slideNumber, oldText);
  presentation.resolve(record.id).text.replace(oldText, newText);
}

function clearBody(slideNumber) {
  const targets = records.filter((r) =>
    r.slide === slideNumber &&
    ["textbox", "shape", "image"].includes(r.kind) &&
    Array.isArray(r.bbox) &&
    Number(r.bbox[1]) >= 140 && Number(r.bbox[1]) < 650
  );
  for (const target of targets) presentation.resolve(target.id).delete();
  return targets.length;
}

function setNotes(slideNumber, text) {
  const record = records.find((r) => r.slide === slideNumber && r.kind === "notes");
  if (!record) throw new Error(`Missing notes on slide ${slideNumber}`);
  const notes = presentation.resolve(record.id);
  notes.setText(text);
  notes.setVisible(true);
}

const slideConfigs = [
  {
    slide: 7,
    file: "01-system-architecture.png",
    alt: "Sơ đồ kiến trúc công nghệ DCID: Client, Governance, AI và Multi-Storage",
    notes: [
      "Sơ đồ render từ Mermaid kiến trúc tổng thể. Đọc từ trái sang phải: Client → Governance → AI → các kho lưu trữ; callback quay lại Backend để cập nhật trạng thái.",
      "",
      "[Sources]",
      "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 2.1, lines 45-98)",
      "- C:/project/new/dcid-web/docs/ARCHITECTURE.md",
    ].join("\n"),
  },
  {
    slide: 10,
    file: "02-ingestion-sequence.png",
    alt: "Sơ đồ sequence ingestion bất đồng bộ từ upload PDF đến callback READY hoặc FAILED",
    notes: [
      "Sơ đồ render từ Mermaid sequence ingestion. Backend trả nhận yêu cầu sớm; Celery xử lý OCR, chunk, embedding và Qdrant trước khi callback READY/FAILED.",
      "",
      "[Sources]",
      "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid A2, lines 277-306)",
      "- C:/project/new/dcid-web/docs/ai_processing.puml",
    ].join("\n"),
  },
  {
    slide: 12,
    file: "03-ai-guardrail-flow.png",
    alt: "Flowchart truy vấn AI với hybrid retrieval, score gate, numeric rule và spatial citation",
    notes: [
      "Sơ đồ render từ Mermaid guardrail. Thiếu bằng chứng thì khóa; đủ bằng chứng thì giữ nguyên số liệu hoặc gọi Local LLM/VLM rồi gắn citation trang, bbox và snippet.",
      "",
      "[Sources]",
      "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 5.4, lines 384-399)",
      "- C:/project/new/dcid-web/docs/ai_sequence.puml",
    ].join("\n"),
  },
  {
    slide: 14,
    file: "04-postgresql-erd.png",
    alt: "ERD PostgreSQL của users, documents, document_versions, pages, query_logs, work_orders và audit_logs",
    notes: [
      "ERD render từ Mermaid trong báo cáo và docs/ERD.md. Trục chính là documents → document_versions → document_pages; query_logs và work_orders cùng tham chiếu version.",
      "",
      "[Sources]",
      "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 3.2, lines 123-220)",
      "- C:/project/new/dcid-web/docs/ERD.md",
    ].join("\n"),
  },
  {
    slide: 15,
    file: "05-version-state-machine.png",
    alt: "State machine vòng đời document version từ PROCESSING đến READY, ACTIVE, SUPERSEDED, OBSOLETE hoặc FAILED",
    notes: [
      "State machine render từ Mermaid. Chỉ version ACTIVE được retrieval và database bảo đảm tối đa một ACTIVE trên mỗi document.",
      "",
      "[Sources]",
      "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 3.3, lines 224-235)",
      "- C:/project/new/dcid-web/docs/ERD.md (section 4)",
    ].join("\n"),
  },
];

replaceText(7, "Từng công nghệ khớp với một nhiệm vụ trong luồng", "Kiến trúc công nghệ: mỗi tầng một trách nhiệm");
replaceText(15, "Mỗi loại dữ liệu có một nguồn sự thật riêng", "Vòng đời version kiểm soát tài liệu hiệu lực");

for (const cfg of slideConfigs) {
  const deleted = clearBody(cfg.slide);
  if (deleted === 0) throw new Error(`No body shapes deleted on slide ${cfg.slide}`);
  const bytes = await fs.readFile(path.join(diagramDir, cfg.file));
  const slide = presentation.slides.items[cfg.slide - 1];
  slide.images.add({
    blob: bytes,
    contentType: "image/png",
    alt: cfg.alt,
    fit: "contain",
    position: { left: 50, top: 145, width: 1180, height: 505 },
    geometry: "rect",
  });
  setNotes(cfg.slide, cfg.notes);
}

const verified = await presentation.inspect({
  kind: "slide,textbox,shape,image,table,chart,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders,alt,contentType",
  maxChars: 600000,
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
