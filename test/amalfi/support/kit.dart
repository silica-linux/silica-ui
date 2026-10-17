// The kit model: a symbol master of the Amalfi UI kit (`test/amalfi/kit/<key>.json`, copied
// from silica-design by `tool/sync_kit.dart`) parsed into a typed layer tree.
//
// The JSON format is described in silica-design's README. Malformed data throws a
// [KitFormatException] naming the file and the layer, never a bare cast error.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

/// Where the fixtures are, relative to the package root (the working directory of tests).
const String kitFixturesPath = 'test/amalfi/kit';

/// The library name of the Icon Kit glyphs nested in masters.
const String iconKitLibrary = 'Silica 1.0 Amalfi Icon Kit';

/// Kit data the harness cannot read.
class KitFormatException implements Exception {
  KitFormatException(this.message);

  final String message;

  @override
  String toString() => 'KitFormatException: $message';
}

/// The type of a kit layer.
enum KitLayerType {
  symbolMaster('SymbolMaster'),
  symbolInstance('SymbolInstance'),
  shapePath('ShapePath'),
  shape('Shape'),
  text('Text'),
  group('Group'),
  image('Image');

  const KitLayerType(this.json);

  /// The name in the JSON.
  final String json;
}

/// Where a border is drawn relative to the layer's outline.
enum KitBorderPosition {
  inside,
  center,
  outside;

  /// The matching [BorderSide.strokeAlign].
  double get strokeAlign => switch (this) {
    inside => BorderSide.strokeAlignInside,
    center => BorderSide.strokeAlignCenter,
    outside => BorderSide.strokeAlignOutside,
  };
}

/// A colour swatch reference (`Light/Surface/Raised`): the appearance and the token name.
@immutable
class KitSwatch {
  const KitSwatch(this.brightness, this.token);

  /// Parses `Light/<token>` or `Dark/<token>`.
  factory KitSwatch.parse(String name) {
    final slash = name.indexOf('/');
    final appearance = slash < 0 ? '' : name.substring(0, slash);
    final brightness = switch (appearance) {
      'Light' => Brightness.light,
      'Dark' => Brightness.dark,
      _ => throw KitFormatException('swatch "$name" is not Light/… or Dark/…'),
    };
    return KitSwatch(brightness, name.substring(slash + 1));
  }

  final Brightness brightness;

  /// The token name in `tokens.json` (`Surface/Raised`, `App/Mail/Flag`).
  final String token;

  /// The token's colour from [AmalfiColors]; null when the tokens have no such colour.
  Color? resolve() => AmalfiColors.of(brightness).byName(token);

  @override
  String toString() =>
      '${brightness == Brightness.dark ? 'Dark' : 'Light'}/$token';
}

/// A fill: a flat colour or a gradient, with the swatch it comes from.
class KitFill {
  KitFill({this.color, this.swatch, this.gradient});

  final Color? color;
  final KitSwatch? swatch;
  final KitGradient? gradient;
}

/// A gradient fill.
class KitGradient {
  KitGradient({
    required this.type,
    required this.from,
    required this.to,
    required this.stops,
  });

  /// `Linear`, `Radial`, `Angular`.
  final String type;

  /// The start and end, as fractions of the layer's frame.
  final Offset from, to;

  /// The stops: position (0–1) and colour.
  final List<(double, Color)> stops;
}

/// A border (Sketch draws borders as strokes of the outline).
class KitBorder {
  KitBorder({
    required this.color,
    required this.thickness,
    required this.position,
    this.swatch,
    this.dashPattern,
    this.lineEnd = 'Butt',
    this.lineJoin = 'Miter',
  });

  final Color color;
  final double thickness;
  final KitBorderPosition position;
  final KitSwatch? swatch;

  /// The dash pattern (on, off, …) of a dashed border: `dashPattern` of the border, or of
  /// the style's `borderOptions`; null when the fixture does not say (solid, or an export
  /// without border options).
  final List<double>? dashPattern;

