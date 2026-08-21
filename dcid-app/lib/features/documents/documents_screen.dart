import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constrained_content.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/responsive.dart';
import '../../data/models/document_summary.dart';
import '../../state/documents_providers.dart';
import '../../state/ingest_progress_provider.dart';
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
  String localized(AppStrings strings) {
    switch (this) {
      case _SortOption.updatedNewest:
        return strings.sortNewest;
      case _SortOption.updatedOldest:
        return strings.sortOldest;
      case _SortOption.titleAZ:
        return strings.sortTitleAZ;
      case _SortOption.titleZA:
        return strings.sortTitleZA;
      case _SortOption.category:
        return strings.sortCategory;
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
        final ca = a.category ?? '';
        final cb = b.category ?? '';
        final cmp = ca.compareTo(cb);
        if (cmp != 0) return cmp;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
  }
  return list;
}

Color _getCategoryColor(String? category) {
  final c = (category ?? '').trim().toUpperCase();
  switch (c) {
    case 'SOP':
      return Colors.teal;
    case 'CIRCUIT':
      return Colors.indigo;
    case 'SAFETY':
      return Colors.deepOrange;
    case 'MANUAL':
      return Colors.blue;
    case 'SPEC':
      return Colors.purple;
    default:
      return Colors.blueGrey;
  }
}

Widget _buildCategoryBadge(String? category, ColorScheme scheme) {
  final text = (category == null || category.trim().isEmpty)
      ? 'OTHER'
      : category.trim().toUpperCase();
  final color = _getCategoryColor(text);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      ),
    ),
  );
}

