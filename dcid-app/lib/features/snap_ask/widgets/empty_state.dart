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
            'No device photos yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the + button below to take a photo,\nupload from gallery, or scan a machine QR code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
