// The layered icons of the silica-icons repo (specification: docs/icon-format.md of that repo):
// where they are installed, the icon.json manifest, the special folders. The icons are
// user or system files (CC BY-SA 4.0 license), not assets of this repository.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Rect;

/// `app`: the shell clips the body and adds edge and shadow; `file`: free shape.
enum IconKind { app, file }

/// The six themes of an app icon (icon-format.md, "Themes"): Default (here `light`), Dark,
/// Clear Light and Clear Dark, Tinted Light and Tinted Dark. [key] is the theme's key in the
/// manifest's `rendered` map.
enum IconAppearance {
  light('default'),
  dark('dark'),
  clear('clear'),
  clearDark('clear-dark'),
  tinted('tinted'),
  tintedDark('tinted-dark');

  const IconAppearance(this.key);

  final String key;

  /// Dark, Clear Dark and Tinted Dark: they take the `-dark` layers.
  bool get isDark =>
      this == IconAppearance.dark ||
      this == IconAppearance.clearDark ||
      this == IconAppearance.tintedDark;

  bool get isClear =>
      this == IconAppearance.clear || this == IconAppearance.clearDark;

  bool get isTinted =>
      this == IconAppearance.tinted || this == IconAppearance.tintedDark;
}

/// The tint of the Tinted renders in silica-icons (icon-format.md, `rendered`): with this tint
/// the shell uses the PNGs, with any other one it composes the SVG layers.
const Color defaultIconTint = Color(0xFF0A84FF);

/// An SVG layer on the 1024 canvas, with the variant for dark themes if there is one.
class IconLayer {
  const IconLayer(this.path, {this.darkPath, this.shadow = false});

  final String path;
  final String? darkPath;

  /// The shell draws a neutral shadow under the layer (`"shadow": "neutral"`).
  final bool shadow;

  String pathFor({required bool dark}) => dark ? darkPath ?? path : path;
}

/// A text drawn by the shell (month and day of the calendar).
class IconText {
  const IconText({
    required this.size,
    required this.weight,
    required this.tracking,
    required this.color,
    required this.darkColor,
    required this.box,
    this.maxWidth,
    this.upper = false,
  });

  final double size;
  final int weight;
  final double tracking;
  final Color color;
  final Color darkColor;

  /// Box on the 1024 canvas; the text is centered.
  final Rect box;
  final double? maxWidth;
  final bool upper;
}

/// Content updated at runtime.
sealed class IconDynamic {
  const IconDynamic();
}

/// Hands rotating around (512, 512), with the cap on top.
class ClockHands extends IconDynamic {
  const ClockHands({
    required this.hour,
    required this.minute,
    required this.second,
    required this.cap,
  });

  final IconLayer hour;
  final IconLayer minute;
  final IconLayer? second;
  final IconLayer cap;
}

/// Month and day written on the foreground.
class CalendarText extends IconDynamic {
  const CalendarText({required this.month, required this.day});

  final IconText month;
  final IconText day;
}

/// A size band of the generic folder: from `minSize` pt (canvas side) up the
/// symbol uses `weight`, scaled by `scale` around the center of the box.
class SymbolBand {
  const SymbolBand({
    required this.minSize,
    required this.weight,
    this.scale = 1,
    this.highlight = true,
  });

  final double minSize;

  /// `light`, `regular` or `semibold`: the folder in `symbols/`.
  final String weight;
  final double scale;

  /// Draws the highlight of the engraving (not below 64 pt: half a pixel would smudge the symbol).
  final bool highlight;
}

/// The engraved effect of the symbol in a theme: the highlight shifted down by `offset`, then the
/// symbol.
class SymbolEffect {
  const SymbolEffect({
    required this.color,
    required this.opacity,
    required this.highlight,
    required this.highlightOpacity,
    required this.offset,
  });

  final Color color;
  final double opacity;
  final Color highlight;
  final double highlightOpacity;

  /// On the 1024 canvas.
  final double offset;
}

/// The folder tint: the luminance of the composed drawing goes from tint × `shade` (at `low`)
/// to the tint lightened towards white by `glow` (at `high`).
class TintRamp {
  const TintRamp({
    required this.low,
    required this.high,
    required this.shade,
    required this.glow,
  });

  final double low;
  final double high;
  final double shade;
  final double glow;

