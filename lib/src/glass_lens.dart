// The glass lens of the segmented controls (as in Clock's section switch on macOS 27): while
// the control is pressed, the selection swells into a lens of glass that magnifies what is
// under it and travels between segments on a spring; on release it shrinks back into the pill.
//
// The glass material behind windows and panels is drawn by Ossido from declared regions; the
// lens is drawn here, in Flutter: the body, its rim and a magnified copy of the content under
// it. Where the engine supports shader image filters (Impeller), a fragment shader
// (`shaders/glass_lens.frag`) bends the content near the lens edge like the rim of a lens;
// elsewhere (Skia, tests) the content is only magnified.
//
// Measured on macOS 27 (Clock's section switch, silica-reference #92, LENS): a capsule lens
// about 91 x 48 pt that magnifies 1.11 x, nearly transparent, with a thin dark outer edge, a
// 1 pt light line at the top and bottom and faint colour fringes on the curved ends.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'glass.dart';

/// A piecewise-linear curve through measured points: `points` are (time fraction, value) pairs,
/// ascending in time, the first at 0 and the last at 1. The value may leave 0..1 (overshoot).
class KeyframeCurve extends Curve {
  const KeyframeCurve(this.points);

  final List<(double, double)> points;

  @override
  double transformInternal(double t) {
    for (var i = 1; i < points.length; i++) {
      final (t1, v1) = points[i];
      if (t <= t1) {
        final (t0, v0) = points[i - 1];
        return t1 == t0 ? v1 : v0 + (v1 - v0) * (t - t0) / (t1 - t0);
      }
    }
    return points.last.$2;
  }
}

/// The sizes and timings of the [GlassLens], measured (LENS, silica-reference #92).
abstract final class GlassLensMetrics {
  /// The content under the lens is drawn this much larger (1.11 measured, both directions).
  static const double magnification = 1.11;

  /// The lens width (90-92 measured).
  static const double width = 91;

  /// The lens rises this far above and below the track (a 48 pt lens on a 36 pt track).
  static const double overhang = 6;

  /// Press on the selected segment: the lens grows out of the pill, first visible outside the
  /// track at +120 ms (height past 36 pt), full at +240 ms after one small bounce (height
  /// 42, 46, 44, 48 pt). Presence 0 is the pill, 1 the lens.
  static const Duration appearDuration = Duration(milliseconds: 240);
  static const Curve appearCurve = KeyframeCurve([
    (0, 0),
    (0.45, 0.35),
    (0.54, 0.7),
    (0.67, 1.05),
    (0.79, 0.95),
    (1, 1),
  ]);

  /// Press on another segment: the pill becomes the lens on the way (a lens at ~+120 ms, full
  /// size at ~+250 ms).
  static const Duration appearTravelDuration = Duration(milliseconds: 250);
  static const Curve appearTravelCurve = KeyframeCurve([
    (0, 0),
    (0.24, 0.2),
    (0.48, 0.55),
    (0.8, 0.95),
    (1, 1),
  ]);

  /// Press on another segment: the pill starts to slide at +28 ms and arrives at ~+400 ms (the
  /// last pixel by ~+500 ms).
  static const Duration travelDelay = Duration(milliseconds: 28);
  static const Duration travelDuration = Duration(milliseconds: 500);
  static const Curve travelCurve = Cubic(0.3, 0, 0.1, 1);

  /// Release inside: the lens is back to the pill in ~130 ms.
  static const Duration retractDuration = Duration(milliseconds: 130);

  /// Release outside (cancel): the lens shrinks in ~100 ms and the pill slides back in ~200 ms.
  static const Duration cancelRetractDuration = Duration(milliseconds: 100);
  static const Duration cancelReturnDuration = Duration(milliseconds: 200);

  /// The glass the pressed lens declares to Ossido.
  static const GlassMaterial material = GlassMaterial.regular;

  /// The kind of surface the lens declares: a small control on glass.
  static const GlassProfile profile = GlassProfile.control;

  /// The body of the pressed lens: clear, so the glass and the content show through.
  static const Color clearFill = Color(0x00FFFFFF);

  /// The refracting band along the edge, as a fraction of the lens's half height.
  static const double refractionRim = 0.45;

  /// How far the band pulls the content inward, as a fraction of the band.
  static const double refractionStrength = 0.35;

  /// The chromatic offset at the curved ends, in pt (the shader samples red and blue apart).
  static const double chromaticOffset = 1.2;
}

/// The look of a [GlassLens]: the body, the rim (a dark outer edge, a 1 pt light line inside
/// the top and bottom, colour fringes on the ends) and the shadow under it. The rim and the shadow fade in with the lens's presence, so at
/// presence 0 the lens is exactly a pill of [fill].
@immutable
class GlassLensStyle {
  const GlassLensStyle({
    required this.fill,
    required this.highlight,
    required this.edge,
    required this.shadow,
    this.fringeWarm = const Color(0x00000000),
    this.fringeCool = const Color(0x00000000),
  });

