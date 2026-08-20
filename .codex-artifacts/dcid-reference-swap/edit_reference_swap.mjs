import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const source = "C:/project/new/dcid-web/.codex-artifacts/dcid-reference-swap/template-starter.pptx";
const output = "C:/project/new/dcid-web/DCID_SEM4_Defense_Deck_Reference_Images_HiRes.pptx";
const workDir = "C:/project/new/dcid-web/.codex-artifacts/dcid-reference-swap";
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
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,alt,prompt,isPlaceholder,placeholders",
  maxChars: 500000,
});
const records = before.ndjson.split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line));

function imageOnSlide(slideNumber) {
  const matches = records.filter((r) => r.slide === slideNumber && r.kind === "image");
  if (matches.length !== 1) throw new Error(`Expected one image on slide ${slideNumber}; found ${matches.length}`);
  return presentation.resolve(matches[0].id);
}

function notesOnSlide(slideNumber) {
  const record = records.find((r) => r.slide === slideNumber && r.kind === "notes");
  if (!record) throw new Error(`Missing notes on slide ${slideNumber}`);
  return presentation.resolve(record.id);
}

async function replaceImage(slideNumber, imagePath, alt, frame) {
  const image = imageOnSlide(slideNumber);
  const oldGeometry = image.geometry;
  const oldBorderRadius = image.borderRadius;
  const oldRotation = image.rotation;
  const oldFlipHorizontal = image.flipHorizontal;
  const oldFlipVertical = image.flipVertical;
  const oldLockAspectRatio = image.lockAspectRatio;
  const bytes = await fs.readFile(imagePath);
  image.replace({
    blob: bytes,
    contentType: "image/png",
    alt,
    fit: "contain",
  });
  image.frame = frame;
  image.crop = { left: 0, top: 0, right: 0, bottom: 0 };
  image.fit = "contain";
  image.geometry = oldGeometry;
  image.borderRadius = oldBorderRadius;
  image.rotation = oldRotation;
  image.flipHorizontal = oldFlipHorizontal;
  image.flipVertical = oldFlipVertical;
  image.lockAspectRatio = oldLockAspectRatio;
}

await replaceImage(
  7,
  path.join(workDir, "diagrams", "architecture-reference-hires.png"),
  "Sơ đồ kiến trúc DCID độ phân giải cao, dựng lại theo ảnh tham chiếu số 1",
  { left: 223, top: 145, width: 834, height: 505 },
);
await replaceImage(
  12,
  path.join(workDir, "diagrams", "guardrail-reference-hires.png"),
  "Sơ đồ guardrail ba lớp độ phân giải cao, dựng lại theo ảnh tham chiếu số 2",
  { left: 405, top: 145, width: 470, height: 505 },
);

const notes7 = notesOnSlide(7);
notes7.setText([
  "Ảnh kiến trúc được dựng lại ở độ phân giải cao theo bố cục và màu của ảnh tham chiếu; không phóng trực tiếp screenshot 676x617 nên chữ và đường nối không bị mờ.",
  "",
  "[Sources]",
  "- C:/Users/HACOM/AppData/Local/Temp/codex-clipboard-c1ae28ef-1139-4846-b87b-6a3071bf3373.png (visual reference)",
  "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 2.1, lines 45-98)",
  "- C:/project/new/dcid-web/docs/ARCHITECTURE.md",
].join("\n"));
notes7.setVisible(true);

const notes12 = notesOnSlide(12);
notes12.setText([
  "Ảnh guardrail được dựng lại ở độ phân giải cao theo bố cục dọc và màu tím nhạt của ảnh tham chiếu; quan hệ và điều kiện lấy từ Mermaid trong báo cáo.",
  "",
  "[Sources]",
  "- C:/Users/HACOM/AppData/Local/Temp/codex-clipboard-34d0134c-1f5c-4e04-b73f-5991dfeedaf8.png (visual reference)",
  "- C:/Users/HACOM/Downloads/report_presentation (1).md (Mermaid 5.4, lines 384-399)",
  "- C:/project/new/dcid-web/docs/ai_sequence.puml",
].join("\n"));
notes12.setVisible(true);

const verified = await presentation.inspect({
  kind: "slide,textbox,shape,image,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,alt,contentType,isPlaceholder,placeholders",
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