  /// The 4 × 5 matrix of `ColorFilter.matrix` (offsets in 0–255) for the tint.
  List<double> matrix(Color tint) {
    const lum = [0.2126, 0.7152, 0.0722];
    final rows = <double>[];
    for (final t in [tint.r, tint.g, tint.b]) {
      final from = t * shade;
      final to = t + (1 - t) * glow;
      final k = (to - from) / (high - low);
      rows.addAll([
        k * lum[0],
        k * lum[1],
        k * lum[2],
        0,
        (from - k * low) * 255,
      ]);
    }
    return [...rows, 0, 0, 0, 1, 0];
  }
}

/// The generic folder: a symbol from `symbols/` engraved on the panel, and a tint.
class FolderSymbol extends IconDynamic {
  const FolderSymbol({
    required this.box,
    required this.bands,
    required this.light,
    required this.dark,
    required this.symbolsDir,
    this.lightTint,
    this.darkTint,
    this.labels = const {},
    this.folders = const {},
    this.fallback,
  });

  /// The 24 × 24 canvas of the symbol on the 1024 canvas.
  final Rect box;

  /// From the largest to the smallest.
  final List<SymbolBand> bands;
  final SymbolEffect light;
  final SymbolEffect dark;

  /// `symbols/` of the repo the icon comes from.
  final String symbolsDir;
  final TintRamp? lightTint;
  final TintRamp? darkTint;

  /// The tags with their color (`red` → #f2382e…).
  final Map<String, Color> labels;

  /// Special folder key (DOCUMENTS, HOME…) → symbol name.
  final Map<String, String> folders;

  /// The icon to use without symbol or tint (the plain folder).
  final String? fallback;

  /// The band for an icon of `side` pt; null below the last one (no symbol).
  SymbolBand? bandFor(double side) {
    for (final band in bands) {
      if (side >= band.minSize) return band;
    }
    return null;
  }

  /// The file of the symbol `name` in weight `weight`, if it exists.
  String? symbolFile(String name, String weight) {
    if (!_idPattern.hasMatch(name) || !_weights.contains(weight)) return null;
    final path = '$symbolsDir/$weight/$name.svg';
    return File(path).existsSync() ? path : null;
  }

  /// A `#rrggbb` color or the name of a tag; null if it is neither.
  Color? tintFor(String? value) =>
      value == null ? null : labels[value] ?? _parseColor(value);
}

/// A silica-icons icon, ready to compose.
/// The generic file: the extension written on the sheet, colored by category, and the repo's map
/// from MIME type and extension to icon (icon-format.md, "Generic file").
class FileLabelRules extends IconDynamic {
  const FileLabelRules({
    required this.box,
    required this.size,
    required this.maxChars,
    required this.maxWidth,
    required this.colors,
    required this.overrides,
    required this.mime,
    required this.extensions,
    required this.fallback,
  });

  /// Label box on the 1024 canvas, text size and limits.
  final Rect box;
  final double size;
  final int maxChars;
  final double maxWidth;

  /// Category → color (light, dark).
  final Map<String, (Color, Color)> colors;

  /// Extension → category (String) or color (Color).
  final Map<String, Object> overrides;

  /// MIME type (also `image/*`) → icon id (and the category when it leads to the generic
  /// file), and extension → id.
  final Map<String, (String, String?)> mime;
  final Map<String, String> extensions;

  /// The icon for files without an extension or with an extension too long.
  final String fallback;
}

/// The label of a type icon (`file-type-label`, icon-format.md "File type
/// icons"): the extension in uppercase in the box, in a single color.
class TypeLabel extends IconDynamic {
  const TypeLabel({
    required this.box,
    required this.size,
    required this.maxChars,
    required this.maxWidth,
    required this.color,
    required this.darkColor,
    required this.noExtension,
    required this.minSize,
  });

  final Rect box;
  final double size;
  final int maxChars;
  final double maxWidth;
  final Color color;
  final Color darkColor;

  /// The text without an extension (or with one too long); null: no label.
  final String? noExtension;

  /// Below this canvas side the label is not drawn.
  final double minSize;
}

class LayeredIcon {
  const LayeredIcon({
    required this.id,
    required this.kind,
    required this.layers,
    this.dynamic,
    this.rendered = const {},
  });

  final String id;
  final IconKind kind;

