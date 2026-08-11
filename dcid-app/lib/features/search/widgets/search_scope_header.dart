import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/document_summary.dart';

/// Scope selection banner, document filter chips, and reasoning mode toggle row.
class SearchScopeHeader extends StatelessWidget {
  const SearchScopeHeader({
    super.key,
    required this.selectedVersionIdsByDocId,
    required this.availableDocs,
    required this.resolvingDocIds,
    required this.reasoningMode,
    required this.loading,
    required this.hasChatMessages,
    required this.onSetDocumentSelected,
    required this.onClearDocSelection,
    required this.onClearChat,
    required this.onReasoningModeChanged,
  });

  final Map<String, String> selectedVersionIdsByDocId;
  final List<DocumentSummary> availableDocs;
  final Set<String> resolvingDocIds;
  final bool reasoningMode;
  final bool loading;
  final bool hasChatMessages;
  final Future<void> Function(DocumentSummary document, bool selected)
      onSetDocumentSelected;
  final VoidCallback onClearDocSelection;
  final VoidCallback onClearChat;
  final ValueChanged<bool> onReasoningModeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentFor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScopeBar(context, colorScheme, accent),
        if (availableDocs.isNotEmpty)
          _buildDocChips(context, colorScheme, accent),
        _buildReasoningRow(context, colorScheme, accent),
      ],
    );
  }

  Widget _buildScopeBar(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          Icon(
            selectedVersionIdsByDocId.isEmpty
                ? Icons.language_outlined
                : Icons.my_location_outlined,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedVersionIdsByDocId.isEmpty
                  ? 'Scope: All Documents (Global RAG)'
                  : 'Scope: ${selectedVersionIdsByDocId.length} document(s) selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (selectedVersionIdsByDocId.isNotEmpty)
            _SmallAction(
              icon: Icons.close_rounded,
              label: 'Clear',
              colorScheme: colorScheme,
              onTap: onClearDocSelection,
            ),
          if (hasChatMessages)
            _SmallAction(
              icon: Icons.refresh_rounded,
              label: 'New chat',
              colorScheme: colorScheme,
              onTap: loading ? null : onClearChat,
            ),
        ],
      ),
    );
  }

  Widget _buildDocChips(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: availableDocs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final doc = availableDocs[index];
          final isSelected = selectedVersionIdsByDocId.containsKey(doc.id);
          final isResolving = resolvingDocIds.contains(doc.id);
          return FilterChip(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? accent.withValues(alpha: 0.8)
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            selectedColor: accent.withValues(alpha: 0.12),
            backgroundColor: colorScheme.surface,
            showCheckmark: false,
            label: Text(
              doc.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accent : colorScheme.onSurface,
              ),
            ),
            selected: isSelected,
            onSelected:
                isResolving ? null : (val) => onSetDocumentSelected(doc, val),
            avatar: isResolving
                ? SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                : isSelected
                    ? Icon(Icons.check_rounded, size: 14, color: accent)
                    : null,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildReasoningRow(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.auto_awesome_rounded,
              key: ValueKey(reasoningMode),
              size: 15,
              color: reasoningMode ? accent : colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reasoning Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: reasoningMode
                    ? accent
                    : colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: reasoningMode,
              onChanged: loading ? null : onReasoningModeChanged,
              activeThumbColor: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colorScheme.outline),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
