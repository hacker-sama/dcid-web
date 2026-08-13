import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constrained_content.dart';
import '../../core/file_viewer/file_viewer.dart';
import '../../data/models/document_detail.dart';
import '../../state/documents_providers.dart';
import '../../state/providers.dart';
import '../../state/role_filter.dart';

/// Chi tiết tài liệu (`/documents/:id`): thông tin + danh sách version
/// với chip trạng thái màu (PLAN-FLUTTER-DOCS.md §2-mục-5).
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(documentDetailProvider(documentId));
    final isAdminLevel = ref.watch(canUploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          if (isAdminLevel)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa tài liệu',
              onPressed: () async {
                final title = detailAsync.value?.document.title ?? 'tài liệu này';
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa tài liệu'),
                    content: Text('Bạn có chắc chắn muốn xóa "$title"? Hành động này không thể hoàn tác.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final repo = ref.read(docsRepositoryProvider);
                    await repo.deleteDocument(documentId);
                    ref.invalidate(documentsProvider);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Đã xóa tài liệu thành công.')),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Không thể xóa tài liệu: $e')),
                    );
                  }
                }
              },
            ),
        ],
      ),

      body: detailAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không tải được chi tiết tài liệu.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(documentDetailProvider(documentId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(documentDetailProvider(documentId).future),
          child: ConstrainedContent(
            maxWidth: 840,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _DocumentInfoCard(detail: detail),
                const SizedBox(height: 16),
                Text('Phiên bản', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (detail.versions.isEmpty)
                  const Text('Chưa có phiên bản nào.')
                else
                  for (final version in detail.versions) ...[
                    _VersionTile(documentId: documentId, version: version),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentInfoCard extends StatelessWidget {
  const _DocumentInfoCard({required this.detail});

  final DocumentDetail detail;

  @override
  Widget build(BuildContext context) {
    final doc = detail.document;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _InfoRow(label: 'Mã máy', value: doc.machineCode),
            _InfoRow(label: 'Loại', value: doc.category),
            _InfoRow(label: 'Vai tối thiểu', value: doc.minRole),
            _InfoRow(label: 'Mô tả', value: doc.description),
            _InfoRow(label: 'Tạo lúc', value: _formatInstant(doc.createdAt)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

class _VersionTile extends ConsumerWidget {
  const _VersionTile({required this.documentId, required this.version});

  final String documentId;
  final VersionSummary version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimmed =
        version.status == 'SUPERSEDED' || version.status == 'OBSOLETE';
    final subtitleParts = [
      if (version.originalFilename != null) version.originalFilename!,
      if (version.pageCount != null) '${version.pageCount} trang',
      if (version.lang != null) version.lang!,
      if (version.fileSize != null) _formatBytes(version.fileSize!),
      if (version.ingestedAt != null)
        'ingest: ${_formatInstant(version.ingestedAt)}',
    ];
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              minVerticalPadding: 14,
              leading: CircleAvatar(child: Text('v${version.versionNo}')),
              title: Text('Phiên bản ${version.versionNo}'),
              subtitle: subtitleParts.isEmpty
                  ? null
                  : Text(subtitleParts.join(' · ')),
              trailing: _StatusChip(status: version.status),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _viewPdf(context, ref),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Xem PDF gốc'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _viewOcr(context, ref),
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Xem chữ OCR'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewPdf(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải file PDF...')),
      );
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        '/api/documents/$documentId/versions/${version.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as Uint8List;
      openOrDownloadFile(
        bytes,
        version.originalFilename ?? 'v${version.versionNo}.pdf',
        'application/pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được file PDF: $e')),
        );
      }
    }
  }

  Future<void> _viewOcr(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final dio = ref.read(apiClientProvider).dio;
      final response =
          await dio.get('/api/documents/$documentId/versions/${version.id}/pages');
      if (context.mounted) Navigator.pop(context); // close progress

      final data = (response.data?['data'] as List<dynamic>?) ?? [];
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
              'Văn bản OCR (${version.originalFilename ?? 'v${version.versionNo}'})'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: data.isEmpty
                ? const Center(
                    child: Text('Chưa có dữ liệu OCR cho phiên bản này.'))
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (_, index) {
                      final item = data[index] as Map<String, dynamic>;
                      final pageNo = item['pageNo'] ?? (index + 1);
                      final text = item['ocrText'] ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trang $pageNo',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          SelectableText(text.isEmpty
                              ? '(Trang trắng / không có chữ)'
                              : text),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close progress if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được dữ liệu OCR: $e')),
        );
      }
    }
  }
}

/// Chip trạng thái version: PROCESSING=xám/loading, ACTIVE=xanh, FAILED=đỏ,
/// SUPERSEDED/OBSOLETE=mờ (mờ áp ở tile), READY=xanh dương.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, Widget? leading) = switch (status) {
      'PROCESSING' => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      'READY' => (Colors.blue.shade100, Colors.blue.shade900, null),
      'ACTIVE' => (Colors.green.shade100, Colors.green.shade900, null),
      'FAILED' => (scheme.errorContainer, scheme.onErrorContainer, null),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Text(
            status,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
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

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}