  /// From bottom to top: for apps the background and the foregrounds, for files the artwork.
  final List<IconLayer> layers;
  final IconDynamic? dynamic;

  /// The whole icon as designed (relief, shadows and glass baked in), a 1024 PNG per theme
  /// (manifest `rendered`, silica-icons ≥ 0.6). Empty in older packs: the layers are used.
  final Map<IconAppearance, String> rendered;

  /// The rendered PNG of [appearance], if the pack has one.
  String? renderedFor(IconAppearance appearance) => rendered[appearance];
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');
final RegExp _folderKeyPattern = RegExp(r'^[A-Z][A-Z0-9_]{0,31}$');
final RegExp _labelPattern = RegExp(r'^[a-z][a-z0-9-]{0,31}$');
const Set<String> _weights = {'light', 'regular', 'semibold'};
final RegExp _filePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}\.svg$');
final RegExp _pngPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}\.png$');

/// Reads `icon.json` of the folder `dir`; null if the manifest is invalid or a file is missing.
LayeredIcon? parseManifest(String dir, String text) {
  Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (json is! Map || json['format'] != 1) return null;
  final id = json['id'];
  if (id is! String || !_idPattern.hasMatch(id)) return null;
  final kind = switch (json['kind']) {
    'app' => IconKind.app,
    'file' => IconKind.file,
    _ => null,
  };
  if (kind == null) return null;
  final variants = json['variants'];
  final darkMap = variants is Map ? variants['dark'] : null;

  String? file(Object? name) =>
      name is String &&
          _filePattern.hasMatch(name) &&
          File('$dir/$name').existsSync()
      ? '$dir/$name'
      : null;

  final layers = <IconLayer>[];
  final rawLayers = json['layers'];
  if (rawLayers is! List || rawLayers.isEmpty || rawLayers.length > 5)
    return null;
  for (final raw in rawLayers) {
    if (raw is! Map) return null;
    final role = raw['role'];
    final path = file(raw['file']);
    if (role is! String || path == null) return null;
    layers.add(
      IconLayer(
        path,
        darkPath: darkMap is Map ? file(darkMap[role]) : null,
        shadow: raw['shadow'] == 'neutral' || raw['shadow'] == 'chromatic',
      ),
    );
  }
  return LayeredIcon(
    id: id,
    kind: kind,
    layers: layers,
    dynamic: _parseDynamic(json['dynamic'], file, dir),
    rendered: _parseRendered(json['rendered'], dir),
  );
}

/// `rendered`: theme key → PNG in the icon's folder. Unknown keys, names outside the folder and
/// missing files are skipped (that theme falls back to the layers).
Map<IconAppearance, String> _parseRendered(Object? raw, String dir) {
  if (raw is! Map) return const {};
  final rendered = <IconAppearance, String>{};
  for (final appearance in IconAppearance.values) {
    final name = raw[appearance.key];
    if (name is String &&
        _pngPattern.hasMatch(name) &&
        File('$dir/$name').existsSync()) {
      rendered[appearance] = '$dir/$name';
    }
  }
  return rendered;
}

IconDynamic? _parseDynamic(
  Object? raw,
  String? Function(Object?) file,
  String dir,
) {
  if (raw is! Map) return null;
  IconLayer? layer(Object? name) {
    if (name is! String) return null;
    final path = file(name);
    if (path == null) return null;
    final dot = name.lastIndexOf('.');
    return IconLayer(
      path,
      darkPath: file('${name.substring(0, dot)}-dark${name.substring(dot)}'),
    );
  }

  switch (raw['type']) {
    case 'clock':
      final hands = raw['hands'];
      if (hands is! List) return null;
      final byName = <String, IconLayer>{};
      for (final hand in hands) {
        if (hand is! Map || hand['unit'] is! String) continue;
        if (layer(hand['file']) case final l?)
          byName[hand['unit'] as String] = l;
      }
      final hour = byName['hour'];
      final minute = byName['minute'];
      final cap = layer(raw['cap']);
      if (hour == null || minute == null || cap == null) return null;
      return ClockHands(
        hour: hour,
        minute: minute,
        second: byName['second'],
        cap: cap,
      );
    case 'calendar':
      final month = _parseText(raw['month']);
      final day = _parseText(raw['day']);
      if (month == null || day == null) return null;
      return CalendarText(month: month, day: day);
    case 'folder-symbol':
      return _parseFolder(raw, dir);
    case 'file-label':
      return _parseFileLabel(raw);
    case 'file-type-label':
      return _parseTypeLabel(raw);
    default:
      return null;
  }
}