  /// The line end (`Butt`, `Round`, `Projecting`) and join (`Miter`, `Round`, `Bevel`) of
  /// the style's `borderOptions`; they matter for a dashed border.
  final String lineEnd;
  final String lineJoin;
}

/// A drop or inner shadow, with the kit's (CSS) blur: σ = blur / 2.
class KitShadow {
  KitShadow({
    required this.color,
    required this.offset,
    required this.blur,
    required this.spread,
  });

  final Color color;
  final Offset offset;
  final double blur;
  final double spread;

  /// As a [BoxShadow] with the same numbers (`blurRadius` = [blur]).
  BoxShadow toBoxShadow() => BoxShadow(
    color: color,
    offset: offset,
    blurRadius: blur,
    spreadRadius: spread,
  );

  @override
  String toString() => 'KitShadow($color, $offset, blur $blur, spread $spread)';
}

/// A blur: `Background` (σ = radius, CSS semantics) or `Glass` (a lens).
class KitBlur {
  KitBlur({
    required this.type,
    required this.radius,
    required this.saturation,
    required this.brightness,
    required this.raw,
  });

  final String type;
  final double radius;
  final double saturation;
  final double brightness;

  /// Every field as in the JSON (distortion, depth, chromaticAberration, specular).
  final Map<String, Object?> raw;
}

/// The corners: radii top-left, top-right, bottom-right, bottom-left (empty: square) and the
/// smoothing (0.6 = Amalfi smooth corners).
class KitCorners {
  KitCorners({required this.radii, required this.smoothing, this.style});

  final List<double> radii;
  final double smoothing;
  final int? style;

  /// Whether every corner has the same radius.
  bool get uniform => radii.toSet().length <= 1;

  /// The largest radius (0 when square).
  double get maxRadius => radii.isEmpty ? 0 : radii.reduce(math.max);
}

/// The style of a layer.
class KitStyle {
  KitStyle({
    this.opacity = 1,
    this.fills = const [],
    this.borders = const [],
    this.shadows = const [],
    this.innerShadows = const [],
    this.blurs = const [],
    this.corners,
  });

  final double opacity;
  final List<KitFill> fills;
  final List<KitBorder> borders;
  final List<KitShadow> shadows;
  final List<KitShadow> innerShadows;
  final List<KitBlur> blurs;
  final KitCorners? corners;

  /// Whether the style draws anything of its own.
  bool get isEmpty =>
      fills.isEmpty &&
      borders.isEmpty &&
      shadows.isEmpty &&
      innerShadows.isEmpty &&
      blurs.isEmpty;
}

/// The font of a text layer.
class KitFont {
  KitFont({
    this.family,
    this.size,
    this.weight,
    this.lineHeight,
    this.kerning,
    this.align,
    this.verticalAlign,
    this.color,
  });

  final String? family;
  final double? size;

  /// Sketch's 0–12 weight scale (5 Regular, 6 Medium, 8 Semibold, 9 Bold).
  final int? weight;
  final double? lineHeight;
  final double? kerning;
  final String? align;
  final String? verticalAlign;
  final Color? color;

  /// [weight] as a [FontWeight]; null when it has no Amalfi equivalent.
  FontWeight? get fontWeight => kitFontWeight(weight);
}

/// A Sketch weight (0–12) as a [FontWeight]: 3 → w300, 5 → w400, 6 → w500, 8 → w600, 9 → w700.
FontWeight? kitFontWeight(int? weight) => switch (weight) {
  3 => FontWeight.w300,
  5 => FontWeight.w400,
  6 => FontWeight.w500,
  8 => FontWeight.w600,
  9 => FontWeight.w700,
  _ => null,
};

/// A text style reference (`Light/Callout/Primary`): the appearance, the Amalfi text style and
/// the colour token.
class KitTextStyleRef {
  KitTextStyleRef(this.brightness, this.style, this.colorToken, {this.weight});

