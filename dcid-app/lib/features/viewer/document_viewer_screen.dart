import 'package:flutter/material.dart';

import '../common/feature_placeholder.dart';

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({required this.versionId, super.key});

  final String versionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tài liệu · $versionId')),
      body: const FeaturePlaceholder(
        icon: Icons.picture_as_pdf,
        title: 'Viewer bản vẽ',
        note: 'Hiển thị ảnh trang + overlay khoanh đỏ bbox số liệu (Stack + CustomPaint).\n'
            'Triển khai M2–M4 (pdfx cho PDF; ảnh crop từ /api/files).',
      ),
    );
  }
}
