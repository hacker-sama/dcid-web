import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/models/document_summary.dart';

/// Modal dialog for searching, filtering, and selecting documents to scope DocuMind chat.
class DocumentScopeDialog extends ConsumerStatefulWidget {
  const DocumentScopeDialog({
    super.key,
    required this.availableDocs,
    required this.selectedVersionIdsByDocId,
    required this.resolvingDocIds,
    required this.onSetDocumentSelected,
    required this.onClearDocSelection,
  });

  final List<DocumentSummary> availableDocs;
  final Map<String, String> selectedVersionIdsByDocId;
  final Set<String> resolvingDocIds;
  final Future<void> Function(DocumentSummary document, bool selected)
      onSetDocumentSelected;
  final VoidCallback onClearDocSelection;

  @override
  ConsumerState<DocumentScopeDialog> createState() =>
      _DocumentScopeDialogState();
}

class _DocumentScopeDialogState extends ConsumerState<DocumentScopeDialog> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final set = <String>{'ALL'};
    for (final doc in widget.availableDocs) {
      if (doc.category != null && doc.category!.isNotEmpty) {
        set.add(doc.category!);
      }
    }
    return set.toList();
  }

  List<DocumentSummary> get _filteredDocs {
    final query = _searchController.text.trim().toLowerCase();
    return widget.availableDocs.where((doc) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          (doc.category != null && doc.category == _selectedCategory);
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;
      final matchesTitle = doc.title.toLowerCase().contains(query);
      final matchesCode =
          (doc.machineCode ?? '').toLowerCase().contains(query);
      return matchesTitle || matchesCode;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedCount = widget.selectedVersionIdsByDocId.length;
    final filtered = _filteredDocs;

    return Dialog(
      backgroundColor: isDark ? kDarkCard : colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 720,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune_rounded, size: 20, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn tài liệu tra cứu',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedCount == 0
                              ? 'Mặc định tra cứu trên tất cả ${widget.availableDocs.length} tài liệu'
                              : 'Đã chọn $selectedCount / ${widget.availableDocs.length} tài liệu',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: selectedCount == 0
                                ? colorScheme.outline
                                : accent,
                            fontWeight: selectedCount == 0
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Box
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên tài liệu, mã máy...',
                  hintStyle: TextStyle(fontSize: 13.5, color: colorScheme.outline),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: colorScheme.outline),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? kDarkBg
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Category Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          cat == 'ALL' ? 'Tất cả danh mục' : cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? accent : colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: accent.withValues(alpha: 0.14),
                        backgroundColor: isDark
                            ? kDarkBg
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        side: BorderSide(
                          color: isSelected
                              ? accent.withValues(alpha: 0.6)
                              : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Action buttons (Select visible / Clear selection)
              Row(
                children: [
                  Text(
                    '${filtered.length} tài liệu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (selectedCount > 0)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        widget.onClearDocSelection();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),

              const Divider(height: 16),

              // Document List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 40, color: colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              'Không tìm thấy tài liệu phù hợp',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final isSelected =
                              widget.selectedVersionIdsByDocId.containsKey(doc.id);
                          final isResolving =
                              widget.resolvingDocIds.contains(doc.id);

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: isResolving
                                ? null
                                : () async {
                                    await widget.onSetDocumentSelected(
                                        doc, !isSelected);
                                    if (mounted) setState(() {});
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 8),
                              child: Row(
                                children: [
                                  // Checkbox or spinner
                                  SizedBox.square(
                                    dimension: 24,
                                    child: isResolving
                                        ? Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: accent,
                                            ),
                                          )
                                        : Checkbox(
                                            value: isSelected,
                                            activeColor: accent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            onChanged: (val) async {
                                              await widget.onSetDocumentSelected(
                                                  doc, val ?? false);
                                              if (mounted) setState(() {});
                                            },
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Document Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? accent
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (doc.category != null &&
                                                doc.category!.isNotEmpty) ...[
                                              _CategoryTag(
                                                category: doc.category!,
                                                colorScheme: colorScheme,
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            if (doc.machineCode != null &&
                                                doc.machineCode!.isNotEmpty)
                                              Text(
                                                'Mã: ${doc.machineCode}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: colorScheme.outline,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Bottom Apply Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      selectedCount == 0
                          ? 'Xong (Tất cả tài liệu)'
                          : 'Áp dụng ($selectedCount đã chọn)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({
    required this.category,
    required this.colorScheme,
  });

  final String category;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
