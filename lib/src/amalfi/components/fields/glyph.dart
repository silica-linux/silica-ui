// The Icon Kit glyphs the fields, wells and forms draw (search, clear, warning, lock,
// chevrons, checkmark, photo, eyedropper), painted synchronously from their path data.
//
// The paths are the 24 pt `symbols/regular/<name>.svg` of silica-icons (CC BY-SA 4.0, like
// the kit), stroked 1.5 at 24 pt with round caps and joins; a glyph drawn at another size is
// the plain vector scaling (README: 16 → 1.0, 12 → 0.75). Shared helper of the fields family,
// to be deduplicated with the other families' glyphs into one Amalfi glyph widget.

import 'package:flutter/widgets.dart';

/// An Icon Kit glyph used by the Amalfi fields, wells and forms.
enum AmalfiGlyph {
  /// `search`: the magnifier of the search field.
  search([
    _GlyphPath(
      'M4.77 10.2A5.43 5.43 0 1 0 15.63 10.2A5.43 5.43 0 1 0 4.77 10.2Z',
    ),
    _GlyphPath('M14.04 14.04 L20.25 20.25'),
  ]),

  /// `xmark`: the cross of the clear button and of a token.
  xmark([_GlyphPath('M5.6 5.6 L18.4 18.4'), _GlyphPath('M18.4 5.6 L5.6 18.4')]),

  /// `warning`: the error mark of a field.
  warning([
    _GlyphPath(
      'M10.4 4.4A1.85 1.85 0 0 1 13.6 4.4L21.0 17.5A1.85 1.85 0 0 1 19.4 20.3H4.6'
      'A1.85 1.85 0 0 1 3.0 17.5Z',
    ),
    _GlyphPath('M12 9.4 L12 13.6'),
    _GlyphPath(
      'M11.45 16.7A0.55 0.55 0 1 0 12.55 16.7A0.55 0.55 0 1 0 11.45 16.7Z',
      filled: true,
    ),
  ]),

  /// `lock`: the leading mark of the secure field.
  lock([
    _GlyphPath(
      'M7.15 12.01H16.85A2.4 2.4 0 0 1 19.25 14.41V18A2.4 2.4 0 0 1 16.85 20.4H7.15'
      'A2.4 2.4 0 0 1 4.75 18V14.41A2.4 2.4 0 0 1 7.15 12.01Z',
    ),
    _GlyphPath('M8.2 12.01V7.4A3.8 3.8 0 0 1 15.8 7.4V12.01'),
    _GlyphPath(
      'M11.4 16.21A0.6 0.6 0 1 0 12.6 16.21A0.6 0.6 0 1 0 11.4 16.21Z',
      filled: true,
    ),
  ]),

  /// `chevron-down`: the combo button and the colour well's picker.
  chevronDown([_GlyphPath('M5.4 9.41 L12 14.59 L18.6 9.41')]),

  /// `chevron-up-down`: the pop-up button.
  chevronUpDown([
    _GlyphPath('M8 9.5 L12 5.5 L16 9.5'),
    _GlyphPath('M8 14.5 L12 18.5 L16 14.5'),
  ]),

  /// `checkmark`: a checked menu item or checkbox.
  checkmark([_GlyphPath('M4.6 12.6 L9.4 17.6 L19.4 6.4')]),

  /// `photo`: the empty image well.
  photo([
    _GlyphPath(
      'M5.15 4.25H18.85A2.4 2.4 0 0 1 21.25 6.65V17.35A2.4 2.4 0 0 1 18.85 19.75H5.15'
      'A2.4 2.4 0 0 1 2.75 17.35V6.65A2.4 2.4 0 0 1 5.15 4.25Z',
    ),
    _GlyphPath(
      'M14.15 8.75A1.6 1.6 0 1 0 17.35 8.75A1.6 1.6 0 1 0 14.15 8.75Z',
    ),
    _GlyphPath('M2.75 17 L8.5 11.25 L13.25 16'),
    _GlyphPath('M11.6 14.35 L15.5 13.25 L21.25 17'),
  ]),

  /// `eyedropper`: the expanded colour well.
  eyedropper([
    _GlyphPath('M4.93 19.07L6.34 15.54L12 9.88'),
    _GlyphPath('M14.12 12L8.46 17.66L4.93 19.07'),
    _GlyphPath('M10.66 8.54L15.46 13.34'),
    _GlyphPath('M11.47 9.35L15.18 5.64A2.25 2.25 0 0 1 18.36 8.82L14.65 12.53'),
  ]);

  const AmalfiGlyph(this._paths);

  final List<_GlyphPath> _paths;

  /// The side of the glyph's canvas in the Icon Kit.
  static const double canvas = 24;

  /// The stroke width at [canvas] size.
  static const double stroke = 1.5;
}

class _GlyphPath {
  const _GlyphPath(this.data, {this.filled = false});

  /// SVG path data (absolute M, L, H, V, A, Z).
  final String data;

  /// Filled as well as stroked (the dots of `warning` and `lock`).
  final bool filled;
}

/// Draws [glyph] in a [size] × [size] box in [color].
class AmalfiGlyphIcon extends StatelessWidget {
  const AmalfiGlyphIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
  });

  final AmalfiGlyph glyph;

  /// The side in points (12, 16, 20 …).
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GlyphPainter(glyph, color)),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final AmalfiGlyph glyph;
  final Color color;

  static final Map<AmalfiGlyph, List<(Path, bool)>> _cache = {};

  static List<(Path, bool)> _paths(AmalfiGlyph glyph) => _cache.putIfAbsent(
    glyph,
    () => [for (final p in glyph._paths) (parseGlyphPath(p.data), p.filled)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = size.shortestSide / AmalfiGlyph.canvas;
    canvas
      ..save()
      ..scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AmalfiGlyph.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;
    for (final (path, filled) in _paths(glyph)) {
      if (filled) canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// Parses SVG path data with absolute `M`, `L`, `H`, `V`, `A` and `Z` commands (what the
/// Icon Kit glyphs use). Unknown commands end the path.
Path parseGlyphPath(String data) {
  final tokens = RegExp(
    r'[MLHVAZmlhvaz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE]-?\d+)?',
  ).allMatches(data).map((m) => m.group(0) ?? '').toList();
  final path = Path();
  var i = 0;
  var command = '';
  var current = Offset.zero;
  var start = Offset.zero;
  double next() => i < tokens.length ? double.tryParse(tokens[i++]) ?? 0 : 0;
  bool isNumber() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!isNumber()) command = tokens[i++];
    switch (command) {
      case 'M':
        current = start = Offset(next(), next());
        path.moveTo(current.dx, current.dy);
        command = 'L';
      case 'L':
        current = Offset(next(), next());
        path.lineTo(current.dx, current.dy);
      case 'H':
        current = Offset(next(), current.dy);
        path.lineTo(current.dx, current.dy);
      case 'V':
        current = Offset(current.dx, next());
        path.lineTo(current.dx, current.dy);
      case 'A':
        final rx = next(), ry = next(), rotation = next();
        final large = next() != 0, sweep = next() != 0;
        current = Offset(next(), next());
        path.arcToPoint(
          current,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: large,
          clockwise: sweep,
        );
      case 'Z' || 'z':
        path.close();
        current = start;
      default:
        return path;
    }
  }
  return path;
}