/// `dynamic` of type `file-label` (the generic file, icon-format.md "Generic file").
FileLabelRules? _parseFileLabel(Map raw) {
  final label = raw['label'];
  if (label is! Map) return null;
  final box = label['box'];
  if (box is! List || box.length != 4 || box.any((v) => v is! num)) return null;
  final colors = <String, (Color, Color)>{};
  final rawColors = raw['colors'];
  if (rawColors is Map) {
    for (final MapEntry(:key, :value) in rawColors.entries) {
      if (key is! String || value is! Map) continue;
      final light = _parseColor(value['color']);
      if (light == null) continue;
      colors[key] = (light, _parseColor(value['dark_color']) ?? light);
    }
  }
  final overrides = <String, Object>{};
  final rawOverrides = raw['overrides'];
  if (rawOverrides is Map) {
    for (final MapEntry(:key, :value) in rawOverrides.entries) {
      if (key is! String) continue;
      if (value is String && colors.containsKey(value)) {
        overrides[key.toLowerCase()] = value;
      } else if (value is Map) {
        final color = _parseColor(value['color']);
        if (color != null) overrides[key.toLowerCase()] = color;
      }
    }
  }
  Map<String, String> ids(Object? map) => {
    if (map is Map)
      for (final MapEntry(:key, :value) in map.entries)
        if (key is String && value is String && _idPattern.hasMatch(value))
          key.toLowerCase(): value,
  };
  final icons = raw['icons'];
  // The entries of `icons.mime`: an id, or `{icon, category}` (the generic file with a category).
  final mime = <String, (String, String?)>{};
  final rawMime = icons is Map ? icons['mime'] : null;
  if (rawMime is Map) {
    for (final MapEntry(:key, :value) in rawMime.entries) {
      if (key is! String) continue;
      if (value is String && _idPattern.hasMatch(value)) {
        mime[key.toLowerCase()] = (value, null);
      } else if (value is Map &&
          value['icon'] is String &&
          _idPattern.hasMatch(value['icon'] as String)) {
        final category = value['category'];
        mime[key.toLowerCase()] = (
          value['icon'] as String,
          category is String ? category : null,
        );
      }
    }
  }
  final fallback = raw['fallback'];
  return FileLabelRules(
    box: Rect.fromLTWH(
      (box[0] as num).toDouble(),
      (box[1] as num).toDouble(),
      (box[2] as num).toDouble(),
      (box[3] as num).toDouble(),
    ),
    size: _number(label['size'], 1, 1024) ?? 160,
    maxChars: (label['max_chars'] as num?)?.toInt().clamp(1, 16) ?? 4,
    maxWidth: _number(label['max_width'], 1, 1024) ?? 534,
    colors: colors,
    overrides: overrides,
    mime: mime,
    extensions: ids(icons is Map ? icons['extensions'] : null),
    fallback: fallback is String && _idPattern.hasMatch(fallback)
        ? fallback
        : 'file-unknown',
  );
}

/// `dynamic` of type `file-type-label`.
TypeLabel? _parseTypeLabel(Map raw) {
  final label = raw['label'];
  if (label is! Map) return null;
  final box = label['box'];
  if (box is! List || box.length != 4 || box.any((v) => v is! num)) return null;
  final color = _parseColor(label['color']);
  if (color == null) return null;
  final none = label['no_extension'];
  return TypeLabel(
    box: Rect.fromLTWH(
      (box[0] as num).toDouble(),
      (box[1] as num).toDouble(),
      (box[2] as num).toDouble(),
      (box[3] as num).toDouble(),
    ),
    size: _number(label['size'], 1, 1024) ?? 100,
    maxChars: (label['max_chars'] as num?)?.toInt().clamp(1, 16) ?? 5,
    maxWidth: _number(label['max_width'], 1, 1024) ?? 440,
    color: color,
    darkColor: _parseColor(label['dark_color']) ?? color,
    noExtension: none is String && none.length <= 8 ? none : null,
    minSize: _number(label['min_size'], 0, 1024) ?? 32,
  );
}

