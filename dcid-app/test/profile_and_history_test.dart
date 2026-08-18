import 'package:dcid_app/data/mock/mock_auth_repository.dart';
import 'package:dcid_app/data/mock/mock_docs_repository.dart';
import 'package:dcid_app/data/models/answer_result.dart';
import 'package:dcid_app/data/models/query_history_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueryHistoryItem Model Test', () {
    test('fromJson parses complete payload correctly', () {
      final json = {
        'id': 'query-uuid-123',
        'question': 'Cách kiểm tra dầu bôi trơn?',
        'answerPreview': 'Kiểm tra mắt thăm dầu...',
        'confidence': 0.895,
        'locked': false,
        'numericRuleHit': true,
        'latencyMs': 250,
        'createdAt': '2026-08-17T08:30:00Z',
        'feedback': 1,
      };

      final item = QueryHistoryItem.fromJson(json);

      expect(item.id, equals('query-uuid-123'));
      expect(item.question, equals('Cách kiểm tra dầu bôi trơn?'));
      expect(item.answerPreview, equals('Kiểm tra mắt thăm dầu...'));
      expect(item.confidence, equals(0.895));
      expect(item.locked, isFalse);
      expect(item.numericRuleHit, isTrue);
      expect(item.latencyMs, equals(250));
      expect(item.feedback, equals(1));
    });

    test('fromJson handles null optional fields safely', () {
      final json = {
        'id': 'query-uuid-456',
        'question': 'Tài liệu hướng dẫn an toàn',
      };

      final item = QueryHistoryItem.fromJson(json);

      expect(item.id, equals('query-uuid-456'));
      expect(item.question, equals('Tài liệu hướng dẫn an toàn'));
      expect(item.answerPreview, isNull);
      expect(item.confidence, isNull);
      expect(item.locked, isFalse);
      expect(item.numericRuleHit, isFalse);
      expect(item.latencyMs, isNull);
      expect(item.feedback, isNull);
    });
  });

  group('AnswerResult Model with queryLogId', () {
    test('fromJson parses queryLogId correctly', () {
      final json = {
        'answer': 'Nội dung trả lời AI',
        'confidence': 0.95,
        'locked': false,
        'numericRule': false,
        'citations': [],
        'queryLogId': 'log-uuid-789',
      };

      final result = AnswerResult.fromJson(json);

      expect(result.answer, equals('Nội dung trả lời AI'));
      expect(result.queryLogId, equals('log-uuid-789'));
    });
  });

  group('Mock Repositories Test', () {
    test('MockAuthRepository changePassword completes without error', () async {
      final repo = MockAuthRepository();
      expect(
        repo.changePassword(currentPassword: 'oldPass', newPassword: 'newPass123'),
        completes,
      );
    });

    test('MockDocsRepository getQueryHistory returns mock items', () async {
      final repo = MockDocsRepository();
      final history = await repo.getQueryHistory();

      expect(history, isNotEmpty);
      expect(history.first['question'], contains('máy dán nhãn'));
    });

    test('MockDocsRepository submitFeedback completes without error', () async {
      final repo = MockDocsRepository();
      expect(
        repo.submitFeedback('mock-query-1', helpful: true, note: 'Rất tốt'),
        completes,
      );
    });
  });
}
