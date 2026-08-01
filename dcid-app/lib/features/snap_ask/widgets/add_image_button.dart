import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Compact header button to add / upload equipment images.
class AddImageButton extends StatelessWidget {
  const AddImageButton({
    super.key,
    required this.onAdd,
    required this.loading,
    required this.scheme,
  });

  final VoidCallback onAdd;
  final bool loading;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: loading ? null : onAdd,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
        foregroundColor: scheme.onPrimaryContainer,
      ),
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            )
          : const Icon(Icons.add_a_photo_outlined, size: 20),
      label: Text(
        loading
            ? 'Đang tải...'
            : (kIsWeb ? 'Tải lên ảnh thiết bị' : 'Chụp / Tải lên ảnh thiết bị'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