double? _number(Object? v, double min, double max) =>
    v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;

/// `dynamic` of type `folder-symbol`; null if a required part is missing or out of range.
FolderSymbol? _parseFolder(Map raw, String dir) {
  final symbol = raw['symbol'];
  if (symbol is! Map) return null;
  final box = symbol['box'];
  if (box is! List || box.length != 4) return null;
  final b = [for (final v in box) _number(v, 0, 1024)];
  if (b.contains(null) || b[2]! <= 0 || b[3]! <= 0) return null;
  final sizes = symbol['sizes'];
  if (sizes is! List || sizes.isEmpty || sizes.length > 8) return null;
  final bands = <SymbolBand>[];
  for (final size in sizes) {
    if (size is! Map) return null;
    final min = _number(size['min_size'], 0, 4096);
    final weight = size['weight'];
    final scale = size['scale'] == null ? 1.0 : _number(size['scale'], 0.25, 4);
    if (min == null || weight is! String || !_weights.contains(weight)) {
      return null;
    }
    if (scale == null) return null;
    bands.add(
      SymbolBand(
        minSize: min,
        weight: weight,
        scale: scale,
        highlight: size['highlight'] != false,
      ),
    );
  }
  bands.sort((a, b) => b.minSize.compareTo(a.minSize));

  final effect = raw['effect'];
  if (effect is! Map) return null;
  SymbolEffect? fx(Object? e) {
    if (e is! Map) return null;
    final color = _parseColor(e['color']);
    final opacity = _number(e['opacity'], 0, 1);
    if (color == null || opacity == null) return null;
    return SymbolEffect(
      color: color,
      opacity: opacity,
      highlight: _parseColor(e['highlight']) ?? const Color(0xFFFFFFFF),
      highlightOpacity: _number(e['highlight_opacity'], 0, 1) ?? 0,
      offset: _number(e['offset'], 0, 64) ?? 0,
    );
  }

  final light = fx(effect['light']);
  if (light == null) return null;
  final dark = fx(effect['dark']) ?? light;

  TintRamp? ramp(Object? r) {
    if (r is! Map) return null;
    final lum = r['luminance'];
    if (lum is! List || lum.length != 2) return null;
    final low = _number(lum[0], 0, 1);
    final high = _number(lum[1], 0, 1);
    final shade = _number(r['shade'], 0, 1);
    final glow = _number(r['glow'], 0, 1);
    if (low == null || high == null || shade == null || glow == null) {
      return null;
    }
    if (high - low < 0.01) return null;
    return TintRamp(low: low, high: high, shade: shade, glow: glow);
  }

  final tint = raw['tint'];
  final labels = <String, Color>{};
  TintRamp? lightTint;
  TintRamp? darkTint;
  if (tint is Map) {
    lightTint = ramp(tint['light']);
    darkTint = ramp(tint['dark']) ?? lightTint;
    final rawLabels = tint['labels'];
    if (rawLabels is Map && rawLabels.length <= 32) {
      for (final MapEntry(:key, :value) in rawLabels.entries) {
        final color = _parseColor(value);
        if (key is String && _labelPattern.hasMatch(key) && color != null) {
          labels[key] = color;
        }
      }
    }
  }

  final folders = <String, String>{};
  final rawFolders = raw['folders'];
  if (rawFolders is Map && rawFolders.length <= 64) {
    for (final MapEntry(:key, :value) in rawFolders.entries) {
      if (key is String &&
          _folderKeyPattern.hasMatch(key) &&
          value is String &&
          _idPattern.hasMatch(value)) {
        folders[key] = value;
      }
    }
  }
  final fallback = raw['fallback'];
  return FolderSymbol(
    box: Rect.fromLTWH(b[0]!, b[1]!, b[2]!, b[3]!),
    bands: bands,
    light: light,
    dark: dark,
    symbolsDir: '${File(dir).parent.parent.path}/symbols',
    lightTint: lightTint,
    darkTint: darkTint,
    labels: labels,
    folders: folders,
    fallback: fallback is String && _idPattern.hasMatch(fallback)
        ? fallback
        : null,
  );
}

