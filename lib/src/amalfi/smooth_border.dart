// Smooth (continuous) corners: a rounded rectangle whose corners blend into the sides with a
// curvature that grows gradually instead of jumping from 0 to 1 / radius as a circular arc does.
//
// Each corner is a circular arc in the middle, shortened by the smoothing, joined to each side
// by a cubic Bézier that starts tangent to the side. With smoothing s the corner starts
// (1 + s) × radius from the vertex instead of radius, and the arc covers 90° × (1 − s). The
// geometry, per corner of radius r (all angles in degrees):
//
//   p     = (1 + s) r                       distance from the vertex where the corner starts
//   arc   = 90 (1 − s)                      angle of the circular part
//   L     = √2 r sin(arc / 2)               each leg of the arc's chord
//   α     = (90 − arc) / 2                  angle covered by each Bézier
//   t     = r tan(α / 2)
//   c     = t cos(45 s),  d = c tan(45 s)
//   b     = (p − L − c − d) / 3,  a = 2 b
//
// The Bézier from the side to the arc has the relative control points (a, 0), (a + b, 0) and
// the end (a + b + c, d); the arc then runs (L, L); the second Bézier mirrors the first.
// When the shape is too small for p, the smoothing shrinks first (it never makes the corner
// rounder than a capsule), then the radius.
//
// Each corner can have its own radius (independent corners, 0 for a square one). Every radius
// is clamped to half the shorter side and every corner fits in that half, so adjacent corners
// never overlap and a uniform border is drawn exactly as with a single radius.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// A rectangle with smooth (continuous) corners, radii in points, with [smoothing] from 0
/// (circular arcs, as [RoundedRectangleBorder]) to 1. Amalfi draws every rounded surface with
/// [AmalfiRadii.smoothing] (the default).
///
/// The default constructor gives the four corners the same [radius];
/// [AmalfiSmoothBorder.only] sets each corner on its own (0 is a square corner). Every radius
/// is clamped to half the shorter side, so a large radius gives a capsule (end).
class AmalfiSmoothBorder extends OutlinedBorder {
  /// A border whose four corners have the same [radius].
  const AmalfiSmoothBorder({
    super.side,
    double radius = 0,
    this.smoothing = AmalfiRadii.smoothing,
  }) : topLeft = radius,
       topRight = radius,
       bottomRight = radius,
       bottomLeft = radius;

  /// A border with a radius per corner (0: square).
  const AmalfiSmoothBorder.only({
    super.side,
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomRight = 0,
    this.bottomLeft = 0,
    this.smoothing = AmalfiRadii.smoothing,
  });

  /// The radius of the top-left corner in points (negative counts as 0).
  final double topLeft;

  /// The radius of the top-right corner in points (negative counts as 0).
  final double topRight;

  /// The radius of the bottom-right corner in points (negative counts as 0).
  final double bottomRight;

  /// The radius of the bottom-left corner in points (negative counts as 0).
  final double bottomLeft;

  /// How far the corners blend into the sides (clamped to 0–1).
  final double smoothing;

  /// Whether the four corners have the same radius.
  bool get isUniform =>
      topLeft == topRight && topLeft == bottomRight && topLeft == bottomLeft;

  /// The corner radius of a uniform border; with per-corner radii, the largest of them.
  double get radius => isUniform
      ? topLeft
      : math.max(
          math.max(topLeft, topRight),
          math.max(bottomRight, bottomLeft),
        );

  /// The radii top-left, top-right, bottom-right, bottom-left.
  List<double> get radii => [topLeft, topRight, bottomRight, bottomLeft];

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(math.max(side.strokeInset, 0));

  @override
  AmalfiSmoothBorder scale(double t) => AmalfiSmoothBorder.only(
    side: side.scale(t),
    topLeft: topLeft * t,
    topRight: topRight * t,
    bottomRight: bottomRight * t,
    bottomLeft: bottomLeft * t,
    smoothing: smoothing,
  );

