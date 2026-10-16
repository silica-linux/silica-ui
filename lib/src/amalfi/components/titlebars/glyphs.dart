// Icon Kit glyphs drawn from their path data, for the window chrome (window controls, title
// pieces, tabs, sidebar rows).
//
// The glyphs are the Regular 24 pt symbols of silica-icons (`symbols/regular/<name>.svg`, CC
// BY-SA 4.0, the Silica project), copied here as path data: the stroke scales with the size
// (`README.md` of the design folder: Regular 24 → 1.5, 16 → 1.0, 12 → 0.75). Only the few
// glyphs the chrome needs are here; this is a family-local helper until a shared symbol widget
// exists.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One path of a glyph: SVG path data in the 24 × 24 box, stroked, or [filled].
@immutable
class AmalfiChromeGlyphPath {
  const AmalfiChromeGlyphPath(this.data, {this.filled = false});

  /// SVG path data (`M`, `L`, `H`, `V`, `C`, `Q`, `A`, `Z` and their relative forms).
  final String data;

  /// Whether the path is filled instead of stroked.
  final bool filled;
}

/// A glyph of the Icon Kit: its [name] in silica-icons and its [paths].
@immutable
class AmalfiChromeGlyphData {
  const AmalfiChromeGlyphData(this.name, this.paths);

  /// The glyph name (`xmark`, `chevron-down`).
  final String name;

  /// The paths, in the 24 × 24 box.
  final List<AmalfiChromeGlyphPath> paths;

  @override
  String toString() => 'AmalfiChromeGlyphData($name)';
}

/// Draws [glyph] in a [size] × [size] box in [color].
///
/// The stroke is the Regular weight scaled to [size] (1.5 at 24); [strokeWidth] overrides it
/// (in points at [size]).
class AmalfiChromeGlyph extends StatelessWidget {
  const AmalfiChromeGlyph(
    this.glyph, {
    super.key,
    this.size = 16,
    required this.color,
    this.strokeWidth,
  });

  final AmalfiChromeGlyphData glyph;

  /// The side of the box, in points.
  final double size;

  final Color color;

  /// The stroke width in points; null: the Regular weight at [size].
  final double? strokeWidth;