  /// Parses a text shared style name; null when it is not `<Light|Dark>/<Style>/<Colour>` with
  /// a style of [AmalfiType].
  static KitTextStyleRef? tryParse(String? name) {
    if (name == null) return null;
    final parts = name.split('/');
    if (parts.length != 3) return null;
    final brightness = switch (parts[0]) {
      'Light' => Brightness.light,
      'Dark' => Brightness.dark,
      _ => null,
    };
    // `Sidebar Emphasis` is the Sidebar style at weight 600 (the selected row).
    final emphasis = parts[1] == 'Sidebar Emphasis';
    final style = AmalfiType.tokenNamed(emphasis ? 'Sidebar' : parts[1]);
    if (brightness == null || style == null) return null;
    final colorToken = switch (parts[2]) {
      'Accent' => 'Accent/Amalfi',
      final colour => 'Text/$colour',
    };
    return KitTextStyleRef(
      brightness,
      style,
      colorToken,
      weight: emphasis ? FontWeight.w600 : null,
    );
  }

  final Brightness brightness;
  final AmalfiTextToken style;

  /// The weight when it differs from the style's, else null.
  final FontWeight? weight;

  /// The colour token (`Text/Primary`, `Accent/Amalfi`).
  final String colorToken;

  /// The colour of [colorToken] in [brightness].
  Color? get color => AmalfiColors.of(brightness).byName(colorToken);
}

/// A glyph of the Icon Kit nested as a symbol instance (`Regular / plus`). The glyphs live in
/// silica-icons as `symbols/<weight>/<name>.svg`, not in the UI kit.
class KitIconRef {
  KitIconRef({required this.weight, required this.name, this.color});

  /// Parses a master name `<Weight> / <name>`; null when it is not one.
  static KitIconRef? tryParse(String master, List<KitOverride> overrides) {
    final m = RegExp(r'^(\w+) / (.+)$').firstMatch(master);
    if (m == null) return null;
    Color? color;
    for (final o in overrides) {
      if (o.property.startsWith('color:') && o.value is String) {
        color = parseKitColor(o.value! as String);
        break;
      }
    }
    return KitIconRef(
      weight: m.group(1)!.toLowerCase(),
      name: m.group(2)!,
      color: color,
    );
  }

  /// `light`, `regular`, `semibold`.
  final String weight;

  /// The glyph name (`plus`, `chevron-down`).
  final String name;

  /// The colour the instance overrides the strokes or fills with; null: the glyph's own.
  final Color? color;

  /// The glyph's path in silica-icons.
  String get svgPath => 'symbols/$weight/$name.svg';
}

/// An override of a symbol instance.
class KitOverride {
  KitOverride(this.path, this.property, this.value);

  final String path;
  final String property;
  final Object? value;
}

/// The stack layout of a group or master.
class KitStack {
  KitStack({
    required this.direction,
    required this.gap,
    required this.padding,
    required this.align,
    required this.justify,
  });

  /// [Axis.horizontal] for Sketch direction 0, [Axis.vertical] for 1.
  final Axis direction;
  final double gap;
  final EdgeInsets padding;
  final int? align;
  final int? justify;
}

/// One layer of a master, with its children.
class KitLayer {
  KitLayer._({
    required this.parent,
    required this.name,
    required this.type,
    required this.frame,
    required this.raw,
  });

  /// The enclosing layer; null for the master.
  final KitLayer? parent;

  final String name;
  final KitLayerType type;

  /// The frame relative to [parent], in points (the master's own frame is its position on
  /// the Sketch page: use [rectInMaster]).
  final Rect frame;

  /// The JSON object, for fields the model does not type.
  final Map<String, Object?> raw;

  late final KitStyle? style;
  late final String? sharedStyle;
  late final String? text;
  late final KitFont? font;
  late final String? master;
  late final String? library;
  late final List<KitOverride> overrides;
  late final KitStack? stack;
  late final bool clipsContent;
  late final String? svg;
  late final String? shapeType;
  late final List<KitLayer> children;

  /// The path from the master: child names joined by `/` (`Surface`, `Content/Label`); the
  /// master itself is the empty path.
  String get path {
    final p = parent;
    if (p == null) return '';
    final up = p.path;
    return up.isEmpty ? name : '$up/$name';
  }

