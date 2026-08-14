import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'docs_repository_interface.dart';
import 'models/answer_result.dart';
import 'models/document_detail.dart';
import 'models/document_summary.dart';
import 'models/sse_event.dart';

/// Read/query/upload documents via the backend (which forwards to the AI service).
class DocsRepository implements IDocsRepository {
  DocsRepository(this._api);

  final ApiClient _api;

  @override
  Future<AnswerResult> ask(
    String question, {
    bool reasoningMode = false,
    List<String>? selectedVersionIds,
    List<Map<String, String>>? history,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/query',
      data: {
        'question': question,
        'reasoningMode': reasoningMode,
        if (selectedVersionIds != null && selectedVersionIds.isNotEmpty)
          'selectedVersionIds': selectedVersionIds,
        if (history != null && history.isNotEmpty)
          'history': history,
      },
    );
    return AnswerResult.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Stream<SseEvent> askStream(
    String question, {
    bool reasoningMode = false,
    List<String>? selectedVersionIds,
    List<Map<String, String>>? history,
  }) async* {
    try {
      final response = await _api.dio.post<ResponseBody>(
        '/api/query/stream',
        data: {
          'question': question,
          'reasoningMode': reasoningMode,
          if (selectedVersionIds != null && selectedVersionIds.isNotEmpty)
            'selectedVersionIds': selectedVersionIds,
          if (history != null && history.isNotEmpty)
            'history': history,
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 10),
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield const SseEvent(
          type: SseEventType.error,
          errorMessage: 'Không nhận được dữ liệu stream từ server',
        );
        return;
      }

      String buffer = '';
      String eventType = 'message';

      await for (final chunk in stream.map((bytes) => utf8.decode(bytes))) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('event:')) {
            eventType = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            if (dataStr.isEmpty) continue;
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              // The AI service includes the event name in its JSON payload.
              // Standard SSE `event:` lines remain supported as a fallback.
              final effectiveEvent = json['event'] as String? ?? eventType;
              if (effectiveEvent == 'meta') {
                final citations = (json['citations'] as List<dynamic>? ?? [])
                    .map((e) => Citation.fromJson(e as Map<String, dynamic>))
                    .toList();
                final guard = json['guard'] as Map<String, dynamic>? ?? {};
                yield SseEvent(
                  type: SseEventType.meta,
                  citations: citations,
                  locked: guard['locked'] as bool? ?? false,
                  numericRule: guard['numericRule'] as bool? ?? false,
                  reasoningMode:
                      guard['reasoningMode'] as bool? ?? reasoningMode,
                  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
                );
              } else if (effectiveEvent == 'delta') {
                yield SseEvent(
                  type: SseEventType.delta,
                  textDelta:
                      json['text'] as String? ?? json['delta'] as String? ?? '',
                );
              } else if (effectiveEvent == 'done') {
                yield SseEvent(
                  type: SseEventType.done,
                  latencyMs: (json['latencyMs'] as num?)?.toInt(),
                );
              } else if (effectiveEvent == 'error') {
                yield SseEvent(
                  type: SseEventType.error,
                  errorMessage: json['message'] as String? ?? 'Lỗi truy vấn AI',
                );
              }
            } catch (_) {
              if (eventType == 'delta') {
                yield SseEvent(type: SseEventType.delta, textDelta: dataStr);
              }
            }
            eventType = 'message';
          }
        }
      }
    } catch (e) {
      yield SseEvent(type: SseEventType.error, errorMessage: _streamErrorMessage(e));
    }
  }

  String _streamErrorMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối AI bị gián đoạn. Vui lòng đợi dịch vụ sẵn sàng rồi thử lại.';
      }
    }
    final message = error.toString().toLowerCase();
    if (message.contains('incomplete_chunked_encoding') ||
        message.contains('connection closed')) {
      return 'Luồng trả lời AI bị ngắt. Vui lòng thử lại sau ít phút.';
    }
    return 'Không truy vấn được AI. Vui lòng thử lại.';
  }

  @override
  Future<AnswerResult> askWithImage(String question, Uint8List imageBytes, String fileName, {String? machineCode}) async {
    final form = FormData.fromMap({
      'question': question,
      if (machineCode != null && machineCode.isNotEmpty) 'machineCode': machineCode,
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/query/vision',
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

  /// `DELETE /api/documents/{id}` (§3.4).
  @override
  Future<void> deleteDocument(String id) async {
    await _api.dio.delete<Map<String, dynamic>>('/api/documents/$id');
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
