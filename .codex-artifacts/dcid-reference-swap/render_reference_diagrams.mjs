import fs from "node:fs/promises";
import path from "node:path";
import { instance } from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@viz-js/viz/dist/viz.js";
import sharp from "file:///C:/Users/HACOM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp/dist/index.mjs";

const outDir = "C:/project/new/dcid-web/.codex-artifacts/dcid-reference-swap/diagrams";
await fs.mkdir(outDir, { recursive: true });
const viz = await instance();

const architecture = `digraph Architecture {
  graph [rankdir=TB, bgcolor="#F8F9FB", pad=0.16, margin=0.02,
         nodesep=0.32, ranksep=0.48, splines=polyline, fontname="Arial"];
  node [shape=box, style="rounded,filled", fillcolor="#F0EDFF", color="#C4B5FD",
        fontcolor="#27223F", fontname="Arial", fontsize=12.5, penwidth=1.2,
        margin="0.16,0.10"];
  edge [color="#6B7280", fontcolor="#374151", fontname="Arial", fontsize=9.5,
        penwidth=1.15, arrowsize=0.65];

  subgraph cluster_client {
    label="1 · TẦNG CLIENT / GIAO DIỆN NGƯỜI DÙNG";
    color="#D8CF68"; fillcolor="#FFFDE8"; style="rounded,filled";
    fontcolor="#5F5715"; fontsize=13; penwidth=1.2;
    web [label="Flutter Web\nKiosk nhà xưởng / Admin"];
    mobile [label="Flutter Mobile\nAndroid Tablet / Smartphone kỹ sư"];
    {rank=same; web; mobile;}
  }

  subgraph cluster_governance {
    label="2 · GOVERNANCE / CONTROL PLANE · Spring Boot 3.3 · Java 21";
    color="#D8CF68"; fillcolor="#FFFDE8"; style="rounded,filled";
    fontcolor="#5F5715"; fontsize=13; penwidth=1.2;
    api [label="REST API + Security Filter\nJWT Bearer / Session Token", fillcolor="#E9E4FF"];
    audit [label="Audit Trail độc lập chuẩn ISO\nGhi nhận bất biến mọi thay đổi"];
    guest [label="Guest Session + TTL Cleanup\nScheduled mỗi 10 phút"];
    auth [label="Xác thực & RBAC\nOPERATOR · ENGINEER · QA_ADMIN · ADMIN"];
    proxy [label="File Proxy Controller\nMinIO Data Streaming"];
    docs [label="Quản lý vòng đời tài liệu\nACTIVE · SUPERSEDED · OBSOLETE"];
    {rank=same; audit; guest; auth; proxy; docs;}
    api -> {audit guest auth proxy docs};
  }

  subgraph cluster_ai {
    label="3 · AI INTELLIGENCE PLANE · Python · FastAPI · Celery";
    color="#D8CF68"; fillcolor="#FFFDE8"; style="rounded,filled";
    fontcolor="#5F5715"; fontsize=13; penwidth=1.2;
    fast [label="FastAPI Gateway :8000\n/ai/query · /ai/ingest · /ai/stream", fillcolor="#E9E4FF"];
    celery [label="Celery Worker Engine\nTask queue bất đồng bộ · Redis"];
    retrieve [label="Hybrid Retrieval\nDense Vector + BM25"];
    extract [label="Trích xuất hỗn hợp\nPyMuPDF native text\nPaddleOCR scan 200 DPI"];
    guard [label="Guardrail + Anti-Hallucination\nConfidence + numeric rules"];
    chunk [label="Layout-Aware Spatial Chunker\nBBox + snippet 300 ký tự"];
    llm [label="Local LLM / VLM\nLM Studio · Ollama\nQwen / DeepSeek"];
    embed [label="Embedding Engine\nmultilingual-e5-small · 384 chiều"];
    {rank=same; retrieve; celery;}
    {rank=same; guard; extract;}
    {rank=same; llm; chunk;}
    fast -> retrieve -> guard -> llm;
    fast -> celery -> extract -> chunk -> embed;
  }

  subgraph cluster_storage {
    label="4 · TẦNG LƯU TRỮ ĐA MÔ HÌNH";
    color="#D8CF68"; fillcolor="#FFFDE8"; style="rounded,filled";
    fontcolor="#5F5715"; fontsize=13; penwidth=1.2;
    pg [shape=cylinder, label="PostgreSQL 16\nUsers · Roles · Docs · Versions\nQuery Logs · Audit Logs"];
    qd [shape=cylinder, label="Qdrant Vector DB\nVector 384-dim + Spatial Payload"];
    minio [shape=cylinder, label="MinIO Object Storage\nPDF gốc · Ảnh trang · Crop BBox"];
    redis [shape=cylinder, label="Redis 7\nCache · Rate-limit · Celery Broker"];
    {rank=same; pg; qd; minio; redis;}
  }

  web -> api [label="HTTPS / REST / SSE"];
  mobile -> api;
  docs -> fast [label="1 · REST dispatch ingest"];
  api -> fast [label="2 · Query / Stream proxy"];
  fast -> celery;
  embed -> qd [label="Upsert vector + payload"];
  retrieve -> qd [label="Semantic search"];
  extract -> minio [label="Lưu file + ảnh trang"];
  {audit guest auth docs} -> pg [style=dashed];
  proxy -> minio;
  celery -> redis [dir=both];
  celery -> docs [label="3 · Callback READY / FAILED", style=dashed, constraint=false];
}`;

