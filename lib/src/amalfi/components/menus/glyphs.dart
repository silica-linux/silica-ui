// The few Icon Kit glyphs the menu, popover and alert families draw themselves (the
// checkmark, the submenu chevron, the warning badge), as vector paths transcribed from
// silica-icons `symbols/regular/<name>.svg` (24 pt grid, stroke 1.5, round caps and joins).
//
// Not exported: to be deduplicated with the fields family's `AmalfiGlyph` (which lacks
// `chevron-right`) into one Amalfi glyph widget.
//
// The stroke scales with the glyph (`docs/design/amalfi/README.md`): 24 → 1.5, 16 → 1.0,
// 12 → 0.75.

import 'package:flutter/widgets.dart';

/// A glyph of the Icon Kit drawn by the Amalfi menus, popovers and alerts.
enum AmalfiMenuGlyph {
  /// `Regular / checkmark`: the checked state of a menu item.
  checkmark,

  /// `Regular / chevron-right`: an item that opens a submenu.
  chevronRight,

  /// `Regular / warning`: the badge of a critical alert.
  warning,
}

/// Draws [glyph] in [color], [size] points square, with the stroke scaled to the size.
class AmalfiMenuGlyphIcon extends StatelessWidget {
  const AmalfiMenuGlyphIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = 12,
  });

  final AmalfiMenuGlyph glyph;

  /// The stroke (and dot) colour.
  final Color color;

  /// The side of the square, in points.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GlyphPainter(glyph, color)),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final AmalfiMenuGlyph glyph;
  final Color color;

  /// The glyph in the 24 pt design grid: stroked paths, filled paths.
  static (List<Path>, List<Path>) _paths(AmalfiMenuGlyph glyph) =>
      switch (glyph) {
        AmalfiMenuGlyph.checkmark => (
          [
            Path()
              ..moveTo(4.6, 12.6)
              ..lineTo(9.4, 17.6)
              ..lineTo(19.4, 6.4),
          ],
          const [],
        ),
        AmalfiMenuGlyph.chevronRight => (
          [
            Path()
              ..moveTo(9.41, 5.4)
              ..lineTo(14.59, 12)
              ..lineTo(9.41, 18.6),
          ],
          const [],
        ),
        AmalfiMenuGlyph.warning => (
          [
            Path()
              ..moveTo(10.4, 4.4)
              ..arcToPoint(const Offset(13.6, 4.4), radius: _r)
              ..lineTo(21.0, 17.5)
              ..arcToPoint(const Offset(19.4, 20.3), radius: _r)
              ..lineTo(4.6, 20.3)
              ..arcToPoint(const Offset(3.0, 17.5), radius: _r)
              ..close(),
            Path()
              ..moveTo(12, 9.4)
              ..lineTo(12, 13.6),
          ],
          [
            Path()..addOval(
              Rect.fromCircle(center: const Offset(12, 16.7), radius: 0.55),
            ),
          ],
        ),
      };

  static const Radius _r = Radius.circular(1.85);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = size.shortestSide / 24;
    final (strokes, fills) = _paths(glyph);
    canvas
      ..save()
      ..scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final p in strokes) {
      canvas.drawPath(p, stroke);
    }
    final fill = Paint()..color = color;
    for (final p in fills) {
      canvas
        ..drawPath(p, fill)
        ..drawPath(p, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
