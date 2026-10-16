// The Icon Kit's `Regular / chevron-up` and `chevron-down` glyphs, drawn as their paths: a
// 24 pt polyline with a 1.5 pt round stroke, scaled to the glyph size (the stroke scales
// with it, `README.md`: 12 pt → 0.75).

import 'package:flutter/widgets.dart';

/// Paints the chevron glyph pointing up ([up]) or down in [color], scaled to the box.
class AmalfiChevronPainter extends CustomPainter {
  const AmalfiChevronPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  /// The glyph's canvas and stroke in the Icon Kit.
  static const double canvas = 24, stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final k = size.shortestSide / AmalfiChevronPainter.canvas;
    final dx = (size.width - AmalfiChevronPainter.canvas * k) / 2;
    final dy = (size.height - AmalfiChevronPainter.canvas * k) / 2;
    Offset p(double x, double y) => Offset(dx + x * k, dy + y * k);
    final (outer, inner) = up ? (14.59, 9.41) : (9.41, 14.59);
    final path = Path()
      ..moveTo(p(5.4, outer).dx, p(5.4, outer).dy)
      ..lineTo(p(12, inner).dx, p(12, inner).dy)
      ..lineTo(p(18.6, outer).dx, p(18.6, outer).dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(AmalfiChevronPainter old) =>
      old.up != up || old.color != color;
}