  /// A copy with the given fields replaced: [radius] sets all four corners, then each corner
  /// argument overrides its own.
  @override
  AmalfiSmoothBorder copyWith({
    BorderSide? side,
    double? radius,
    double? topLeft,
    double? topRight,
    double? bottomRight,
    double? bottomLeft,
    double? smoothing,
  }) => AmalfiSmoothBorder.only(
    side: side ?? this.side,
    topLeft: topLeft ?? radius ?? this.topLeft,
    topRight: topRight ?? radius ?? this.topRight,
    bottomRight: bottomRight ?? radius ?? this.bottomRight,
    bottomLeft: bottomLeft ?? radius ?? this.bottomLeft,
    smoothing: smoothing ?? this.smoothing,
  );

  /// This border with every rounded corner's radius grown by [delta] (negative shrinks it,
  /// never below 0); square corners stay square. For a shadow's spread or a ring drawn around
  /// the shape.
  AmalfiSmoothBorder inflateRadii(double delta) => AmalfiSmoothBorder.only(
    side: side,
    topLeft: _grow(topLeft, delta),
    topRight: _grow(topRight, delta),
    bottomRight: _grow(bottomRight, delta),
    bottomLeft: _grow(bottomLeft, delta),
    smoothing: smoothing,
  );

  static double _grow(double r, double delta) =>
      r > 0 ? math.max(r + delta, 0) : 0;

