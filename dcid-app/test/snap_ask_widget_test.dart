import 'package:dcid_app/data/mock/mock_docs_repository.dart';
import 'package:dcid_app/data/models/answer_result.dart';
import 'package:dcid_app/features/search/answer_view.dart';
import 'package:dcid_app/features/snap_ask/snap_ask_screen.dart';
import 'package:dcid_app/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapAskScreen Widget Tests', () {
    testWidgets('renders empty state when no photos are uploaded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            docsRepositoryProvider.overrideWithValue(MockDocsRepository()),
          ],
          child: const MaterialApp(home: Scaffold(body: SnapAskScreen())),
        ),
      );

      // Verify empty state texts exist (English after i18n refactor)
      expect(find.text('No device photos yet'), findsOneWidget);
      expect(find.textContaining('Tap the + button below'), findsOneWidget);
      expect(find.byIcon(Icons.camera_roll_outlined), findsOneWidget);
    });
  });

  group('AnswerView Widget Tests', () {
    testWidgets('renders Markdown content (bold, code, headers)', (
      WidgetTester tester,
    ) async {
      const result = AnswerResult(
        answer: '''**Phân tích kỹ thuật**
- Linh kiện: `MR-J4`
- Điện áp: **220V**''',
        confidence: 0.95,
        locked: false,
        numericRule: true,
        reasoningMode: true,
        citations: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnswerView(result: result, shrinkWrap: true),
            ),
          ),
        ),
      );

      expect(find.textContaining('Phân tích kỹ thuật'), findsOneWidget);
      expect(find.textContaining('Confidence:'), findsNothing);
      expect(find.textContaining('Direct Data Extraction'), findsOneWidget);
      expect(find.textContaining('Reasoning mode'), findsOneWidget);
    });

    testWidgets('renders locked guardrail red banner when locked is true', (
      WidgetTester tester,
    ) async {
      const result = AnswerResult(
        answer: 'Thấp hơn ngưỡng tin cậy',
        confidence: 0.35,
        locked: true,
        numericRule: false,
        citations: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnswerView(result: result, shrinkWrap: true),
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Insufficient data confidence'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders copy answer button and allows tapping', (
      WidgetTester tester,
    ) async {
      const result = AnswerResult(
        answer: 'Nội dung trả lời cần sao chép',
        confidence: 0.9,
        locked: false,
        numericRule: false,
        citations: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnswerView(result: result, shrinkWrap: true),
            ),
          ),
        ),
      );

      expect(find.text('Sao chép'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('copy_answer_button')));
      await tester.pumpAndSettle();

      // After 2s animation & SnackBar timer settle, button returns to ready state
      expect(find.text('Sao chép'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });
}
