import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';

/// Place-holder empty state shown when no equipment image has been uploaded yet.
class SnapEmptyState extends ConsumerWidget {
  const SnapEmptyState({
    super.key,
    required this.onAdd,
    required this.scheme,
  });

  final VoidCallback onAdd;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_roll_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            strings.noSnapPhotos,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.noSnapPhotosDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
