import fs from "node:fs/promises";
import path from "node:path";
import { instance } from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@viz-js/viz/dist/viz.js";
import sharp from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp/dist/index.mjs";

const outDir = "C:/project/new/dcid-web/.codex-artifacts/dcid-uml-render/diagrams";
await fs.mkdir(outDir, { recursive: true });
const viz = await instance();

const light = {
  bg: "#FFFFFF", ink: "#111827", muted: "#475569", cyan: "#009FE3",
  panel: "#F1F5F9", panel2: "#E0F2FE", line: "#94A3B8", danger: "#B91C1C",
};
const dark = {
  bg: "#0F172A", ink: "#F8FAFC", muted: "#CBD5E1", cyan: "#38BDF8",
  panel: "#1E3A5F", panel2: "#132B46", line: "#38BDF8", danger: "#8C3631",
};

const common = (c, rankdir = "LR") => `
  graph [rankdir=${rankdir}, bgcolor="${c.bg}", pad=0.20, margin=0.04,
         nodesep=0.34, ranksep=0.62, splines=ortho, fontname="Arial"];
  node [shape=box, style="rounded,filled", fillcolor="${c.panel}", color="${c.line}",
        fontcolor="${c.ink}", fontname="Arial", fontsize=15, penwidth=1.4,
        margin="0.18,0.13"];
  edge [color="${c.cyan}", fontcolor="${c.muted}", fontname="Arial",
        fontsize=11, penwidth=1.6, arrowsize=0.75];
`;

