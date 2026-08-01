import 'package:flutter/material.dart';

/// Place-holder empty state shown when no equipment image has been uploaded yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.onAdd,
    required this.scheme,
  });

  final VoidCallback onAdd;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_roll_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Chưa có ảnh thiết bị nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chụp hoặc tải lên ảnh thiết bị\nđể bắt đầu phân tích bằng AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Thêm ảnh đầu tiên'),
          ),
        ],
      ),
    );
  }
}