  /// The frame in the master's coordinates (the master at the origin).
  Rect get rectInMaster {
    final p = parent;
    if (p == null) return Offset.zero & frame.size;
    return frame.shift(p.rectInMaster.topLeft);
  }

  /// The text style reference of a text layer (`Light/Callout/Primary`); null when none.
  KitTextStyleRef? get textStyle =>
      type == KitLayerType.text ? KitTextStyleRef.tryParse(sharedStyle) : null;

  /// The Icon Kit glyph of an instance from the Icon Kit library; null otherwise.
  KitIconRef? get icon =>
      type == KitLayerType.symbolInstance && library == iconKitLibrary
      ? KitIconRef.tryParse(master ?? '', overrides)
      : null;

  /// Whether this instance nests another master of the UI kit (not a library glyph).
  bool get isKitInstance =>
      type == KitLayerType.symbolInstance && library == null && master != null;

  /// This layer and every layer below it, depth first.
  Iterable<KitLayer> get descendants sync* {
    yield this;
    for (final c in children) {
      yield* c.descendants;
    }
  }

  @override
  String toString() => 'KitLayer(${type.json} "$path" $frame)';
}

/// A symbol master loaded from the fixtures.
class KitMaster {
  KitMaster._(this.key, this.root);

  /// Loads the master whose key is [key] (its name, plus ` (<id>)` for the few masters that
  /// share a name), from `test/amalfi/kit/<key>.json`.
  factory KitMaster.load(String key) {
    final cached = _cache[key];
    if (cached != null) return cached;
    final file = File('$kitFixturesPath/$key.json');
    if (!file.existsSync()) {
      throw KitFormatException(
        'no fixture ${file.path}: run `dart run tool/sync_kit.dart --design '
        '<silica-design> <prefix>` for it',
      );
    }
    final Object? data;
    try {
      data = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw KitFormatException('${file.path}: not JSON (${e.message})');
    }
    final master = KitMaster._(key, _parseLayer(data, null, file.path));
    if (master.root.type != KitLayerType.symbolMaster) {
      throw KitFormatException('${file.path}: the root is not a SymbolMaster');
    }
    return _cache[key] = master;
  }

  static final Map<String, KitMaster> _cache = {};

  /// The fixture key.
  final String key;

  /// The master layer.
  final KitLayer root;

  /// The symbol name.
  String get name => (root.raw['name'] as String?) ?? key;

  /// The master's size.
  Size get size => root.frame.size;

  /// The appearance, from the last name segment.
  Brightness get brightness {
    final last = name.split('/').last;
    return switch (last) {
      'Dark' => Brightness.dark,
      'Light' => Brightness.light,
      _ => throw KitFormatException(
        '$name: the name ends neither in Light nor Dark',
      ),
    };
  }

  /// The 2× PNG.
  File get png => File('$kitFixturesPath/$key@2x.png');

  /// The layer at [path] (`Surface`, `Content/Label`); throws when there is none.
  KitLayer layer(String path) {
    final found = maybeLayer(path);
    if (found == null) {
      final known = root.descendants.skip(1).map((l) => '"${l.path}"');
      throw KitFormatException(
        '$name has no layer "$path"; it has ${known.join(', ')}',
      );
    }
    return found;
  }

  /// The layer at [path]; null when there is none.
  KitLayer? maybeLayer(String path) {
    if (path.isEmpty) return root;
    for (final l in root.descendants) {
      if (l.path == path) return l;
    }
    return null;
  }

  /// The master nested by the instance [layer]; throws when its fixture is missing.
  static KitMaster nested(KitLayer layer) {
    if (!layer.isKitInstance) {
      throw KitFormatException(
        '${layer.path} is not an instance of a kit master',
      );
    }
    return KitMaster.load(layer.master!);
  }

