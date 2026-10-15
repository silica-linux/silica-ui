// The glass lens of the segmented controls (as in Clock's section switch on macOS 27): while
// the control is pressed, the selection swells into a lens of glass that magnifies what is
// under it and travels between segments on a spring; on release it shrinks back into the pill.
//
// The lens is drawn here, in Flutter, from the window's own pixels under it. Where the engine
// supports shader image filters (Impeller), it is a backdrop filter clipped to the capsule that
// runs `shaders/glass_lens.frag` on what is already painted below: the track, its rim, the pill,
// the labels and, where the lens overhangs the control, the toolbar. The shader magnifies them,
// bends them near the rim, blurs the rim slightly, splits red and blue on the curved ends and
// draws the dark outer edge and the light lines. Elsewhere (Skia, tests) the lens falls back to
// a magnified copy of the content it is given, with the rim painted over it.
//
// No glass region is declared to Ossido for the lens (by default): the compositor's glass shows
// what is behind the window, and the lens refracts the window's own content. Over the track
// that content is opaque, so a region would never show; where the lens overhangs the toolbar,
// the toolbar's own glass region already provides the material behind the window, and a second
// region would double its blur, edge light and shadow.
//
// Measured on macOS 27 (Clock's section switch, silica-reference #92, LENS): a capsule lens
// about 91 x 48 pt that magnifies 1.11 x, nearly transparent, with a thin dark outer edge, a
// 1 pt light line at the top and bottom, the track's edge lines seen refracted ~3 pt inside it
// and faint colour fringes on the curved ends.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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

  /// The glass a [GlassLens] declares to Ossido when asked to ([GlassLens.material]); the
  /// segmented control declares none (see the top of this file).
  static const GlassMaterial material = GlassMaterial.regular;

  /// The kind of surface a lens with a glass region declares: a small control on glass.
  static const GlassProfile profile = GlassProfile.control;

  /// The body of the pressed lens: clear, so the content shows through.
  static const Color clearFill = Color(0x00FFFFFF);

  /// How far outward the backdrop is sampled at the very rim, in pt, growing with the square
  /// of the distance from the centre. 11.5 puts the track's edge lines (18 pt from the centre)
  /// ~3 pt inside the 24 pt half height of the lens, as measured: 15 / 1.11 + 11.5 (15/24)^2
  /// = 18.
  static const double refractionDepth = 11.5;

  /// The blur radius at the rim, in pt (none at the centre).
  static const double rimBlur = 1.2;

  /// The chromatic offset at the curved ends, in pt (the shader samples red and blue apart).
  static const double chromaticOffset = 1.2;

  /// The glass is a little brighter than what it shows (+2-4 levels measured on the track).
  static const double lift = 3 / 255;
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

/// A lens of glass at [rect]: a capsule that shows what is painted under it, magnified around
/// its centre and refracted along its edge.
///
/// It fills its parent, in the same coordinate space as [rect]: place it in a `Stack` with
/// `Positioned.fill`, over the content it magnifies. Where the engine supports shader image
/// filters (Impeller) and [refraction] is on, the lens is a backdrop filter: it refracts the
/// pixels already painted below it, so it must paint after them (an overlay is the surest
/// place) and [content] is not used. Otherwise it shows [content] (a copy of what lies under
/// it, laid out at the size of the [GlassLens]) magnified, with the rim painted over it: see
/// [usesBackdrop]. It ignores the pointer and semantics. At [presence] 0 nothing is drawn.
class GlassLens extends StatefulWidget {
  const GlassLens({
    super.key,
    required this.rect,
    required this.presence,
    this.content,
    this.magnification = GlassLensMetrics.magnification,
    this.style,
    this.refraction = true,
    this.material,
  });

  /// The lens bounds; a capsule (radius half the shorter side).
  final Rect rect;

  /// 0 hidden, 1 fully swollen; it may overshoot above 1. The magnification, the refraction,
  /// the rim and the shadow grow with it.
  final double presence;

  /// The fallback content under the lens (when it is not a backdrop filter), laid out at the
  /// size of the [GlassLens]. Null: the fallback shows only the body and the rim.
  final Widget? content;

