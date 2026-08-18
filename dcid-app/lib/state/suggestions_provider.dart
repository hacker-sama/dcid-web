import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/document_summary.dart';
import '../data/models/user_role.dart';
import 'auth_controller.dart';
import 'documents_providers.dart';
import 'role_filter.dart';

class SearchSuggestionItem {
  final String label;
  final IconData icon;

  const SearchSuggestionItem({
    required this.label,
    required this.icon,
  });
}

/// Helper function to generate role-based and document-contextual suggestions.
List<SearchSuggestionItem> generateSuggestionsForRole({
  required UserRole? role,
  List<DocumentSummary>? documents,
}) {
  final items = <SearchSuggestionItem>[];

  // Filter documents visible to the role if documents are provided
  final visibleCategories = role != null ? visibleCategoriesForRole(role) : const <String>{};
  final relevantDocs = documents?.where((d) => visibleCategories.contains(d.category)).toList() ?? [];

  // Add document-contextual suggestions if documents are available
  if (relevantDocs.isNotEmpty) {
    for (int i = 0; i < relevantDocs.length && i < 2; i++) {
      final doc = relevantDocs[i];
      final title = doc.title.trim();
      if (role == UserRole.operatorRole) {
        items.add(SearchSuggestionItem(
          label: 'Check operating steps in $title',
          icon: Icons.assignment_outlined,
        ));
      } else if (role == UserRole.engineer) {
        items.add(SearchSuggestionItem(
          label: 'Find technical specs in $title',
          icon: Icons.find_in_page_outlined,
        ));
      } else {
        items.add(SearchSuggestionItem(
          label: 'Review status of $title',
          icon: Icons.verified_outlined,
        ));
      }
    }
  }

  // Complement with role-tailored defaults
  switch (role) {
    case UserRole.operatorRole:
      items.addAll(const [
        SearchSuggestionItem(
          label: 'Check CNC-01 operating SOP',
          icon: Icons.build_circle_outlined,
        ),
        SearchSuggestionItem(
          label: 'Summarize safety protocols',
          icon: Icons.shield_outlined,
        ),
        SearchSuggestionItem(
          label: 'Check emergency shutdown steps',
          icon: Icons.warning_amber_rounded,
        ),
        SearchSuggestionItem(
          label: 'Review shift safety checklist',
          icon: Icons.checklist_rtl_rounded,
        ),
      ]);
      break;

    case UserRole.engineer:
      items.addAll(const [
        SearchSuggestionItem(
          label: 'Find voltage specs for TRUC-1',
          icon: Icons.bolt_outlined,
        ),
        SearchSuggestionItem(
          label: 'List schematics for Module A',
          icon: Icons.schema_outlined,
        ),
        SearchSuggestionItem(
          label: 'Check hydraulic pressure tolerances',
          icon: Icons.handyman_outlined,
        ),
        SearchSuggestionItem(
          label: 'Review PLC error codes & remedies',
          icon: Icons.precision_manufacturing_outlined,
        ),
      ]);
      break;

    case UserRole.qaAdmin:
    case UserRole.admin:
      items.addAll(const [
        SearchSuggestionItem(
          label: 'Review pending document approvals',
          icon: Icons.verified_user_outlined,
        ),
        SearchSuggestionItem(
          label: 'Check system audit log summary',
          icon: Icons.fact_check_outlined,
        ),
        SearchSuggestionItem(
          label: 'Summarize QA document compliance',
          icon: Icons.admin_panel_settings_outlined,
        ),
        SearchSuggestionItem(
          label: 'Audit unassigned machine codes',
          icon: Icons.folder_shared_outlined,
        ),
      ]);
      break;

    case null:
      items.addAll(const [
        SearchSuggestionItem(
          label: 'Check CNC-01 operating SOP',
          icon: Icons.build_circle_outlined,
        ),
        SearchSuggestionItem(
          label: 'Summarize safety protocols',
          icon: Icons.shield_outlined,
        ),
        SearchSuggestionItem(
          label: 'Find voltage specs for TRUC-1',
          icon: Icons.bolt_outlined,
        ),
        SearchSuggestionItem(
          label: 'List schematics for Module A',
          icon: Icons.schema_outlined,
        ),
      ]);
      break;
  }

  // Deduplicate and cap to 4 items
  final uniqueLabels = <String>{};
  final result = <SearchSuggestionItem>[];
  for (final item in items) {
    if (uniqueLabels.add(item.label)) {
      result.add(item);
      if (result.length >= 4) break;
    }
  }
  return result;
}

/// Provider that delivers dynamic, role-tailored search suggestion chips.
final searchSuggestionsProvider = Provider<List<SearchSuggestionItem>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final role = auth.user?.role;
  // Protected document data must not be requested while session restoration
  // is still in progress. SearchScreen also watches this same provider, so
  // Riverpod shares one in-flight GET /api/documents request between both UIs.
  final docs = auth.isAuthenticated
      ? ref.watch(documentsProvider).value
      : null;

  return generateSuggestionsForRole(role: role, documents: docs);
});
