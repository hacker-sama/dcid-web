import 'dart:typed_data';

import 'models/answer_result.dart';
import 'models/document_detail.dart';
import 'models/document_summary.dart';

/// Contract for document operations (query, list, detail, upload).
///
/// Both the real [DocsRepository] (Dio/backend) and [MockDocsRepository]
/// (hardcoded data) implement this interface so they can be swapped
/// transparently via Riverpod provider overrides.
abstract class IDocsRepository {
  /// `POST /api/query` — RAG search.
  Future<AnswerResult> ask(
    String question, {
    bool reasoningMode = false,
    List<String>? selectedVersionIds,
    List<Map<String, String>>? history,
  });

  /// `POST /api/query` — Snap & Ask (multipart with image).
  Future<AnswerResult> askWithImage(String question, Uint8List imageBytes, String fileName);

  /// `GET /api/documents` — paginated list.
  Future<List<DocumentSummary>> listDocuments();

  /// `GET /api/documents/{id}` — detail with versions.
  Future<DocumentDetail> getDocumentDetail(String id);

  /// `POST /api/documents` — multipart upload (QA_ADMIN/ADMIN only).
  Future<DocumentDetail> uploadDocument({
    required String title,
    required String category,
    String? machineCode,
    String? minRole,
    String? description,
    String? lang,
    required Uint8List fileBytes,
    required String fileName,
  });
}
