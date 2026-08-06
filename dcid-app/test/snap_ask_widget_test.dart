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
    testWidgets('renders empty state when no photos are uploaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            docsRepositoryProvider.overrideWithValue(MockDocsRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SnapAskScreen(),
            ),
          ),
        ),
      );

      // Verify empty state texts exist (English after i18n refactor)
      expect(find.text('No device photos yet'), findsOneWidget);
      expect(find.textContaining('Tap the + button below'), findsOneWidget);
      expect(find.byIcon(Icons.camera_roll_outlined), findsOneWidget);
    });
  });

  group('AnswerView Widget Tests', () {
    testWidgets('renders Markdown content (bold, code, headers)',
        (WidgetTester tester) async {
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
      expect(find.textContaining('Tin cậy: 95%'), findsOneWidget);
      expect(find.textContaining('Trích số liệu trực tiếp'), findsOneWidget);
      expect(find.textContaining('Reasoning mode'), findsOneWidget);
    });

    testWidgets('renders locked guardrail red banner when locked is true',
        (WidgetTester tester) async {
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

      expect(find.textContaining('Không đủ dữ liệu chắc chắn'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
