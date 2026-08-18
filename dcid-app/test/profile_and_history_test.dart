import 'package:dcid_app/data/mock/mock_auth_repository.dart';
import 'package:dcid_app/data/mock/mock_docs_repository.dart';
import 'package:dcid_app/data/models/answer_result.dart';
import 'package:dcid_app/data/models/feedback_admin_item.dart';
import 'package:dcid_app/data/models/query_history_item.dart';
import 'package:dcid_app/features/history/history_screen.dart';
import 'package:dcid_app/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        'feedbackNote': 'Câu trả lời rất rõ ràng',
        'feedbackAt': '2026-08-17T08:35:00Z',
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
      expect(item.feedbackNote, equals('Câu trả lời rất rõ ràng'));
      expect(item.feedbackAt, isNotNull);
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
      expect(item.feedbackNote, isNull);
      expect(item.feedbackAt, isNull);
    });
  });

  group('FeedbackAdminItem Model Test', () {
    test('fromJson parses admin feedback payload correctly', () {
      final json = {
        'id': 'fb-uuid-001',
        'actorId': 'user-uuid-123',
        'actorUsername': 'operator1',
        'question': 'Áp suất khí nén bao nhiêu bar?',
        'answerPreview': 'Áp suất làm việc tiêu chuẩn là 6.0 bar...',
        'confidence': 0.92,
        'locked': false,
        'feedback': 1,
        'feedbackNote': 'Chính xác theo catalog',
        'feedbackAt': '2026-08-18T10:00:00Z',
        'createdAt': '2026-08-18T09:59:00Z',
      };

      final item = FeedbackAdminItem.fromJson(json);

      expect(item.id, equals('fb-uuid-001'));
      expect(item.actorUsername, equals('operator1'));
      expect(item.feedback, equals(1));
      expect(item.feedbackNote, equals('Chính xác theo catalog'));
      expect(item.confidence, equals(0.92));
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

  group('HistoryScreen Widget Tests', () {
    testWidgets('renders search field, filter chips, and history list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            docsRepositoryProvider.overrideWithValue(MockDocsRepository()),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);
      // Verify date filter options exist
      expect(find.text('Tất cả'), findsWidgets);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('7 ngày qua'), findsOneWidget);
      expect(find.text('30 ngày qua'), findsOneWidget);
      // Verify feedback status filter options exist
      expect(find.text('👍 Đã thích'), findsOneWidget);
      expect(find.text('👎 Không thích'), findsOneWidget);
      expect(find.text('🔒 Bị khóa'), findsOneWidget);
    });
  });
}
