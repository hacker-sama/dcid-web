import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constrained_content.dart';
import '../../core/file_viewer/file_viewer.dart';
import '../../core/localization/locale_controller.dart';
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
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.documentDetail),
        actions: [
          if (isAdminLevel)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: strings.deleteDocument,
              onPressed: () async {
                final title = detailAsync.value?.document.title ?? strings.documentDetail;
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
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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
                    await repo.deleteDocument(documentId);
                    ref.invalidate(documentsProvider);
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.deleteSuccess)),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.deleteFailed(e.toString()))),
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
                strings.loadDetailFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(documentDetailProvider(documentId)),
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
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
                _DocumentInfoCard(detail: detail, strings: strings),
                const SizedBox(height: 16),
                Text(strings.versionsList, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (detail.versions.isEmpty)
                  Text(strings.noVersions)
                else
                  for (final version in detail.versions) ...[
                    _VersionTile(documentId: documentId, version: version, strings: strings),
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
  const _DocumentInfoCard({required this.detail, required this.strings});

  final DocumentDetail detail;
  final dynamic strings;

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
            _InfoRow(label: strings.machineCode, value: doc.machineCode),
            _InfoRow(label: strings.category, value: doc.category),
            _InfoRow(label: strings.minRole, value: doc.minRole),
            _InfoRow(label: strings.description, value: doc.description),
            _InfoRow(label: strings.createdAt, value: _formatInstant(doc.createdAt)),
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
  const _VersionTile({required this.documentId, required this.version, required this.strings});

  final String documentId;
  final VersionSummary version;
  final dynamic strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimmed =
        version.status == 'SUPERSEDED' || version.status == 'OBSOLETE';
    final subtitleParts = [
      if (version.originalFilename != null) version.originalFilename!,
      if (version.pageCount != null) '${version.pageCount} ${strings.pageNumber(version.pageCount!).toLowerCase()}',
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
              title: Text(strings.versionNumber(version.versionNo)),
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
                    label: Text(strings.viewOriginalPdf),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _viewOcr(context),
                    icon: const Icon(Icons.description, size: 18),
                    label: Text(strings.viewOcrText),
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
        SnackBar(
          content: Text(strings.loadingPdf),
          duration: const Duration(seconds: 2),
        ),
      );
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        '/api/documents/$documentId/versions/${version.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      final dynamic rawData = response.data;
      final Uint8List bytes;
      if (rawData is Uint8List) {
        bytes = rawData;
      } else if (rawData is List<int>) {
        bytes = Uint8List.fromList(rawData);
      } else {
        throw Exception(strings.invalidBinaryData);
      }
      openOrDownloadFile(
        bytes,
        version.originalFilename ?? 'v${version.versionNo}.pdf',
        'application/pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.downloadPdfFailed(e.toString()))),
        );
      }
    }
  }

  void _viewOcr(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _OcrViewerDialog(
        documentId: documentId,
        version: version,
      ),
    );
  }
}

/// Dialog hiển thị nội dung văn bản OCR cho phiên bản tài liệu.
class _OcrViewerDialog extends ConsumerStatefulWidget {
  const _OcrViewerDialog({
    required this.documentId,
    required this.version,
  });

  final String documentId;
  final VersionSummary version;

  @override
  ConsumerState<_OcrViewerDialog> createState() => _OcrViewerDialogState();
}

class _OcrViewerDialogState extends ConsumerState<_OcrViewerDialog> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pages = [];
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchOcr();
  }

  Future<void> _fetchOcr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        '/api/documents/${widget.documentId}/versions/${widget.version.id}/pages',
      );
      final rawList = (response.data?['data'] as List<dynamic>?) ?? [];
      final pages = rawList
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
      if (mounted) {
        setState(() {
          _pages = pages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _copyAllText() {
    final strings = ref.read(appStringsProvider);
    final buffer = StringBuffer();
    for (var i = 0; i < _pages.length; i++) {
      final item = _pages[i];
      final pageNo = item['pageNo'] ?? (i + 1);
      final text = item['ocrText'] ?? '';
      buffer.writeln('--- ${strings.pageNumber(pageNo)} ---');
      buffer.writeln(text);
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.allOcrCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final name = widget.version.originalFilename ?? 'v${widget.version.versionNo}';
    final title = strings.ocrDialogTitle(name);
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (_loading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.loadingOcrData),
          ],
        ),
      );
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: scheme.error, size: 40),
              const SizedBox(height: 12),
              Text(
                strings.loadOcrFailed(_error!),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchOcr,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    } else if (_pages.isEmpty) {
      body = Center(
        child: Text(strings.noOcrData),
      );
    } else {
      final filteredPages = _filterQuery.trim().isEmpty
          ? _pages
          : _pages.where((item) {
              final text = (item['ocrText'] as String? ?? '').toLowerCase();
              return text.contains(_filterQuery.toLowerCase());
            }).toList();

      body = Column(
        children: [
          if (_pages.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: strings.searchOcrKeyword,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _filterQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _filterQuery = val),
              ),
            ),
          ],
          Expanded(
            child: filteredPages.isEmpty
                ? Center(
                    child: Text(strings.noOcrPagesMatch),
                  )
                : ListView.separated(
                    itemCount: filteredPages.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (ctx, index) {
                      final item = filteredPages[index];
                      final pageNo = item['pageNo'] ?? (index + 1);
                      final text = item['ocrText'] as String? ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                strings.pageNumber(pageNo),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  tooltip: strings.copyPage(pageNo),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(strings.pageCopied(pageNo)),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            text.isEmpty
                                ? strings.blankPageNotice
                                : text,
                            style: TextStyle(
                              color: text.isEmpty ? scheme.outline : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 650,
        height: 480,
        child: body,
      ),
      actions: [
        if (!_loading && _error == null && _pages.isNotEmpty)
          OutlinedButton.icon(
            onPressed: _copyAllText,
            icon: const Icon(Icons.copy_all, size: 16),
            label: Text(strings.copyAllOcr),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
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
