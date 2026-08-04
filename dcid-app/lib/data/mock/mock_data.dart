import '../models/answer_result.dart';
import '../models/document_detail.dart';
import '../models/document_summary.dart';
import '../models/page_info.dart';

/// Hardcoded mock data mirroring API-CONTRACT.md structures.
/// Used by [MockDocsRepository] for Week 1 development.
class MockData {
  const MockData._();

  // ── Documents ──────────────────────────────────────────────────────────

  static const documents = <DocumentSummary>[
    DocumentSummary(
      id: 'doc-001',
      title: 'SOP Vận hành máy CNC XK-500',
      machineCode: 'CNC-01',
      category: 'SOP',
      minRole: 'OPERATOR',
      description: 'Quy trình vận hành chuẩn máy CNC XK-500, bao gồm khởi động, chạy thử và tắt máy an toàn.',
      createdAt: '2026-06-15T08:00:00Z',
      updatedAt: '2026-07-10T14:30:00Z',
    ),
    DocumentSummary(
      id: 'doc-002',
      title: 'Bản vẽ mạch điện CNC XK-500',
      machineCode: 'CNC-01',
      category: 'CIRCUIT',
      minRole: 'ENGINEER',
      description: 'Sơ đồ mạch điện chi tiết bao gồm servo driver, PLC I/O, và hệ thống bảo vệ.',
      createdAt: '2026-06-01T10:00:00Z',
      updatedAt: '2026-07-08T09:15:00Z',
    ),
    DocumentSummary(
      id: 'doc-003',
      title: 'Hướng dẫn an toàn xưởng CNC',
      machineCode: null,
      category: 'SAFETY',
      minRole: 'OPERATOR',
      description: 'Quy tắc an toàn chung khi làm việc trong xưởng CNC.',
      createdAt: '2026-05-20T06:00:00Z',
      updatedAt: '2026-06-25T11:00:00Z',
    ),
    DocumentSummary(
      id: 'doc-004',
      title: 'Bản vẽ kỹ thuật Servo Driver MR-J4',
      machineCode: 'CNC-01',
      category: 'DRAWING',
      minRole: 'ENGINEER',
      description: 'Bản vẽ kỹ thuật chi tiết cho Servo Driver Mitsubishi MR-J4 dùng trên trục X, Y, Z.',
      createdAt: '2026-04-10T07:30:00Z',
      updatedAt: '2026-07-01T16:45:00Z',
    ),
    DocumentSummary(
      id: 'doc-005',
      title: 'Nhật ký bảo trì CNC XK-500 — Tháng 6/2026',
      machineCode: 'CNC-01',
      category: 'MAINTENANCE_LOG',
      minRole: 'ENGINEER',
      description: 'Ghi chép chi tiết các lần bảo trì định kỳ và sự cố trong tháng 6/2026.',
      createdAt: '2026-07-01T08:00:00Z',
      updatedAt: '2026-07-15T12:00:00Z',
    ),
    DocumentSummary(
      id: 'doc-006',
      title: 'SOP Thay dao CNC',
      machineCode: 'CNC-01',
      category: 'SOP',
      minRole: 'OPERATOR',
      description: 'Quy trình chuẩn thay dao CNC an toàn, bao gồm kiểm tra trước và sau.',
      createdAt: '2026-06-20T09:00:00Z',
      updatedAt: '2026-07-12T10:30:00Z',
    ),
  ];

  // ── Document Details ───────────────────────────────────────────────────

  static DocumentDetail detailForDoc(String docId) {
    final doc = documents.firstWhere(
      (d) => d.id == docId,
      orElse: () => documents.first,
    );
    return DocumentDetail(
      document: doc,
      versions: [
        VersionSummary(
          id: '$docId-v2',
          versionNo: 2,
          status: 'ACTIVE',
          lang: 'vi,en',
          pageCount: 12,
          originalFilename: '${doc.title.replaceAll(' ', '_')}.pdf',
          fileSize: 2457600, // ~2.4 MB
          createdAt: doc.updatedAt,
          ingestedAt: doc.updatedAt,
        ),
        VersionSummary(
          id: '$docId-v1',
          versionNo: 1,
          status: 'SUPERSEDED',
          lang: 'vi',
          pageCount: 10,
          originalFilename: '${doc.title.replaceAll(' ', '_')}_v1.pdf',
          fileSize: 1843200, // ~1.8 MB
          createdAt: doc.createdAt,
          ingestedAt: doc.createdAt,
        ),
      ],
    );
  }

  // ── Pages (for viewer) ─────────────────────────────────────────────────

  static List<PageInfo> pagesForVersion(String versionId) => [
        PageInfo(
          pageNo: 1,
          imageKey: 'documents/mock/v1/pages/1.png',
          width: 1654,
          height: 2339,
        ),
        PageInfo(
          pageNo: 2,
          imageKey: 'documents/mock/v1/pages/2.png',
          width: 1654,
          height: 2339,
        ),
        PageInfo(
          pageNo: 3,
          imageKey: 'documents/mock/v1/pages/3.png',
          width: 1654,
          height: 2339,
        ),
      ];

  // ── Mock bounding boxes (normalized 0.0–1.0) ──────────────────────────

  static List<BoundingBox> bboxesForPage(int pageNo) {
    if (pageNo == 1) {
      return const [
        BoundingBox(
          x: 0.12,
          y: 0.25,
          width: 0.35,
          height: 0.04,
          label: 'Điện áp: 200–230 VAC',
        ),
        BoundingBox(
          x: 0.10,
          y: 0.42,
          width: 0.50,
          height: 0.03,
          label: 'Dòng định mức: 3.5A',
        ),
      ];
    }
    if (pageNo == 2) {
      return const [
        BoundingBox(
          x: 0.20,
          y: 0.15,
          width: 0.60,
          height: 0.06,
          label: 'Bảng thông số servo trục X',
        ),
      ];
    }
    return const [];
  }

  // ── Answer Results ─────────────────────────────────────────────────────

  static AnswerResult answerNormal = const AnswerResult(
    answer:
        'Điện áp cấp cho servo trục X là 200–230 VAC (1 pha) hoặc 380–480 VAC '
        '(3 pha) tùy model driver. Theo tài liệu SOP máy CNC XK-500 trang 12, '
        'bảng thông số ghi rõ: "Input voltage: 200–230 VAC ±10%, 50/60 Hz". '
        'Cần đảm bảo nguồn cấp ổn định, có UPS/stabilizer nếu điện áp lưới dao động.',
    confidence: 0.83,
    locked: false,
    numericRule: true,
    citations: [
      Citation(
        versionId: 'doc-001-v2',
        pageNo: 12,
        bboxKey: 'documents/doc-001/v2/crops/p12-1.png',
        snippet: 'Input voltage: 200–230 VAC ±10%, 50/60 Hz',
      ),
      Citation(
        versionId: 'doc-004-v2',
        pageNo: 3,
        bboxKey: 'documents/doc-004/v2/crops/p3-1.png',
        snippet: 'Servo MR-J4: rated supply 200V class',
      ),
    ],
  );

  static AnswerResult answerLocked = const AnswerResult(
    answer:
        'Không đủ dữ liệu chắc chắn. Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm.',
    confidence: 0.35,
    locked: true,
    numericRule: false,
    citations: [
      Citation(
        versionId: 'doc-002-v2',
        pageNo: 5,
        bboxKey: null,
        snippet: null,
      ),
    ],
  );
}