  /// The area the 2× PNG covers, in master coordinates: the frame grown by shadows and outer
  /// borders, nested masters included, clipped by groups that clip.
  ///
  /// It matches the PNG of most masters; where text or paths overflow their frames it may
  /// differ by a few points on the right or bottom (the pixel test then reports it).
  Rect get renderBounds => _bounds(root, Offset.zero, isRoot: true)!;

  /// The frames of every text layer, nested masters included, in master coordinates.
  List<Rect> get textRects => _texts(root, Offset.zero, isRoot: true);

  /// The regions of refracting glass (Glass/Regular and Thick, a `Glass` blur that is not
  /// the Clear lens), nested masters included, in master coordinates.
  List<KitGlassBand> get glassBands => _bands(root, Offset.zero, isRoot: true);

  /// The shadows the kit PNGs do not draw: Sketch draws no shadow for a layer without a fill,
  /// and the Light glass layers have none since the tint moved to its own layer (the JSON keeps
  /// the shadow, the code draws it). Master coordinates, nested masters included.
  List<KitShadowRing> get unpaintedShadows =>
      _rings(root, Offset.zero, isRoot: true);

  /// The area [layer] paints, effects and nested masters included, in master coordinates.
  Rect paintBoundsOf(KitLayer layer) =>
      _bounds(layer, layer.rectInMaster.topLeft - layer.frame.topLeft)!;
}

Rect? _union(Rect? a, Rect? b) =>
    a == null ? b : (b == null ? a : a.expandToInclude(b));

Rect _effects(Rect rect, KitStyle? style) {
  if (style == null) return rect;
  var out = rect;
  for (final b in style.borders) {
    final grow = switch (b.position) {
      KitBorderPosition.outside => b.thickness,
      KitBorderPosition.center => b.thickness / 2,
      KitBorderPosition.inside => 0.0,
    };
    out = out.expandToInclude(rect.inflate(grow));
  }
  for (final s in style.shadows) {
    out = out.expandToInclude(rect.shift(s.offset).inflate(s.blur + s.spread));
  }
  return out;
}

Rect? _bounds(KitLayer layer, Offset origin, {bool isRoot = false}) {
  final at = isRoot ? origin : origin + layer.frame.topLeft;
  final rect = at & layer.frame.size;
  if (layer.isKitInstance) {
    final nested = KitMaster.nested(layer);
    final inner = nested.renderBounds;
    final sx = nested.size.width == 0
        ? 1.0
        : layer.frame.width / nested.size.width;
    final sy = nested.size.height == 0
        ? 1.0
        : layer.frame.height / nested.size.height;
    return _effects(
      Rect.fromLTRB(
        at.dx + inner.left * sx,
        at.dy + inner.top * sy,
        at.dx + inner.right * sx,
        at.dy + inner.bottom * sy,
      ),
      layer.style,
    );
  }
  Rect? children;
  for (final c in layer.children) {
    children = _union(children, _bounds(c, at));
  }
  if (layer.clipsContent && children != null) {
    children = children.intersect(rect);
  }
  return _union(_effects(rect, layer.style), children);
}

/// The edge band of a glass layer: the shape's rounded rectangle and how far inside its edge
/// the refraction reaches (`depth` × half the shorter side, `materials.md`).
class KitGlassBand {
  KitGlassBand(this.rect, this.radius, this.width);

  final Rect rect;
  final double radius;
  final double width;

  /// Whether [p] (master coordinates) lies in the band: inside the outline, within [width] of
  /// it (and 1 pt either side: the rims and the antialiasing).
  bool inBand(Offset p) {
    final r = math.min(radius, rect.shortestSide / 2);
    final c = rect.center - p;
    final h = Offset(rect.width / 2 - r, rect.height / 2 - r);
    final dx = math.max(c.dx.abs() - h.dx, 0.0);
    final dy = math.max(c.dy.abs() - h.dy, 0.0);
    final inside = r - math.sqrt(dx * dx + dy * dy);
    return inside >= -1 && inside < width + 1;
  }

  KitGlassBand shifted(Offset by) =>
      KitGlassBand(rect.shift(by), radius, width);
}

