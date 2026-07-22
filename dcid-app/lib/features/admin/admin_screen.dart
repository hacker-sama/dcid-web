import 'package:flutter/material.dart';

import '../common/feature_placeholder.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.admin_panel_settings,
      title: 'Quản trị / QA',
      note: 'Upload tài liệu, quản lý version (ACTIVE/SUPERSEDED/OBSOLETE), '
          'người dùng, audit log.\nTriển khai M3 (màn lớn, data_table_2/fl_chart).',
    );
  }
}
