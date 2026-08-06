import 'package:flutter/material.dart';

/// CustomPainter that draws bounding box annotations over image previews.
class BBoxPainter extends CustomPainter {
  BBoxPainter(this.boxes);
  final List<Rect> boxes;

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    for (final box in boxes) {
      canvas.drawRect(
        Rect.fromLTRB(
          (box.left / 1000.0) * size.width,
          (box.top / 1000.0) * size.height,
          (box.right / 1000.0) * size.width,
          (box.bottom / 1000.0) * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BBoxPainter oldDelegate) => true;
}
