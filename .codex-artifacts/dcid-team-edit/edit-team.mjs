import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const source = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-team-edit\\template-starter.pptx";
const output = "C:\\project\\new\\dcid-web\\DCID_SEM4_Defense_Deck_Team_Updated.pptx";
const workDir = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-team-edit";
const renderDir = path.join(workDir, "final-render");
const layoutDir = path.join(workDir, "final-layout");

async function saveBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

const presentation = await PresentationFile.importPptx(await FileBlob.load(source));
await fs.mkdir(renderDir, { recursive: true });
await fs.mkdir(layoutDir, { recursive: true });

const edits = [
  [1, "Nhóm thực hiện: [Tên nhóm]", "Nhóm thực hiện: Nhóm DCID"],

  [2, "[Tên thành viên 1]", "Phạm Hải Đông"],
  [2, "PM / Documentation", "Leader · Backend · Governance"],
  [2, "Scope · báo cáo · slide · điều phối", "Điều phối · Auth/RBAC · version · audit"],

  [2, "[Tên thành viên 2]", "Lê Nhật Huy"],
  [2, "Backend", "Phó nhóm · AI/RAG"],
  [2, "Auth/RBAC · tài liệu/version · audit · API", "OCR · RAG · guardrail · tích hợp Backend–AI"],

  [2, "[Tên thành viên 3]", "Phạm Anh Vũ"],
  [2, "AI Engineer", "Backend / Full-stack"],
  [2, "OCR · RAG · guardrail · LLM/VLM", "API · dữ liệu · tích hợp giao diện"],

  [2, "[Tên thành viên 4]", "Nguyễn Minh Hà"],
  [2, "Frontend Flutter", "Data · Evaluation · Tài liệu"],
  [2, "Web kiosk · Android · citation viewer", "Dataset · eval · chuẩn hóa tài liệu"],

  [2, "[Tên thành viên 5]", "Dương Anh Vũ"],
  [2, "Data / QA / DevOps", "Flutter Frontend"],
  [2, "Dataset · eval · Docker · CI/CD", "Web kiosk · Android · citation viewer"],
];

const before = await presentation.inspect({
  kind: "textbox",
  include: "id,slide,text",
  maxChars: 100000,
});
const records = before.ndjson
  .split(/\r?\n/)
  .filter(Boolean)
  .map((line) => JSON.parse(line));

for (const [slideNumber, oldText, newText] of edits) {
  const match = records.find((record) => record.slide === slideNumber && record.text === oldText);
  if (!match) throw new Error(`Could not find slide ${slideNumber} text: ${oldText}`);
  const target = presentation.resolve(match.id);
  target.text.replace(oldText, newText);
}

const verified = await presentation.inspect({
  kind: "slide,textbox,shape,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders",
  maxChars: 200000,
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
