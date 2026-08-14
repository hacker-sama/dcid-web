import 'package:flutter/material.dart';

import '../../data/models/page_info.dart';

/// Custom painter that draws red bounding box rectangles over a page image.
///
/// Bounding box coordinates are **normalized** (0.0–1.0). The painter scales
/// them to the actual display size using:
/// ```
/// displayX = bbox.x * size.width
/// displayY = bbox.y * size.height
/// ```
class BBoxOverlayPainter extends CustomPainter {
  BBoxOverlayPainter({
    required this.bboxes,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2.5,
    this.fillOpacity = 0.08,
  });

  final List<BoundingBox> bboxes;
  final Color strokeColor;
  final double strokeWidth;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = strokeColor.withValues(alpha: fillOpacity)
      ..style = PaintingStyle.fill;

    final labelStyle = TextStyle(
      color: strokeColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      backgroundColor: Colors.white.withValues(alpha: 0.85),
    );

    for (final bbox in bboxes) {
      final rect = Rect.fromLTWH(
        bbox.x * size.width,
        bbox.y * size.height,
        bbox.width * size.width,
        bbox.height * size.height,
      );

      // Draw semi-transparent fill + solid stroke.
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);

      // Draw label above the box if present.
      if (bbox.label != null && bbox.label!.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: ' ${bbox.label!} ', style: labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: size.width - rect.left);
        final labelY = (rect.top - tp.height - 2).clamp(0.0, size.height);
        tp.paint(canvas, Offset(rect.left, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BBoxOverlayPainter old) =>
      bboxes != old.bboxes || strokeColor != old.strokeColor;
}