/// The ring a shadow covers around [body] (the rounded rectangle of its layer).
class KitShadowRing {
  KitShadowRing(this.body, this.radius, this.outer);

  final Rect body;
  final double radius;
  final Rect outer;

  /// Whether [p] (master coordinates) lies in the shadow's area, outside the body (1 pt of
  /// the body's edge included: the antialiasing).
  bool contains(Offset p) {
    if (!outer.contains(p)) return false;
    final r = math.min(radius, body.shortestSide / 2);
    final c = body.center - p;
    final h = Offset(body.width / 2 - r, body.height / 2 - r);
    final dx = math.max(c.dx.abs() - h.dx, 0.0);
    final dy = math.max(c.dy.abs() - h.dy, 0.0);
    return r - math.sqrt(dx * dx + dy * dy) < 1;
  }

  KitShadowRing shifted(Offset by) =>
      KitShadowRing(body.shift(by), radius, outer.shift(by));
}

List<KitShadowRing> _rings(
  KitLayer layer,
  Offset origin, {
  bool isRoot = false,
}) {
  final at = isRoot ? origin : origin + layer.frame.topLeft;
  if (layer.isKitInstance) {
    return [
      for (final b in KitMaster.nested(layer).unpaintedShadows) b.shifted(at),
    ];
  }
  final style = layer.style;
  final rect = at & layer.frame.size;
  return [
    if (style != null &&
        style.fills.isEmpty &&
        style.shadows.isNotEmpty &&
        style.blurs.any((b) => b.type == 'Glass'))
      KitShadowRing(
        rect,
        math.min(style.corners?.maxRadius ?? 0, layer.frame.shortestSide / 2),
        _effects(rect, style),
      ),
    for (final c in layer.children) ..._rings(c, at),
  ];
}

List<KitGlassBand> _bands(
  KitLayer layer,
  Offset origin, {
  bool isRoot = false,
}) {
  final at = isRoot ? origin : origin + layer.frame.topLeft;
  if (layer.isKitInstance) {
    return [for (final b in KitMaster.nested(layer).glassBands) b.shifted(at)];
  }
  return [
    for (final b in layer.style?.blurs ?? const <KitBlur>[])
      if (b.type == 'Glass' &&
          ((b.raw['chromaticAberration'] as num?) ?? 0) !=
              AmalfiMaterials.clear.refraction!.chromaticAberration)
        KitGlassBand(
          at & layer.frame.size,
          math.min(
            layer.style?.corners?.maxRadius ?? 0,
            layer.frame.shortestSide / 2,
          ),
          ((b.raw['depth'] as num?) ?? 0) * layer.frame.shortestSide / 2,
        ),
    for (final c in layer.children) ..._bands(c, at),
  ];
}

List<Rect> _texts(KitLayer layer, Offset origin, {bool isRoot = false}) {
  final at = isRoot ? origin : origin + layer.frame.topLeft;
  if (layer.type == KitLayerType.text) return [at & layer.frame.size];
  if (layer.isKitInstance) {
    final nested = KitMaster.nested(layer);
    return [for (final r in nested.textRects) r.shift(at)];
  }
  return [for (final c in layer.children) ..._texts(c, at)];
}

/// Parses `#rrggbbaa` (or `#rrggbb`).
Color parseKitColor(String hex) {
  final m = RegExp(r'^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$').firstMatch(hex);
  if (m == null) throw KitFormatException('"$hex" is not a #rrggbbaa colour');
  final rgb = int.parse(m.group(1)!, radix: 16);
  final a = m.group(2) == null ? 0xFF : int.parse(m.group(2)!, radix: 16);
  return Color((a << 24) | rgb);
}

