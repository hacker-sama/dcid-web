import 'package:flutter/material.dart';

import '../common/feature_placeholder.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.folder,
      title: 'Tài liệu',
      note: 'Danh sách tài liệu theo máy/loại; QA upload version.\n'
          'Triển khai M1–M3 (GET /api/documents, upload multipart).',
    );
  }
}
