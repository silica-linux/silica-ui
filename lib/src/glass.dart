// Glass computed by Ossido (silica-glass-v1, docs/protocols.md): the widget declares its
// area, the compositor puts the blurred background of the material behind it. The child
// draws on top (text, icons) and leaves the rest transparent.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The measured glasses: clear (Dock), thick (menus, search), regular (the Liquid Glass of
/// controls, with the strong lens on the edge) and notification (banners and Notification Center).
enum GlassMaterial { clear, thick, regular, notification }

/// A glass area as large as its child, with circular-arc corners.
class Glass extends SingleChildRenderObjectWidget {
  const Glass({
    super.key,
    this.radius = 0,
    this.material = GlassMaterial.clear,
    this.group = 0,
    this.tip,
    super.child,
  });

  final double radius;
  final GlassMaterial material;

  /// Glass merges only with glass of the same group; a higher group sits on top
  /// (a submenu on its menu: two distinct panels even where they overlap).
  final int group;

  /// A tip under the glass, in the same shape: the edge runs from the body to the tip.
  final GlassTip? tip;

  @override
  RenderGlass createRenderObject(BuildContext context) =>
      RenderGlass(radius: radius, material: material, group: group, tip: tip);

  @override
  void updateRenderObject(BuildContext context, RenderGlass renderObject) {
    renderObject
      ..radius = radius
      ..material = material
      ..group = group
      ..tip = tip;
  }
}

/// The edge of the glass a tip sits on, pointing away from the body.
enum TipEdge { bottom, top, left, right }

/// The tip of a glass, a drop shape that merges into the body (silica-glass-v1 versions 4–6).
/// `x` is the center along the edge (from the left for top and bottom, from the top for left
/// and right), `width` the base along the edge, `height` the depth away from it. The menu tip
/// measured on the Dock is 24 × 10 pt.
@immutable
class GlassTip {
  const GlassTip({
    required this.x,
    required this.width,
    required this.height,
    this.edge = TipEdge.bottom,
  });

  final double x;
  final double width;
  final double height;
  final TipEdge edge;

  /// On the top edge, pointing up (a popover under its button).
  bool get up => edge == TipEdge.top;

  @override
  bool operator ==(Object other) =>
      other is GlassTip &&
      other.x == x &&
      other.width == width &&
      other.height == height &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(x, width, height, edge);
}

/// The render object of [Glass]: it registers itself while attached to the tree.
class RenderGlass extends RenderProxyBox {
  RenderGlass({
    required double radius,
    required GlassMaterial material,
    int group = 0,
    GlassTip? tip,
  }) : _radius = radius,
       _material = material,
       _group = group,
       _tip = tip;

  int _group;
  int get group => _group;
  set group(int value) {
    if (value == _group) return;
    _group = value;
    GlassRegistry.instance.schedule();
  }

  GlassTip? _tip;
  GlassTip? get tip => _tip;
  set tip(GlassTip? value) {
    if (value == _tip) return;
    _tip = value;
    GlassRegistry.instance.schedule();
  }

