import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme.dart';
import '../../../data/models/document_summary.dart';
import 'document_scope_dialog.dart';

/// Scope selection banner, document filter chips, and chat actions.
class SearchScopeHeader extends ConsumerWidget {
  const SearchScopeHeader({
    super.key,
    required this.selectedVersionIdsByDocId,
    required this.availableDocs,
    required this.resolvingDocIds,
    required this.loading,
    required this.hasChatMessages,
    required this.onSetDocumentSelected,
    required this.onClearDocSelection,
    required this.onClearChat,
  });

  final Map<String, String> selectedVersionIdsByDocId;
  final List<DocumentSummary> availableDocs;
  final Set<String> resolvingDocIds;
  final bool loading;
  final bool hasChatMessages;
  final Future<void> Function(DocumentSummary document, bool selected)
  onSetDocumentSelected;
  final VoidCallback onClearDocSelection;
  final VoidCallback onClearChat;

  void _openScopeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DocumentScopeDialog(
        availableDocs: availableDocs,
        selectedVersionIdsByDocId: selectedVersionIdsByDocId,
        resolvingDocIds: resolvingDocIds,
        onSetDocumentSelected: onSetDocumentSelected,
        onClearDocSelection: onClearDocSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentFor(context);
    final strings = ref.watch(appStringsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScopeBar(context, colorScheme, accent, strings),
        if (availableDocs.isNotEmpty)
          _buildDocChips(context, colorScheme, accent),
      ],
    );
  }

  Widget _buildScopeBar(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
    dynamic strings,
  ) {
    final hasSelection = selectedVersionIdsByDocId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            hasSelection ? Icons.my_location_outlined : Icons.language_outlined,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: availableDocs.isEmpty ? null : () => _openScopeDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      hasSelection
                          ? strings.scopeSelectedDocs(selectedVersionIdsByDocId.length)
                          : strings.scopeAllDocs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? accent
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (availableDocs.isNotEmpty)
            _SmallAction(
              icon: Icons.tune_rounded,
              label: hasSelection ? 'Đổi phạm vi' : 'Chọn (${availableDocs.length})',
              colorScheme: colorScheme,
              onTap: () => _openScopeDialog(context),
            ),
          if (hasSelection) ...[
            const SizedBox(width: 4),
            _SmallAction(
              icon: Icons.close_rounded,
              label: strings.clear,
              colorScheme: colorScheme,
              onTap: onClearDocSelection,
            ),
          ],
          if (hasChatMessages) ...[
            const SizedBox(width: 4),
            _SmallAction(
              icon: Icons.refresh_rounded,
              label: strings.newChat,
              colorScheme: colorScheme,
              onTap: loading ? null : onClearChat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocChips(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
  ) {
    // If documents are selected, show ONLY selected chips for clean UI
    final hasSelection = selectedVersionIdsByDocId.isNotEmpty;
    final docsToShow = hasSelection
        ? availableDocs
            .where((d) => selectedVersionIdsByDocId.containsKey(d.id))
            .toList()
        : (availableDocs.length <= 6
            ? availableDocs
            : availableDocs.take(5).toList());

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: docsToShow.length + (hasSelection || availableDocs.length > 5 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == docsToShow.length) {
            // "More / Add" action button
            return ActionChip(
              avatar: Icon(
                hasSelection ? Icons.add_rounded : Icons.more_horiz_rounded,
                size: 15,
                color: accent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: accent.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              backgroundColor: accent.withValues(alpha: 0.08),
              label: Text(
                hasSelection
                    ? 'Thêm tài liệu...'
                    : 'Xem tất cả (${availableDocs.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              onPressed: () => _openScopeDialog(context),
              visualDensity: VisualDensity.compact,
            );
          }

          final doc = docsToShow[index];
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accent : colorScheme.onSurface,
              ),
            ),
            selected: isSelected,
            onSelected: isResolving
                ? null
                : (val) => onSetDocumentSelected(doc, val),
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
