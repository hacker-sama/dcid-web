import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'docs_repository_interface.dart';
import 'models/answer_result.dart';
import 'models/document_detail.dart';
import 'models/document_summary.dart';

/// Decorator repository that caches document lists and Q&A answers in local storage.
/// Provides offline fallback when network requests fail.
class OfflineCacheDocsRepository implements IDocsRepository {
  OfflineCacheDocsRepository(this._inner, this._storage);

  final IDocsRepository _inner;
  final FlutterSecureStorage _storage;

  static const _cacheKeyDocsList = 'offline_cache_docs_list';
  static const _cacheKeyAnswersPrefix = 'offline_cache_answer_';

  @override
  Future<AnswerResult> ask(
    String question, {
    bool reasoningMode = false,
    List<String>? selectedVersionIds,
    List<Map<String, String>>? history,
  }) async {
    try {
      final result = await _inner.ask(
        question,
        reasoningMode: reasoningMode,
        selectedVersionIds: selectedVersionIds,
        history: history,
      );
      // Cache latest successful answer
      await _cacheAnswer(question, result);
      return result;
    } catch (_) {
      // Try retrieving cached answer for this query
      final cached = await _getCachedAnswer(question);
      if (cached != null) return cached;

      // Offline fallback response
      return AnswerResult(
        answer: '⚠️ **Chế độ Ngoại tuyến (Offline Cache)**\n\n'
            'Dịch vụ máy chủ tạm thời không thể kết nối. '
            'Hiển thị kết quả tra cứu gần nhất từ bộ nhớ tạm local.\n\n'
            '**Câu hỏi:** "$question"',
        confidence: 0.5,
        locked: false,
        numericRule: false,
        reasoningMode: reasoningMode,
        citations: [],
      );
    }
  }

  @override
  Future<AnswerResult> askWithImage(
    String question,
    Uint8List imageBytes,
    String fileName, {
    String? machineCode,
  }) async {
    return _inner.askWithImage(
      question,
      imageBytes,
      fileName,
      machineCode: machineCode,
    );
  }

  @override
  Future<List<DocumentSummary>> listDocuments() async {
    try {
      final docs = await _inner.listDocuments();
      await _cacheDocsList(docs);
      return docs;
    } catch (_) {
      final cachedDocs = await _getCachedDocsList();
      if (cachedDocs != null && cachedDocs.isNotEmpty) {
        return cachedDocs;
      }
      rethrow;
    }
  }

  @override
  Future<DocumentDetail> getDocumentDetail(String id) async {
    return _inner.getDocumentDetail(id);
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
    return _inner.uploadDocument(
      title: title,
      category: category,
      machineCode: machineCode,
      minRole: minRole,
      description: description,
      lang: lang,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  @override
  Future<void> deleteDocument(String id) async {
    return _inner.deleteDocument(id);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _cacheDocsList(List<DocumentSummary> docs) async {
    try {
      final jsonList = docs
          .map((d) => {
                'id': d.id,
                'title': d.title,
                'machineCode': d.machineCode,
                'category': d.category,
                'minRole': d.minRole,
                'description': d.description,
                'createdAt': d.createdAt?.toIso8601String(),
                'updatedAt': d.updatedAt?.toIso8601String(),
              })
          .toList();
      await _storage.write(key: _cacheKeyDocsList, value: jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<DocumentSummary>?> _getCachedDocsList() async {
    try {
      final raw = await _storage.read(key: _cacheKeyDocsList);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheAnswer(String question, AnswerResult answer) async {
    try {
      final key = '$_cacheKeyAnswersPrefix${question.hashCode}';
      final jsonMap = {
        'answer': answer.answer,
        'confidence': answer.confidence,
        'guard': {
          'locked': answer.locked,
          'numericRule': answer.numericRule,
          'reasoningMode': answer.reasoningMode,
        },
        'citations': answer.citations
            .map((c) => {
                  'versionId': c.versionId,
                  'pageNo': c.pageNo,
                  'bboxKey': c.bboxKey,
                  'snippet': c.snippet,
                })
            .toList(),
      };
      await _storage.write(key: key, value: jsonEncode(jsonMap));
    } catch (_) {}
  }

  Future<AnswerResult?> _getCachedAnswer(String question) async {
    try {
      final key = '$_cacheKeyAnswersPrefix${question.hashCode}';
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AnswerResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
