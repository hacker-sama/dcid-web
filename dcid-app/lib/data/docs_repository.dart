import 'api_client.dart';
import 'models/answer_result.dart';
import 'models/document_summary.dart';

/// Read/query documents via the backend (which forwards to the AI service).
class DocsRepository {
  DocsRepository(this._api);

  final ApiClient _api;

  Future<AnswerResult> ask(String question) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/query',
      data: {'question': question},
    );
    return AnswerResult.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<List<DocumentSummary>> listDocuments() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/api/documents');
    final list = res.data!['data'] as List<dynamic>? ?? const [];
    return list
        .map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // TODO(M1+): upload multipart (QA), version management, Snap & Ask image (M4).
}