KitLayer _parseLayer(Object? data, KitLayer? parent, String file) {
  String where() => '$file: ${parent == null ? 'root' : '"${parent.path}/…"'}';
  if (data is! Map<String, Object?>) {
    throw KitFormatException('${where()}: a layer is not an object');
  }
  T? opt<T>(String key) {
    final v = data[key];
    if (v == null) return null;
    if (v is T) return v as T;
    throw KitFormatException(
      '${where()}: "$key" of "${data['name']}" is not $T',
    );
  }

  final name = opt<String>('name') ?? '';
  final typeName = opt<String>('type');
  final type = KitLayerType.values.where((t) => t.json == typeName).firstOrNull;
  if (type == null) {
    throw KitFormatException(
      '${where()}: "$name" has unknown type "$typeName"',
    );
  }
  final frame = opt<Map<String, Object?>>('frame');
  if (frame == null)
    throw KitFormatException('${where()}: "$name" has no frame');
  double num_(Map<String, Object?> m, String key, [double? fallback]) {
    final v = m[key];
    if (v is num) return v.toDouble();
    if (v == null && fallback != null) return fallback;
    throw KitFormatException('${where()}: "$name": "$key" is not a number');
  }

  final layer = KitLayer._(
    parent: parent,
    name: name,
    type: type,
    frame: Rect.fromLTWH(
      num_(frame, 'x'),
      num_(frame, 'y'),
      num_(frame, 'w'),
      num_(frame, 'h'),
    ),
    raw: data,
  );
  layer
    ..style = _parseStyle(
      opt<Map<String, Object?>>('style'),
      '${where()} "$name"',
    )
    ..sharedStyle = opt<String>('sharedStyle')
    ..text = opt<String>('text')
    ..font = _parseFont(opt<Map<String, Object?>>('font'), '${where()} "$name"')
    ..master = opt<String>('master')
    ..library = opt<String>('library')
    ..overrides = [
      for (final o in opt<List>('overrides') ?? const [])
        if (o is Map)
          KitOverride('${o['path']}', '${o['property']}', o['value']),
    ]
    ..stack = _parseStack(
      opt<Map<String, Object?>>('stack'),
      '${where()} "$name"',
    )
    ..clipsContent = opt<bool>('clipsContent') ?? false
    ..svg = opt<String>('svg')
    ..shapeType = opt<String>('shapeType');
  layer.children = [
    for (final c in opt<List>('children') ?? const [])
      _parseLayer(c, layer, file),
  ];
  return layer;
}

KitStyle? _parseStyle(Map<String, Object?>? s, String where) {
  if (s == null) return null;
  List<Map<String, Object?>> list(String key) {
    final v = s[key];
    if (v == null) return const [];
    if (v is! List || v.any((e) => e is! Map<String, Object?>)) {
      throw KitFormatException('$where: style.$key is not a list of objects');
    }
    return v.cast<Map<String, Object?>>();
  }

  double n(Map<String, Object?> m, String key, double fallback) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is! num) throw KitFormatException('$where: "$key" is not a number');
    return v.toDouble();
  }

  Color color(Map<String, Object?> m) {
    final v = m['color'];
    if (v is! String) throw KitFormatException('$where: a colour is missing');
    return parseKitColor(v);
  }

  KitSwatch? swatch(Map<String, Object?> m) =>
      m['swatch'] is String ? KitSwatch.parse(m['swatch']! as String) : null;

  KitShadow shadow(Map<String, Object?> m) => KitShadow(
    color: color(m),
    offset: Offset(n(m, 'x', 0), n(m, 'y', 0)),
    blur: n(m, 'blur', 0),
    spread: n(m, 'spread', 0),
  );

  final options = s['borderOptions'] is Map<String, Object?>
      ? s['borderOptions']! as Map<String, Object?>
      : null;
  List<double>? dashes(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    return [for (final x in raw) (x as num).toDouble()];
  }

  final corners = s['corners'];
  return KitStyle(
    opacity: n(s, 'opacity', 1),
    fills: [
      for (final f in list('fills'))
        if (f['gradient'] case final Map<String, Object?> g)
          KitFill(gradient: _parseGradient(g, where), swatch: swatch(f))
        else
          KitFill(color: color(f), swatch: swatch(f)),
    ],
    borders: [
      for (final b in list('borders'))
        KitBorder(
          color: color(b),
          thickness: n(b, 'thickness', 1),
          position: switch (b['position']) {
            'Inside' => KitBorderPosition.inside,
            'Outside' => KitBorderPosition.outside,
            'Center' || null => KitBorderPosition.center,
            final other => throw KitFormatException(
              '$where: unknown border position "$other"',
            ),
          },
          swatch: swatch(b),
          dashPattern: dashes(b['dashPattern'] ?? options?['dashPattern']),
          lineEnd: '${b['lineEnd'] ?? options?['lineEnd'] ?? 'Butt'}',
          lineJoin: '${b['lineJoin'] ?? options?['lineJoin'] ?? 'Miter'}',
        ),
    ],
    shadows: [for (final x in list('shadows')) shadow(x)],
    innerShadows: [for (final x in list('innerShadows')) shadow(x)],
    blurs: [
      for (final b in list('blurs'))
        KitBlur(
          type: '${b['type']}',
          radius: n(b, 'radius', 0),
          saturation: n(b, 'saturation', 1),
          brightness: n(b, 'brightness', 1),
          raw: b,
        ),
    ],
    corners: corners is Map<String, Object?>
        ? KitCorners(
            // The export writes one radius for four equal corners (a circle: `[8]`).
            radii: switch ([
              for (final r in (corners['radii'] as List?) ?? const [])
                if (r is num)
                  r.toDouble()
                else
                  throw KitFormatException(
                    '$where: a corner radius is not a number',
                  ),
            ]) {
              [final r] => [r, r, r, r],
              final radii => radii,
            },
            smoothing: n(corners, 'smoothing', 0),
            style: (corners['style'] as num?)?.toInt(),
          )
        : null,
  );
}