  /// The magnification at presence 1.
  final double magnification;

  /// Null: [GlassLensStyle.of].
  final GlassLensStyle? style;

  /// Refract the backdrop with the lens shader, when the engine supports it.
  final bool refraction;

  /// When set, the lens also declares a glass region of this material to Ossido, so the
  /// compositor draws the material behind the window under it. Only useful where the window is
  /// transparent under the lens; the segmented control leaves it null.
  final GlassMaterial? material;

  /// Whether the backdrop refraction can be drawn: shader image filters need Impeller.
  static bool get refractionSupported =>
      debugRefractionSupportedOverride ??
      ui.ImageFilter.isShaderFilterSupported;

  /// Tests: pretend the engine does (true) or does not (false) support shader image filters.
  @visibleForTesting
  static bool? debugRefractionSupportedOverride;

  /// Tests: builds the backdrop filter from the configured lens shader instead of
  /// `ImageFilter.shader`, which throws without Impeller.
  @visibleForTesting
  static ui.ImageFilter Function(ui.FragmentShader shader)? debugShaderFilter;

  /// Whether a lens with [refraction] is drawn as a backdrop filter now: the engine supports it
  /// and the shader is loaded ([loadProgram]). Otherwise it shows its [content].
  static bool get usesBackdrop => refractionSupported && _program != null;

  /// The lens shader, loaded once when first needed (null until loaded, or when loading fails).
  static ui.FragmentProgram? get program => _program;
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loading;

  /// Tests: forgets the loaded shader.
  @visibleForTesting
  static void debugReset() {
    _program = null;
    _loading = null;
  }

  /// The asset of the lens shader.
  static const String shaderAsset =
      'packages/silica_ui/shaders/glass_lens.frag';
  static const String _rootAsset = 'shaders/glass_lens.frag';

  /// Loads the lens shader if the engine can use it; completes with null otherwise.
  static Future<ui.FragmentProgram?> loadProgram() {
    if (!refractionSupported) return SynchronousFuture(null);
    final loaded = _program;
    if (loaded != null) return SynchronousFuture(loaded);
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
    if (!GlassLens.refractionSupported) return;
    final program = GlassLens.program;
    if (program != null) {
      _shader = program.fragmentShader();
      return;
    }
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
    final shader = widget.refraction && GlassLens.refractionSupported
        ? _shader
        : null;

    Widget lens;
    if (shader != null) {
      lens = _LensBackdrop(
        key: const ValueKey('glass lens refraction'),
        shader: shader,
        presence: p,
        magnification: scale,
        style: style,
      );
    } else {
      lens = LayoutBuilder(
        builder: (context, constraints) {
          final full = constraints.biggest;
          final c = rect.center;
          final transform = Matrix4.identity()
            ..translateByDouble(-rect.left, -rect.top, 0, 1)
            ..translateByDouble(c.dx, c.dy, 0, 1)
            ..scaleByDouble(scale, scale, 1, 1)
            ..translateByDouble(-c.dx, -c.dy, 0, 1);
          final content = widget.content;
          return CustomPaint(
            painter: GlassLensPainter(style: style, presence: p, rim: false),
            foregroundPainter: GlassLensPainter(
              style: style,
              presence: p,
              rim: true,
            ),
            child: content == null
                ? const SizedBox.expand()
                : ClipRRect(
                    borderRadius: BorderRadius.all(radius),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: full.width,
                      maxWidth: full.width,
                      minHeight: full.height,
                      maxHeight: full.height,
                      child: Transform(transform: transform, child: content),
                    ),
                  ),
          );
        },
      );
    }
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
  }
}

/// The lens as a backdrop filter: the backdrop under its capsule, refracted by the lens shader.
class _LensBackdrop extends LeafRenderObjectWidget {
  const _LensBackdrop({
    super.key,
    required this.shader,
    required this.presence,
    required this.magnification,
    required this.style,
  });

  final ui.FragmentShader shader;
  final double presence;
  final double magnification;
  final GlassLensStyle style;

