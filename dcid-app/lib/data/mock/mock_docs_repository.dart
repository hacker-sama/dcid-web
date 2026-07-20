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
  Future<AnswerResult> ask(String question) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // Return a guardrail-locked answer if question contains "test-locked"
    // so the red banner can be manually tested.
    if (question.toLowerCase().contains('test-locked')) {
      return MockData.answerLocked;
    }
    return MockData.answerNormal;
  }

  @override
  Future<AnswerResult> askWithImage(String question, Uint8List imageBytes, String fileName) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // Trả về một câu trả lời mock đặc thù cho Snap & Ask
    return AnswerResult(
      answer: 'Dựa trên hình ảnh bạn cung cấp và tài liệu $fileName, đây là linh kiện Servo Driver MR-J4. Điện áp yêu cầu là 200-230 VAC.',
      confidence: 0.89,
      locked: false,
      numericRule: false,
      citations: [
        MockData.answerNormal.citations.first,
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
}
