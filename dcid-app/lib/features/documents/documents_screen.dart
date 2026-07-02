import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/document_summary.dart';
import '../../state/auth_controller.dart';
import '../../state/documents_providers.dart';
import 'upload_document_sheet.dart';

/// Danh sách tài liệu (`/documents`): loading / error / empty state,
/// pull-to-refresh, upload chỉ cho QA_ADMIN/ADMIN.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  Future<void> _openUploadSheet(BuildContext context, WidgetRef ref) async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const UploadDocumentSheet(),
    );
    if (uploaded == true && context.mounted) {
      ref.invalidate(documentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải lên — đang xử lý OCR')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);
    final isAdminLevel =
        ref.watch(authControllerProvider).user?.role.isAdminLevel ?? false;

    return Scaffold(
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(documentsProvider),
        ),
        data: (docs) => RefreshIndicator(
          onRefresh: () => ref.refresh(documentsProvider.future),
          child: docs.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _DocumentTile(document: docs[index]),
                ),
        ),
      ),
      floatingActionButton: isAdminLevel
          ? FloatingActionButton.extended(
              onPressed: () => _openUploadSheet(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Tải tài liệu'),
            )
          : null,
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final DocumentSummary document;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (document.machineCode != null && document.machineCode!.isNotEmpty)
        document.machineCode!,
      if (document.category != null && document.category!.isNotEmpty)
        document.category!,
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        minVerticalPadding: 14,
        leading: const Icon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/documents/${document.id}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // ListView để pull-to-refresh hoạt động cả khi rỗng.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
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
