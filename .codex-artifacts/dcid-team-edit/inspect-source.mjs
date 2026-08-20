import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const source = "C:\\project\\new\\dcid-web\\DCID_SEM4_Defense_Deck.pptx";
const outDir = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-team-edit\\source-inspect";

async function saveBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

const presentation = await PresentationFile.importPptx(await FileBlob.load(source));
await fs.mkdir(outDir, { recursive: true });

const snapshot = await presentation.inspect({
  kind: "slide,textbox,shape,image,table,chart,notes,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,isPlaceholder,placeholders",
  maxChars: 200000,
});
await fs.writeFile(path.join(outDir, "source-inspect.ndjson"), snapshot.ndjson, "utf8");

for (const [index, slide] of presentation.slides.items.entries()) {
  const stem = `slide-${String(index + 1).padStart(2, "0")}`;
  await saveBlob(path.join(outDir, `${stem}.png`), await presentation.export({ slide, format: "png", scale: 1 }));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(outDir, `${stem}.layout.json`), await layout.text(), "utf8");
}

await saveBlob(
  path.join(outDir, "source-montage.webp"),
  await presentation.export({ format: "webp", montage: true, scale: 1 }),
);

console.log(`Inspected ${presentation.slides.items.length} slides`);
