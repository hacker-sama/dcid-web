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
        if (history != null && history.isNotEmpty) 'history': history,
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
          if (history != null && history.isNotEmpty) 'history': history,
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
      yield SseEvent(
        type: SseEventType.error,
        errorMessage: _streamErrorMessage(e),
      );
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
  Future<AnswerResult> askWithImage(
    String question,
    Uint8List imageBytes,
    String fileName, {
    String? machineCode,
  }) async {
    FormData buildForm() => FormData.fromMap({
      'question': question,
      if (machineCode != null && machineCode.isNotEmpty)
        'machineCode': machineCode,
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });
    try {
      // The upload request now only enqueues work and returns immediately.
      // Short status polls avoid holding a browser/proxy connection open while
      // OCR and the vision model are waiting for the shared AI slot.
      final created = await _api.dio.post<Map<String, dynamic>>(
        '/api/query/vision/jobs',
        data: buildForm(),
      );
      final job = created.data!['data'] as Map<String, dynamic>;
      final jobId = job['jobId'] as String?;
      if (jobId == null || jobId.isEmpty) {
        throw StateError('Vision job response does not contain jobId');
      }
      return _waitForVisionJob(jobId);
    } on DioException catch (error) {
      // Rolling deployment compatibility: an older backend may be serving the
      // new Flutter bundle briefly before the async endpoint is available.
      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 405) {
        return _askWithImageSync(buildForm());
      }
      rethrow;
    }
  }

  Future<AnswerResult> _waitForVisionJob(String jobId) async {
    final deadline = DateTime.now().add(const Duration(minutes: 15));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/api/query/vision/jobs/$jobId',
      );
      final job = response.data!['data'] as Map<String, dynamic>;
      final status = job['status'] as String? ?? 'QUEUED';
      if (status == 'SUCCEEDED') {
        final result = job['result'] as Map<String, dynamic>?;
        if (result == null) {
          throw StateError('Completed vision job does not contain a result');
        }
        return AnswerResult.fromJson(result);
      }
      if (status == 'FAILED') {
        throw DioException(
          requestOptions: response.requestOptions,
          response: Response<Map<String, dynamic>>(
            requestOptions: response.requestOptions,
            statusCode: 503,
            data: {'error': job['error'] ?? 'Vision processing failed'},
          ),
          type: DioExceptionType.badResponse,
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw DioException(
      requestOptions: RequestOptions(path: '/api/query/vision/jobs/$jobId'),
      type: DioExceptionType.receiveTimeout,
      message: 'Vision job exceeded the 15-minute client deadline',
    );
  }

  Future<AnswerResult> _askWithImageSync(FormData form) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/api/query/vision',
      data: form,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
    );
    return AnswerResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
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
      if (machineCode != null && machineCode.isNotEmpty)
        'machineCode': machineCode,
      if (minRole != null && minRole.isNotEmpty) 'minRole': minRole,
      if (description != null && description.isNotEmpty)
        'description': description,
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

  @override
  Future<List<dynamic>> getQueryHistory({int page = 0, int size = 20}) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/api/query/history',
      queryParameters: {'page': page, 'size': size},
    );
    final data = res.data!['data'] as Map<String, dynamic>? ?? {};
    return data['items'] as List<dynamic>? ?? [];
  }

  @override
  Future<void> submitFeedback(
    String queryId, {
    required bool helpful,
    String? note,
  }) async {
    await _api.dio.post<Map<String, dynamic>>(
      '/api/query/$queryId/feedback',
      data: {
        'helpful': helpful,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
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
