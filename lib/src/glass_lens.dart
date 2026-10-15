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
// PROVISIONAL: the lens is not measured yet (LENS request to the reference Mac). Size,
// magnification and springs are the best macOS 27 estimate and may change in a minor version;
// names and types may not.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'glass.dart';

/// The sizes and springs of the [GlassLens] (*provisional*: not measured yet).
abstract final class GlassLensMetrics {
  /// The content under the lens is drawn this much larger (1.2–1.4 on macOS 27).
  static const double magnification = 1.3;

  /// The lens is this much wider than the pill it grows from.
  static const double widthScale = 1.12;

  /// The lens is this much taller than the pill it grows from (it rises past the track).
  static const double heightScale = 1.4;

  /// The travel between segments: a spring with a slight overshoot (~3 %).
  static final SpringDescription travelSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 520, ratio: 0.75);

  /// The swell on press: quick, overshooting a little.
  static final SpringDescription appearSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 700, ratio: 0.65);

  /// The shrink on release: quick, without a visible bounce.
  static final SpringDescription disappearSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 700, ratio: 0.9);

  /// The glass the pressed lens declares to Ossido (*provisional*: LENS, silica-reference #92).
  static const GlassMaterial material = GlassMaterial.regular;

  /// The body of the pressed lens: clear, so the glass and the content show through
  /// (*provisional*: LENS, silica-reference #92).
  static const Color clearFill = Color(0x00FFFFFF);

  /// The refracting band along the edge, as a fraction of the lens's half height.
  static const double refractionRim = 0.45;

  /// How far the band pulls the content inward, as a fraction of the band.
  static const double refractionStrength = 0.35;
}

/// The look of a [GlassLens]: the body, the rim (a highlight above, a darker edge below) and
/// the shadow under it. The rim and the shadow fade in with the lens's presence, so at
/// presence 0 the lens is exactly a pill of [fill].
@immutable
class GlassLensStyle {
  const GlassLensStyle({
    required this.fill,
    required this.highlight,
    required this.edge,
    required this.shadow,
  });

  /// The body; usually the selection pill's colour, so the lens grows out of it seamlessly.
  final Color fill;

  /// The rim's upper half (a light line along the top).
  final Color highlight;

  /// The rim's lower half.
  final Color edge;

  /// The soft shadow under the swollen lens.
  final Color shadow;

  /// Light: a white body with a bright rim (*provisional*).
  static const GlassLensStyle light = GlassLensStyle(
    fill: Color(0xFFFFFFFF),
    highlight: Color(0xFFFFFFFF),
    edge: Color(0x24000000),
    shadow: Color(0x2E000000),
  );

  /// Dark: a lifted gray body with a light rim above (*provisional*).
  static const GlassLensStyle dark = GlassLensStyle(
    fill: Color(0xFF5C5C5C),
    highlight: Color(0x66FFFFFF),
    edge: Color(0x33FFFFFF),
    shadow: Color(0x66000000),
  );

  /// The style for the system appearance.
  static GlassLensStyle of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;

  GlassLensStyle copyWith({
    Color? fill,
    Color? highlight,
    Color? edge,
    Color? shadow,
  }) => GlassLensStyle(
    fill: fill ?? this.fill,
    highlight: highlight ?? this.highlight,
    edge: edge ?? this.edge,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is GlassLensStyle &&
      other.fill == fill &&
      other.highlight == highlight &&
      other.edge == edge &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(fill, highlight, edge, shadow);
}

/// The lens rectangle for a pill `pill` at `presence` (0 the pill, 1 the full lens, above 1
/// while the swell overshoots): centred on the pill, [GlassLensMetrics.widthScale] ×
/// [GlassLensMetrics.heightScale] larger at presence 1.
Rect glassLensRect(Rect pill, double presence) {
  if (presence <= 0) return pill;
  final p = presence;
  return Rect.fromCenter(
    center: pill.center,
    width: pill.width * (1 + (GlassLensMetrics.widthScale - 1) * p),
    height: pill.height * (1 + (GlassLensMetrics.heightScale - 1) * p),
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
            ..setFloat(3, GlassLensMetrics.refractionStrength * p.clamp(0, 1));
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
          lens = Glass(radius: radius.x, material: material, child: lens);
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
    final ring = shape.deflate(0.5);
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [fade(style.highlight), fade(style.edge), fade(style.edge)],
          [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(GlassLensPainter old) =>
      old.style != style || old.presence != presence || old.rim != rim;
}
