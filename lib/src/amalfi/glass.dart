// The Amalfi glass surface: Glass/Regular, Glass/Thick and the static look of Glass/Clear,
// drawn in the order of `materials.md`: backdrop → blur → saturation → tint → inside rim →
// rim light → content, with the drop shadow outside the shape only.
//
// The kit's (CSS) blur semantics are kept: a background blur of radius r is a Gaussian of
// σ = r; a drop or inner shadow of blur b is a Gaussian of σ = b / 2.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'smooth_border.dart';
import 'theme.dart';
import 'token_types.dart';
import 'tokens.g.dart';

/// A surface of an Amalfi glass [material] with smooth corners of [radius], holding [child]
/// (which is not clipped: keep it inside the shape).
///
/// The appearance comes from [AmalfiTheme.of]. With [opaque] (no blur available, or reduced
/// transparency) the backdrop is replaced by `Surface/Window` under the tint, as
/// `materials.md` asks; rims and shadow stay. A lens material ([AmalfiMaterials.clear]) is
/// drawn without its refraction: the lens itself is a separate, animated effect.
class AmalfiGlass extends StatelessWidget {
  const AmalfiGlass({
    super.key,
    this.material = AmalfiMaterials.thick,
    this.radius = 0,
    this.opaque = false,
    this.child,
  });

  /// The material (`AmalfiMaterials.regular`, `.thick`, `.clear`).
  final AmalfiGlassMaterial material;

  /// The corner radius in points (smoothing [AmalfiRadii.smoothing]); a radius of at least
  /// half the shorter side gives a capsule.
  final double radius;

  /// Whether to draw an opaque fallback instead of blurring the backdrop.
  final bool opaque;

  final Widget? child;

  /// The drop shadows of [material] in [brightness]; empty when it has none.
  static List<BoxShadow> shadowsOf(
    AmalfiGlassMaterial material,
    Brightness brightness,
  ) {
    final level = material.shadowLevel;
    if (level == null) return const [];
    return AmalfiShadows.of(brightness).level(level) ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final brightness = theme.brightness;
    final shape = AmalfiSmoothBorder(radius: radius);
    final face = CustomPaint(
      painter: _GlassFacePainter(
        shape: shape,
        under: opaque ? theme.colors.surfaceWindow : null,
        tint: material.tint(brightness),
        rim: material.rimInside(brightness),
        rimWidth: material.rimInsideWidth,
        rimLight: material.rimLight(brightness),
        rimLightOffset: material.rimLightOffset,
        rimLightBlur: material.rimLightBlur,
      ),
      child: child,
    );
    final saturation = material.saturation;
    // The backdrop blur is clipped to the shape; the face is drawn unclipped with its own
    // antialiased outline, so that the edge pixels are not antialiased twice.
    return CustomPaint(
      painter: _OutsideShadowPainter(
        shape: shape,
        shadows: shadowsOf(material, brightness),
      ),
      child: Stack(
        children: [
          if (!opaque)
            Positioned.fill(
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: ColorFilter.matrix(_saturationMatrix(saturation)),
                    inner: ui.ImageFilter.blur(
                      sigmaX: material.backgroundBlur,
                      sigmaY: material.backgroundBlur,
                      tileMode: TileMode.clamp,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          face,
        ],
      ),
    );
  }
}

/// The colour matrix that multiplies the saturation by [s] (Rec. 709 luma weights).
List<double> _saturationMatrix(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final t = 1 - s;
  return [
    r * t + s, g * t, b * t, 0, 0, //
    r * t, g * t + s, b * t, 0, 0, //
    r * t, g * t, b * t + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// The σ of a kit shadow of blur [blur] (CSS box-shadow semantics).
double amalfiShadowSigma(double blur) => blur / 2;

/// Paints [shadows] of [shape] outside the shape only, as the kit draws them under glass.
class _OutsideShadowPainter extends CustomPainter {
  const _OutsideShadowPainter({required this.shape, required this.shadows});

  final AmalfiSmoothBorder shape;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty || size.isEmpty) return;
    final rect = Offset.zero & size;
    final outline = shape.getOuterPath(rect);
    var reach = 0.0;
    for (final s in shadows) {
      reach = [
        reach,
        s.blurRadius + s.spreadRadius + s.offset.distance,
      ].reduce((a, b) => a > b ? a : b);
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
        shape
            .copyWith(radius: shape.radius + s.spreadRadius)
            .getOuterPath(cast),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutsideShadowPainter old) =>
      old.shape != shape || old.shadows != shadows;
}

/// Paints the face of the glass: optional opaque base, tint, inside rim, rim light.
class _GlassFacePainter extends CustomPainter {
  const _GlassFacePainter({
    required this.shape,
    required this.under,
    required this.tint,
    required this.rim,
    required this.rimWidth,
    required this.rimLight,
    required this.rimLightOffset,
    required this.rimLightBlur,
  });

  final AmalfiSmoothBorder shape;
  final Color? under;
  final Color? tint;
  final Color rim;
  final double rimWidth;
  final Color rimLight;
  final Offset rimLightOffset;
  final double rimLightBlur;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final outline = shape.getOuterPath(rect);
    if (under case final color?) {
      canvas.drawPath(outline, Paint()..color = color);
    }
    if (tint case final color?) {
      canvas.drawPath(outline, Paint()..color = color);
    }
    if (rimWidth > 0) {
      // An inside stroke of the outline itself (as the kit strokes it): twice as wide,
      // clipped to the shape.
      canvas
        ..save()
        ..clipPath(outline)
        ..drawPath(
          outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = rimWidth * 2
            ..color = rim,
        )
        ..restore();
    }
    // The rim light: an inner shadow, the light falling inside the edge from [rimLightOffset].
    final reach = rimLightBlur * 2 + rimLightOffset.distance + 1;
    canvas
      ..save()
      ..clipPath(outline)
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rect.inflate(reach)),
          shape.getOuterPath(rect.shift(rimLightOffset)),
        ),
        Paint()
          ..color = rimLight
          ..maskFilter = rimLightBlur > 0
              ? MaskFilter.blur(
                  BlurStyle.normal,
                  amalfiShadowSigma(rimLightBlur),
                )
              : null,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_GlassFacePainter old) =>
      old.shape != shape ||
      old.under != under ||
      old.tint != tint ||
      old.rim != rim ||
      old.rimWidth != rimWidth ||
      old.rimLight != rimLight ||
      old.rimLightOffset != rimLightOffset ||
      old.rimLightBlur != rimLightBlur;
}
