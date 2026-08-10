import 'package:flutter/material.dart';

import '../../../data/models/snap_entry.dart';
import '../viewer/bbox_painter.dart';

/// Full-screen interactive preview dialog for equipment images with spatial bounding box annotations.
void showSnapPreviewDialog({
  required BuildContext context,
  required SnapEntry snap,
  required List<Rect> boxes,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            child: Center(
              child: CustomPaint(
                foregroundPainter: BBoxPainter(boxes),
                child: Image.memory(snap.bytes),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton.filled(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
