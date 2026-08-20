import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const BUILD_DIR = "C:\\project\\new\\dcid-web\\.codex-artifacts\\dcid-sem4-deck";
const FINAL_PPTX = "C:\\project\\new\\dcid-web\\DCID_SEM4_Defense_Deck.pptx";
const HERO = path.join(BUILD_DIR, "dcid-hero.png");
const ICON = path.join(BUILD_DIR, "dcid-icon.png");
const RENDER_DIR = path.join(BUILD_DIR, "rendered");

const W = 1280;
const H = 720;
const C = {
  bg: "#FFFFFF",
  ink: "#101828",
  body: "#344054",
  muted: "#667085",
  navy: "#111A2E",
  navy2: "#1C2A44",
  cyan: "#16A8E0",
  cyan2: "#66D0F6",
  cyanPale: "#E9F7FD",
  panel: "#F2F4F7",
  panel2: "#EAECF0",
  rule: "#D0D5DD",
  green: "#087F5B",
  greenPale: "#E6F7F0",
  amber: "#B54708",
  amberPale: "#FFF4E5",
  red: "#B42318",
  redPale: "#FEE4E2",
  white: "#FFFFFF",
};
const FONT = "Arial";

async function readImageBytes(filePath) {
  const bytes = await fs.readFile(filePath);
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

function addText(slide, text, x, y, w, h, opts = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name: opts.name,
    position: { left: x, top: y, width: w, height: h },
    fill: opts.fill ?? "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    fontSize: opts.size ?? 20,
    typeface: FONT,
    color: opts.color ?? C.body,
    bold: opts.bold ?? false,
    alignment: opts.align ?? "left",
    verticalAlignment: opts.valign ?? "top",
    autoFit: opts.autoFit ?? "shrinkText",
  };
  return shape;
}

function addBox(slide, x, y, w, h, opts = {}) {
  const shape = slide.shapes.add({
    geometry: opts.geometry ?? "roundRect",
    name: opts.name,
    position: { left: x, top: y, width: w, height: h },
    fill: opts.fill ?? C.panel,
    line: {
      style: opts.lineStyle ?? "solid",
      fill: opts.line ?? "none",
      width: opts.lineWidth ?? 0,
    },
    borderRadius: opts.radius ?? "rounded-xl",
  });
  if (opts.text) {
    shape.text = opts.text;
    shape.text.style = {
      fontSize: opts.size ?? 18,
      typeface: FONT,
      color: opts.color ?? C.ink,
      bold: opts.bold ?? false,
      alignment: opts.align ?? "center",
      verticalAlignment: opts.valign ?? "middle",
      autoFit: "shrinkText",
    };
  }
  return shape;
}

function addRule(slide, x, y, w, color = C.rule, height = 2) {
  return slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height },
    fill: color,
    line: { style: "solid", fill: "none", width: 0 },
  });
}

function addRightArrow(slide, x, y, w = 54, h = 28, fill = C.cyanPale) {
  return slide.shapes.add({
    geometry: "rightArrow",
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill: "none", width: 0 },
  });
}

function addDownArrow(slide, x, y, w = 26, h = 48, fill = C.cyanPale) {
  return slide.shapes.add({
    geometry: "downArrow",
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill: "none", width: 0 },
  });
}

function addLine(slide, x, y, w, h, color = C.rule, width = 2, style = "solid") {
  return slide.shapes.add({
    geometry: "line",
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style, fill: color, width },
  });
}

function addHeader(slide, section, title, page, dark = false) {
  const ink = dark ? C.white : C.ink;
  addText(slide, section.toUpperCase(), 56, 34, 420, 22, {
    size: 13, bold: true, color: dark ? C.cyan2 : C.cyan,
  });
  addText(slide, title, 56, 68, 1165, 64, {
    size: 40, bold: true, color: ink,
  });
}

function addFooter(slide, page, dark = false) {
  const line = dark ? "#31405A" : C.rule;
  const text = dark ? "#AEBBD0" : C.muted;
  addRule(slide, 56, 674, 1168, line, 1);
  addText(slide, "DCID · Digital Cognitive Industrial System", 56, 682, 560, 18, {
    size: 10, color: text,
  });
  addText(slide, `${page}/12`, 1150, 682, 74, 18, {
    size: 10, color: text, align: "right",
  });
}

function setNotes(slide, talkTrack, sources) {
  const lines = [talkTrack, "", "[Sources]", ...sources.map((s) => `- ${s}`)];
  slide.speakerNotes.textFrame.setText(lines.join("\n"));
  slide.speakerNotes.setVisible(true);
}

function addLabel(slide, text, x, y, w, fill = C.cyanPale, color = C.navy) {
  return addBox(slide, x, y, w, 30, {
    fill, text, size: 13, color, bold: true, geometry: "roundRect",
  });
}