IconText? _parseText(Object? raw) {
  if (raw is! Map) return null;
  double? number(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
  final size = number(raw['size']);
  final box = raw['box'];
  final color = _parseColor(raw['color']);
  if (size == null || size <= 0 || size > 1024 || color == null) return null;
  if (box is! List || box.length != 4) return null;
  final b = [for (final v in box) number(v)];
  if (b.contains(null)) return null;
  return IconText(
    size: size,
    weight: (number(raw['weight']) ?? 400).round().clamp(100, 900),
    tracking: number(raw['tracking']) ?? 0,
    color: color,
    darkColor: _parseColor(raw['dark_color']) ?? color,
    box: Rect.fromLTWH(b[0]!, b[1]!, b[2]!, b[3]!),
    maxWidth: number(raw['max_width']),
    upper: raw['case'] == 'upper',
  );
}

Color? _parseColor(Object? raw) {
  if (raw is! String ||
      !RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(raw)) {
    return null;
  }
  final rgb = int.parse(raw.substring(1, 7), radix: 16);
  final alpha = raw.length == 9 ? int.parse(raw.substring(7), radix: 16) : 0xFF;
  return Color((alpha << 24) | rgb);
}

/// The folders with the icons, most important first: `SILICA_ICONS_DIR` (development), then
/// `silica/icons` in the XDG data folders.
List<String> silicaIconDirs(Map<String, String> env) => [
  if (env['SILICA_ICONS_DIR'] case final dir? when dir.isNotEmpty) dir,
  for (final dir in xdgDataDirs(env)) '$dir/silica/icons',
];

final Map<String, LayeredIcon?> _cache = {};

/// The icon `id` (folder `apps/<id>` or `files/<id>`), or null.
LayeredIcon? findSilicaIcon(String id, {Map<String, String>? env}) {
  if (!_idPattern.hasMatch(id)) return null;
  final environment = env ?? Platform.environment;
  if (env == null && _cache.containsKey(id)) return _cache[id];
  LayeredIcon? found;
  search:
  for (final base in silicaIconDirs(environment)) {
    for (final group in ['apps', 'files']) {
      final manifest = File('$base/$group/$id/icon.json');
      if (!manifest.existsSync()) continue;
      try {
        found = parseManifest(
          manifest.parent.path,
          manifest.readAsStringSync(),
        );
      } on FileSystemException {
        found = null;
      }
      if (found != null) break search;
    }
  }
  if (env == null) _cache[id] = found;
  return found;
}

/// The data folders according to the XDG Base Directory specification: the user's first.
List<String> xdgDataDirs(Map<String, String> env) {
  final home = env['HOME'] ?? '';
  final dataHome = env['XDG_DATA_HOME'] ?? '$home/.local/share';
  final dataDirs = (env['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share')
      .split(':')
      .where((d) => d.isNotEmpty);
  return [dataHome, ...dataDirs];
}

/// The xdg-user-dirs folders (`~/.config/user-dirs.dirs`), by key: DESKTOP,
/// DOCUMENTS, DOWNLOAD, MUSIC, PICTURES, VIDEOS, TEMPLATES, PUBLICSHARE. An entry equal to the
/// home is disabled (xdg-user-dirs specification) and does not appear.
Map<String, String> xdgUserDirs(Map<String, String> env) {
  final home = _trimSlash(env['HOME'] ?? '');
  if (home.isEmpty) return const {};
  final config = env['XDG_CONFIG_HOME'] ?? '$home/.config';
  final dirs = <String, String>{};
  try {
    final file = File('$config/user-dirs.dirs');
    if (!file.existsSync() || file.lengthSync() > 64 * 1024) return dirs;
    final line = RegExp(r'^XDG_([A-Z]{1,32})_DIR="([^"]*)"\s*$');
    for (final text in file.readAsLinesSync()) {
      final m = line.firstMatch(text.trim());
      if (m == null) continue;
      var value = m[2]!;
      if (value.startsWith(r'$HOME')) {
        value = '$home${value.substring(5)}';
      } else if (!value.startsWith('/')) {
        continue;
      }
      value = _trimSlash(value);
      if (value.isEmpty || value == home || value.contains('/../')) continue;
      dirs[m[1]!] = value;
    }
  } on FileSystemException {
    return dirs;
  } on FormatException {
    return dirs;
  }
  return dirs;
}

String _trimSlash(String path) {
  var p = path;
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// The special folder key of `path` (for `folders` of the generic folder): the keys
/// of xdg-user-dirs, then `HOME`, `APPLICATIONS` (`~/Applications` and `applications` in the
/// XDG data folders) and `LIBRARY` (`~/.local/share`). `SHARED` and `NETWORK` have no
/// path: they are passed by whoever knows the folder. Null for any other folder.
String? specialFolderKey(String path, {Map<String, String>? env}) {
  final environment = env ?? Platform.environment;
  final p = _trimSlash(path);
  if (p.isEmpty) return null;
  final home = _trimSlash(environment['HOME'] ?? '');
  for (final MapEntry(:key, :value) in xdgUserDirs(environment).entries) {
    if (value == p) return key;
  }
  if (home.isNotEmpty && p == home) return 'HOME';
  final data = xdgDataDirs(environment).map(_trimSlash).toList();
  if ((home.isNotEmpty && p == '$home/Applications') ||
      data.any((d) => p == '$d/applications')) {
    return 'APPLICATIONS';
  }
  if (home.isNotEmpty && p == '$home/.local/share') return 'LIBRARY';
  return null;
}

/// The folder to draw: the icon (the generic folder or the plain one), the engraved
/// symbol and the tint.
class FolderIcon {
  const FolderIcon(this.icon, {this.symbol, this.tint});

  final LayeredIcon icon;

  /// Name of a symbol in `symbols/` (only with the generic folder).
  final String? symbol;
  final Color? tint;
}

/// The icon of the folder `path`: the symbol of the special folder (or `symbol`, which wins;
/// `key` for folders without a fixed path, like `SHARED` and `NETWORK`) and the tint (`#rrggbb`
/// or the name of a tag). Without symbol or tint, or if the symbol does not exist, the plain
/// folder (`fallback`). Null if there is no folder icon at all.
FolderIcon? resolveFolderIcon(
  String path, {
  String? symbol,
  String? key,
  String? tint,
  Map<String, String>? env,
}) {
  final generic = findSilicaIcon('folder-generic', env: env);
  final dyn = generic?.dynamic;
  if (generic == null || dyn is! FolderSymbol) {
    final plain = findSilicaIcon('folder', env: env);
    return plain == null ? null : FolderIcon(plain);
  }
  final folderKey = key ?? specialFolderKey(path, env: env);
  final name = symbol ?? (folderKey == null ? null : dyn.folders[folderKey]);
  final valid = name != null && dyn.symbolFile(name, 'regular') != null;
  final color = dyn.tintFor(tint);
  if (!valid && color == null) {
    final plain = findSilicaIcon(dyn.fallback ?? 'folder', env: env);
    return FolderIcon(plain ?? generic);
  }
  return FolderIcon(generic, symbol: valid ? name : null, tint: color);
}

/// The silica-icons icon id for a file, from the extension of the name (no extension:
/// `file-unknown`; unknown extension: `file-generic`).
String fileIconId(String name) {
  final lower = name.toLowerCase();
  final dot = lower.lastIndexOf('.');
  final ext = dot <= 0 ? '' : lower.substring(dot + 1);
  return switch (ext) {
    'png' ||
    'jpg' ||
    'jpeg' ||
    'gif' ||
    'webp' ||
    'svg' ||
    'heic' => 'file-image',
    'mp3' || 'ogg' || 'flac' || 'wav' || 'm4a' => 'file-audio',
    'mp4' || 'mkv' || 'webm' || 'mov' || 'avi' => 'file-video',
    'pdf' => 'file-pdf',
    'zip' ||
    'tar' ||
    'gz' ||
    'xz' ||
    'zst' ||
    '7z' ||
    'rar' ||
    'deb' => 'file-archive',
    'txt' || 'md' || 'rtf' || 'odt' || 'doc' || 'docx' => 'file-text',
    'rs' ||
    'dart' ||
    'py' ||
    'js' ||
    'ts' ||
    'c' ||
    'h' ||
    'json' ||
    'sh' => 'file-code',
    '' => 'file-unknown',
    _ => 'file-generic',
  };
}

/// The icon of a file (`fileIconId`), or the generic one if it is missing.
LayeredIcon? fileIconFor(String name, {Map<String, String>? env}) =>
    findSilicaIcon(fileIconId(name), env: env) ??
    findSilicaIcon('file-generic', env: env);
