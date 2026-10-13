// Vetro calcolato da Ossido (silica-glass-v1, docs/protocols.md): il widget dichiara la
// sua area, il compositor ci mette dietro lo sfondo sfocato del materiale. Il figlio
// disegna sopra (testo, icone) e lascia trasparente il resto.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// I vetri misurati: chiaro (Dock), spesso (menu, ricerca), regolare (il Liquid Glass
/// dei controlli, con la lente forte sul bordo) e notifica (banner e Centro notifiche).
enum GlassMaterial { clear, thick, regular, notification }

/// Un'area di vetro grande quanto il figlio, con angoli ad arco di cerchio.
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

  /// Il vetro si fonde solo con quello dello stesso gruppo; un gruppo più alto sta sopra
  /// (un sottomenu sul suo menu: due pannelli distinti anche dove si sovrappongono).
  final int group;

  /// Una punta sotto il vetro, nella stessa forma: il bordo corre dal corpo alla punta.
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

/// La punta sotto un vetro, rivolta in basso: `x` è il centro dal bordo sinistro, la base
/// larga `width` poggia sul bordo inferiore, il vertice è `height` più in basso.
@immutable
class GlassTip {
  const GlassTip({required this.x, required this.width, required this.height});

  final double x;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      other is GlassTip &&
      other.x == x &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, width, height);
}

/// Il render object di [Glass]: si registra finché è attaccato all'albero.
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
    // Dopo ogni disegno la posizione può essere cambiata.
    GlassRegistry.instance.schedule();
    super.paint(context, offset);
  }

  /// La regione in pixel logici della superficie, con le trasformazioni degli antenati
  /// (un vetro che si gonfia cresce anche nel compositor, raggio compreso).
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

  /// La regione del corpo e, se c'è, quella della punta.
  List<Map<String, Object>> regions() {
    final body = region();
    final tip = this.tip;
    if (tip == null) return [body];
    final rect = MatrixUtils.transformRect(
      getTransformTo(null),
      Rect.fromLTWH(tip.x - tip.width / 2, size.height, tip.width, tip.height),
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
        'shape': 'tip',
        if (group != 0) 'group': group,
      },
    ];
  }

  /// L'opacità degli antenati (`Opacity`, `FadeTransition`, `AnimatedOpacity`): il vetro
  /// compare e scompare in dissolvenza insieme al pannello che lo contiene.
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

/// Raccoglie le aree di vetro dopo ogni frame e le manda all'embedder quando cambiano.
///
/// Si controlla a ogni frame, non solo quando un [RenderGlass] si ridisegna: un antenato
/// che cambia trasformazione o opacità (un pannello che si apre) può spostare il vetro
/// senza ridisegnarlo, e il compositor resterebbe con la geometria vecchia.
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
      // Dopo il disegno di ogni frame (i callback persistenti girano in ordine di
      // registrazione, dopo quello del rendering).
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

  /// Le regioni attuali, nell'ordine di registrazione.
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
      // Fuori da Silica (test, altri embedder) il vetro non c'è.
    }
  }

  static String _key(Map<String, Object> region) =>
      region.entries.map((entry) => '${entry.key}=${entry.value}').join(',');
}
