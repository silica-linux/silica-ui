// Smooth (continuous) corners: a rounded rectangle whose corners blend into the sides with a
// curvature that grows gradually instead of jumping from 0 to 1 / radius as a circular arc does.
//
// Each corner is a circular arc in the middle, joined to each side by a cubic Bézier that
// starts tangent to the side. With smoothing s on a side, the corner starts (1 + s) × radius
// from the vertex along that side instead of radius, and the Bézier covers α = 45° × s of the
// corner's turn; the arc covers what is left (90° × (1 − s) when both sides have s). Per side,
// for a corner of radius r (angles in degrees):
//
//   p     = (1 + s) r                       distance from the vertex where the corner starts
//   α     = 45 s                            angle covered by the Bézier
//   c     = r tan(α / 2) cos α,  d = c tan α
//   b     = (p − r + r sin α − c) / 3,  a = 2 b
//
// The Bézier from the side has the relative control points (a, 0), (a + b, 0) and ends on the
// circle at α, (a + b + c, d) from its start; the arc runs to 90 − α of the other side, whose
// Bézier mirrors the first.
//
// The smoothing is fitted to each side on its own, as the kit's editor does: on a side
// shorter than 2 p it shrinks until the corner fits in half of the side (a capsule keeps the
// smoothing along its long sides and meets its short sides as a circle). Every radius is
// clamped to half the shorter side, so a large radius gives a capsule. Each corner can have
// its own radius (independent corners, 0 for a square one); adjacent corners never overlap.

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

  /// A copy with the given fields replaced: [radius] sets all four corners.
  @override
  AmalfiSmoothBorder copyWith({
    BorderSide? side,
    double? radius,
    double? smoothing,
  }) => AmalfiSmoothBorder.only(
    side: side ?? this.side,
    topLeft: radius ?? topLeft,
    topRight: radius ?? topRight,
    bottomRight: radius ?? bottomRight,
    bottomLeft: radius ?? bottomLeft,
    smoothing: smoothing ?? this.smoothing,
  );

  /// A copy with the given corners' radii replaced.
  AmalfiSmoothBorder copyWithCorners({
    double? topLeft,
    double? topRight,
    double? bottomRight,
    double? bottomLeft,
  }) => AmalfiSmoothBorder.only(
    side: side,
    topLeft: topLeft ?? this.topLeft,
    topRight: topRight ?? this.topRight,
    bottomRight: bottomRight ?? this.bottomRight,
    bottomLeft: bottomLeft ?? this.bottomLeft,
    smoothing: smoothing,
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
  final halfWidth = rect.width / 2, halfHeight = rect.height / 2;
  final limit = math.min(halfWidth, halfHeight);
  final s = smoothing.isFinite ? smoothing.clamp(0.0, 1.0) : 0.0;
  // Going clockwise, each corner is entered along one side and left along the other: the
  // top-right corner from the top edge (horizontal) to the right edge (vertical), and so on.
  final tr = _SmoothCorner(topRight, s, limit, halfWidth, halfHeight);
  final br = _SmoothCorner(bottomRight, s, limit, halfHeight, halfWidth);
  final bl = _SmoothCorner(bottomLeft, s, limit, halfWidth, halfHeight);
  final tl = _SmoothCorner(topLeft, s, limit, halfHeight, halfWidth);
  if (tl.isSquare && tr.isSquare && br.isSquare && bl.isSquare) {
    return path..addRect(rect);
  }

  final Rect(:left, :top, :right, :bottom) = rect;
  // Each corner is drawn in its own frame (see _SmoothCorner), rotated onto the rect.
  Offset atTopRight(Offset p) => Offset(right + p.dx, top + p.dy);
  Offset atBottomRight(Offset p) => Offset(right - p.dy, bottom + p.dx);
  Offset atBottomLeft(Offset p) => Offset(left - p.dx, bottom - p.dy);
  Offset atTopLeft(Offset p) => Offset(left + p.dy, top - p.dx);

  final start = atTopLeft(tl.end);
  path.moveTo(start.dx, start.dy);
  tr.addTo(path, atTopRight);
  br.addTo(path, atBottomRight);
  bl.addTo(path, atBottomLeft);
  tl.addTo(path, atTopLeft);
  return path..close();
}

/// The geometry of one smooth corner (see the comment at the top of this file), in the frame
/// of a top-right corner: the vertex at the origin, entered along the top edge (y = 0, from
/// negative x) and left along the right edge (x = 0, towards positive y).
class _SmoothCorner {
  factory _SmoothCorner(
    double radius,
    double smoothing,
    double limit,
    double inBudget,
    double outBudget,
  ) {
    final r = radius.isFinite ? radius.clamp(0.0, limit) : 0.0;
    if (r <= 0) return const _SmoothCorner._square();
    // On each side the smoothing shrinks until the corner fits in half of that side.
    double fit(double budget) =>
        math.max(0.0, math.min(smoothing, budget / r - 1));
    return _SmoothCorner._(r, fit(inBudget), fit(outBudget));
  }

  const _SmoothCorner._(this.r, this.sIn, this.sOut);

  const _SmoothCorner._square() : this._(0, 0, 0);

  final double r;

  /// The smoothing on the side the corner is entered from and on the side it leaves along.
  final double sIn, sOut;

  bool get isSquare => r <= 0;

  static double _rad(double degrees) => degrees * math.pi / 180;

  /// The point of the corner's circle at [degrees] from the top (0) to the right (90).
  Offset _onCircle(double degrees) {
    final a = _rad(degrees);
    return Offset(-r + r * math.sin(a), r - r * math.cos(a));
  }

  /// Where the corner starts on the incoming side.
  Offset get start => Offset(-(1 + sIn) * r, 0);

  /// Where the corner ends on the outgoing side.
  Offset get end => Offset(0, (1 + sOut) * r);

  /// Draws the incoming side up to the corner, then the corner, with [at] mapping the
  /// corner's frame onto the rect.
  void addTo(Path path, Offset Function(Offset) at) {
    if (isSquare) {
      final v = at(Offset.zero);
      path.lineTo(v.dx, v.dy);
      return;
    }
    final s0 = at(start);
    path.lineTo(s0.dx, s0.dy);
    void cubic(Offset c1, Offset c2, Offset e) {
      final p1 = at(c1), p2 = at(c2), p3 = at(e);
      path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    }

    // The Bézier from the incoming side to the arc, tangent to the side at its start and to
    // the circle at its end, which is αIn = 45 sIn into the corner.
    final alphaIn = 45 * sIn;
    final arcStart = _onCircle(alphaIn);
    if (alphaIn > 0) {
      final c = r * math.tan(_rad(alphaIn / 2)) * math.cos(_rad(alphaIn));
      final b = (arcStart.dx - start.dx - c) / 3;
      cubic(start + Offset(2 * b, 0), start + Offset(3 * b, 0), arcStart);
    }
    // The circular part.
    final alphaOut = 45 * sOut;
    final arcEnd = _onCircle(90 - alphaOut);
    if (90 - alphaOut - alphaIn > 1e-9) {
      final e = at(arcEnd);
      path.arcToPoint(e, radius: Radius.circular(r));
    }
    // The Bézier from the arc to the outgoing side, the mirror of the first.
    if (alphaOut > 0) {
      final c = r * math.tan(_rad(alphaOut / 2)) * math.cos(_rad(alphaOut));
      final b = (end.dy - arcEnd.dy - c) / 3;
      cubic(Offset(0, arcEnd.dy + c), Offset(0, arcEnd.dy + b + c), end);
    }
  }
}
