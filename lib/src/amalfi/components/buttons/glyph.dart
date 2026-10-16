// The few stroke glyphs the buttons draw themselves (the pop-up chevrons, the gradient
// button's plus and minus, the menu checkmark), from the Silica Icon Kit symbols of the same
// names (silica-icons `symbols/regular/*.svg`, 24 pt, stroke 1.5, round caps and joins).

import 'package:flutter/widgets.dart';

/// A stroke glyph of [AmalfiButtonGlyph].
enum AmalfiButtonGlyphShape {
  /// `plus`.
  plus([
    [Offset(12, 4), Offset(12, 20)],
    [Offset(4, 12), Offset(20, 12)],
  ]),

  /// `minus`.
  minus([
    [Offset(4, 12), Offset(20, 12)],
  ]),

  /// `chevron-down` (pull-down buttons).
  chevronDown([
    [Offset(5.4, 9.41), Offset(12, 14.59), Offset(18.6, 9.41)],
  ]),

  /// `chevron-up-down` (pop-up buttons).
  chevronUpDown([
    [Offset(8, 9.5), Offset(12, 5.5), Offset(16, 9.5)],
    [Offset(8, 14.5), Offset(12, 18.5), Offset(16, 14.5)],
  ]),

  /// `checkmark` (the chosen item of a menu).
  checkmark([
    [Offset(4.6, 12.6), Offset(9.4, 17.6), Offset(19.4, 6.4)],
  ]);

  const AmalfiButtonGlyphShape(this.strokes);

  /// The polylines on the 24 pt canvas.
  final List<List<Offset>> strokes;
}

/// A Regular-weight glyph of [shape], [size] points square, in [color]. The stroke scales
/// with the size, as the Icon Kit's: 1.5 at 24, 1 at 16, 0.75 at 12.
///
/// [size] and [color] default to the ambient [IconTheme] (buttons set it for their glyphs).
class AmalfiButtonGlyph extends StatelessWidget {
  const AmalfiButtonGlyph(this.shape, {super.key, this.size, this.color});

  final AmalfiButtonGlyphShape shape;
  final double? size;
  final Color? color;

  /// The Icon Kit canvas side.
  static const double canvas = 24;

  /// The Regular stroke on the 24 pt canvas.
  static const double stroke = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 16;
    final paint = color ?? theme.color ?? const Color(0xFF000000);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(painter: _GlyphPainter(shape, paint)),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.shape, this.color);

  final AmalfiButtonGlyphShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = size.shortestSide / AmalfiButtonGlyph.canvas;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AmalfiButtonGlyph.stroke * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final line in shape.strokes) {
      final path = Path();
      for (var i = 0; i < line.length; i++) {
        final p = line[i] * scale;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.shape != shape || old.color != color;
}
