import 'package:dio/dio.dart';

import 'api_client.dart';
import 'models/answer_result.dart';
import 'models/guest_session_models.dart';

class GuestRepository {
  GuestRepository(this._api);

  final ApiClient _api;

  /// Tạo một phiên hỏi đáp tạm thời ẩn danh mới.
  Future<CreateSessionData> createSession() async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/api/public/sessions',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CreateSessionData.fromJson(data);
  }

  /// Lấy chi tiết phiên ẩn danh.
  Future<GuestSessionData> getSessionDetail(String sessionId, String token) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/api/public/sessions/$sessionId',
      options: Options(headers: {'X-Session-Token': token}),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return GuestSessionData.fromJson(data);
  }

  /// Upload file PDF tạm vào phiên công khai.
  Future<GuestDocumentItem> uploadDocument(
    String sessionId,
    String token,
    List<int> bytes,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _api.dio.post<Map<String, dynamic>>(
      '/api/public/sessions/$sessionId/documents',
      data: formData,
      options: Options(headers: {'X-Session-Token': token}),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return GuestDocumentItem.fromJson(data);
  }

  /// Lấy trạng thái xử lý OCR/Indexing của tài liệu tạm.
  Future<GuestDocumentItem> getDocumentStatus(
    String sessionId,
    String documentId,
    String token,
  ) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/api/public/sessions/$sessionId/documents/$documentId/status',
      options: Options(headers: {'X-Session-Token': token}),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return GuestDocumentItem.fromJson(data);
  }

  /// Gửi câu hỏi RAG trong phạm vi tài liệu thuộc phiên tạm.
  Future<AnswerResult> askQuestion(
    String sessionId,
    String token,
    String question,
  ) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/api/public/sessions/$sessionId/query',
      data: {'question': question},
      options: Options(headers: {'X-Session-Token': token}),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return AnswerResult.fromJson(data);
  }

  /// Người dùng chủ động kết thúc phiên công khai.
  Future<void> deleteSession(String sessionId, String token) async {
    await _api.dio.delete<void>(
      '/api/public/sessions/$sessionId',
      options: Options(headers: {'X-Session-Token': token}),
    );
  }
}
