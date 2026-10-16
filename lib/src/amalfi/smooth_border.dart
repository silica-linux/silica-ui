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

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// A rectangle with smooth (continuous) corners: [radius] in points, [smoothing] from 0
/// (circular arcs, as [RoundedRectangleBorder]) to 1. Amalfi draws every rounded surface with
/// [AmalfiRadii.smoothing] (the default).
///
/// The radius is clamped to half the shorter side, so a large radius gives a capsule.
class AmalfiSmoothBorder extends OutlinedBorder {
  const AmalfiSmoothBorder({
    super.side,
    this.radius = 0,
    this.smoothing = AmalfiRadii.smoothing,
  });

  /// The corner radius in points (negative counts as 0).
  final double radius;

  /// How far the corner blends into the sides (clamped to 0–1).
  final double smoothing;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(math.max(side.strokeInset, 0));

  @override
  AmalfiSmoothBorder scale(double t) => AmalfiSmoothBorder(
    side: side.scale(t),
    radius: radius * t,
    smoothing: smoothing,
  );

  @override
  AmalfiSmoothBorder copyWith({
    BorderSide? side,
    double? radius,
    double? smoothing,
  }) => AmalfiSmoothBorder(
    side: side ?? this.side,
    radius: radius ?? this.radius,
    smoothing: smoothing ?? this.smoothing,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is AmalfiSmoothBorder) {
      return AmalfiSmoothBorder(
        side: BorderSide.lerp(a.side, side, t),
        radius: _lerp(a.radius, radius, t),
        smoothing: _lerp(a.smoothing, smoothing, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is AmalfiSmoothBorder) {
      return AmalfiSmoothBorder(
        side: BorderSide.lerp(side, b.side, t),
        radius: _lerp(radius, b.radius, t),
        smoothing: _lerp(smoothing, b.smoothing, t),
      );
    }
    return super.lerpTo(b, t);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      smoothRectPath(rect, radius, smoothing);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = math.max(side.strokeInset, 0.0);
    return smoothRectPath(rect.deflate(inset), radius - inset, smoothing);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    // The stroke is centred on a path offset by the stroke alignment, so that inside (-1)
    // keeps it within [rect] and outside (1) puts it all beyond it.
    final offset = side.strokeOffset / 2;
    canvas.drawPath(
      smoothRectPath(rect.inflate(offset), radius + offset, smoothing),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AmalfiSmoothBorder &&
      other.side == side &&
      other.radius == radius &&
      other.smoothing == smoothing;

  @override
  int get hashCode => Object.hash(side, radius, smoothing);

  @override
  String toString() =>
      'AmalfiSmoothBorder($side, radius: $radius, smoothing: $smoothing)';
}

/// The outline of [rect] with smooth corners of [radius] and [smoothing] (see
/// [AmalfiSmoothBorder]). An empty or non-finite rect gives an empty path.
Path smoothRectPath(Rect rect, double radius, double smoothing) {
  final path = Path();
  if (!rect.isFinite || rect.width <= 0 || rect.height <= 0) return path;
  final budget = math.min(rect.width, rect.height) / 2;
  final r = radius.isFinite ? radius.clamp(0.0, budget) : 0.0;
  if (r <= 0) return path..addRect(rect);
  var s = smoothing.isFinite ? smoothing.clamp(0.0, 1.0) : 0.0;
  // Shrink the smoothing until the corner fits in its half of the shorter side.
  s = math.min(s, budget / r - 1);
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
  final a = 2 * b;
  final radiusOf = Radius.circular(r);

  final Rect(:left, :top, :right, :bottom) = rect;
  path.moveTo(left + p, top);
  // Top edge, then the top-right corner.
  path
    ..lineTo(right - p, top)
    ..relativeCubicTo(a, 0, a + b, 0, a + b + c, d)
    ..relativeArcToPoint(Offset(l, l), radius: radiusOf)
    ..relativeCubicTo(d, c, d, b + c, d, a + b + c)
    // Right edge, bottom-right corner.
    ..lineTo(right, bottom - p)
    ..relativeCubicTo(0, a, 0, a + b, -d, a + b + c)
    ..relativeArcToPoint(Offset(-l, l), radius: radiusOf)
    ..relativeCubicTo(-c, d, -(b + c), d, -(a + b + c), d)
    // Bottom edge, bottom-left corner.
    ..lineTo(left + p, bottom)
    ..relativeCubicTo(-a, 0, -(a + b), 0, -(a + b + c), -d)
    ..relativeArcToPoint(Offset(-l, -l), radius: radiusOf)
    ..relativeCubicTo(-d, -c, -d, -(b + c), -d, -(a + b + c))
    // Left edge, top-left corner.
    ..lineTo(left, top + p)
    ..relativeCubicTo(0, -a, 0, -(a + b), d, -(a + b + c))
    ..relativeArcToPoint(Offset(l, -l), radius: radiusOf)
    ..relativeCubicTo(c, -d, b + c, -d, a + b + c, -d)
    ..close();
  return path;
}
