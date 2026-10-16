// Shapes painted as the kit paints them: drop shadows with CSS `box-shadow` semantics, drawn
// outside the shape only, and inside borders stroked on the outline itself.
//
// The kit (and `tokens.json`) gives a shadow's blur b as a CSS blur: a Gaussian of σ = b / 2,
// where Flutter's own [BoxShadow] uses σ ≈ 0.58 b + 0.5. A shadow never shows through a
// translucent fill (glass, a hover overlay), so it is clipped to the outside of the shape.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../smooth_border.dart';
import '../tokens.g.dart';

/// The σ of a kit shadow of blur [blur] (CSS box-shadow semantics).
double amalfiShadowSigma(double blur) => blur / 2;

/// The soft shadow of raised opaque controls at rest (push buttons, checkbox and radio boxes,
/// switch and slider thumbs, the selected segment, the disclosure button): `Shadow/Soft`,
/// 0, 1, blur 2 — the kit's control shadow, which keeps the level 1 geometry
/// ([AmalfiShadows.level1]) in the `Shadow/Soft` colour.
List<BoxShadow> amalfiControlShadows(AmalfiColors colors) => [
  BoxShadow(
    color: colors.shadowSoft,
    offset: const Offset(0, 1),
    blurRadius: 2,
  ),
];

/// [shape] grown by [delta] on every side, for a shadow's spread: an [AmalfiSmoothBorder]
/// grows its rounded corners with it (square corners stay square).
ShapeBorder _spread(ShapeBorder shape, double delta) =>
    delta != 0 && shape is AmalfiSmoothBorder
    ? shape.inflateRadii(delta)
    : shape;

/// Paints [shadows] of [shape] laid out in [rect] outside the shape only, each blurred with
/// σ = blur / 2. [outlineAt] gives the outline of the shape in a rect (default: [shape]'s
/// outer path); a spread grows the rect (and an [AmalfiSmoothBorder]'s radii).
void paintAmalfiShadows(
  Canvas canvas,
  Rect rect,
  List<BoxShadow> shadows, {
  ShapeBorder? shape,
  Path Function(Rect rect)? outlineAt,
  TextDirection? textDirection,
}) {
  if (shadows.isEmpty || rect.isEmpty || !rect.isFinite) return;
  assert(shape != null || outlineAt != null);
  Path outline(Rect r, double spread) =>
      outlineAt?.call(r) ??
      _spread(shape!, spread).getOuterPath(r, textDirection: textDirection);
  var reach = 0.0;
  for (final s in shadows) {
    reach = math.max(
      reach,
      s.blurRadius * 2 + s.spreadRadius.abs() + s.offset.distance + 1,
    );
  }
  canvas
    ..save()
    ..clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(reach)),
        outline(rect, 0),
      ),
    );
  for (final s in shadows) {
    final paint = Paint()
      ..color = s.color
      ..maskFilter = s.blurRadius > 0
          ? MaskFilter.blur(BlurStyle.normal, amalfiShadowSigma(s.blurRadius))
          : null;
    canvas.drawPath(
      outline(rect.shift(s.offset).inflate(s.spreadRadius), s.spreadRadius),
      paint,
    );
  }
  canvas.restore();
}

/// Strokes [side] inside [shape] laid out in [rect]: an [OutlinedBorder] strokes it as its
/// own `paint` does (on the outline inset by half the width, which matches the kit's inside
/// borders at the smooth corners); any other shape on its outline, twice as wide and clipped
/// to the shape.
void paintAmalfiInsideBorder(
  Canvas canvas,
  Rect rect,
  ShapeBorder shape,
  BorderSide side, {
  TextDirection? textDirection,
}) {
  if (side.style == BorderStyle.none || side.width <= 0) return;
  final inside = side.copyWith(strokeAlign: BorderSide.strokeAlignInside);
  if (shape is OutlinedBorder) {
    shape
        .copyWith(side: inside)
        .paint(canvas, rect, textDirection: textDirection);
    return;
  }
  final outline = shape.getOuterPath(rect, textDirection: textDirection);
  canvas
    ..save()
    ..clipPath(outline)
    ..drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width * 2
        ..color = side.color,
    )
    ..restore();
}

/// A [ShapeDecoration] painted as the kit draws a shape: its [shadows] outside the shape only,
/// each [BoxShadow.blurRadius] read as a CSS blur (σ = blur / 2); then the fill, the gradient
/// and the shape's border.
///
/// Use it for every opaque Amalfi surface (`DecoratedBox(decoration: AmalfiShapeDecoration(…))`)
/// so that its shadows have the kit's blur.
class AmalfiShapeDecoration extends ShapeDecoration {
  const AmalfiShapeDecoration({
    super.color,
    super.gradient,
    super.shadows,
    required super.shape,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _AmalfiShapePainter(this, onChanged);

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) =>
      a is AmalfiShapeDecoration ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) =>
      b is AmalfiShapeDecoration ? _lerp(this, b, t) : super.lerpTo(b, t);

  static AmalfiShapeDecoration _lerp(
    AmalfiShapeDecoration a,
    AmalfiShapeDecoration b,
    double t,
  ) {
    final s = ShapeDecoration.lerp(a, b, t)!;
    return AmalfiShapeDecoration(
      color: s.color,
      gradient: s.gradient,
      shadows: s.shadows,
      shape: s.shape,
    );
  }
}

class _AmalfiShapePainter extends BoxPainter {
  _AmalfiShapePainter(this._decoration, super.onChanged);

  final AmalfiShapeDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty || !size.isFinite) return;
    final rect = offset & size;
    final direction = configuration.textDirection;
    final shape = _decoration.shape;
    final outline = shape.getOuterPath(rect, textDirection: direction);

    paintAmalfiShadows(
      canvas,
      rect,
      _decoration.shadows ?? const [],
      shape: shape,
      textDirection: direction,
    );
    final color = _decoration.color;
    final gradient = _decoration.gradient;
    if (color != null) canvas.drawPath(outline, Paint()..color = color);
    if (gradient != null) {
      canvas.drawPath(
        outline,
        Paint()..shader = gradient.createShader(rect, textDirection: direction),
      );
    }
    shape.paint(canvas, rect, textDirection: direction);
  }
}
