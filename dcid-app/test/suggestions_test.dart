import 'package:dcid_app/data/models/document_summary.dart';
import 'package:dcid_app/data/models/user_role.dart';
import 'package:dcid_app/state/suggestions_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dynamic Role-Based Suggestions Generator', () {
    test('OPERATOR role generates Operator-tailored prompts (SOP & Safety)', () {
      final suggestions = generateSuggestionsForRole(role: UserRole.operatorRole);

      expect(suggestions.length, equals(4));
      final labels = suggestions.map((s) => s.label).toList();

      expect(labels, contains('Check CNC-01 operating SOP'));
      expect(labels, contains('Summarize safety protocols'));
      expect(labels, contains('Check emergency shutdown steps'));
      expect(labels, contains('Review shift safety checklist'));
    });

    test('ENGINEER role generates Engineer-tailored prompts (Tech Specs & Schematics)', () {
      final suggestions = generateSuggestionsForRole(role: UserRole.engineer);

      expect(suggestions.length, equals(4));
      final labels = suggestions.map((s) => s.label).toList();

      expect(labels, contains('Find voltage specs for TRUC-1'));
      expect(labels, contains('List schematics for Module A'));
      expect(labels, contains('Check hydraulic pressure tolerances'));
      expect(labels, contains('Review PLC error codes & remedies'));
    });

    test('ADMIN and QA_ADMIN roles generate Admin-tailored prompts (Audit & Approvals)', () {
      for (final role in [UserRole.qaAdmin, UserRole.admin]) {
        final suggestions = generateSuggestionsForRole(role: role);

        expect(suggestions.length, equals(4));
        final labels = suggestions.map((s) => s.label).toList();

        expect(labels, contains('Review pending document approvals'));
        expect(labels, contains('Check system audit log summary'));
        expect(labels, contains('Summarize QA document compliance'));
        expect(labels, contains('Audit unassigned machine codes'));
      }
    });

    test('Combines dynamic document context when visible documents are available', () {
      final docs = [
        const DocumentSummary(
          id: 'doc-1',
          title: 'CNC Mill Safety Guidelines 2026',
          category: 'SAFETY',
        ),
        const DocumentSummary(
          id: 'doc-2',
          title: 'TRUC-1 Electrical Diagram',
          category: 'CIRCUIT',
        ),
      ];

      // OPERATOR only sees SAFETY (doc-1), not CIRCUIT (doc-2)
      final opSuggestions = generateSuggestionsForRole(
        role: UserRole.operatorRole,
        documents: docs,
      );
      final opLabels = opSuggestions.map((s) => s.label).toList();
      expect(opLabels.first, contains('CNC Mill Safety Guidelines 2026'));

      // ENGINEER sees all categories (doc-1 & doc-2)
      final engSuggestions = generateSuggestionsForRole(
        role: UserRole.engineer,
        documents: docs,
      );
      final engLabels = engSuggestions.map((s) => s.label).toList();
      expect(engLabels.any((l) => l.contains('CNC Mill Safety Guidelines 2026')), isTrue);
      expect(engLabels.any((l) => l.contains('TRUC-1 Electrical Diagram')), isTrue);
    });
  });
}
