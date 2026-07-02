import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/document_detail.dart';
import '../../state/documents_providers.dart';

/// Chi tiết tài liệu (`/documents/:id`): thông tin + danh sách version
/// với chip trạng thái màu (PLAN-FLUTTER-DOCS.md §2-mục-5).
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tài liệu')),
      body: detailAsync.when(
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
                  _VersionTile(version: version),
                  const SizedBox(height: 8),
                ],
            ],
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

class _VersionTile extends StatelessWidget {
  const _VersionTile({required this.version});

  final VersionSummary version;

  @override
  Widget build(BuildContext context) {
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
        child: ListTile(
          minVerticalPadding: 14,
          leading: CircleAvatar(child: Text('v${version.versionNo}')),
          title: Text('Phiên bản ${version.versionNo}'),
          subtitle:
              subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
          trailing: _StatusChip(status: version.status),
        ),
      ),
    );
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
