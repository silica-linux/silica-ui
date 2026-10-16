// The smooth capsule as the kit draws it.
//
// `AmalfiSmoothBorder` with a radius of half the height gives up the smoothing (no room on
// the short side) and draws a plain stadium. The kit keeps the smoothing along the long side:
// each corner starts (1 + s) × r from the end, runs the first Bézier of a smooth corner, then a
// circular arc of radius r straight to the middle of the short side (the Bézier ends on that
// circle). Measured on `Segments/Action/Icon 2/Regular` (56 × 28): the corner starts at 22.4,
// the Bézier ends at (14.76, 1.53) from it, the arc meets the side at y 14.
//
// Kept in this family until AmalfiSmoothBorder draws capsules this way (it would also fix the
// glass capsules, which AmalfiGlass draws with AmalfiSmoothBorder).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../tokens.g.dart';

/// A capsule (radius half the shorter side) with smooth ends, as the kit draws it; any other
/// radius is an [AmalfiSmoothBorder].
class AmalfiCapsuleBorder extends AmalfiSmoothBorder {
  const AmalfiCapsuleBorder({
    super.side,
    super.radius,
    super.smoothing = AmalfiRadii.smoothing,
  });

  @override
  AmalfiCapsuleBorder copyWith({
    BorderSide? side,
    double? radius,
    double? smoothing,
  }) => AmalfiCapsuleBorder(
    side: side ?? this.side,
    radius: radius ?? this.radius,
    smoothing: smoothing ?? this.smoothing,
  );

  @override
  AmalfiCapsuleBorder scale(double t) => AmalfiCapsuleBorder(
    side: side.scale(t),
    radius: radius * t,
    smoothing: smoothing,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      amalfiCapsulePath(rect, radius, smoothing);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = math.max(side.strokeInset, 0.0);
    return amalfiCapsulePath(rect.deflate(inset), radius - inset, smoothing);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    final offset = side.strokeOffset / 2;
    canvas.drawPath(
      amalfiCapsulePath(rect.inflate(offset), radius + offset, smoothing),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AmalfiCapsuleBorder &&
      other.side == side &&
      other.radius == radius &&
      other.smoothing == smoothing;

  @override
  int get hashCode => Object.hash(AmalfiCapsuleBorder, side, radius, smoothing);
}

/// The outline of [rect] with corners of [radius] and [smoothing]: the kit's smooth capsule
/// when [radius] is at least half the shorter side and the longer side leaves room for the
/// smoothing, otherwise [smoothRectPath].
Path amalfiCapsulePath(Rect rect, double radius, double smoothing) {
  if (!rect.isFinite || rect.width <= 0 || rect.height <= 0) return Path();
  final r = math.min(rect.width, rect.height) / 2;
  final s = smoothing.isFinite ? smoothing.clamp(0.0, 1.0) : 0.0;
  final long = math.max(rect.width, rect.height);
  final p = (1 + s) * r;
  if (!radius.isFinite || radius < r - 1e-9 || s <= 0 || p > long / 2) {
    return smoothRectPath(rect, radius, smoothing);
  }
  if (rect.height > rect.width) {
    // A vertical capsule: the horizontal one, transposed.
    final t = Matrix4.identity()
      ..setEntry(0, 0, 0)
      ..setEntry(0, 1, 1)
      ..setEntry(1, 0, 1)
      ..setEntry(1, 1, 0);
    final flat = amalfiCapsulePath(
      Rect.fromLTWH(rect.top, rect.left, rect.height, rect.width),
      radius,
      smoothing,
    );
    return flat.transform(t.storage);
  }

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
  final e = a + b + c; // where the Bézier ends, along the long side
  final circle = Radius.circular(r);

  final Rect(:left, :top, :right, :bottom) = rect;
  final cy = top + r;
  return Path()
    ..moveTo(left + p, top)
    ..lineTo(right - p, top)
    ..relativeCubicTo(a, 0, a + b, 0, e, d)
    ..arcToPoint(Offset(right, cy), radius: circle)
    ..arcToPoint(Offset(right - p + e, bottom - d), radius: circle)
    ..cubicTo(
      right - p + a + b,
      bottom,
      right - p + a,
      bottom,
      right - p,
      bottom,
    )
    ..lineTo(left + p, bottom)
    ..relativeCubicTo(-a, 0, -(a + b), 0, -e, -d)
    ..arcToPoint(Offset(left, cy), radius: circle)
    ..arcToPoint(Offset(left + p - e, top + d), radius: circle)
    ..cubicTo(left + p - a - b, top, left + p - a, top, left + p, top)
    ..close();
}
