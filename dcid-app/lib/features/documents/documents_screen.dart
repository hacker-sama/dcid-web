import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../core/responsive.dart';
import '../../core/constrained_content.dart';
import '../../data/models/document_summary.dart';
import '../../state/documents_providers.dart';
import '../../state/providers.dart';
import '../../state/role_filter.dart';
import 'upload_document_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sort options
// ─────────────────────────────────────────────────────────────────────────────

enum _SortOption {
  updatedNewest,
  updatedOldest,
  titleAZ,
  titleZA,
  category,
}

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.updatedNewest:
        return 'Newest first';
      case _SortOption.updatedOldest:
        return 'Oldest first';
      case _SortOption.titleAZ:
        return 'Title A→Z';
      case _SortOption.titleZA:
        return 'Title Z→A';
      case _SortOption.category:
        return 'Category / Code';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortOption.updatedNewest:
        return Icons.arrow_downward;
      case _SortOption.updatedOldest:
        return Icons.arrow_upward;
      case _SortOption.titleAZ:
        return Icons.sort_by_alpha;
      case _SortOption.titleZA:
        return Icons.sort_by_alpha;
      case _SortOption.category:
        return Icons.label_outline;
    }
  }
}

List<DocumentSummary> _applySorting(
    List<DocumentSummary> docs, _SortOption sort) {
  final list = List<DocumentSummary>.from(docs);
  switch (sort) {
    case _SortOption.updatedNewest:
      list.sort((a, b) {
        final ta = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
    case _SortOption.updatedOldest:
      list.sort((a, b) {
        final ta = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(0);
        return ta.compareTo(tb);
      });
    case _SortOption.titleAZ:
      list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case _SortOption.titleZA:
      list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    case _SortOption.category:
      list.sort((a, b) {
        final cmp = (a.category ?? '').compareTo(b.category ?? '');
        if (cmp != 0) return cmp;
        return (a.machineCode ?? '').compareTo(b.machineCode ?? '');
      });
  }
  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Danh sách tài liệu (`/documents`): loading / error / empty state,
/// pull-to-refresh, upload chỉ cho QA_ADMIN/ADMIN.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  _SortOption _sort = _SortOption.updatedNewest;

  Future<void> _openUploadSheet(BuildContext context) async {
    final isWide = Responsive.isWide(context);
    final messenger = ScaffoldMessenger.of(context);
    final Object? uploaded;
    if (isWide) {
      uploaded = await showDialog<Object>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: const UploadDocumentSheet(),
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      uploaded = await showModalBottomSheet<Object>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const UploadDocumentSheet(),
      );
    }
    if (uploaded != null && (uploaded == true || uploaded is String)) {
      ref.invalidate(documentsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Uploaded — OCR processing started...')),
      );
      if (uploaded is String && context.mounted) {
        context.push('/documents/$uploaded');
      }
    }
  }

  Future<void> _confirmAndDeleteDocument(
      BuildContext context, String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "$title"? This will permanently remove all versions and related search data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final repo = ref.read(docsRepositoryProvider);
        await repo.deleteDocument(docId);
        ref.invalidate(documentsProvider);
        messenger.showSnackBar(
          const SnackBar(content: Text('Document deleted successfully.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not delete document: $e')),
        );
      }
    }
  }

  // ── Sort bar (mobile: compact dropdown / tablet: filter chips) ───────────

  Widget _buildSortBar(ColorScheme scheme, {required bool isMobile}) {
    if (isMobile) {
      // ── Compact dropdown for narrow phone screens ─────────────────────────
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.sort, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Sort:',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              // Pill-shaped dropdown button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primaryContainer,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_SortOption>(
                    value: _sort,
                    isDense: true,
                    icon: Icon(Icons.expand_more,
                        size: 18, color: scheme.primary),
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _SortOption.values
                        .map((opt) => DropdownMenuItem(
                              value: opt,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(opt.icon,
                                      size: 15,
                                      color: scheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text(opt.label),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _sort = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Scrollable FilterChip row for tablet ─────────────────────────────────
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Sort:',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SortOption.values.map((opt) {
                  final selected = _sort == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: Icon(opt.icon, size: 14),
                      label: Text(opt.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) => setState(() => _sort = opt),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: scheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);
    final canUpload = ref.watch(canUploadProvider);
    final canDelete = ref.watch(canDeleteDocumentProvider);
    final visibleCategories = ref.watch(visibleCategoriesProvider);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.compact;
        final isDesktop = constraints.maxWidth >= Breakpoints.expanded;
        final isTablet = constraints.maxWidth >= Breakpoints.medium &&
            constraints.maxWidth < Breakpoints.expanded;

        return Scaffold(
          body: SafeArea(
            child: docsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorState(
                onRetry: () => ref.invalidate(documentsProvider),
              ),
              data: (allDocs) {
                // Role-based filtering.
                final filtered = visibleCategories.isEmpty
                    ? allDocs
                    : allDocs
                        .where((d) =>
                            d.category == null ||
                            visibleCategories.contains(d.category))
                        .toList();

                // Apply sort.
                final docs = _applySorting(filtered, _sort);

                if (docs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(documentsProvider.future),
                    child: _EmptyState(
                      isAdminLevel: canUpload,
                      onUploadPressed: () => _openUploadSheet(context),
                    ),
                  );
                }

                if (isDesktop) {
                  return _DesktopView(
                    docs: docs,
                    canUpload: canUpload,
                    canDelete: canDelete,
                    sort: _sort,
                    scheme: scheme,
                    onSortChanged: (s) => setState(() => _sort = s),
                    onUpload: () => _openUploadSheet(context),
                    onDelete: (id, title) =>
                        _confirmAndDeleteDocument(context, id, title),
                    onRefresh: () => ref.refresh(documentsProvider.future),
                  );
                }

                // Mobile / tablet list.
                final listBody = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSortBar(scheme, isMobile: isMobile),
                    Expanded(
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final subtitleParts = <String>[
                            if (doc.category != null &&
                                doc.category!.isNotEmpty)
                              doc.category!,
                            if (doc.machineCode != null &&
                                doc.machineCode!.isNotEmpty)
                              'Code: ${doc.machineCode}',
                            if (doc.updatedAt != null &&
                                doc.updatedAt!.isNotEmpty)
                              'Updated: ${_formatRelative(doc.updatedAt)}',
                          ];
                          return RepaintBoundary(
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                              minVerticalPadding: isTablet ? 10 : 14,
                              leading:
                                  const Icon(Icons.description_outlined),
                              title: Text(
                                doc.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: subtitleParts.isEmpty
                                  ? null
                                  : Text(
                                      subtitleParts.join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(fontSize: 12),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete',
                                      onPressed: () =>
                                          _confirmAndDeleteDocument(
                                              context,
                                              doc.id,
                                              doc.title),
                                    ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () =>
                                  context.push('/documents/${doc.id}'),
                            ),
                          ),
                        );
                        },
                      ),
                    ),
                  ],
                );

                final refreshed = RefreshIndicator(
                  onRefresh: () => ref.refresh(documentsProvider.future),
                  child: listBody,
                );

                if (isTablet) {
                  return ConstrainedContent(
                    maxWidth: 840,
                    child: refreshed,
                  );
                }
                return refreshed;
              },
            ),
          ),
          floatingActionButton: (canUpload &&
                  (!isDesktop || docsAsync.value?.isEmpty == true))
              ? Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 16 : 0),
                  child: FloatingActionButton.extended(
                    onPressed: () => _openUploadSheet(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Document'),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop table view
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopView extends StatelessWidget {
  const _DesktopView({
    required this.docs,
    required this.canUpload,
    required this.canDelete,
    required this.sort,
    required this.scheme,
    required this.onSortChanged,
    required this.onUpload,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<DocumentSummary> docs;
  final bool canUpload;
  final bool canDelete;
  final _SortOption sort;
  final ColorScheme scheme;
  final ValueChanged<_SortOption> onSortChanged;
  final VoidCallback onUpload;
  final void Function(String id, String title) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedContent(
            maxWidth: 1400,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Toolbar header ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: [
                          // Sort dropdown
                          DropdownButton<_SortOption>(
                            value: sort,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.sort),
                            borderRadius: BorderRadius.circular(10),
                            items: _SortOption.values
                                .map((opt) => DropdownMenuItem(
                                      value: opt,
                                      child: Row(
                                        children: [
                                          Icon(opt.icon, size: 16),
                                          const SizedBox(width: 8),
                                          Text(opt.label,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) onSortChanged(v);
                            },
                          ),
                          if (canUpload) ...[
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: onUpload,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Document'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 600,
                    child: DataTable2(
                      columnSpacing: 24,
                      horizontalMargin: 12,
                      minWidth: 800,
                      columns: const [
                        DataColumn2(
                          label: Text('Document Name'),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text('Category'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('Machine Code'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('Updated'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text(''),
                          size: ColumnSize.S,
                        ),
                      ],
                      rows: docs.map((doc) {
                        return DataRow2(
                          onTap: () =>
                              context.push('/documents/${doc.id}'),
                          cells: [
                            DataCell(Text(doc.title)),
                            DataCell(Chip(
                              label: Text(doc.category ?? 'OTHER'),
                              visualDensity: VisualDensity.compact,
                            )),
                            DataCell(Text(doc.machineCode ?? '—')),
                            DataCell(
                                Text(_formatInstant(doc.updatedAt) ?? '—')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete document',
                                      onPressed: () =>
                                          onDelete(doc.id, doc.title),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () => context
                                        .push('/documents/${doc.id}'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.isAdminLevel = false, this.onUploadPressed});

  final bool isAdminLevel;
  final VoidCallback? onUploadPressed;

  @override
  Widget build(BuildContext context) {
    // ListView allows pull-to-refresh even when empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (isAdminLevel && onUploadPressed != null)
              FilledButton.icon(
                onPressed: onUploadPressed,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
              ),
          ],
        ),
        const SizedBox(height: 120),
        Icon(Icons.folder_open,
            size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Center(child: Text('No documents found')),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load documents.\nCheck backend connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatting helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a short absolute timestamp, e.g. "01/08/2026 14:30".
String? _formatInstant(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Returns a human-friendly relative time, e.g. "2 hours ago".
/// Falls back to the absolute formatted date for older items.
String _formatRelative(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final diff = DateTime.now().difference(parsed.toLocal());
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _formatInstant(iso) ?? '—';
}