/// Màn hình danh sách tài liệu (`/documents`):
/// - Role-based filtering.
/// - Thanh Filter: Tìm kiếm real-time (tên, mã máy, danh mục), lọc Category, Sort.
/// - Phân trang (Pagination): Desktop (bảng co giãn mượt mà + footer phân trang) và Mobile/Tablet.
/// - Desktop (≥1024px): DataTable trong Card shrink-wrap không bị cắt góc.
/// - Tablet (600–1023px) & Mobile (<600px): Card list kèm thanh filter và phân trang gọn gàng.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  _SortOption _sort = _SortOption.updatedNewest;
  int _currentPage = 1;
  int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = '';
      _sort = _SortOption.updatedNewest;
      _currentPage = 1;
    });
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory.isNotEmpty ||
      _sort != _SortOption.updatedNewest;

  // ── Open upload modal ─────────────────────────────────────────────────────

  Future<void> _openUploadSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    final Object? uploaded;
    if (isDesktop) {
      uploaded = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
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
      final strings = ref.read(appStringsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.uploadSuccessSnackbar)),
      );
      if (uploaded is String && context.mounted) {
        context.push('/documents/$uploaded');
      }
    }
  }

  Future<void> _confirmAndDeleteDocument(
      BuildContext context, String docId, String title) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.confirmDelete),
        content: Text(strings.deleteConfirmDesc(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.delete),
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
          SnackBar(content: Text(strings.deleteSuccess)),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.deleteFailed(e.toString()))),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);
    final canUpload = ref.watch(canUploadProvider);
    final canDelete = ref.watch(canDeleteDocumentProvider);
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.watch(appStringsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.compact;
        final isDesktop = constraints.maxWidth >= Breakpoints.expanded;
        final isTablet = constraints.maxWidth >= Breakpoints.medium &&
            constraints.maxWidth < Breakpoints.expanded;

        return Scaffold(
          body: SafeArea(
            child: docsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorState(
                strings: strings,
                onRetry: () => ref.invalidate(documentsProvider),
              ),
              data: (allDocs) {
                // 1. Role-based filtering — handled by backend (GET /api/documents
                //    returns only documents accessible to the current user's minRole).
                //    Client-side category filtering was removed to avoid a double-filter
                //    mismatch between minRole (backend) and category (client).
                final roleFiltered = allDocs;

                // Build category list dynamically from available docs
                final extractedCategories = <String>{};
                for (final d in roleFiltered) {
                  final cat = (d.category ?? '').trim().toUpperCase();
                  if (cat.isNotEmpty) extractedCategories.add(cat);
                }
                final standardCats = {'SOP', 'DRAWING', 'CIRCUIT', 'SAFETY', 'MAINTENANCE_LOG', 'OTHER'};
                final availableCategories =
                    {...standardCats, ...extractedCategories}.toList()..sort();

                // 2. Category filtering
                final categoryFiltered = (_selectedCategory.isEmpty ||
                        _selectedCategory == 'ALL')
                    ? roleFiltered
                    : roleFiltered
                        .where((d) =>
                            (d.category ?? 'OTHER').trim().toUpperCase() ==
                            _selectedCategory.toUpperCase())
                        .toList();

                // 3. Search query filtering (Title, Machine Code, Category)
                final query = _searchController.text.trim().toLowerCase();
                final searchFiltered = query.isEmpty
                    ? categoryFiltered
                    : categoryFiltered.where((d) {
                        final matchesTitle =
                            d.title.toLowerCase().contains(query);
                        final matchesCode =
                            (d.machineCode ?? '').toLowerCase().contains(query);
                        final matchesCategory =
                            (d.category ?? '').toLowerCase().contains(query);
                        return matchesTitle || matchesCode || matchesCategory;
                      }).toList();

                // 4. Sorting
                final sortedDocs = _applySorting(searchFiltered, _sort);

                // 5. Pagination calculations
                final totalItems = sortedDocs.length;
                final totalPages =
                    (totalItems / _pageSize).ceil().clamp(1, 999999).toInt();
                final safePage = _currentPage.clamp(1, totalPages);
                final startIndex =
                    totalItems == 0 ? 0 : (safePage - 1) * _pageSize;
                final endIndex =
                    (startIndex + _pageSize).clamp(0, totalItems);
                final pageDocs = totalItems == 0
                    ? <DocumentSummary>[]
                    : sortedDocs.sublist(startIndex, endIndex);

                if (isDesktop) {
                  return _DesktopView(
                    allDocs: allDocs,
                    filteredDocs: sortedDocs,
                    pageDocs: pageDocs,
                    totalItems: totalItems,
                    currentPage: safePage,
                    totalPages: totalPages,
                    pageSize: _pageSize,
                    startIndex: startIndex,
                    endIndex: endIndex,
                    availableCategories: availableCategories,
                    selectedCategory: _selectedCategory,
                    searchController: _searchController,
                    hasActiveFilters: _hasActiveFilters,
                    canUpload: canUpload,
                    canDelete: canDelete,
                    sort: _sort,
                    scheme: scheme,
                    strings: strings,
                    onSearchChanged: () =>
                        setState(() => _currentPage = 1),
                    onCategoryChanged: (cat) => setState(() {
                      _selectedCategory = cat;
                      _currentPage = 1;
                    }),
                    onSortChanged: (s) => setState(() => _sort = s),
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    onPageSizeChanged: (s) => setState(() {
                      _pageSize = s;
                      _currentPage = 1;
                    }),
                    onClearFilters: _clearFilters,
                    onUpload: () => _openUploadSheet(context),
                    onDelete: (id, title) =>
                        _confirmAndDeleteDocument(context, id, title),
                    onRefresh: () =>
                        ref.refresh(documentsProvider.future),
                  );
                }

                // Mobile & Tablet view
                return _MobileTabletView(
                  allDocs: allDocs,
                  filteredDocs: sortedDocs,
                  pageDocs: pageDocs,
                  totalItems: totalItems,
                  currentPage: safePage,
                  totalPages: totalPages,
                  pageSize: _pageSize,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  availableCategories: availableCategories,
                  selectedCategory: _selectedCategory,
                  searchController: _searchController,
                  hasActiveFilters: _hasActiveFilters,
                  isTablet: isTablet,
                  isMobile: isMobile,
                  canUpload: canUpload,
                  canDelete: canDelete,
                  sort: _sort,
                  scheme: scheme,
                  strings: strings,
                  onSearchChanged: () =>
                      setState(() => _currentPage = 1),
                  onCategoryChanged: (cat) => setState(() {
                    _selectedCategory = cat;
                    _currentPage = 1;
                  }),
                  onSortChanged: (s) => setState(() => _sort = s),
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  onClearFilters: _clearFilters,
                  onUpload: () => _openUploadSheet(context),
                  onDelete: (id, title) =>
                      _confirmAndDeleteDocument(context, id, title),
                  onRefresh: () =>
                      ref.refresh(documentsProvider.future),
                );
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
                    label: Text(strings.uploadNewDocument),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop view (Adaptive Card + Natural Scroll + Table + Pagination)
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopView extends StatelessWidget {
  const _DesktopView({
    required this.allDocs,
    required this.filteredDocs,
    required this.pageDocs,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.startIndex,
    required this.endIndex,
    required this.availableCategories,
    required this.selectedCategory,
    required this.searchController,
    required this.hasActiveFilters,
    required this.canUpload,
    required this.canDelete,
    required this.sort,
    required this.scheme,
    required this.strings,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.onClearFilters,
    required this.onUpload,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<DocumentSummary> allDocs;
  final List<DocumentSummary> filteredDocs;
  final List<DocumentSummary> pageDocs;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int startIndex;
  final int endIndex;
  final List<String> availableCategories;
  final String selectedCategory;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final bool canUpload;
  final bool canDelete;
  final _SortOption sort;
  final ColorScheme scheme;
  final AppStrings strings;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onUpload;
  final void Function(String id, String title) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          ConstrainedContent(
            maxWidth: 1400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Header Toolbar ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.documentsTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.documentsSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (canUpload)
                      FilledButton.icon(
                        onPressed: onUpload,
                        icon: const Icon(Icons.upload_file),
                        label: Text(strings.uploadNewDocument),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Ingestion Progress Banners
                const _IngestProgressBannerList(),

                // ── 2. Filter & Search Card ───────────────────────────────────
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Search Field
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              controller: searchController,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) => onSearchChanged(),
                              decoration: InputDecoration(
                                hintText: strings.searchDocsPlaceholder,
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: scheme.outline,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: scheme.outline,
                                ),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          searchController.clear();
                                          onSearchChanged();
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: scheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Category Dropdown
                        SizedBox(
                          width: 180,
                          height: 42,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: strings.docTableCategory,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: scheme.outline,
                              ),
                              floatingLabelStyle: TextStyle(
                                fontSize: 12,
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory.isEmpty ? 'ALL' : selectedCategory,
                                borderRadius: BorderRadius.circular(10),
                                menuMaxHeight: 300,
                                isExpanded: true,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: scheme.outline,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text(
                                      strings.allCategories,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  ...availableCategories.map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      )),
                                ],
                                onChanged: (v) =>
                                    onCategoryChanged(v == 'ALL' ? '' : (v ?? '')),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Sort Dropdown
                        SizedBox(
                          width: 190,
                          height: 42,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: strings.sortBy,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: scheme.outline,
                              ),
                              floatingLabelStyle: TextStyle(
                                fontSize: 12,
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: scheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<_SortOption>(
                                value: sort,
                                borderRadius: BorderRadius.circular(10),
                                menuMaxHeight: 300,
                                isExpanded: true,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: scheme.outline,
                                ),
                                items: _SortOption.values
                                    .map((opt) => DropdownMenuItem(
                                          value: opt,
                                          child: Row(
                                            children: [
                                              Icon(opt.icon,
                                                  size: 14,
                                                  color: scheme.onSurfaceVariant),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  opt.localized(strings),
                                                  overflow: TextOverflow.ellipsis,
                                                  style:
                                                      const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) onSortChanged(v);
                                },
                              ),
                            ),
                          ),
                        ),

                        // Clear Filters Button
                        if (hasActiveFilters) ...[
                          const SizedBox(width: 10),
                          IconButton.outlined(
                            tooltip: strings.clearFilters,
                            icon: const Icon(Icons.filter_alt_off_rounded,
                                size: 18),
                            onPressed: onClearFilters,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3. Table Card (Shrink-wrap height + Pagination footer) ────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (totalItems == 0)
                          Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open,
                                      size: 52, color: scheme.outline),
                                  const SizedBox(height: 12),
                                  Text(
                                    strings.noDocsFound,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    strings.noDocsFoundDesc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (hasActiveFilters) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: onClearFilters,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: Text(strings.clearFilters),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, tableConstraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: tableConstraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowHeight: 48,
                                    dataRowMinHeight: 54,
                                    dataRowMaxHeight: 60,
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(
                                      scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          strings.docTableTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          strings.docTableCategory,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          strings.docTableMachineCode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          strings.docTableUpdated,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            strings.docTableActions,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: pageDocs.map((doc) {
                                      return DataRow(
                                        onSelectChanged: (_) => context
                                            .push('/documents/${doc.id}'),
                                        cells: [
                                          // Title
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.description_outlined,
                                                  size: 18,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 10),
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 380),
                                                  child: Text(
                                                    doc.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Category Badge
                                          DataCell(
                                            _buildCategoryBadge(
                                                doc.category, scheme),
                                          ),
                                          // Machine Code
                                          DataCell(
                                            Text(
                                              doc.machineCode?.isNotEmpty == true
                                                  ? doc.machineCode!
                                                  : '—',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: doc.machineCode
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? scheme.onSurface
                                                    : scheme.outline,
                                                fontFamily: doc.machineCode
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? 'monospace'
                                                    : null,
                                                fontWeight: doc.machineCode
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          // Updated At
                                          DataCell(
                                            Text(
                                              _formatInstant(doc.updatedAt) ??
                                                  '—',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          // Actions
                                          DataCell(
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (canDelete)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      tooltip:
                                                          strings.deleteDocument,
                                                      onPressed: () => onDelete(
                                                          doc.id, doc.title),
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.chevron_right,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => context
                                                        .push('/documents/${doc.id}'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),

                        // ── 4. Pagination Footer ─────────────────────────────
                        if (totalItems > 0) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Total records counter
                                Text(
                                  strings.showingDocsCount(
                                    startIndex + 1,
                                    endIndex,
                                    totalItems,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                // Rows per page & Navigation controls
                                Row(
                                  children: [
                                    Text(
                                      strings.rowsPerPage,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: pageSize,
                                        isDense: true,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.onSurface,
                                        ),
                                        items: [10, 25, 50]
                                            .map((s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text('$s'),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) onPageSizeChanged(v);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),

                                    // First Page
                                    IconButton(
                                      icon: const Icon(Icons.first_page,
                                          size: 18),
                                      tooltip: strings.firstPage,
                                      onPressed: currentPage > 1
                                          ? () => onPageChanged(1)
                                          : null,
                                    ),

                                    // Previous Page
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left,
                                          size: 18),
                                      tooltip: strings.previousPage,
                                      onPressed: currentPage > 1
                                          ? () =>
                                              onPageChanged(currentPage - 1)
                                          : null,
                                    ),

                                    // Page Number Indicator
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Text(
                                        strings.pageOf(
                                            currentPage, totalPages),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),

                                    // Next Page
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right,
                                          size: 18),
                                      tooltip: strings.nextPage,
                                      onPressed: currentPage < totalPages
                                          ? () =>
                                              onPageChanged(currentPage + 1)
                                          : null,
                                    ),

                                    // Last Page
                                    IconButton(
                                      icon: const Icon(Icons.last_page,
                                          size: 18),
                                      tooltip: strings.lastPage,
                                      onPressed: currentPage < totalPages
                                          ? () => onPageChanged(totalPages)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile & Tablet view (Card list + Filter chips + Pagination bar)
// ─────────────────────────────────────────────────────────────────────────────

class _MobileTabletView extends StatelessWidget {
  const _MobileTabletView({
    required this.allDocs,
    required this.filteredDocs,
    required this.pageDocs,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.startIndex,
    required this.endIndex,
    required this.availableCategories,
    required this.selectedCategory,
    required this.searchController,
    required this.hasActiveFilters,
    required this.isTablet,
    required this.isMobile,
    required this.canUpload,
    required this.canDelete,
    required this.sort,
    required this.scheme,
    required this.strings,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onClearFilters,
    required this.onUpload,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<DocumentSummary> allDocs;
  final List<DocumentSummary> filteredDocs;
  final List<DocumentSummary> pageDocs;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int startIndex;
  final int endIndex;
  final List<String> availableCategories;
  final String selectedCategory;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final bool isTablet;
  final bool isMobile;
  final bool canUpload;
  final bool canDelete;
  final _SortOption sort;
  final ColorScheme scheme;
  final AppStrings strings;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onUpload;
  final void Function(String id, String title) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final listBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _IngestProgressBannerList(),

        // ── Search field ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: searchController,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              textAlignVertical: TextAlignVertical.center,
              onChanged: (_) => onSearchChanged(),
              decoration: InputDecoration(
                hintText: strings.searchDocsPlaceholder,
                hintStyle: TextStyle(fontSize: 13, color: scheme.outline),
                prefixIcon: Icon(Icons.search, size: 18, color: scheme.outline),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),

        // ── Category FilterChips row ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(strings.allCategories,
                        style: const TextStyle(fontSize: 12)),
                    selected: selectedCategory.isEmpty,
                    onSelected: (_) => onCategoryChanged(''),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: scheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selectedCategory.isEmpty
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: selectedCategory.isEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                ...availableCategories.map((cat) {
                  final selected =
                      selectedCategory.toUpperCase() == cat.toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) => onCategoryChanged(selected ? '' : cat),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: scheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ── Sort bar ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              Icon(Icons.sort, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${strings.sortBy}:',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primaryContainer,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_SortOption>(
                    value: sort,
                    isDense: true,
                    icon: Icon(Icons.expand_more,
                        size: 16, color: scheme.primary),
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(
                      fontSize: 12,
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
                                      size: 14, color: scheme.onSurface),
                                  const SizedBox(width: 6),
                                  Text(opt.localized(strings)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onSortChanged(v);
                    },
                  ),
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: strings.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClearFilters,
                ),
              ],
            ],
          ),
        ),

        // ── Document cards list ───────────────────────────────────────────────
        Expanded(
          child: totalItems == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open,
                            size: 48, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          strings.noDocsFound,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.noDocsFoundDesc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: onClearFilters,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: Text(strings.clearFilters),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: pageDocs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = pageDocs[index];
                    return RepaintBoundary(
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/documents/${doc.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        doc.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (canDelete)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: strings.deleteDocument,
                                        onPressed: () => onDelete(
                                            doc.id, doc.title),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    _buildCategoryBadge(
                                        doc.category, scheme),
                                    if (doc.machineCode != null &&
                                        doc.machineCode!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Code: ${doc.machineCode}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    if (doc.updatedAt != null &&
                                        doc.updatedAt!.isNotEmpty)
                                      Text(
                                        _formatRelative(doc.updatedAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // ── Mobile/Tablet Pagination Footer ──────────────────────────────────
        if (totalItems > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${startIndex + 1}–$endIndex / $totalItems',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: strings.previousPage,
                      onPressed: currentPage > 1
                          ? () => onPageChanged(currentPage - 1)
                          : null,
                    ),
                    Text(
                      '$currentPage / $totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      tooltip: strings.nextPage,
                      onPressed: currentPage < totalPages
                          ? () => onPageChanged(currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );

    final refreshed = RefreshIndicator(
      onRefresh: onRefresh,
      child: listBody,
    );

    if (isTablet) {
      return ConstrainedContent(
        maxWidth: 840,
        child: refreshed,
      );
    }
    return refreshed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.strings});

  final VoidCallback onRetry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${strings.error}: Could not load documents.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(strings.retry),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Ingestion Progress Banners (STOMP WebSocket)
// ─────────────────────────────────────────────────────────────────────────────

class _IngestProgressBannerList extends ConsumerWidget {
  const _IngestProgressBannerList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressMap = ref.watch(ingestProgressProvider);
    if (progressMap.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: progressMap.entries.map((entry) {
        final versionId = entry.key;
        final msg = entry.value;

        Color cardColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
        Color accentColor = Colors.blue.shade700;
        IconData statusIcon = Icons.hourglass_top_rounded;

        if (msg.isDone) {
          cardColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
          accentColor = Colors.green.shade700;
          statusIcon = Icons.check_circle_rounded;
        } else if (msg.isFailed) {
          cardColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
          accentColor = Colors.red.shade700;
          statusIcon = Icons.error_outline_rounded;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: accentColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      msg.message.isNotEmpty
                          ? msg.message
                          : 'Processing document pipeline...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${msg.step} (${msg.progress}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  if (msg.isDone || msg.isFailed) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref.read(ingestProgressProvider.notifier).untrack(versionId);
                        ref.invalidate(documentsProvider);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: msg.progress > 0 ? (msg.progress / 100.0) : null,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