  @override
  RenderGlassLensBackdrop createRenderObject(BuildContext context) =>
      RenderGlassLensBackdrop(
        shader: shader,
        presence: presence,
        magnification: magnification,
        style: style,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlassLensBackdrop renderObject,
  ) {
    renderObject
      ..shader = shader
      ..presence = presence
      ..magnification = magnification
      ..style = style;
  }
}

/// Paints a [GlassLens] as a backdrop filter clipped to its capsule (it fills its size). The
/// shader works in the backdrop's physical pixels, so the lens geometry is taken from the
/// paint transform to the view at every paint.
class RenderGlassLensBackdrop extends RenderBox {
  RenderGlassLensBackdrop({
    required ui.FragmentShader shader,
    required double presence,
    required double magnification,
    required GlassLensStyle style,
  }) : _shader = shader,
       _presence = presence,
       _magnification = magnification,
       _style = style;

  ui.FragmentShader get shader => _shader;
  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (identical(value, _shader)) return;
    _shader = value;
    markNeedsPaint();
  }

  double get presence => _presence;
  double _presence;
  set presence(double value) {
    if (value == _presence) return;
    _presence = value;
    markNeedsPaint();
  }

  /// The magnification at the current presence.
  double get magnification => _magnification;
  double _magnification;
  set magnification(double value) {
    if (value == _magnification) return;
    _magnification = value;
    markNeedsPaint();
  }

  GlassLensStyle get style => _style;
  GlassLensStyle _style;
  set style(GlassLensStyle value) {
    if (value == _style) return;
    _style = value;
    markNeedsPaint();
  }

  /// The filter of the last paint (tests).
  @visibleForTesting
  ui.ImageFilter? get debugFilter => _filter;
  ui.ImageFilter? _filter;

  /// The float uniforms of the last paint from index 2 on (tests): the lens centre and half
  /// size in physical pixels, the pixels per point, the magnification, the refraction depth,
  /// the rim blur, the chromatic offset, the presence, the lift, the edge and highlight colours.
  @visibleForTesting
  List<double> get debugUniforms => List.unmodifiable(_uniforms);
  final List<double> _uniforms = [];

  final LayerHandle<BackdropFilterLayer> _backdrop =
      LayerHandle<BackdropFilterLayer>();

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool hitTestSelf(Offset position) => false;

  /// Sets the shader's uniforms for a lens at `physical` (the lens in the backdrop's physical
  /// pixels) with `pt` physical pixels per point.
  void _configure(Rect physical, double pt) {
    final t = presence.clamp(0.0, 1.0);
    final c = physical.center;
    var i = 2; // 0 and 1: the backdrop size, set by the engine.
    _uniforms.clear();
    void put(double v) {
      _uniforms.add(v);
      shader.setFloat(i++, v);
    }

    void color(Color c) {
      put(c.r);
      put(c.g);
      put(c.b);
      put(c.a);
    }

    put(c.dx);
    put(c.dy);
    put(physical.width / 2);
    put(physical.height / 2);
    put(pt);
    put(magnification);
    put(GlassLensMetrics.refractionDepth * t);
    put(GlassLensMetrics.rimBlur * t);
    put(GlassLensMetrics.chromaticOffset * t);
    put(t);
    put(GlassLensMetrics.lift);
    color(style.edge);
    color(style.highlight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    // To the view's physical pixels: the transform to the root includes the root's own
    // (the device pixel ratio), unlike `getTransformTo(null)`.
    final toView = getTransformTo(owner?.rootNode);
    final physical = MatrixUtils.transformRect(toView, Offset.zero & size);
    _configure(physical, physical.width / size.width);
    final filter = (GlassLens.debugShaderFilter ?? ui.ImageFilter.shader)(
      shader,
    );
    _filter = filter;
    final bounds = offset & size;
    layer = context.pushClipRRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.shortestSide / 2),
      ),
      (context, offset) {
        final layer = _backdrop.layer ??= BackdropFilterLayer();
        layer.filter = filter;
        context.pushLayer(layer, (_, _) {}, offset, childPaintBounds: bounds);
      },
      clipBehavior: Clip.antiAlias,
      oldLayer: layer as ClipRRectLayer?,
    );
  }

  @override
  void dispose() {
    _backdrop.layer = null;
    super.dispose();
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