const guardrail = `digraph Guardrail {
  graph [rankdir=TB, bgcolor="#F8F9FB", pad=0.20, margin=0.03,
         nodesep=0.42, ranksep=0.48, splines=polyline, fontname="Arial"];
  node [shape=box, style="rounded,filled", fillcolor="#F0EDFF", color="#C4B5FD",
        fontcolor="#27223F", fontname="Arial", fontsize=14, penwidth=1.25,
        margin="0.22,0.13"];
  edge [color="#6B7280", fontcolor="#374151", fontname="Arial", fontsize=11,
        penwidth=1.2, arrowsize=0.70];

  q [label="Kỹ sư đặt câu hỏi tra cứu"];
  hybrid [label="Hybrid Retrieval\nQdrant + BM25"];
  topk [label="Lấy Top-K chunks có điểm số cao nhất"];
  score [shape=diamond, label="LỚP 1 · KIỂM TRA ĐỘ TIN CẬY\nScore < 0.60\n(hoặc < 0.25 khi hỏi tóm tắt)?", width=3.0, height=1.22];
  lock [label="KÍCH HOẠT KHÓA GUARDRAIL\nDữ liệu không đủ tin cậy để trả lời\nVui lòng kiểm tra bản vẽ gốc", fillcolor="#F7E8F0", color="#E879A7"];
  numeric [shape=diamond, label="LỚP 2 · KIỂM TRA SỐ LIỆU\nCó thông số điện áp, áp suất,\ndung sai...?", width=2.85, height=1.20];
  rule [label="RULE-BASED EXTRACTION\nTrích xuất chính xác giá trị số\ntừ văn bản gốc"];
  llm [label="GỬI CONTEXT SANG LLM LOCAL\nQwen / DeepSeek\nSinh câu trả lời phân tích"];
  cite [label="LỚP 3 · SPATIAL CITATION\nTrang X · BBox · snippet 300 ký tự"];
  answer [label="Trả về giao diện người dùng\nCâu trả lời có bằng chứng", fillcolor="#FFFFFF"];

  q -> hybrid -> topk -> score;
  score -> lock [label="ĐÚNG · không đủ dữ liệu"];
  score -> numeric [label="SAI · đủ tin cậy"];
  numeric -> rule [label="CÓ"];
  numeric -> llm [label="KHÔNG"];
  {rule llm} -> cite;
  cite -> answer;
}`;

async function render(name, dot, targetWidth, targetHeight) {
  const svg = viz.renderString(dot, { format: "svg", engine: "dot" });
  await fs.writeFile(path.join(outDir, `${name}.svg`), svg, "utf8");
  await sharp(Buffer.from(svg), { density: 180, limitInputPixels: false })
    .trim({ background: "#F8F9FB" })
    .extend({ top: 36, bottom: 36, left: 36, right: 36, background: "#F8F9FB" })
    .resize({ width: targetWidth, height: targetHeight, fit: "inside", withoutEnlargement: false })
    .sharpen({ sigma: 0.55 })
    .png({ compressionLevel: 9 })
    .toFile(path.join(outDir, `${name}.png`));
}

await render("architecture-reference-hires", architecture, 3600, 1900);
await render("guardrail-reference-hires", guardrail, 2200, 1900);
console.log(`Rendered high-resolution reference replacements in ${outDir}`);
