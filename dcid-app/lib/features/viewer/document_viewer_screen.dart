import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constrained_content.dart';
import '../../core/env.dart';
import '../../data/api_client.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/page_info.dart';
import '../../state/providers.dart';
import 'bbox_painter.dart';

/// Document page viewer with bounding box overlays.
///
/// Displays a page image (from MinIO via `/api/files/{imageKey}`) and
/// draws red rectangles at normalized bbox coordinates using
/// [BBoxOverlayPainter]. Supports pinch-to-zoom via [InteractiveViewer].
///
/// Query params:
/// - `page` (int) — initial page number to display (default: 1).
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({
    required this.versionId,
    this.pageNo,
    this.customBboxes,
    super.key,
  });

  final String versionId;
  final int? pageNo;
  final List<BoundingBox>? customBboxes;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late List<PageInfo> _pages;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    // In Week 1, use mock pages. Later: fetch from API via
    // `GET /api/documents/{id}` → version.pages.
    _pages = MockData.pagesForVersion(widget.versionId);
    _currentPage = (widget.pageNo ?? 1).clamp(1, _pages.isEmpty ? 1 : _pages.length);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tài liệu · ${widget.versionId}'),
        actions: [
          // Page navigation in app bar.
          if (_pages.length > 1) ...[
            IconButton(
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Trang trước',
            ),
            Center(
              child: Text(
                'Trang $_currentPage / ${_pages.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: _currentPage < _pages.length
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Trang sau',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _pages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  const Text('Chưa có dữ liệu trang cho phiên bản này.'),
                ],
              ),
            )
          : ConstrainedContent(
              maxWidth: 1000,
              child: _PageViewer(
                page: _pages[_currentPage - 1],
                bboxes: widget.customBboxes ?? MockData.bboxesForPage(_currentPage),
              ),
            ),
    );
  }
}

/// Renders a single page image with bounding box overlays.
class _PageViewer extends StatelessWidget {
  const _PageViewer({required this.page, required this.bboxes});

  final PageInfo page;
  final List<BoundingBox> bboxes;

  @override
  Widget build(BuildContext context) {
    // In Week 1, we use a placeholder colored box to simulate the page image.
    // When the real backend is ready, replace this with:
    //   Image.network('${Env.apiBaseUrl}/api/files/${page.imageKey}')
    final scheme = Theme.of(context).colorScheme;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: (page.width ?? 1654) / (page.height ?? 2339),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // ── Page image (Real image from API) ─────────────────
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    // Fetch token from secure storage to authenticate image request
                    child: Consumer(
                      builder: (context, ref, child) {
                        return FutureBuilder<String?>(
                          future: ref.read(secureStorageProvider).read(key: ApiClient.tokenKey),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final token = snapshot.data;
                            final imageUrl = '${Env.apiBaseUrl}/api/files/${page.imageKey}';
                            
                            return Image.network(
                              imageUrl,
                              headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _MockPageContent(
                                  pageNo: page.pageNo,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Bounding box overlays ─────────────────────────
                  if (bboxes.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BBoxOverlayPainter(bboxes: bboxes),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Mock page content showing placeholder text to simulate a real page image.
/// Replace with `Image.network(...)` when connected to the real backend.
class _MockPageContent extends StatelessWidget {
  const _MockPageContent({
    required this.pageNo,
    required this.width,
    required this.height,
  });

  final int pageNo;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Simulate a technical document page with mock content.
    return Padding(
      padding: EdgeInsets.all(width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: scheme.primaryContainer.withValues(alpha: 0.3),
            child: Text(
              'SOP Vận hành máy CNC XK-500 — Trang $pageNo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.025,
                color: scheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: height * 0.04),

          // Simulated text lines
          for (var i = 0; i < 8; i++) ...[
            Container(
              height: height * 0.012,
              width: width * (0.5 + (i % 3) * 0.15),
              margin: EdgeInsets.only(bottom: height * 0.015),
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],

          SizedBox(height: height * 0.03),

          // Simulated table / data area (where bboxes will appear)
          Container(
            width: width * 0.7,
            padding: EdgeInsets.all(width * 0.02),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảng thông số kỹ thuật',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.02,
                  ),
                ),
                SizedBox(height: height * 0.01),
                _mockTableRow('Điện áp', '200–230 VAC ±10%', width),
                _mockTableRow('Tần số', '50/60 Hz', width),
                _mockTableRow('Dòng định mức', '3.5A', width),
                _mockTableRow('Công suất', '750W', width),
              ],
            ),
          ),

          const Spacer(),

          // Footer
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Trang $pageNo',
              style: TextStyle(
                fontSize: width * 0.018,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockTableRow(String label, String value, double parentWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: parentWidth * 0.005),
      child: Row(
        children: [
          SizedBox(
            width: parentWidth * 0.2,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
