// The opaque raised panel of alerts in a window and of dialogs (kit `Alerts/Alert/*`,
// `Dialogs/Dialog/*`): `Surface/Raised`, a 1 pt `Line/Border` inside, the level 3 shadow
// outside, smooth corners.
//
// The shadow follows the kit's (CSS) semantics, σ = blur / 2, as `AmalfiGlass` draws it.

import 'package:flutter/widgets.dart';

import '../../glass.dart' show amalfiShadowSigma;
import '../../smooth_border.dart';
import '../../theme.dart';

/// An opaque panel with smooth corners of [radius]: [color] (default `Surface/Raised`), a
/// 1 pt [borderColor] line inside the edge (default `Line/Border`) and, with [shadow], the
/// level 3 drop shadow of the appearance, drawn outside the shape only.
class AmalfiAlertSurface extends StatelessWidget {
  const AmalfiAlertSurface({
    super.key,
    this.radius = 20,
    this.color,
    this.borderColor,
    this.shadow = true,
    this.child,
  });

  /// The corner radius in points (smoothing 0.6).
  final double radius;

  /// The fill; null: `Surface/Raised`.
  final Color? color;

  /// The inside line; null: `Line/Border`.
  final Color? borderColor;

  /// Whether the level 3 shadow is drawn.
  final bool shadow;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    return CustomPaint(
      painter: _SurfacePainter(
        shape: AmalfiSmoothBorder(radius: radius),
        fill: color ?? theme.colors.surfaceRaised,
        border: borderColor ?? theme.colors.lineBorder,
        shadows: shadow
            ? theme.shadows.level(3) ?? const <BoxShadow>[]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }
}

class _SurfacePainter extends CustomPainter {
  const _SurfacePainter({
    required this.shape,
    required this.fill,
    required this.border,
    required this.shadows,
  });

  final AmalfiSmoothBorder shape;
  final Color fill;
  final Color border;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final outline = shape.getOuterPath(rect);
    paintOutsideShadows(canvas, rect, outline, shape, shadows);
    canvas
      ..drawPath(outline, Paint()..color = fill)
      ..save()
      ..clipPath(outline)
      ..drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = border,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.border != border ||
      old.shadows != shadows;
}

/// Paints [shadows] of the shape [outline] (in [rect], drawn by [shape] at a grown size for
/// a spread) outside [outline] only, with σ = blur / 2.
void paintOutsideShadows(
  Canvas canvas,
  Rect rect,
  Path outline,
  AmalfiSmoothBorder shape,
  List<BoxShadow> shadows, {
  Path Function(Rect rect)? pathAt,
}) {
  if (shadows.isEmpty) return;
  var reach = 0.0;
  for (final s in shadows) {
    final r = s.blurRadius + s.spreadRadius + s.offset.distance;
    if (r > reach) reach = r;
  }
  canvas
    ..save()
    ..clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(reach * 2 + 1)),
        outline,
      ),
    );
  for (final s in shadows) {
    final paint = Paint()
      ..color = s.color
      ..maskFilter = s.blurRadius > 0
          ? MaskFilter.blur(BlurStyle.normal, amalfiShadowSigma(s.blurRadius))
          : null;
    final cast = rect.shift(s.offset).inflate(s.spreadRadius);
    canvas.drawPath(
      pathAt?.call(cast) ??
          shape
              .copyWith(radius: shape.radius + s.spreadRadius)
              .getOuterPath(cast),
      paint,
    );
  }
  canvas.restore();
}