KitGradient _parseGradient(Map<String, Object?> g, String where) {
  Offset point(Object? v) {
    if (v is Map && v['x'] is num && v['y'] is num) {
      return Offset((v['x']! as num).toDouble(), (v['y']! as num).toDouble());
    }
    if (v is List && v.length == 2 && v.every((e) => e is num)) {
      return Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }
    throw KitFormatException('$where: a gradient point is not {x, y}');
  }

  final stops = g['stops'];
  if (stops is! List)
    throw KitFormatException('$where: a gradient has no stops');
  return KitGradient(
    type: '${g['type']}',
    from: point(g['from']),
    to: point(g['to']),
    stops: [
      for (final s in stops)
        if (s is List && s.length == 2 && s[0] is num && s[1] is String)
          ((s[0] as num).toDouble(), parseKitColor(s[1] as String))
        else
          throw KitFormatException(
            '$where: a gradient stop is not [position, colour]',
          ),
    ],
  );
}

KitFont? _parseFont(Map<String, Object?>? f, String where) {
  if (f == null) return null;
  double? n(String key) {
    final v = f[key];
    if (v == null) return null;
    if (v is! num)
      throw KitFormatException('$where: font.$key is not a number');
    return v.toDouble();
  }

  return KitFont(
    family: f['family'] as String?,
    size: n('size'),
    weight: n('weight')?.toInt(),
    lineHeight: n('lineHeight'),
    kerning: n('kerning'),
    align: f['align'] as String?,
    verticalAlign: f['verticalAlign'] as String?,
    color: f['color'] is String ? parseKitColor(f['color']! as String) : null,
  );
}

KitStack? _parseStack(Map<String, Object?>? s, String where) {
  if (s == null) return null;
  double n(Map<Object?, Object?> m, String key) {
    final v = m[key];
    return v is num ? v.toDouble() : 0;
  }

  final p = s['padding'];
  final padding = p is Map
      ? EdgeInsets.fromLTRB(
          n(p, 'left'),
          n(p, 'top'),
          n(p, 'right'),
          n(p, 'bottom'),
        )
      : EdgeInsets.zero;
  return KitStack(
    direction: s['direction'] == 1 ? Axis.vertical : Axis.horizontal,
    gap: n(s, 'gap'),
    padding: padding,
    align: (s['align'] as num?)?.toInt(),
    justify: (s['justify'] as num?)?.toInt(),
  );
}
