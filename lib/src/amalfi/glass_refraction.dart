// The edge refraction of Glass/Regular and Glass/Thick for the Flutter backend of AmalfiGlass:
// a backdrop filter that runs `shaders/glass_edge.frag` on the (already blurred) backdrop,
// clipped to the glass shape. The shader works in the backdrop's physical pixels, so the shape's
// geometry is taken from the paint transform to the view at every paint (as the segmented
// lens does, `RenderGlassLensBackdrop`). Needs shader image filters (Impeller); without them
// AmalfiGlass tones the blurred backdrop with colour filters only.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../glass_lens.dart';
import 'components/popovers/popover_surface.dart';
import 'smooth_border.dart';
import 'token_types.dart';

/// Loads and hands out the edge-refraction shader of `AmalfiGlass`.
abstract final class AmalfiGlassRefraction {
  static const String shaderAsset =
      'packages/silica_ui/shaders/glass_edge.frag';
  static const String _rootAsset = 'shaders/glass_edge.frag';

  /// Whether the backdrop shader can run: the engine supports shader image filters (the same
  /// switch as the segmented lens, [GlassLens.refractionSupported]).
  static bool get supported => GlassLens.refractionSupported;

  /// The shader program, once loaded.
  static ui.FragmentProgram? get program => _program;
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loading;

  /// Tests: forgets the loaded shader.
  @visibleForTesting
  static void debugReset() {
    _program = null;
    _loading = null;
  }

  /// Loads the shader if the engine can use it; completes with null otherwise.
  static Future<ui.FragmentProgram?> load() {
    if (!supported) return SynchronousFuture(null);
    final loaded = _program;
    if (loaded != null) return SynchronousFuture(loaded);
    return _loading ??= ui.FragmentProgram.fromAsset(shaderAsset)
        .catchError((Object _) => ui.FragmentProgram.fromAsset(_rootAsset))
        .then<ui.FragmentProgram?>((p) => _program = p)
        .catchError((Object _) => null);
  }

  /// The rounded rectangle the shader approximates [shape] by, in the coordinates of a box of
  /// [size]: the body (a popover's arrow excluded) and the corner radius; null for an outline
  /// the shader cannot describe.
  static (Rect, double)? geometry(ShapeBorder shape, Size size) {
    final rect = Offset.zero & size;
    if (shape is AmalfiSmoothBorder) return (rect, shape.radius);
    if (shape is AmalfiPopoverBorder) {
      return (shape.shape.body(rect), AmalfiPopoverMetrics.radius);
    }
    return null;
  }
}

/// The backdrop filter that refracts the backdrop at the edge of [shape]; it fills its size.
class AmalfiGlassRefractionLayer extends LeafRenderObjectWidget {
  const AmalfiGlassRefractionLayer({
    super.key,
    required this.shader,
    required this.shape,
    required this.material,
    required this.brightness,
  });

  final ui.FragmentShader shader;
  final ShapeBorder shape;
  final AmalfiGlassMaterial material;
  final Brightness brightness;

  @override
  RenderAmalfiGlassRefraction createRenderObject(BuildContext context) =>
      RenderAmalfiGlassRefraction(
        shader: shader,
        shape: shape,
        material: material,
        brightness: brightness,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAmalfiGlassRefraction renderObject,
  ) {
    renderObject
      ..shader = shader
      ..shape = shape
      ..material = material
      ..brightness = brightness;
  }
}

/// The strength of the specular highlight along the top rim, by appearance.
const double _specularLight = 0.22;
const double _specularDark = 0.12;

class RenderAmalfiGlassRefraction extends RenderBox {
  RenderAmalfiGlassRefraction({
    required ui.FragmentShader shader,
    required ShapeBorder shape,
    required AmalfiGlassMaterial material,
    required Brightness brightness,
  }) : _shader = shader,
       _shape = shape,
       _material = material,
       _brightness = brightness;

