import 'package:flutter/material.dart';

import '../common/feature_placeholder.dart';

class SnapAskScreen extends StatelessWidget {
  const SnapAskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.camera_alt,
      title: 'Snap & Ask',
      note: 'Chụp ảnh thiết bị/tài liệu rồi đặt câu hỏi (camera).\n'
          'Triển khai ở M4: package camera/image_picker → gửi ảnh tới /api/query.',
    );
  }
}