  static AmalfiSmoothBorder _lerpBorders(
    AmalfiSmoothBorder a,
    AmalfiSmoothBorder b,
    double t,
  ) => AmalfiSmoothBorder.only(
    side: BorderSide.lerp(a.side, b.side, t),
    topLeft: _lerp(a.topLeft, b.topLeft, t),
    topRight: _lerp(a.topRight, b.topRight, t),
    bottomRight: _lerp(a.bottomRight, b.bottomRight, t),
    bottomLeft: _lerp(a.bottomLeft, b.bottomLeft, t),
    smoothing: _lerp(a.smoothing, b.smoothing, t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is AmalfiSmoothBorder) return _lerpBorders(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is AmalfiSmoothBorder) return _lerpBorders(this, b, t);
    return super.lerpTo(b, t);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// The outline of [rect] with every rounded corner grown by [delta].
  Path _path(Rect rect, double delta) => smoothRectPathOnly(
    rect,
    topLeft: _grow(topLeft, delta),
    topRight: _grow(topRight, delta),
    bottomRight: _grow(bottomRight, delta),
    bottomLeft: _grow(bottomLeft, delta),
    smoothing: smoothing,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = math.max(side.strokeInset, 0.0);
    return _path(rect.deflate(inset), -inset);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    // The stroke is centred on a path offset by the stroke alignment, so that inside (-1)
    // keeps it within [rect] and outside (1) puts it all beyond it. Square corners stay
    // square.
    final offset = side.strokeOffset / 2;
    canvas.drawPath(_path(rect.inflate(offset), offset), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is AmalfiSmoothBorder &&
      other.side == side &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft &&
      other.smoothing == smoothing;

  @override
  int get hashCode =>
      Object.hash(side, topLeft, topRight, bottomRight, bottomLeft, smoothing);

  @override
  String toString() => isUniform
      ? 'AmalfiSmoothBorder($side, radius: $topLeft, smoothing: $smoothing)'
      : 'AmalfiSmoothBorder($side, topLeft: $topLeft, topRight: $topRight, '
            'bottomRight: $bottomRight, bottomLeft: $bottomLeft, '
            'smoothing: $smoothing)';
}

/// The outline of [rect] with smooth corners of [radius] and [smoothing] (see
/// [AmalfiSmoothBorder]). An empty or non-finite rect gives an empty path.
Path smoothRectPath(Rect rect, double radius, double smoothing) =>
    smoothRectPathOnly(
      rect,
      topLeft: radius,
      topRight: radius,
      bottomRight: radius,
      bottomLeft: radius,
      smoothing: smoothing,
    );

/// The outline of [rect] with a smooth corner of its own radius at each corner (0: square),
/// all with [smoothing] (see [AmalfiSmoothBorder.only]). An empty or non-finite rect gives an
/// empty path.
Path smoothRectPathOnly(
  Rect rect, {
  double topLeft = 0,
  double topRight = 0,
  double bottomRight = 0,
  double bottomLeft = 0,
  double smoothing = AmalfiRadii.smoothing,
}) {
  final path = Path();
  if (!rect.isFinite || rect.width <= 0 || rect.height <= 0) return path;
  final budget = math.min(rect.width, rect.height) / 2;
  final s = smoothing.isFinite ? smoothing.clamp(0.0, 1.0) : 0.0;
  final tl = _SmoothCorner(topLeft, s, budget);
  final tr = _SmoothCorner(topRight, s, budget);
  final br = _SmoothCorner(bottomRight, s, budget);
  final bl = _SmoothCorner(bottomLeft, s, budget);
  if (tl.isSquare && tr.isSquare && br.isSquare && bl.isSquare) {
    return path..addRect(rect);
  }

  final Rect(:left, :top, :right, :bottom) = rect;
  path.moveTo(left + tl.p, top);
  // Top edge, then the top-right corner.
  path.lineTo(right - tr.p, top);
  if (!tr.isSquare) {
    final _SmoothCorner(:a, :b, :c, :d, :l) = tr;
    path
      ..relativeCubicTo(a, 0, a + b, 0, a + b + c, d)
      ..relativeArcToPoint(Offset(l, l), radius: tr.circular)
      ..relativeCubicTo(d, c, d, b + c, d, a + b + c);
  }
  // Right edge, bottom-right corner.
  path.lineTo(right, bottom - br.p);
  if (!br.isSquare) {
    final _SmoothCorner(:a, :b, :c, :d, :l) = br;
    path
      ..relativeCubicTo(0, a, 0, a + b, -d, a + b + c)
      ..relativeArcToPoint(Offset(-l, l), radius: br.circular)
      ..relativeCubicTo(-c, d, -(b + c), d, -(a + b + c), d);
  }
  // Bottom edge, bottom-left corner.
  path.lineTo(left + bl.p, bottom);
  if (!bl.isSquare) {
    final _SmoothCorner(:a, :b, :c, :d, :l) = bl;
    path
      ..relativeCubicTo(-a, 0, -(a + b), 0, -(a + b + c), -d)
      ..relativeArcToPoint(Offset(-l, -l), radius: bl.circular)
      ..relativeCubicTo(-d, -c, -d, -(b + c), -d, -(a + b + c));
  }
  // Left edge, top-left corner.
  path.lineTo(left, top + tl.p);
  if (!tl.isSquare) {
    final _SmoothCorner(:a, :b, :c, :d, :l) = tl;
    path
      ..relativeCubicTo(0, -a, 0, -(a + b), d, -(a + b + c))
      ..relativeArcToPoint(Offset(l, -l), radius: tl.circular)
      ..relativeCubicTo(c, -d, b + c, -d, a + b + c, -d);
  }
  return path..close();
}

/// The geometry of one smooth corner (see the comment at the top of this file).
class _SmoothCorner {
  factory _SmoothCorner(double radius, double smoothing, double budget) {
    final r = radius.isFinite ? radius.clamp(0.0, budget) : 0.0;
    if (r <= 0) return const _SmoothCorner._square();
    // Shrink the smoothing until the corner fits in its half of the shorter side.
    final s = math.min(smoothing, budget / r - 1);
    final p = math.min((1 + s) * r, budget);
    double rad(double degrees) => degrees * math.pi / 180;
    final arc = 90 * (1 - s);
    final l = math.sin(rad(arc / 2)) * r * math.sqrt2;
    final alpha = (90 - arc) / 2;
    final t = r * math.tan(rad(alpha / 2));
    final beta = 45 * s;
    final c = t * math.cos(rad(beta));
    final d = c * math.tan(rad(beta));
    final b = (p - l - c - d) / 3;
    return _SmoothCorner._(r, p, 2 * b, b, c, d, l);
  }

  const _SmoothCorner._(this.r, this.p, this.a, this.b, this.c, this.d, this.l);

  const _SmoothCorner._square() : this._(0, 0, 0, 0, 0, 0, 0);

  final double r, p, a, b, c, d, l;

  bool get isSquare => r <= 0;

  Radius get circular => Radius.circular(r);
}