  ui.FragmentShader get shader => _shader;
  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (identical(value, _shader)) return;
    _shader = value;
    markNeedsPaint();
  }

  ShapeBorder get shape => _shape;
  ShapeBorder _shape;
  set shape(ShapeBorder value) {
    if (value == _shape) return;
    _shape = value;
    markNeedsPaint();
  }

  AmalfiGlassMaterial get material => _material;
  AmalfiGlassMaterial _material;
  set material(AmalfiGlassMaterial value) {
    if (identical(value, _material)) return;
    _material = value;
    markNeedsPaint();
  }

  Brightness get brightness => _brightness;
  Brightness _brightness;
  set brightness(Brightness value) {
    if (value == _brightness) return;
    _brightness = value;
    markNeedsPaint();
  }

  /// The filter of the last paint (tests).
  @visibleForTesting
  ui.ImageFilter? get debugFilter => _filter;
  ui.ImageFilter? _filter;

  /// The float uniforms of the last paint from index 2 on (tests): the body's centre and half
  /// size in physical pixels, the pixels per point, the radius, distortion, depth, chromatic
  /// split, saturation, brightness and specular strength.
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

  void _configure(double radius, double pt, Rect physical) {
    final refraction = material.refraction;
    final dark = brightness == Brightness.dark;
    var i = 2; // 0 and 1: the backdrop size, set by the engine.
    _uniforms.clear();
    void put(double v) {
      _uniforms.add(v);
      shader.setFloat(i++, v);
    }

    put(physical.center.dx);
    put(physical.center.dy);
    put(physical.width / 2);
    put(physical.height / 2);
    put(pt);
    put(radius);
    put(refraction?.distortion ?? 0);
    put(refraction?.depth ?? 0);
    put(refraction?.chromaticAberration ?? 0);
    put(material.saturation);
    put(dark ? material.brightnessDark : material.brightnessLight);
    put(
      material.specularHighlights ? (dark ? _specularDark : _specularLight) : 0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final geometry = AmalfiGlassRefraction.geometry(shape, size);
    if (size.isEmpty || geometry == null) return;
    final (body, radius) = geometry;
    // To the view's physical pixels: the transform to the root includes the root's own
    // (the device pixel ratio), unlike `getTransformTo(null)`.
    final toView = getTransformTo(owner?.rootNode);
    final physical = MatrixUtils.transformRect(toView, body);
    _configure(radius, physical.width / body.width, physical);
    // ignore: invalid_use_of_visible_for_testing_member
    final filter = (GlassLens.debugShaderFilter ?? ui.ImageFilter.shader)(
      shader,
    );
    _filter = filter;
    final bounds = offset & size;
    layer = context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      shape.getOuterPath(Offset.zero & size),
      (context, offset) {
        final layer = _backdrop.layer ??= BackdropFilterLayer();
        layer.filter = filter;
        context.pushLayer(layer, (_, _) {}, offset, childPaintBounds: bounds);
      },
      clipBehavior: Clip.antiAlias,
      oldLayer: layer as ClipPathLayer?,
    );
  }

  @override
  void dispose() {
    _backdrop.layer = null;
    super.dispose();
  }
}

/// Holds the shader of an `AmalfiGlass` and loads it when needed.
mixin AmalfiGlassShaderState<T extends StatefulWidget> on State<T> {
  ui.FragmentShader? glassShader;

  /// Starts loading the shader if the engine supports it.
  void loadGlassShader() {
    if (!AmalfiGlassRefraction.supported || glassShader != null) return;
    final program = AmalfiGlassRefraction.program;
    if (program != null) {
      glassShader = program.fragmentShader();
      return;
    }
    unawaited(
      AmalfiGlassRefraction.load().then((p) {
        if (p != null && mounted && glassShader == null) {
          setState(() => glassShader = p.fragmentShader());
        }
      }),
    );
  }

  @override
  void dispose() {
    glassShader?.dispose();
    super.dispose();
  }
}
