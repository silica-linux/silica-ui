// A ring or an arc of a ring, stroked on its centre line: the dial's track and value.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints a circle inscribed in the box, stroked [width] wide on its outline (half inside,
/// half outside), from the top clockwise over [sweep] of a turn (1: the whole ring), with
/// round ends when [roundCaps].
class AmalfiArcPainter extends CustomPainter {
  const AmalfiArcPainter({
    required this.color,
    required this.width,
    this.sweep = 1,
    this.roundCaps = false,
  });

  final Color color;
  final double width;

  /// The part of the turn drawn, 0–1.
  final double sweep;
  final bool roundCaps;

  @override
  void paint(Canvas canvas, Size size) {
    final s = sweep.isFinite ? sweep.clamp(0.0, 1.0) : 0.0;
    if (s <= 0 || size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = roundCaps ? StrokeCap.round : StrokeCap.butt;
    final rect = Offset.zero & size;
    if (s >= 1) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawArc(rect, -math.pi / 2, s * 2 * math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(AmalfiArcPainter old) =>
      old.color != color ||
      old.width != width ||
      old.sweep != sweep ||
      old.roundCaps != roundCaps;
}