  /// The body; usually the selection pill's colour, so the lens grows out of it seamlessly.
  final Color fill;

  /// The 1 pt light line inside the top and bottom edges.
  final Color highlight;

  /// The dark outer edge.
  final Color edge;

  /// The soft shadow under the swollen lens.
  final Color shadow;

  /// The faint colour fringes on the left and right curved ends.
  final Color fringeWarm;
  final Color fringeCool;

  /// The measured look: it is the same in light and dark (Clock is always dark).
  static const GlassLensStyle clear = GlassLensStyle(
    fill: Color(0x00FFFFFF),
    highlight: Color(0x66FFFFFF),
    edge: Color(0x66000000),
    shadow: Color(0x33000000),
    fringeWarm: Color(0x33FF9A4D),
    fringeCool: Color(0x334DA6FF),
  );

  static const GlassLensStyle light = clear;
  static const GlassLensStyle dark = clear;

  /// The style for the system appearance.
  static GlassLensStyle of(BuildContext context) => clear;

  GlassLensStyle copyWith({
    Color? fill,
    Color? highlight,
    Color? edge,
    Color? shadow,
    Color? fringeWarm,
    Color? fringeCool,
  }) => GlassLensStyle(
    fill: fill ?? this.fill,
    highlight: highlight ?? this.highlight,
    edge: edge ?? this.edge,
    shadow: shadow ?? this.shadow,
    fringeWarm: fringeWarm ?? this.fringeWarm,
    fringeCool: fringeCool ?? this.fringeCool,
  );

  @override
  bool operator ==(Object other) =>
      other is GlassLensStyle &&
      other.fill == fill &&
      other.highlight == highlight &&
      other.edge == edge &&
      other.shadow == shadow &&
      other.fringeWarm == fringeWarm &&
      other.fringeCool == fringeCool;

  @override
  int get hashCode =>
      Object.hash(fill, highlight, edge, shadow, fringeWarm, fringeCool);
}

/// The lens rectangle for a pill `pill` at `presence` (0 the pill, 1 the full lens, above 1
/// while the swell overshoots): centred on the pill, growing to the size `lens` (by default
/// the measured 91 x 48 pt lens of the 36 pt track).
Rect glassLensRect(
  Rect pill,
  double presence, {
  Size lens = const Size(GlassLensMetrics.width, 48),
}) {
  if (presence <= 0) return pill;
  final p = presence;
  return Rect.fromCenter(
    center: pill.center,
    width: pill.width + (lens.width - pill.width) * p,
    height: pill.height + (lens.height - pill.height) * p,
  );
}

/// A lens of glass over `content`: a capsule at [rect] that shows `content` magnified around
/// its centre, with refraction along its edge where the engine allows it.
///
/// It fills its parent, in the same coordinate space as [content] and [rect]: place it in a
/// `Stack` with `Positioned.fill`, over the content it magnifies, and give it a copy of that
/// content (labels and icons as they would look under the lens). It ignores the pointer and
/// semantics. At [presence] 0 nothing is drawn.
class GlassLens extends StatefulWidget {
  const GlassLens({
    super.key,
    required this.rect,
    required this.presence,
    required this.content,
    this.magnification = GlassLensMetrics.magnification,
    this.style,
    this.refraction = true,
    this.material,
  });

  /// The lens bounds; a capsule (radius half the shorter side).
  final Rect rect;

  /// 0 hidden, 1 fully swollen; it may overshoot above 1. The magnification, the rim and the
  /// shadow grow with it.
  final double presence;

  /// The content under the lens, laid out at the size of the [GlassLens].
  final Widget content;

  /// The magnification at presence 1.
  final double magnification;

  /// Null: [GlassLensStyle.of].
  final GlassLensStyle? style;

  /// Bend the content along the edge with the lens shader, when the engine supports it.
  final bool refraction;

  /// When set, the lens also declares a glass region of this material to Ossido (a lens over
  /// transparent content, so the compositor draws the material behind it).
  final GlassMaterial? material;

  /// Whether the edge refraction can be drawn: shader image filters need Impeller.
  static bool get refractionSupported => ui.ImageFilter.isShaderFilterSupported;

  /// The lens shader, loaded once when first needed (null until loaded, or when loading fails).
  static ui.FragmentProgram? get program => _program;
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loading;

  /// The asset of the lens shader.
  static const String shaderAsset =
      'packages/silica_ui/shaders/glass_lens.frag';
  static const String _rootAsset = 'shaders/glass_lens.frag';

