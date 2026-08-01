import 'dart:typed_data';

import '../docs_repository_interface.dart';
import '../models/answer_result.dart';
import '../models/document_detail.dart';
import '../models/document_summary.dart';
import 'mock_data.dart';

/// Mock implementation of [IDocsRepository] for Week 1 development.
///
/// Returns hardcoded data after a small artificial delay to simulate
/// network latency. Swap with the real [DocsRepository] by removing
/// the Riverpod provider override in `main.dart`.
class MockDocsRepository implements IDocsRepository {
  @override
  Future<AnswerResult> ask(
    String question, {
    bool reasoningMode = false,
    List<String>? selectedVersionIds,
    List<Map<String, String>>? history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // Return a guardrail-locked answer if question contains "test-locked"
    // so the red banner can be manually tested.
    if (question.toLowerCase().contains('test-locked')) {
      return MockData.answerLocked;
    }
    return MockData.answerNormal;
  }

  @override
  Future<AnswerResult> askWithImage(
    String question,
    Uint8List imageBytes,
    String fileName, {
    String? machineCode,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final machineTag =
        machineCode != null ? ' (Mã máy: $machineCode)' : '';
    final sizeKb = (imageBytes.length / 1024).toStringAsFixed(0);

    // Rich OCR-style mock response mimicking DeepSeek-R1 reasoning output.
    return AnswerResult(
      answer: '''**Phân tích hình ảnh thiết bị**$machineTag

📷 Tệp: `$fileName` · Kích thước: ${sizeKb}KB

---

**Kết quả nhận dạng OCR:**
Từ hình ảnh bạn cung cấp, hệ thống nhận diện được linh kiện **Servo Driver Mitsubishi MR-J4-10A** gắn trên trục X của máy CNC XK-500.

**Các thông số kỹ thuật trích xuất được:**
| Thông số | Giá trị |
|---|---|
| Điện áp vào | 200–230 VAC ±10%, 50/60 Hz |
| Dòng định mức | 3.5 A |
| Công suất định mức | 750 W |
| Nhiệt độ vận hành | 0°C – 55°C |
| Khối lượng | 0.9 kg |

**Phân tích trả lời cho câu hỏi:** "$question"

**Bước 1 — Xác định ngữ cảnh:**
Dựa trên nhãn trên thiết bị và cấu trúc vỏ máy, đây là Servo Amplifier dòng MR-J4 của Mitsubishi Electric, được dùng để điều khiển động cơ servo trục X trên máy CNC XK-500.

**Bước 2 — Tra cứu tài liệu kỹ thuật:**
Theo tài liệu "Bản vẽ kỹ thuật Servo Driver MR-J4" (trang 3) và SOP vận hành máy CNC XK-500 (trang 12): nguồn cấp phải đảm bảo điện áp ổn định trong dải 200–230 VAC ±10%. Nếu điện áp lưới dao động vượt ngưỡng này, cần lắp thêm bộ ổn áp (voltage stabilizer) hoặc UPS.

**Bước 3 — Kết luận:**
Thiết bị đang ở trạng thái hoạt động bình thường (đèn RDY xanh). Không phát hiện dấu hiệu cháy nổ, biến dạng nhiệt, hoặc lỏng kết nối cáp. Khuyến nghị kiểm tra điện trở cách điện định kỳ 6 tháng/lần theo quy trình bảo trì.''',
      confidence: 0.91,
      locked: false,
      numericRule: true,
      reasoningMode: true,
      citations: [
        MockData.answerNormal.citations.first,
        MockData.answerNormal.citations.last,
      ],
    );
  }

  @override
  Future<List<DocumentSummary>> listDocuments() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockData.documents;
  }

  @override
  Future<DocumentDetail> getDocumentDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.detailForDoc(id);
  }

  @override
  Future<DocumentDetail> uploadDocument({
    required String title,
    required String category,
    String? machineCode,
    String? minRole,
    String? description,
    String? lang,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    // Simulate upload + AI processing time.
    await Future<void>.delayed(const Duration(seconds: 2));
    // Return a new document in PROCESSING state.
    final newDoc = DocumentSummary(
      id: 'doc-new-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      machineCode: machineCode,
      category: category,
      minRole: minRole,
      description: description,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    return DocumentDetail(
      document: newDoc,
      versions: [
        VersionSummary(
          id: '${newDoc.id}-v1',
          versionNo: 1,
          status: 'PROCESSING',
          lang: lang,
          originalFilename: fileName,
          fileSize: fileBytes.length,
          createdAt: newDoc.createdAt,
        ),
      ],
    );
  }

  @override
  Future<void> deleteDocument(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