function addBullet(slide, number, title, body, x, y, w, accent = C.cyan) {
  addText(slide, number, x, y, 46, 34, { size: 22, bold: true, color: accent });
  addText(slide, title, x + 58, y, w - 58, 30, { size: 21, bold: true, color: C.ink });
  addText(slide, body, x + 58, y + 34, w - 58, 58, { size: 16, color: C.body });
}

async function build() {
  await fs.mkdir(RENDER_DIR, { recursive: true });
  const heroBytes = await readImageBytes(HERO);
  const iconBytes = await readImageBytes(ICON);
  const deck = Presentation.create({ slideSize: { width: W, height: H } });

  // 1 — Cover
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    slide.images.add({
      blob: heroBytes,
      contentType: "image/png",
      alt: "Kỹ sư nhà máy sử dụng tablet để đối chiếu bản vẽ và tài liệu kỹ thuật",
      fit: "cover",
      position: { left: 646, top: 0, width: 634, height: 720 },
    });
    slide.shapes.add({
      geometry: "rect",
      position: { left: 592, top: 0, width: 176, height: 720 },
      fill: { color: C.white, transparency: 18 },
      line: { style: "solid", fill: "none", width: 0 },
    });
    slide.images.add({
      blob: iconBytes,
      contentType: "image/png",
      alt: "Biểu tượng ứng dụng DCID",
      fit: "contain",
      position: { left: 56, top: 42, width: 58, height: 58 },
    });
    addText(slide, "PROJECT SEM4 · 2026", 132, 54, 340, 24, {
      size: 14, bold: true, color: C.cyan,
    });
    addText(slide, "DCID", 56, 152, 500, 76, { size: 62, bold: true, color: C.navy });
    addText(slide, "Digital Cognitive\nIndustrial System", 56, 224, 530, 132, {
      size: 42, bold: true, color: C.ink,
    });
    addRule(slide, 56, 382, 132, C.cyan, 5);
    addText(slide, "Đúng tri thức · Đúng phiên bản\nNgay tại hiện trường", 56, 414, 520, 92, {
      size: 25, color: C.body,
    });
    addText(slide, "Trợ lý tri thức kỹ thuật on-premise cho nhà máy", 56, 582, 530, 32, {
      size: 17, bold: true, color: C.navy,
    });
    addText(slide, "Nhóm thực hiện: [Tên nhóm]", 56, 625, 520, 24, {
      size: 15, color: C.muted,
    });
    setNotes(slide,
      "Mở đầu bằng bài toán ra quyết định kỹ thuật tại hiện trường, không giới thiệu hệ thống như một chatbot PDF thông thường.",
      [
        "C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — project positioning and presentation brief",
        "C:\\project\\new\\dcid-web\\dcid-app\\web\\icons\\Icon-512.png — project-owned app icon",
        "OpenAI image generation — custom hero generated for this deck; prompt recorded in source-notes.txt",
      ]);
  }

  // 2 — Team
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "01 · Team", "5 vai trò, một luồng bàn giao rõ ràng", 2);
    addText(slide, "Tên thành viên", 56, 166, 340, 26, { size: 15, bold: true, color: C.muted });
    addText(slide, "Phụ trách chính", 418, 166, 330, 26, { size: 15, bold: true, color: C.muted });
    addText(slide, "Đầu ra chịu trách nhiệm", 775, 166, 449, 26, { size: 15, bold: true, color: C.muted });
    addRule(slide, 56, 198, 1168, C.rule, 2);
    const rows = [
      ["[Tên thành viên 1]", "PM / Documentation", "Scope · báo cáo · slide · điều phối"],
      ["[Tên thành viên 2]", "Backend", "Auth/RBAC · tài liệu/version · audit · API"],
      ["[Tên thành viên 3]", "AI Engineer", "OCR · RAG · guardrail · LLM/VLM"],
      ["[Tên thành viên 4]", "Frontend Flutter", "Web kiosk · Android · citation viewer"],
      ["[Tên thành viên 5]", "Data / QA / DevOps", "Dataset · eval · Docker · CI/CD"],
    ];
    rows.forEach((r, i) => {
      const y = 218 + i * 82;
      if (i % 2 === 0) addBox(slide, 50, y - 8, 1180, 70, { fill: "#FAFBFC", geometry: "rect" });
      addText(slide, String(i + 1).padStart(2, "0"), 64, y + 8, 44, 28, { size: 18, bold: true, color: C.cyan });
      addText(slide, r[0], 122, y + 7, 270, 32, { size: 19, bold: true, color: C.ink });
      addText(slide, r[1], 418, y + 7, 330, 32, { size: 18, bold: true, color: C.navy });
      addText(slide, r[2], 775, y + 7, 430, 42, { size: 17, color: C.body });
    });
    addFooter(slide, 2);
    setNotes(slide,
      "Giới thiệu từng thành viên trong một câu: tên, vai trò và đầu ra. Thay các placeholder bằng tên thật trước khi trình chiếu.",
      ["C:\\project\\new\\dcid-web\\docs\\PLAN-THESIS.md — five-role responsibility model"]);
  }

  // 3 — Core business problem
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "02 · Core business", "Bài toán thật: tìm đúng tài liệu dưới áp lực hiện trường", 3);
    addText(slide,
      "Khi máy dừng, kỹ sư không cần thêm một chatbot — họ cần bằng chứng kỹ thuật đúng, có hiệu lực và được phép xem.",
      56, 150, 1160, 68, { size: 25, bold: true, color: C.navy });
    addRule(slide, 56, 236, 1168, C.cyan, 3);
    addBullet(slide, "01", "Tài liệu phân tán", "SOP, manual và bản vẽ nằm ở nhiều nơi; tìm thủ công làm tăng thời gian xử lý sự cố.", 56, 278, 540);
    addBullet(slide, "02", "Nhiều phiên bản", "Dùng nhầm bản cũ có thể tạo thao tác sai, ảnh hưởng an toàn, chất lượng và tuân thủ.", 56, 408, 540);
    addBullet(slide, "03", "Không thể đưa lên cloud", "Bản vẽ và quy trình nội bộ chứa bí mật công nghệ, cần giữ trong mạng nhà máy.", 650, 278, 554);
    addBullet(slide, "04", "AI có thể suy đoán", "Một con số sai về điện áp, áp suất hoặc dung sai có thể gây hậu quả vận hành nghiêm trọng.", 650, 408, 554);
    addBox(slide, 650, 548, 554, 78, {
      fill: C.navy, text: "Mục tiêu kinh doanh: giảm thời gian tìm tri thức\nvà giảm rủi ro quyết định sai", size: 21, bold: true, color: C.white,
    });
    addFooter(slide, 3);
    setNotes(slide,
      "Nhấn mạnh tác động vận hành: downtime, an toàn, chất lượng và tuân thủ. Không hứa thay thế chuyên gia; DCID hỗ trợ quyết định có căn cứ.",
      ["C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — pain points", "C:\\project\\new\\dcid-web\\README.md — official document governance scope"]);
  }

  // 4 — Product response and users
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "02 · Core business", "DCID trả lời từ tài liệu có kiểm soát", 4);
    addText(slide, "Ba cam kết sản phẩm", 56, 160, 470, 30, { size: 22, bold: true, color: C.navy });
    const promises = [
      ["PRIVATE", "Chạy on-premise; dữ liệu không rời hệ thống nội bộ."],
      ["GROUNDED", "Câu trả lời gắn trang, đoạn trích và vị trí nguồn."],
      ["GOVERNED", "RBAC, phiên bản ACTIVE, audit và feedback."],
    ];
    promises.forEach((p, i) => {
      const y = 216 + i * 118;
      addLabel(slide, p[0], 56, y, 132, i === 0 ? C.cyanPale : C.panel);
      addText(slide, p[1], 210, y - 2, 350, 64, { size: 18, color: C.body });
      addRule(slide, 56, y + 82, 504, C.rule, 1);
    });
    addBox(slide, 616, 158, 608, 442, { fill: C.navy, geometry: "roundRect" });
    addText(slide, "Người dùng và công việc chính", 656, 194, 500, 34, { size: 24, bold: true, color: C.white });
    const users = [
      ["OPERATOR", "Tra SOP vận hành và an toàn"],
      ["ENGINEER", "Tra bản vẽ, lỗi máy, thông số và hướng dẫn"],
      ["QA_ADMIN", "Upload, quản lý phiên bản và phát hành"],
      ["ADMIN", "Quản trị người dùng, audit và hệ thống"],
    ];
    users.forEach((u, i) => {
      const y = 260 + i * 72;
      addText(slide, u[0], 656, y, 150, 26, { size: 14, bold: true, color: C.cyan2 });
      addText(slide, u[1], 830, y - 2, 330, 40, { size: 17, color: C.white });
    });
    addText(slide, "Kênh phụ trợ: Guest / Ask cho dùng thử tài liệu tạm thời", 656, 552, 500, 30, { size: 15, color: "#C8D4E7" });
    addFooter(slide, 4);
    setNotes(slide,
      "Core business là kho tri thức chính thức có quản trị. Guest / Ask là kênh dùng thử, không phải trọng tâm giá trị.",
      ["C:\\project\\new\\dcid-web\\README.md — dual-plane and role model", "C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — private/grounded/governed proposition"]);
  }

  // 5 — Architecture
  {
    const slide = deck.slides.add();
    slide.background.fill = C.navy;
    addHeader(slide, "03 · Architecture", "Dual-plane tách quản trị nghiệp vụ khỏi xử lý AI", 5, true);
    // Connector-like arrows first so nodes sit above them.
    addDownArrow(slide, 615, 188, 32, 54, "#2B6481");
    addRightArrow(slide, 552, 341, 66, 36, "#2B6481");
    addDownArrow(slide, 310, 508, 30, 48, "#2B6481");
    addDownArrow(slide, 930, 508, 30, 48, "#2B6481");
    addBox(slide, 410, 146, 460, 74, { fill: C.white, text: "FLUTTER CLIENTS\nWeb kiosk · Admin · Android", size: 20, bold: true, color: C.navy });
    addBox(slide, 56, 276, 496, 230, { fill: "#1A2D47", line: "#355271", lineWidth: 1 });
    addText(slide, "GOVERNANCE PLANE", 88, 306, 410, 30, { size: 22, bold: true, color: C.cyan2 });
    addText(slide, "Spring Boot 3.3 · Java 21", 88, 344, 410, 28, { size: 18, bold: true, color: C.white });
    addText(slide, "Auth / RBAC\nDocument & version lifecycle\nGuest session & TTL\nAudit · API · file proxy", 88, 388, 410, 104, { size: 17, color: "#D5DEEB" });
    addBox(slide, 618, 276, 606, 230, { fill: "#173451", line: "#3A6E90", lineWidth: 1 });
    addText(slide, "AI INTELLIGENCE PLANE", 650, 306, 510, 30, { size: 22, bold: true, color: C.cyan2 });
    addText(slide, "FastAPI · Celery · Local LLM/VLM", 650, 344, 510, 28, { size: 18, bold: true, color: C.white });
    addText(slide, "OCR / vision\nChunk + embedding\nHybrid retrieval\nGuardrail + grounded answer", 650, 388, 510, 104, { size: 17, color: "#D5DEEB" });
    const stores = [
      ["PostgreSQL", "nghiệp vụ"], ["MinIO", "PDF / ảnh"], ["Qdrant", "vector"], ["Redis", "queue / cache"],
    ];
    stores.forEach((s, i) => {
      const x = 56 + i * 292;
      addBox(slide, x, 566, 254, 76, { fill: i === 0 ? C.white : "#EAF3FA", text: `${s[0]}\n${s[1]}`, size: 18, bold: true, color: C.navy });
    });
    addFooter(slide, 5, true);
    setNotes(slide,
      "Giải thích ranh giới trách nhiệm: backend là single writer của PostgreSQL; AI chỉ nhận contract nội bộ và xử lý tri thức. Đây là quyết định quan trọng nhất của kiến trúc.",
      ["C:\\project\\new\\dcid-web\\docs\\ARCHITECTURE.md — dual-plane architecture", "C:\\project\\new\\dcid-web\\docs\\API-CONTRACT.md — backend/AI contract", "C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — architecture summary"]);
  }

  // 6 — Technology stack
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "04 · Technology", "Mỗi công nghệ giữ một trách nhiệm rõ ràng", 6);
    const rows = [
      ["Client", "Flutter · Riverpod · Dio · SSE/STOMP", "Một codebase cho Web kiosk và Android"],
      ["Governance", "Java 21 · Spring Boot · Security · JPA", "RBAC, version, audit, API và single-writer"],
      ["AI", "Python · FastAPI · Celery · PyMuPDF · PaddleOCR", "OCR, RAG, vision và xử lý nền"],
      ["Retrieval", "multilingual-e5 · BM25 · Qdrant", "Bắt cả ý nghĩa lẫn mã máy / mã lỗi chính xác"],
      ["Storage", "PostgreSQL · MinIO · Redis", "Tách metadata, file nhị phân và hàng đợi"],
      ["Ops", "Docker Compose · Nginx · GitHub Actions", "Đóng gói, triển khai nội bộ và CI/CD"],
    ];
    addText(slide, "LỚP", 56, 156, 160, 26, { size: 13, bold: true, color: C.muted });
    addText(slide, "CÔNG NGHỆ", 246, 156, 430, 26, { size: 13, bold: true, color: C.muted });
    addText(slide, "VÌ SAO DÙNG", 712, 156, 512, 26, { size: 13, bold: true, color: C.muted });
    addRule(slide, 56, 190, 1168, C.rule, 2);
    rows.forEach((r, i) => {
      const y = 208 + i * 70;
      if (i === 2 || i === 3) addBox(slide, 48, y - 6, 1184, 58, { fill: C.cyanPale, geometry: "rect" });
      addText(slide, r[0], 56, y, 150, 30, { size: 17, bold: true, color: i === 2 ? C.cyan : C.navy });
      addText(slide, r[1], 246, y, 430, 42, { size: 16, bold: true, color: C.ink });
      addText(slide, r[2], 712, y, 500, 42, { size: 16, color: C.body });
    });
    addFooter(slide, 6);
    setNotes(slide,
      "Không đọc danh sách công nghệ. Nêu tiêu chí chọn: phân tách trách nhiệm, chạy on-premise, chịu lỗi và đủ nhẹ cho hạ tầng edge.",
      ["C:\\project\\new\\dcid-web\\README.md — repository stack", "C:\\project\\new\\dcid-web\\docker-compose.yml — deployed services", "C:\\project\\new\\dcid-web\\docs\\ARCHITECTURE.md — technology decisions"]);
  }

  // 7 — Use cases
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "05 · Use cases", "Hai phân hệ, hai mức tin cậy và vòng đời dữ liệu khác nhau", 7);
    addBox(slide, 56, 160, 552, 430, { fill: C.navy });
    addText(slide, "A · KHO TÀI LIỆU CHÍNH THỨC", 88, 194, 460, 28, { size: 17, bold: true, color: C.cyan2 });
    addText(slide, "Dùng hằng ngày trong nhà máy", 88, 240, 460, 42, { size: 27, bold: true, color: C.white });
    addText(slide, "• Đăng nhập JWT và lọc theo RBAC\n• Upload SOP / manual / bản vẽ\n• Quản lý version và trạng thái ACTIVE\n• Hỏi đáp RAG + trích dẫn\n• Ghi query log và audit", 88, 316, 450, 190, { size: 18, color: "#E3EAF4" });
    addLabel(slide, "CORE BUSINESS", 88, 532, 162, "#D0F1FC", C.navy);
    addBox(slide, 648, 160, 576, 430, { fill: C.panel, line: C.rule, lineWidth: 1 });
    addText(slide, "B · GUEST / ASK", 682, 194, 470, 28, { size: 17, bold: true, color: C.cyan });
    addText(slide, "Trải nghiệm nhanh với tài liệu tạm", 682, 240, 470, 42, { size: 27, bold: true, color: C.navy });
    addText(slide, "• Không cần tài khoản\n• Session token ngẫu nhiên\n• File và vector cô lập theo session\n• TTL 2 giờ; cleanup định kỳ\n• Không trộn vào kho chính thức", 682, 316, 470, 190, { size: 18, color: C.body });
    addLabel(slide, "KÊNH DÙNG THỬ", 682, 532, 162, C.white, C.navy);
    addFooter(slide, 7);
    setNotes(slide,
      "Use case A chứng minh governance và giá trị vận hành. Use case B chứng minh cô lập dữ liệu và trải nghiệm không cần tài khoản.",
      ["C:\\project\\new\\dcid-web\\README.md — official and guest workflows", "C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — dual-system workflows"]);
  }

  // 8 — Ingestion flow
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "06 · Main flow", "Tài liệu được biến thành tri thức có vị trí nguồn", 8);
    const xs = [56, 272, 488, 704, 920];
    for (let i = 0; i < 4; i++) addRightArrow(slide, xs[i] + 166, 300, 48, 30, C.cyanPale);
    const steps = [
      ["01", "UPLOAD", "PDF vào MinIO\nVersion = PROCESSING"],
      ["02", "EXTRACT", "Native text hoặc\nPaddleOCR 200 DPI"],
      ["03", "CHUNK", "Giữ bảng + Bbox\n+ snippet nguồn"],
      ["04", "EMBED", "multilingual-e5\nvector 384 chiều"],
      ["05", "INDEX", "Qdrant + payload\ncallback READY"],
    ];
    steps.forEach((s, i) => {
      const x = xs[i];
      addText(slide, s[0], x, 206, 52, 26, { size: 16, bold: true, color: C.cyan });
      addBox(slide, x, 248, 166, 162, { fill: i === 1 ? C.navy : C.panel, line: i === 1 ? C.navy : C.rule, lineWidth: 1 });
      addText(slide, s[1], x + 18, 270, 130, 28, { size: 18, bold: true, color: i === 1 ? C.cyan2 : C.navy, align: "center" });
      addText(slide, s[2], x + 16, 320, 134, 68, { size: 15, color: i === 1 ? C.white : C.body, align: "center", valign: "middle" });
    });
    addBox(slide, 56, 470, 1030, 112, { fill: C.cyanPale, geometry: "rect" });
    addText(slide, "Điểm khác biệt", 80, 492, 180, 28, { size: 18, bold: true, color: C.cyan });
    addText(slide, "Mỗi chunk giữ page_no + bbox + snippet, nên câu trả lời có thể mở đúng trang và khoanh đúng vùng bằng chứng.", 276, 488, 780, 58, { size: 20, bold: true, color: C.navy });
    addBox(slide, 1108, 470, 116, 112, { fill: C.navy, text: "ASYNC\nCelery + Redis", size: 16, bold: true, color: C.white });
    addFooter(slide, 8);
    setNotes(slide,
      "Đi theo 5 bước. Nhấn mạnh ingestion chạy nền để upload không phải chờ OCR/embedding, và metadata không gian được giữ xuyên suốt.",
      ["C:\\Users\\HACOM\\Downloads\\report_presentation (1).md — ingestion sequence", "C:\\project\\new\\dcid-web\\dcid-ai\\app\\pipeline\\ocr.py — hybrid extraction", "C:\\project\\new\\dcid-web\\docs\\API-CONTRACT.md — ingest callback"]);
  }

  // 9 — Query flow and guardrail
  {
    const slide = deck.slides.add();
    slide.background.fill = C.navy;
    addHeader(slide, "06 · Main flow", "Câu hỏi chỉ đi tới LLM sau khi qua quyền và bằng chứng", 9, true);
    const x = [58, 252, 446, 640, 834, 1028];
    for (let i = 0; i < 5; i++) addRightArrow(slide, x[i] + 144, 276, 44, 28, "#2B6481");
    const nodes = [
      ["QUESTION", "Câu hỏi +\nmachine code"],
      ["POLICY", "RBAC + chỉ\nversion ACTIVE"],
      ["RETRIEVE", "Dense + BM25\nTop-K evidence"],
      ["GUARD", "Score gate +\nkiểm số liệu"],
      ["GENERATE", "Local LLM/VLM\ntrả lời theo context"],
      ["PROVE", "Citation + audit\nhoặc từ chối"],
    ];
    nodes.forEach((n, i) => {
      const fill = i === 3 ? "#7A2E2A" : (i === 5 ? C.white : "#1B314E");
      const titleColor = i === 5 ? C.cyan : C.cyan2;
      const bodyColor = i === 5 ? C.navy : C.white;
      addBox(slide, x[i], 224, 144, 154, { fill, line: i === 5 ? C.white : "#385673", lineWidth: 1 });
      addText(slide, n[0], x[i] + 12, 246, 120, 24, { size: 14, bold: true, color: titleColor, align: "center" });
      addText(slide, n[1], x[i] + 12, 292, 120, 60, { size: 15, color: bodyColor, bold: i === 5, align: "center", valign: "middle" });
    });
    addBox(slide, 58, 438, 552, 126, { fill: "#213853" });
    addText(slide, "Khi bằng chứng đủ", 86, 462, 230, 26, { size: 18, bold: true, color: C.greenPale });
    addText(slide, "Trả lời + confidence + citations\n→ người dùng mở trang nguồn để đối chiếu", 86, 500, 480, 52, { size: 17, color: C.white });
    addBox(slide, 670, 438, 554, 126, { fill: "#4A2528" });
    addText(slide, "Khi bằng chứng yếu", 698, 462, 230, 26, { size: 18, bold: true, color: "#FFC8C4" });
    addText(slide, "Khóa hoặc gắn nhãn câu trả lời tham khảo\n→ yêu cầu kỹ sư kiểm tra bản vẽ gốc", 698, 500, 480, 52, { size: 17, color: C.white });
    addText(slide, "Thông điệp an toàn: giảm câu trả lời thiếu căn cứ — không tuyên bố AI không bao giờ sai.", 58, 612, 1166, 32, { size: 18, bold: true, color: C.cyan2, align: "center" });
    addFooter(slide, 9, true);
    setNotes(slide,
      "Đây là slide quan trọng nhất. Trình bày theo thứ tự: policy trước retrieval, guardrail trước generation, và luôn có bằng chứng hoặc từ chối. Không dùng tuyên bố tuyệt đối '0% hallucination'.",
      ["C:\\project\\new\\dcid-web\\dcid-backend\\src\\main\\java\\vn\\dcid\\service\\QueryService.java — allowed ACTIVE versions by role", "C:\\project\\new\\dcid-web\\dcid-ai\\app\\services\\query_service.py — RAG orchestration", "C:\\project\\new\\dcid-web\\dcid-ai\\app\\pipeline\\guardrails.py — threshold and numeric rules"]);
  }

  // 10 — Database design
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "07 · Database design", "PostgreSQL giữ nghiệp vụ; file và vector tách riêng", 10);
    // Relationship lines first.
    addLine(slide, 222, 280, 96, 0, C.rule, 2);
    addLine(slide, 510, 280, 94, 0, C.rule, 2);
    addLine(slide, 414, 322, 0, 86, C.rule, 2);
    addLine(slide, 700, 322, 0, 86, C.rule, 2);
    addLine(slide, 892, 280, 94, 0, C.rule, 2);
    addLine(slide, 1082, 322, 0, 86, C.rule, 2);
    const entities = [
      [56, 228, 166, 94, "USERS", "role · status"],
      [318, 228, 192, 94, "DOCUMENTS", "machine_code · min_role"],
      [604, 228, 192, 94, "VERSIONS", "status · version_no"],
      [986, 228, 190, 94, "QUERY_LOGS", "confidence · locked"],
      [318, 408, 192, 94, "AUDIT_LOGS", "actor · action · detail"],
      [604, 408, 192, 94, "PAGES", "page_no · image_key"],
      [986, 408, 190, 94, "GUEST SESSIONS", "token_hash · expires_at"],
    ];
    entities.forEach((e, i) => {
      const primary = [1, 2].includes(i);
      addBox(slide, e[0], e[1], e[2], e[3], { fill: primary ? C.navy : C.panel, line: primary ? C.navy : C.rule, lineWidth: 1 });
      addText(slide, e[4], e[0] + 14, e[1] + 18, e[2] - 28, 24, { size: 16, bold: true, color: primary ? C.cyan2 : C.navy, align: "center" });
      addText(slide, e[5], e[0] + 12, e[1] + 52, e[2] - 24, 26, { size: 13, color: primary ? C.white : C.body, align: "center" });
    });
    addText(slide, "1 → N", 236, 258, 64, 22, { size: 12, bold: true, color: C.muted, align: "center" });
    addText(slide, "1 → N", 522, 258, 64, 22, { size: 12, bold: true, color: C.muted, align: "center" });
    addText(slide, "N → 1", 904, 258, 64, 22, { size: 12, bold: true, color: C.muted, align: "center" });
    addText(slide, "Ngoài PostgreSQL", 56, 558, 240, 26, { size: 18, bold: true, color: C.navy });
    addLabel(slide, "MINIO · PDF / ảnh", 298, 554, 230, C.cyanPale, C.navy);
    addLabel(slide, "QDRANT · vector + bbox", 548, 554, 270, C.cyanPale, C.navy);
    addLabel(slide, "REDIS · queue / cache", 838, 554, 250, C.cyanPale, C.navy);
    addText(slide, "Nguyên tắc: chỉ Backend ghi PostgreSQL", 56, 620, 1168, 28, { size: 19, bold: true, color: C.cyan, align: "center" });
    addFooter(slide, 10);
    setNotes(slide,
      "Không đọc toàn bộ schema. Nêu ba quan hệ cốt lõi: document–version, version–page, query–matched version; sau đó giải thích polyglot persistence.",
      ["C:\\project\\new\\dcid-web\\docs\\ERD.md — relational schema and storage separation", "C:\\project\\new\\dcid-web\\dcid-backend\\src\\main\\resources\\db\\migration — implemented schema"]);
  }

  // 11 — Status
  {
    const slide = deck.slides.add();
    slide.background.fill = C.bg;
    addHeader(slide, "08 · Delivery status", "Lõi end-to-end đã chạy; đánh giá khoa học còn thiếu", 11);
    addBox(slide, 56, 158, 552, 428, { fill: C.greenPale, line: "#A6DCCB", lineWidth: 1 });
    addText(slide, "ĐÃ LÀM ĐƯỢC", 88, 190, 470, 28, { size: 18, bold: true, color: C.green });
    addText(slide,
      "✓ Auth/RBAC, tài liệu/version, audit\n✓ Upload → OCR → chunk → embed → index\n✓ RAG thật + local LLM/VLM + citations\n✓ Flutter Web/Android + SSE + Snap & Ask\n✓ Docker, Nginx, CI/CD và deploy nội bộ",
      88, 244, 456, 206, { size: 19, color: C.ink });
    addBox(slide, 88, 476, 456, 78, { fill: C.white, text: "OCR spike nhỏ: EN 100% · VI 89,6%\n(8 câu; chưa phải benchmark cuối)", size: 17, bold: true, color: C.navy, line: "#B7D9CC", lineWidth: 1 });
    addBox(slide, 648, 158, 576, 428, { fill: C.amberPale, line: "#F1C48B", lineWidth: 1 });
    addText(slide, "CHƯA HOÀN THIỆN", 682, 190, 480, 28, { size: 18, bold: true, color: C.amber });
    addText(slide,
      "○ Dataset VI/EN và degradation set\n○ Eval set + harness đo Recall / faithfulness\n○ OCR preprocessing để giảm lỗi dấu tiếng Việt\n○ Upload progress thời gian thực hoàn chỉnh\n○ Pilot/UAT trên một dây chuyền thực tế",
      682, 244, 474, 206, { size: 19, color: C.ink });
    addBox(slide, 682, 476, 474, 78, { fill: C.white, text: "Không công bố Recall 95,4% hay 0% hallucination\nkhi chưa có eval set tái lập", size: 17, bold: true, color: C.red, line: "#F0B6B2", lineWidth: 1 });
    addFooter(slide, 11);
    setNotes(slide,
      "Tách rõ implemented và measured. Đây là cách trả lời an toàn nếu hội đồng hỏi 'số liệu lấy ở đâu'. Chỉ dùng baseline có mô tả mẫu đo.",
      ["C:\\project\\new\\dcid-web\\docs\\ROADMAP.md — verified implementation status updated 2026-08-06", "C:\\project\\new\\dcid-web\\docs\\PLAN-THESIS.md — OCR spike and pending evaluation work"]);
  }

  // 12 — Lessons and close
  {
    const slide = deck.slides.add();
    slide.background.fill = C.navy;
    addHeader(slide, "09 · Lessons", "Ba bài học quyết định chất lượng của dự án", 12, true);
    const cards = [
      ["01", "Contract trước, code sau", "Chốt ranh giới Backend ↔ AI giúp thay OCR, vector DB hoặc LLM mà không phá nghiệp vụ."],
      ["02", "Đo thật thay vì tuyên bố", "E2E và benchmark tái lập quan trọng hơn KPI đẹp nhưng không có dataset và ground truth."],
      ["03", "AI an toàn là một hệ thống", "RBAC, version, retrieval, guardrail, citation và audit cùng tạo niềm tin — không phải riêng mô hình."],
    ];
    cards.forEach((c, i) => {
      const x = 56 + i * 400;
      addBox(slide, x, 174, 360, 300, { fill: i === 1 ? C.white : "#1C304B", line: i === 1 ? C.white : "#385673", lineWidth: 1 });
      addText(slide, c[0], x + 28, 204, 58, 32, { size: 22, bold: true, color: C.cyan2 });
      addText(slide, c[1], x + 28, 258, 304, 62, { size: 24, bold: true, color: i === 1 ? C.navy : C.white });
      addText(slide, c[2], x + 28, 346, 304, 94, { size: 17, color: i === 1 ? C.body : "#D4DEEC" });
    });
    addText(slide, "DCID đã chứng minh một kiến trúc khả thi cho trợ lý tri thức công nghiệp on-premise.", 80, 524, 1120, 44, { size: 25, bold: true, color: C.white, align: "center" });
    addText(slide, "Bước tiếp theo: hoàn thiện eval → pilot một dây chuyền → đo tác động vận hành", 80, 584, 1120, 36, { size: 19, color: C.cyan2, align: "center" });
    addLabel(slide, "Q&A / LIVE DEMO", 510, 632, 260, C.cyan2, C.navy);
    addFooter(slide, 12, true);
    setNotes(slide,
      "Kết thúc bằng kết luận có thể bảo vệ: kiến trúc đã chạy, giá trị đã rõ, nhưng cần đánh giá và pilot trước khi khẳng định hiệu quả sản xuất. Sau đó chuyển sang live demo.",
      ["C:\\project\\new\\dcid-web\\docs\\ROADMAP.md — implementation lessons and next milestones", "C:\\project\\new\\dcid-web\\docs\\SETUP.md — E2E issues and fixes", "C:\\project\\new\\dcid-web\\docs\\PLAN-THESIS.md — evaluation plan"]);
  }

  // Export render previews and final PPTX.
  for (const [index, slide] of deck.slides.items.entries()) {
    const stem = `slide-${String(index + 1).padStart(2, "0")}`;
    const png = await deck.export({ slide, format: "png", scale: 1 });
    await fs.writeFile(path.join(RENDER_DIR, `${stem}.png`), new Uint8Array(await png.arrayBuffer()));
    const layout = await slide.export({ format: "layout" });
    await fs.writeFile(path.join(RENDER_DIR, `${stem}.layout.json`), await layout.text());
  }
  const montage = await deck.export({ format: "webp", montage: true, scale: 1 });
  await fs.writeFile(path.join(RENDER_DIR, "deck-montage.webp"), new Uint8Array(await montage.arrayBuffer()));
  const pptx = await PresentationFile.exportPptx(deck);
  await pptx.save(FINAL_PPTX);
  console.log(`Created ${FINAL_PPTX}`);
  console.log(`Slides: ${deck.slides.items.length}`);
}

build().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