  /// Loads the lens shader if the engine can use it; completes with null otherwise.
  static Future<ui.FragmentProgram?> loadProgram() {
    if (!refractionSupported) return SynchronousFuture(null);
    // In an app the shader is under the package's prefix; in this package's own example and
    // tests it is a root asset.
    return _loading ??= ui.FragmentProgram.fromAsset(shaderAsset)
        .catchError((Object _) => ui.FragmentProgram.fromAsset(_rootAsset))
        .then<ui.FragmentProgram?>((p) => _program = p)
        .catchError((Object _) => null);
  }

  @override
  State<GlassLens> createState() => _GlassLensState();
}

class _GlassLensState extends State<GlassLens> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (widget.refraction) _load();
  }

  @override
  void didUpdateWidget(GlassLens old) {
    super.didUpdateWidget(old);
    if (widget.refraction && _shader == null) _load();
  }

  void _load() {
    final program = GlassLens.program;
    if (program != null) {
      _shader = program.fragmentShader();
      return;
    }
    if (!GlassLens.refractionSupported) return;
    unawaited(
      GlassLens.loadProgram().then((p) {
        if (p != null && mounted && _shader == null) {
          setState(() => _shader = p.fragmentShader());
        }
      }),
    );
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.presence;
    final rect = widget.rect;
    if (p <= 0.001 || rect.isEmpty) return const SizedBox.shrink();
    final style = widget.style ?? GlassLensStyle.of(context);
    final radius = Radius.circular(rect.shortestSide / 2);
    final scale = 1 + (widget.magnification - 1) * p.clamp(0.0, 1.5);
    final c = rect.center;
    final transform = Matrix4.identity()
      ..translateByDouble(-rect.left, -rect.top, 0, 1)
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.biggest;
        Widget magnified = ClipRRect(
          borderRadius: BorderRadius.all(radius),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: full.width,
            maxWidth: full.width,
            minHeight: full.height,
            maxHeight: full.height,
            child: Transform(transform: transform, child: widget.content),
          ),
        );
        final shader = widget.refraction ? _shader : null;
        if (shader != null) {
          shader
            ..setFloat(2, GlassLensMetrics.refractionRim)
            ..setFloat(3, GlassLensMetrics.refractionStrength * p.clamp(0, 1))
            ..setFloat(4, GlassLensMetrics.chromaticOffset * p.clamp(0, 1));
          magnified = ImageFiltered(
            key: const ValueKey('glass lens refraction'),
            imageFilter: ui.ImageFilter.shader(shader),
            child: magnified,
          );
        }
        Widget lens = CustomPaint(
          painter: GlassLensPainter(style: style, presence: p, rim: false),
          foregroundPainter: GlassLensPainter(
            style: style,
            presence: p,
            rim: true,
          ),
          child: magnified,
        );
        final material = widget.material;
        if (material != null) {
          lens = Glass(
            radius: radius.x,
            material: material,
            profile: GlassLensMetrics.profile,
            child: lens,
          );
        }
        return IgnorePointer(
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fromRect(
                  key: const ValueKey('glass lens'),
                  rect: rect,
                  child: lens,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints a lens capsule filling its size: with `rim` false the shadow and the body, with
/// `rim` true the rim over the content. The rim and the shadow are scaled by `presence`.
class GlassLensPainter extends CustomPainter {
  const GlassLensPainter({
    required this.style,
    required this.presence,
    this.rim = false,
  });

  final GlassLensStyle style;
  final double presence;
  final bool rim;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = presence.clamp(0.0, 1.0);
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide / 2),
    );
    Color fade(Color c) => c.withValues(alpha: c.a * t);
    if (!rim) {
      if (t > 0 && style.shadow.a > 0) {
        canvas.drawRRect(
          shape.shift(Offset(0, 1.5 * t)),
          Paint()
            ..color = fade(style.shadow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * t),
        );
      }
      canvas.drawRRect(shape, Paint()..color = style.fill);
      return;
    }
    if (t == 0) return;
    // The dark outer edge.
    canvas.drawRRect(
      shape.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = fade(style.edge),
    );
    final ring = shape.deflate(2);
    const clear = Color(0x00000000);
    // The light line inside the top and bottom edges.
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [
            fade(style.highlight),
            fade(style.highlight).withValues(alpha: 0),
            fade(style.highlight).withValues(alpha: 0),
            fade(style.highlight),
          ],
          [0, 0.12, 0.88, 1],
        ),
    );
    // Faint colour fringes on the curved ends.
    if (style.fringeWarm != clear || style.fringeCool != clear) {
      canvas.drawRRect(
        shape.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(size.width, 0),
            [
              fade(style.fringeWarm),
              fade(style.fringeWarm).withValues(alpha: 0),
              fade(style.fringeCool).withValues(alpha: 0),
              fade(style.fringeCool),
            ],
            [0, 0.2, 0.8, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(GlassLensPainter old) =>
      old.style != style || old.presence != presence || old.rim != rim;
}