  double _radius;
  double get radius => _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    GlassRegistry.instance.schedule();
  }

  GlassMaterial _material;
  GlassMaterial get material => _material;
  set material(GlassMaterial value) {
    if (value == _material) return;
    _material = value;
    GlassRegistry.instance.schedule();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    GlassRegistry.instance.add(this);
  }

  @override
  void detach() {
    GlassRegistry.instance.remove(this);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // After every paint the position may have changed.
    GlassRegistry.instance.schedule();
    super.paint(context, offset);
  }

  /// The region in logical pixels of the surface, with the ancestors' transforms
  /// (a swelling glass grows in the compositor too, radius included).
  Map<String, Object> region() {
    final transform = getTransformTo(null);
    final rect = MatrixUtils.transformRect(transform, Offset.zero & size);
    final factor = size.width > 0 ? rect.width / size.width : 1.0;
    return {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'radius': radius * factor,
      'material': material.name,
      'opacity': opacity,
      if (group != 0) 'group': group,
    };
  }

  /// The region of the body and, if there is one, of the tip.
  List<Map<String, Object>> regions() {
    final body = region();
    final tip = this.tip;
    if (tip == null) return [body];
    final rect = MatrixUtils.transformRect(
      getTransformTo(null),
      switch (tip.edge) {
        TipEdge.bottom => Rect.fromLTWH(
          tip.x - tip.width / 2,
          size.height,
          tip.width,
          tip.height,
        ),
        TipEdge.top => Rect.fromLTWH(
          tip.x - tip.width / 2,
          -tip.height,
          tip.width,
          tip.height,
        ),
        // Sideways the rectangle's width is the depth and its height the base.
        TipEdge.left => Rect.fromLTWH(
          -tip.height,
          tip.x - tip.width / 2,
          tip.height,
          tip.width,
        ),
        TipEdge.right => Rect.fromLTWH(
          size.width,
          tip.x - tip.width / 2,
          tip.height,
          tip.width,
        ),
      },
    );
    return [
      body,
      {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
        'material': material.name,
        'opacity': body['opacity'] ?? 1.0,
        'shape': switch (tip.edge) {
          TipEdge.bottom => 'tip',
          TipEdge.top => 'tip-up',
          TipEdge.left => 'tip-left',
          TipEdge.right => 'tip-right',
        },
        if (group != 0) 'group': group,
      },
    ];
  }

  /// The ancestors' opacity (`Opacity`, `FadeTransition`, `AnimatedOpacity`): the glass
  /// fades in and out together with the panel that contains it.
  double get opacity {
    var value = 1.0;
    for (RenderObject? node = parent; node != null; node = node.parent) {
      if (node is RenderOpacity) {
        value *= node.opacity;
      } else if (node is RenderAnimatedOpacity) {
        value *= node.opacity.value;
      }
    }
    return value.clamp(0.0, 1.0);
  }
}

/// Collects the glass areas after every frame and sends them to the embedder when they change.
///
/// It is checked at every frame, not only when a [RenderGlass] repaints: an ancestor that
/// changes transform or opacity (a panel opening) can move the glass without repainting
/// it, and the compositor would keep the old geometry.
class GlassRegistry {
  GlassRegistry._();

  static final GlassRegistry instance = GlassRegistry._();

  static const MethodChannel channel = MethodChannel(
    'silica/glass',
    JSONMethodCodec(),
  );

  final Set<RenderGlass> _glasses = {};
  List<Map<String, Object>> _sent = const [];
  bool _scheduled = false;
  bool _everyFrame = false;

  void add(RenderGlass glass) {
    _glasses.add(glass);
    if (!_everyFrame) {
      _everyFrame = true;
      // After the paint of every frame (persistent callbacks run in registration order,
      // after the rendering one).
      SchedulerBinding.instance.addPersistentFrameCallback((_) {
        if (_glasses.isNotEmpty || _sent.isNotEmpty) _send();
      });
    }
    schedule();
  }

  void remove(RenderGlass glass) {
    _glasses.remove(glass);
    schedule();
  }

  /// The current regions, in registration order.
  @visibleForTesting
  List<Map<String, Object>> get regions => [
    for (final glass in _glasses)
      if (glass.attached && glass.hasSize) ...glass.regions(),
  ];

  void schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _send();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  Future<void> _send() async {
    final regions = this.regions;
    if (listEquals(regions.map(_key).toList(), _sent.map(_key).toList()))
      return;
    _sent = regions;
    try {
      await channel.invokeMethod<Object?>('setRegions', regions);
    } on MissingPluginException {
      // Outside Silica (tests, other embedders) there is no glass.
    }
  }

  static String _key(Map<String, Object> region) =>
      region.entries.map((entry) => '${entry.key}=${entry.value}').join(',');
}