  /// The Regular stroke width at [size]: 1.5 at 24, scaled linearly.
  static double regularStroke(double size) => 1.5 * size / 24;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _GlyphPainter(glyph, color, strokeWidth ?? regularStroke(size)),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, this.strokeWidth);

  final AmalfiChromeGlyphData glyph;
  final Color color;
  final double strokeWidth;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 24;
    if (scale <= 0) return;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final p in glyph.paths) {
      final path = _cache.putIfAbsent(p.data, () => parseSvgPathData(p.data));
      canvas.drawPath(path, p.filled ? fill : stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

final RegExp _token = RegExp(
  r'[MmLlHhVvCcQqAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

/// Parses SVG path [data] (absolute and relative `M L H V C Q A Z`) into a [Path]. Unknown or
/// truncated commands end the path where they start (never throws).
Path parseSvgPathData(String data) {
  final path = Path();
  final tokens = [for (final m in _token.allMatches(data)) m.group(0)!];
  var i = 0;
  var command = '';
  var current = Offset.zero;
  var start = Offset.zero;

  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double? number() {
    if (i >= tokens.length || isCommand(tokens[i])) return null;
    return double.tryParse(tokens[i++]);
  }

  while (i < tokens.length) {
    if (isCommand(tokens[i])) command = tokens[i++];
    if (command.isEmpty) break;
    final relative = command.toLowerCase() == command;
    Offset at(double x, double y) =>
        relative ? current + Offset(x, y) : Offset(x, y);
    switch (command.toUpperCase()) {
      case 'Z':
        path.close();
        current = start;
        command = '';
        continue;
      case 'M':
        final x = number(), y = number();
        if (x == null || y == null) return path;
        current = start = at(x, y);
        path.moveTo(current.dx, current.dy);
        // Further pairs are implicit line-tos.
        command = relative ? 'l' : 'L';
      case 'L':
        final x = number(), y = number();
        if (x == null || y == null) return path;
        current = at(x, y);
        path.lineTo(current.dx, current.dy);
      case 'H':
        final x = number();
        if (x == null) return path;
        current = Offset(relative ? current.dx + x : x, current.dy);
        path.lineTo(current.dx, current.dy);
      case 'V':
        final y = number();
        if (y == null) return path;
        current = Offset(current.dx, relative ? current.dy + y : y);
        path.lineTo(current.dx, current.dy);
      case 'C':
        final v = [for (var k = 0; k < 6; k++) number()];
        if (v.contains(null)) return path;
        final a = at(v[0]!, v[1]!), b = at(v[2]!, v[3]!), c = at(v[4]!, v[5]!);
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
        current = c;
      case 'Q':
        final v = [for (var k = 0; k < 4; k++) number()];
        if (v.contains(null)) return path;
        final a = at(v[0]!, v[1]!), b = at(v[2]!, v[3]!);
        path.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
        current = b;
      case 'A':
        final v = [for (var k = 0; k < 7; k++) number()];
        if (v.contains(null)) return path;
        final end = at(v[5]!, v[6]!);
        path.arcToPoint(
          end,
          radius: Radius.elliptical(v[0]!.abs(), v[1]!.abs()),
          rotation: v[2]!,
          largeArc: v[3]! != 0,
          clockwise: v[4]! != 0,
        );
        current = end;
      default:
        return path;
    }
  }
  return path;
}

/// The Icon Kit glyphs the window chrome uses.
abstract final class AmalfiChromeGlyphs {
  /// `xmark`.
  static const AmalfiChromeGlyphData xmark = AmalfiChromeGlyphData('xmark', [
    AmalfiChromeGlyphPath('M5.6 5.6 L18.4 18.4'),
    AmalfiChromeGlyphPath('M18.4 5.6 L5.6 18.4'),
  ]);

  /// `minus`.
  static const AmalfiChromeGlyphData minus = AmalfiChromeGlyphData('minus', [
    AmalfiChromeGlyphPath('M4 12 L20 12'),
  ]);

  /// `plus`.
  static const AmalfiChromeGlyphData plus = AmalfiChromeGlyphData('plus', [
    AmalfiChromeGlyphPath('M12 4 L12 20'),
    AmalfiChromeGlyphPath('M4 12 L20 12'),
  ]);

  /// `chevron-down`.
  static const AmalfiChromeGlyphData chevronDown = AmalfiChromeGlyphData(
    'chevron-down',
    [AmalfiChromeGlyphPath('M5.4 9.41 L12 14.59 L18.6 9.41')],
  );

  /// `chevron-right`.
  static const AmalfiChromeGlyphData chevronRight = AmalfiChromeGlyphData(
    'chevron-right',
    [AmalfiChromeGlyphPath('M9.41 5.4 L14.59 12 L9.41 18.6')],
  );

  /// `chevron-left`.
  static const AmalfiChromeGlyphData chevronLeft = AmalfiChromeGlyphData(
    'chevron-left',
    [AmalfiChromeGlyphPath('M14.59 5.4 L9.41 12 L14.59 18.6')],
  );

  /// `doc`.
  static const AmalfiChromeGlyphData doc = AmalfiChromeGlyphData('doc', [
    AmalfiChromeGlyphPath(
      'M12.47 2.75H7.97A2.2 2.2 0 0 0 5.77 4.95V19.05A2.2 2.2 0 0 0 7.97 21.25H16.03A2.2 2.2 0 0 0 18.23 19.05V8.51Z',
    ),
    AmalfiChromeGlyphPath('M12.47 2.75 L12.47 8.51 L18.23 8.51'),
  ]);

  /// `folder`.
  static const AmalfiChromeGlyphData folder = AmalfiChromeGlyphData('folder', [
    AmalfiChromeGlyphPath(
      'M2.75 6.88V16.22A2.4 2.4 0 0 0 5.15 18.62H18.85A2.4 2.4 0 0 0 21.25 16.22V9.58A2.4 2.4 0 0 0 18.85 7.18H11.2L9.6 5.18C9.3 4.78 9 4.68 8.5 4.68H4.95A2.2 2.2 0 0 0 2.75 6.88Z',
    ),
    AmalfiChromeGlyphPath('M2.75 9.78 L21.25 9.78'),
  ]);

  /// `clock`.
  static const AmalfiChromeGlyphData clock = AmalfiChromeGlyphData('clock', [
    AmalfiChromeGlyphPath(
      'M2.75 12A9.25 9.25 0 1 0 21.25 12A9.25 9.25 0 1 0 2.75 12Z',
    ),
    AmalfiChromeGlyphPath('M12 6.28 L12 12 L16.24 15.18'),
  ]);

  /// `download`.
  static const AmalfiChromeGlyphData download =
      AmalfiChromeGlyphData('download', [
        AmalfiChromeGlyphPath('M12 3.4 L12 15.4'),
        AmalfiChromeGlyphPath('M7.4 10.8 L12 15.4 L16.6 10.8'),
        AmalfiChromeGlyphPath('M4.4 20.4 L19.6 20.4'),
      ]);

  /// `photo`.
  static const AmalfiChromeGlyphData photo = AmalfiChromeGlyphData('photo', [
    AmalfiChromeGlyphPath(
      'M5.15 4.25H18.85A2.4 2.4 0 0 1 21.25 6.65V17.35A2.4 2.4 0 0 1 18.85 19.75H5.15A2.4 2.4 0 0 1 2.75 17.35V6.65A2.4 2.4 0 0 1 5.15 4.25Z',
    ),
    AmalfiChromeGlyphPath(
      'M14.15 8.75A1.6 1.6 0 1 0 17.35 8.75A1.6 1.6 0 1 0 14.15 8.75Z',
    ),
    AmalfiChromeGlyphPath('M2.75 17 L8.5 11.25 L13.25 16'),
    AmalfiChromeGlyphPath('M11.6 14.35 L15.5 13.25 L21.25 17'),
  ]);

  /// `music-note`.
  static const AmalfiChromeGlyphData musicNote = AmalfiChromeGlyphData(
    'music-note',
    [
      AmalfiChromeGlyphPath(
        'M4.75 17.25A2.25 2.25 0 1 0 9.25 17.25A2.25 2.25 0 1 0 4.75 17.25Z',
        filled: true,
      ),
      AmalfiChromeGlyphPath(
        'M14.75 15.25A2.25 2.25 0 1 0 19.25 15.25A2.25 2.25 0 1 0 14.75 15.25Z',
        filled: true,
      ),
      AmalfiChromeGlyphPath('M9.25 17.25 L9.25 6.25 L19.25 4.25 L19.25 15.25'),
      AmalfiChromeGlyphPath('M9.25 9.75 L19.25 7.75'),
    ],
  );

  /// `sidebar`.
  static const AmalfiChromeGlyphData
  sidebar = AmalfiChromeGlyphData('sidebar', [
    AmalfiChromeGlyphPath(
      'M5.15 6.57H18.85A2.4 2.4 0 0 1 21.25 8.97V15.03A2.4 2.4 0 0 1 18.85 17.43H5.15A2.4 2.4 0 0 1 2.75 15.03V8.97A2.4 2.4 0 0 1 5.15 6.57Z',
    ),
    AmalfiChromeGlyphPath('M9.82 6.57 L9.82 17.43'),
    AmalfiChromeGlyphPath('M5.4 9.47 L7.22 9.47'),
    AmalfiChromeGlyphPath('M5.4 12.07 L7.22 12.07'),
  ]);

  /// `tag`.
  static const AmalfiChromeGlyphData tag = AmalfiChromeGlyphData('tag', [
    AmalfiChromeGlyphPath(
      'M3.25 12L8.6 5.25H18.85A2.4 2.4 0 0 1 21.25 7.65V16.35A2.4 2.4 0 0 1 18.85 18.75H8.6Z',
    ),
    AmalfiChromeGlyphPath(
      'M8.4 12A0.6 0.6 0 1 0 9.6 12A0.6 0.6 0 1 0 8.4 12Z',
      filled: true,
    ),
  ]);

  /// `star`.
  static const AmalfiChromeGlyphData star = AmalfiChromeGlyphData('star', [
    AmalfiChromeGlyphPath(
      'M12 2.95 L14.22 9.79 L21.42 9.79 L15.6 14.02 L17.82 20.86 L12 16.63 L6.18 20.86 L8.4 14.02 L2.58 9.79 L9.78 9.79Z',
    ),
  ]);

  /// `gear`.
  static const AmalfiChromeGlyphData gear = AmalfiChromeGlyphData('gear', [
    AmalfiChromeGlyphPath(
      'M10.21 2.77 L13.79 2.77 L13.62 5.25 L15.63 6.08 L17.26 4.21 L19.79 6.74 L17.92 8.37 L18.75 10.38 L21.23 10.21 L21.23 13.79 L18.75 13.62 L17.92 15.63 L19.79 17.26 L17.26 19.79 L15.63 17.92 L13.62 18.75 L13.79 21.23 L10.21 21.23 L10.38 18.75 L8.37 17.92 L6.74 19.79 L4.21 17.26 L6.08 15.63 L5.25 13.62 L2.77 13.79 L2.77 10.21 L5.25 10.38 L6.08 8.37 L4.21 6.74 L6.74 4.21 L8.37 6.08 L10.38 5.25Z',
    ),
    AmalfiChromeGlyphPath(
      'M8.38 12A3.62 3.62 0 1 0 15.62 12A3.62 3.62 0 1 0 8.38 12Z',
    ),
  ]);

  /// `list-bullet`.
  static const AmalfiChromeGlyphData listBullet =
      AmalfiChromeGlyphData('list-bullet', [
        AmalfiChromeGlyphPath(
          'M4.45 6A0.55 0.55 0 1 0 5.55 6A0.55 0.55 0 1 0 4.45 6Z',
          filled: true,
        ),
        AmalfiChromeGlyphPath(
          'M4.45 12A0.55 0.55 0 1 0 5.55 12A0.55 0.55 0 1 0 4.45 12Z',
          filled: true,
        ),
        AmalfiChromeGlyphPath(
          'M4.45 18A0.55 0.55 0 1 0 5.55 18A0.55 0.55 0 1 0 4.45 18Z',
          filled: true,
        ),
        AmalfiChromeGlyphPath('M9 6 L20 6'),
        AmalfiChromeGlyphPath('M9 12 L20 12'),
        AmalfiChromeGlyphPath('M9 18 L20 18'),
      ]);

  /// `square-grid-2x2`.
  static const AmalfiChromeGlyphData
  squareGrid2x2 = AmalfiChromeGlyphData('square-grid-2x2', [
    AmalfiChromeGlyphPath(
      'M5.35 3.75H8.9A1.6 1.6 0 0 1 10.5 5.35V8.9A1.6 1.6 0 0 1 8.9 10.5H5.35A1.6 1.6 0 0 1 3.75 8.9V5.35A1.6 1.6 0 0 1 5.35 3.75Z',
    ),
    AmalfiChromeGlyphPath(
      'M5.35 13.5H8.9A1.6 1.6 0 0 1 10.5 15.1V18.65A1.6 1.6 0 0 1 8.9 20.25H5.35A1.6 1.6 0 0 1 3.75 18.65V15.1A1.6 1.6 0 0 1 5.35 13.5Z',
    ),
    AmalfiChromeGlyphPath(
      'M15.1 3.75H18.65A1.6 1.6 0 0 1 20.25 5.35V8.9A1.6 1.6 0 0 1 18.65 10.5H15.1A1.6 1.6 0 0 1 13.5 8.9V5.35A1.6 1.6 0 0 1 15.1 3.75Z',
    ),
    AmalfiChromeGlyphPath(
      'M15.1 13.5H18.65A1.6 1.6 0 0 1 20.25 15.1V18.65A1.6 1.6 0 0 1 18.65 20.25H15.1A1.6 1.6 0 0 1 13.5 18.65V15.1A1.6 1.6 0 0 1 15.1 13.5Z',
    ),
  ]);

  /// `search`.
  static const AmalfiChromeGlyphData search = AmalfiChromeGlyphData('search', [
    AmalfiChromeGlyphPath(
      'M4.77 10.2A5.43 5.43 0 1 0 15.63 10.2A5.43 5.43 0 1 0 4.77 10.2Z',
    ),
    AmalfiChromeGlyphPath('M14.04 14.04 L20.25 20.25'),
  ]);

  /// `share`.
  static const AmalfiChromeGlyphData share = AmalfiChromeGlyphData('share', [
    AmalfiChromeGlyphPath(
      'M8.6 9.4H7.15A2.4 2.4 0 0 0 4.75 11.8V18.45A2.4 2.4 0 0 0 7.15 20.85H16.85A2.4 2.4 0 0 0 19.25 18.45V11.8A2.4 2.4 0 0 0 16.85 9.4H15.4',
    ),
    AmalfiChromeGlyphPath('M12 3.2 L12 14.4'),
    AmalfiChromeGlyphPath('M8.6 6.6 L12 3.2 L15.4 6.6'),
  ]);

  /// `ellipsis-circle`.
  static const AmalfiChromeGlyphData ellipsisCircle =
      AmalfiChromeGlyphData('ellipsis-circle', [
        AmalfiChromeGlyphPath(
          'M2.75 12A9.25 9.25 0 1 0 21.25 12A9.25 9.25 0 1 0 2.75 12Z',
        ),
        AmalfiChromeGlyphPath(
          'M7.4 12A0.5 0.5 0 1 0 8.4 12A0.5 0.5 0 1 0 7.4 12Z',
          filled: true,
        ),
        AmalfiChromeGlyphPath(
          'M11.5 12A0.5 0.5 0 1 0 12.5 12A0.5 0.5 0 1 0 11.5 12Z',
          filled: true,
        ),
        AmalfiChromeGlyphPath(
          'M15.6 12A0.5 0.5 0 1 0 16.6 12A0.5 0.5 0 1 0 15.6 12Z',
          filled: true,
        ),
      ]);

  /// `compose`.
  static const AmalfiChromeGlyphData
  compose = AmalfiChromeGlyphData('compose', [
    AmalfiChromeGlyphPath(
      'M10.5 4.25H6.15A2.4 2.4 0 0 0 3.75 6.65V17.85A2.4 2.4 0 0 0 6.15 20.25H17.35A2.4 2.4 0 0 0 19.75 17.85V13.5',
    ),
    AmalfiChromeGlyphPath(
      'M9.13 14.87L10.26 10.91L16.2 4.97A1 1 0 0 1 17.61 4.97L19.03 6.39A1 1 0 0 1 19.03 7.8L13.09 13.74L9.13 14.87Z',
    ),
    AmalfiChromeGlyphPath('M10.26 10.91L13.09 13.74'),
  ]);

  /// `trash`.
  static const AmalfiChromeGlyphData trash = AmalfiChromeGlyphData('trash', [
    AmalfiChromeGlyphPath('M3.6 6.4 L20.4 6.4'),
    AmalfiChromeGlyphPath(
      'M9.1 6.4V5.2A1.7 1.7 0 0 1 10.8 3.5H13.2A1.7 1.7 0 0 1 14.9 5.2V6.4',
    ),
    AmalfiChromeGlyphPath(
      'M5.6 6.4L6.6 18.9A2.1 2.1 0 0 0 8.7 20.8H15.3A2.1 2.1 0 0 0 17.4 18.9L18.4 6.4',
    ),
    AmalfiChromeGlyphPath('M10 10 L10 16.8'),
    AmalfiChromeGlyphPath('M14 10 L14 16.8'),
  ]);
}
