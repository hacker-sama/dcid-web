import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'api_client.dart';
import 'docs_repository_interface.dart';
import 'models/answer_result.dart';
import 'models/document_detail.dart';
import 'models/document_summary.dart';

/// Read/query/upload documents via the backend (which forwards to the AI service).
class DocsRepository implements IDocsRepository {
  DocsRepository(this._api);

  final ApiClient _api;

  @override
  Future<AnswerResult> ask(String question) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/query',
      data: {'question': question},
    );
    return AnswerResult.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<AnswerResult> askWithImage(String question, Uint8List imageBytes, String fileName) async {
    final form = FormData.fromMap({
      'question': question,
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/query',
      data: form,
    );
    return AnswerResult.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// `GET /api/documents` — PagedResponse: items live in `data.items`
  /// (docs/PLAN-FLUTTER-DOCS.md §3.1).
  @override
  Future<List<DocumentSummary>> listDocuments() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/api/documents');
    return parseDocumentList(res.data!);
  }

  /// `GET /api/documents/{id}` (§3.2).
  @override
  Future<DocumentDetail> getDocumentDetail(String id) async {
    final res = await _api.dio.get<Map<String, dynamic>>('/api/documents/$id');
    return DocumentDetail.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// `POST /api/documents` multipart — QA_ADMIN/ADMIN only (§3.3).
  /// Field names match the backend exactly; optional fields are omitted when null.
  ///
  /// Nhận file dưới dạng bytes (không phải path): trên web `PlatformFile.path`
  /// luôn null (trình duyệt không lộ đường dẫn hệ thống), nên đây là cách
  /// upload hoạt động thống nhất trên mọi nền tảng (web/Android/Windows).
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
    final form = FormData.fromMap({
      'title': title,
      'category': category,
      if (machineCode != null && machineCode.isNotEmpty) 'machineCode': machineCode,
      if (minRole != null && minRole.isNotEmpty) 'minRole': minRole,
      if (description != null && description.isNotEmpty) 'description': description,
      if (lang != null && lang.isNotEmpty) 'lang': lang,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/documents',
      data: form,
    );
    return DocumentDetail.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// Pure parser for the §3.1 PagedResponse body — unit-testable without HTTP.
  static List<DocumentSummary> parseDocumentList(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}