const diagrams = [
  {
    name: "01-system-architecture",
    bg: light.bg,
    dot: `digraph G {
      ${common(light, "LR")}
      graph [nodesep=0.42, ranksep=0.74];
      node [shape=box, fontsize=14, margin="0.22,0.16"];
      client [label="CLIENT / GIAO DIỆN\n────────────\nFlutter Web · Kiosk / Admin\nFlutter Mobile · Tablet kỹ sư"];
      gov [label="GOVERNANCE / CONTROL PLANE\n─────────────────\nSpring Boot 3.3 · Java 21\nREST API + JWT / Session Token\nRBAC 4 cấp\nDocument + Version Lifecycle\nGuest TTL · Audit · File Proxy", fillcolor="#111827", fontcolor="#FFFFFF"];
      ai [label="AI INTELLIGENCE PLANE\n────────────────\nPython · FastAPI · Celery\nPyMuPDF + PaddleOCR 200 DPI\nSpatial Chunker · BBox + snippet\ne5-small · Dense + BM25\nGuardrail · Local LLM / VLM", fillcolor="#E0F2FE"];
      store [label="MULTI-STORAGE\n────────────\nPostgreSQL · metadata / RBAC / audit\nQdrant · vector + spatial payload\nMinIO · PDF / page image / bbox crop\nRedis · queue / cache / rate-limit"];
      client -> gov [label="HTTPS · REST · SSE", penwidth=2.2];
      gov -> ai [label="ingest · query · stream", penwidth=2.2];
      ai -> gov [label="callback READY / FAILED", constraint=false];
      gov -> store [label="single-writer PG · file proxy"];
      ai -> store [label="Qdrant · MinIO · Redis"];
    }`,
  },
  {
    name: "02-ingestion-sequence",
    bg: light.bg,
    dot: `digraph G {
      ${common(light, "TB")}
      graph [nodesep=0.34, ranksep=0.50];
      node [fontsize=13]; edge [fontsize=10];
      qa [label="QA / ADMIN\nUPLOAD PDF", fillcolor="#111827", fontcolor="#FFFFFF"];
      be [label="SPRING BOOT\nBACKEND"];
      minio [shape=cylinder, label="MINIO\nPDF GỐC"];
      pg [shape=cylinder, label="POSTGRESQL\nVERSION = PROCESSING"];
      ai [label="FASTAPI\n202 ACCEPTED"];
      celery [label="CELERY WORKER\nXỬ LÝ NỀN", fillcolor="#E0F2FE"];
      extract [label="1 · EXTRACT\nPyMuPDF / PaddleOCR 200 DPI"];
      chunk [label="2 · CHUNK\nLayout + BBox + snippet"];
      embed [label="3 · EMBED\ne5-small · 384 chiều"];
      qdrant [shape=cylinder, label="QDRANT\nVECTOR + PAYLOAD"];
      ready [label="CALLBACK\nREADY / FAILED", fillcolor="#111827", fontcolor="#FFFFFF"];
      {rank=same; qa; be; minio; pg;}
      {rank=same; ai; celery;}
      {rank=same; extract; chunk; embed; qdrant; ready;}
      qa -> be [label="POST /api/documents"];
      be -> minio [label="lưu PDF gốc"];
      be -> pg [label="Version = PROCESSING"];
      be -> ai [label="POST /ai/ingest"];
      ai -> celery [label="202 + Redis queue"];
      celery -> extract [label="tải PDF"];
      extract -> chunk -> embed -> qdrant;
      qdrant -> ready [label="callback READY / FAILED"];
      ready -> pg [label="status + page_count + audit", constraint=false];
      celery -> minio [label="upload page images", constraint=false];
    }`,
  },
  {
    name: "03-ai-guardrail-flow",
    bg: dark.bg,
    dot: `digraph G {
      ${common(dark, "TB")}
      graph [nodesep=0.38, ranksep=0.52];
      q [label="KỸ SƯ ĐẶT CÂU HỎI", fillcolor="#FFFFFF", fontcolor="#0F172A"];
      search [label="HYBRID RETRIEVAL\nQdrant + BM25"];
      topk [label="TOP-K CHUNKS\nEvidence tốt nhất"];
      gate [shape=diamond, label="SCORE ĐỦ\nTIN CẬY?", fillcolor="#1E3A5F"];
      lock [label="LOCKED = TRUE\nDữ liệu chưa đủ · kiểm tra bản gốc", fillcolor="#8C3631", color="#FCA5A5"];
      numeric [shape=diamond, label="CÓ THÔNG SỐ\nKỸ THUẬT?", fillcolor="#1E3A5F"];
      rule [label="RULE-BASED\nGiữ nguyên số liệu gốc"];
      llm [label="LOCAL LLM / VLM\nChỉ sinh từ context"];
      cite [label="SPATIAL CITATION\nTrang + BBox + snippet"];
      answer [label="CÂU TRẢ LỜI CÓ BẰNG CHỨNG", fillcolor="#FFFFFF", fontcolor="#0F172A"];
      {rank=same; q; search; topk; gate;}
      {rank=same; lock; numeric;}
      {rank=same; rule; llm; cite; answer;}
      q -> search -> topk -> gate;
      gate -> lock [label="KHÔNG"];
      gate -> numeric [label="CÓ"];
      numeric -> rule [label="CÓ"];
      numeric -> llm [label="KHÔNG"];
      rule -> cite;
      llm -> cite;
      cite -> answer;
    }`,
  },
  {
    name: "04-postgresql-erd",
    bg: light.bg,
    dot: `digraph G {
      ${common(light, "TB")}
      graph [nodesep=0.34, ranksep=0.60, splines=polyline];
      node [shape=box, style="rounded,filled", fontsize=10.5, margin="0.14,0.10"];
      users [label="USERS\n────────\nid : uuid PK\nusername : varchar UK\nrole : OPERATOR / ENGINEER / QA / ADMIN\nis_active : boolean", fillcolor="#111827", fontcolor="#FFFFFF"];
      docs [label="DOCUMENTS\n────────\nid : uuid PK\ntitle : varchar\nmachine_code : varchar\ncategory / min_role : varchar\ncreated_by : uuid FK"];
      vers [label="DOCUMENT_VERSIONS\n────────\nid : uuid PK\ndocument_id : uuid FK\nversion_no : int\nstorage_key : varchar\nstatus : PROCESSING / READY / ACTIVE / ...\nlang / page_count", fillcolor="#E0F2FE"];
      pages [label="DOCUMENT_PAGES\n────────\nid : uuid PK\nversion_id : uuid FK\npage_no : int\nimage_key : varchar\nwidth / height : int"];
      queries [label="QUERY_LOGS\n────────\nid : uuid PK\nactor_id : uuid FK\nquestion : text\nmatched_version_id : uuid FK\nconfidence / locked / latency_ms"];
      work [label="WORK_ORDERS\n────────\nid : uuid PK\ncmms_ref : varchar UK\ndocument_version_id : uuid FK\ndeep_link / status"];
      audit [label="AUDIT_LOGS\n────────\nid : uuid PK\nactor_id : uuid\naction / resource_type\nresource_id : uuid\ndetail : jsonb"];
      {rank=same; users; docs; vers;}
      {rank=same; audit; pages; queries; work;}
      users -> docs [label="1  creates  N"];
      users -> queries [label="1  asks  N"];
      docs -> vers [label="1  has  N", penwidth=2.6];
      vers -> pages [label="1  has  N", penwidth=2.6];
      vers -> queries [label="1  matched by  N"];
      vers -> work [label="1  deep-links  N"];
      users -> audit [style=dashed, label="actor_id (logical)"];
    }`,
  },
  {
    name: "05-version-state-machine",
    bg: dark.bg,
    dot: `digraph G {
      ${common(dark, "LR")}
      graph [nodesep=0.36, ranksep=0.70];
      start [shape=circle, label="", width=0.24, fixedsize=true, fillcolor="#FFFFFF"];
      processing [label="PROCESSING\nQA upload PDF"];
      ready [label="READY\nAI ingest xong", fillcolor="#1E3A5F"];
      active [label="ACTIVE\nĐược phép retrieval", fillcolor="#FFFFFF", fontcolor="#0F172A", penwidth=2.3];
      superseded [label="SUPERSEDED\nCó version ACTIVE mới"];
      obsolete [label="OBSOLETE\nHết hiệu lực"];
      failed [label="FAILED\nOCR / ingest lỗi", fillcolor="#8C3631", color="#FCA5A5"];
      end [shape=doublecircle, label="", width=0.24, fixedsize=true, fillcolor="#FFFFFF"];
      start -> processing [label="upload"];
      processing -> ready [label="callback thành công"];
      processing -> failed [label="callback lỗi"];
      ready -> active [label="QA publish"];
      active -> superseded [label="version mới ACTIVE"];
      active -> obsolete [label="QA đánh dấu hết hiệu lực"];
      ready -> obsolete [label="hủy trước phát hành"];
      superseded -> obsolete [label="tiêu hủy"];
      failed -> end;
      note [shape=note, label="RÀNG BUỘC DATABASE\nTối đa 1 ACTIVE / document\nRetrieval chỉ lấy version ACTIVE", fillcolor="#132B46", color="#38BDF8"];
      active -> note [style=dashed, arrowhead=none];
    }`,
  },
];

for (const item of diagrams) {
  const svg = viz.renderString(item.dot, { format: "svg", engine: "dot" });
  await fs.writeFile(path.join(outDir, `${item.name}.svg`), svg, "utf8");
  await sharp(Buffer.from(svg), { density: 220 })
    .trim({ background: item.bg })
    .extend({ top: 28, bottom: 28, left: 28, right: 28, background: item.bg })
    .resize({ width: 2600, height: 1080, fit: "inside", withoutEnlargement: false })
    .png({ compressionLevel: 9 })
    .toFile(path.join(outDir, `${item.name}.png`));
}

console.log(`Rendered ${diagrams.length} UML-derived diagrams in ${outDir}`);
