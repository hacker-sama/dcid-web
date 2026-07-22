import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../core/responsive.dart';
import '../../core/constrained_content.dart';
import '../../state/auth_controller.dart';
import '../../state/documents_providers.dart';
import 'upload_document_sheet.dart';

/// Danh sách tài liệu (`/documents`): loading / error / empty state,
/// pull-to-refresh, upload chỉ cho QA_ADMIN/ADMIN.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  Future<void> _openUploadSheet(BuildContext context, WidgetRef ref) async {
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
        const SnackBar(content: Text('Đã tải lên — đang xử lý OCR...')),
      );
      if (uploaded is String && context.mounted) {
        context.push('/documents/$uploaded');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);
    final isAdminLevel =
        ref.watch(authControllerProvider).user?.role.isAdminLevel ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= Breakpoints.expanded;
        final isTablet = constraints.maxWidth >= Breakpoints.medium &&
            constraints.maxWidth < Breakpoints.expanded;

        return Scaffold(
          body: docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _ErrorState(
              onRetry: () => ref.invalidate(documentsProvider),
            ),
            data: (docs) {
              if (docs.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(documentsProvider.future),
                  child: _EmptyState(
                    isAdminLevel: isAdminLevel,
                    onUploadPressed: () => _openUploadSheet(context, ref),
                  ),
                );
              }

              if (isDesktop) {
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(documentsProvider.future),
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
                              // Toolbar header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Danh sách tài liệu',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  if (isAdminLevel)
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _openUploadSheet(context, ref),
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Tải tài liệu'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 600, // Chiều cao hợp lý cho bảng
                                child: DataTable2(
                                  columnSpacing: 24,
                                  horizontalMargin: 12,
                                  minWidth: 800,
                                  columns: const [
                                    DataColumn2(
                                      label: Text('Tên tài liệu'),
                                      size: ColumnSize.L,
                                    ),
                                    DataColumn2(
                                      label: Text('Loại'),
                                      size: ColumnSize.M,
                                    ),
                                    DataColumn2(
                                      label: Text('Mã máy'),
                                      size: ColumnSize.M,
                                    ),
                                    DataColumn2(
                                      label: Text('Cập nhật'),
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
                                        DataCell(Text(
                                            _formatInstant(doc.updatedAt) ?? '—')),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right),
                                            onPressed: () =>
                                                context.push('/documents/${doc.id}'),
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

              // Mobile and Tablet views
              final listView = ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final subtitleParts = [
                    if (doc.machineCode != null && doc.machineCode!.isNotEmpty)
                      doc.machineCode!,
                    if (doc.category != null && doc.category!.isNotEmpty)
                      doc.category!,
                  ];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      dense: isTablet, // dense is true on tablet
                      minVerticalPadding: isTablet ? 10 : 14,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(doc.title),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(subtitleParts.join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/documents/${doc.id}'),
                    ),
                  );
                },
              );

              if (isTablet) {
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(documentsProvider.future),
                  child: ConstrainedContent(
                    maxWidth: 840,
                    child: listView,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(documentsProvider.future),
                child: listView,
              );
            },
          ),
          floatingActionButton: (isAdminLevel && (!isDesktop || docsAsync.value?.isEmpty == true))
              ? FloatingActionButton.extended(
                  onPressed: () => _openUploadSheet(context, ref),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Tải tài liệu'),
                )
              : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.isAdminLevel = false, this.onUploadPressed});

  final bool isAdminLevel;
  final VoidCallback? onUploadPressed;

  @override
  Widget build(BuildContext context) {
    // ListView để pull-to-refresh hoạt động cả khi rỗng.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách tài liệu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (isAdminLevel && onUploadPressed != null)
              FilledButton.icon(
                onPressed: onUploadPressed,
                icon: const Icon(Icons.upload_file),
                label: const Text('Tải tài liệu'),
              ),
          ],
        ),
        const SizedBox(height: 120),
        Icon(Icons.folder_open,
            size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Center(child: Text('Chưa có tài liệu')),
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
            'Không tải được danh sách tài liệu.\nKiểm tra kết nối backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

String? _formatInstant(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
