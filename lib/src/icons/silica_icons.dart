// Le icone a livelli del repo silica-icons (specifica: docs/icon-format.md di quel repo):
// dove sono installate, il manifest icon.json, le cartelle speciali. Le icone sono
// file dell'utente o del sistema (licenza CC BY-SA 4.0), non asset di questo repository.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Rect;

/// `app`: la shell ritaglia il corpo e aggiunge bordo e ombra; `file`: forma libera.
enum IconKind { app, file }

/// Un livello SVG sulla tela 1024, con la variante per i temi scuri se c'è.
class IconLayer {
  const IconLayer(this.path, {this.darkPath, this.shadow = false});

  final String path;
  final String? darkPath;

  /// La shell disegna sotto il livello un'ombra neutra (`"shadow": "neutral"`).
  final bool shadow;

  String pathFor({required bool dark}) => dark ? darkPath ?? path : path;
}

/// Un testo disegnato dalla shell (mese e giorno del calendario).
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

  /// Riquadro sulla tela 1024; il testo è centrato.
  final Rect box;
  final double? maxWidth;
  final bool upper;
}

/// Contenuto aggiornato a runtime.
sealed class IconDynamic {
  const IconDynamic();
}

/// Lancette che ruotano attorno a (512, 512), con il perno sopra.
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

/// Mese e giorno scritti sul primo piano.
class CalendarText extends IconDynamic {
  const CalendarText({required this.month, required this.day});

  final IconText month;
  final IconText day;
}

/// Una fascia di dimensioni della cartella generica: da `minSize` pt (lato del corpo) in su il
/// simbolo usa `weight`, scalato di `scale` attorno al centro del riquadro.
class SymbolBand {
  const SymbolBand({
    required this.minSize,
    required this.weight,
    this.scale = 1,
    this.highlight = true,
  });

  final double minSize;

  /// `light`, `regular` o `semibold`: la cartella di `symbols/`.
  final String weight;
  final double scale;

  /// Disegna il riflesso dello scavo (sotto 64 pt no: mezzo pixel impasterebbe il simbolo).
  final bool highlight;
}

/// L'effetto inciso del simbolo in un tema: il riflesso spostato in basso di `offset`, poi il
/// simbolo.
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

  /// Sulla tela 1024.
  final double offset;
}

/// La tinta della cartella: la luminanza del disegno composto va da tinta × `shade` (a `low`)
/// alla tinta schiarita verso il bianco di `glow` (a `high`).
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

  /// La matrice 4 × 5 di `ColorFilter.matrix` (scostamenti in 0–255) per la tinta.
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

/// La cartella generica: un simbolo di `symbols/` inciso sul pannello e una tinta.
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

  /// La tela 24 × 24 del simbolo sulla tela 1024.
  final Rect box;

  /// Dalla più grande alla più piccola.
  final List<SymbolBand> bands;
  final SymbolEffect light;
  final SymbolEffect dark;

  /// `symbols/` del repo da cui viene l'icona.
  final String symbolsDir;
  final TintRamp? lightTint;
  final TintRamp? darkTint;

  /// Le etichette con il loro colore (`red` → #f2382e…).
  final Map<String, Color> labels;

  /// Chiave della cartella speciale (DOCUMENTS, HOME…) → nome del simbolo.
  final Map<String, String> folders;

  /// L'icona da usare senza simbolo né tinta (la cartella semplice).
  final String? fallback;

  /// La fascia per un'icona di `side` pt; null sotto l'ultima (niente simbolo).
  SymbolBand? bandFor(double side) {
    for (final band in bands) {
      if (side >= band.minSize) return band;
    }
    return null;
  }

  /// Il file del simbolo `name` nel peso `weight`, se esiste.
  String? symbolFile(String name, String weight) {
    if (!_idPattern.hasMatch(name) || !_weights.contains(weight)) return null;
    final path = '$symbolsDir/$weight/$name.svg';
    return File(path).existsSync() ? path : null;
  }

  /// Un colore `#rrggbb` o il nome di un'etichetta; null se non è né l'uno né l'altro.
  Color? tintFor(String? value) =>
      value == null ? null : labels[value] ?? _parseColor(value);
}

/// Un'icona di silica-icons, pronta da comporre.
/// Il file generico: l'estensione scritta sul foglio, colorata per categoria, e la mappa del
/// repo da tipo MIME ed estensione all'icona (icon-format.md, "File generico").
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

  /// Riquadro dell'etichetta sulla tela 1024, corpo del testo e limiti.
  final Rect box;
  final double size;
  final int maxChars;
  final double maxWidth;

  /// Categoria → colore (chiaro, scuro).
  final Map<String, (Color, Color)> colors;

  /// Estensione → categoria (String) o colore (Color).
  final Map<String, Object> overrides;

  /// Tipo MIME (anche `image/*`) → id dell'icona (e la categoria quando porta al file
  /// generico), ed estensione → id.
  final Map<String, (String, String?)> mime;
  final Map<String, String> extensions;

  /// L'icona per i file senza estensione o con un'estensione troppo lunga.
  final String fallback;
}

/// L'etichetta di un'icona di tipo (`file-type-label`, icon-format.md "Icone dei tipi di
/// file"): l'estensione in maiuscolo nel riquadro, in un solo colore.
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

  /// Il testo senza estensione (o con una troppo lunga); null: nessuna etichetta.
  final String? noExtension;

  /// Sotto questo lato del corpo l'etichetta non si disegna.
  final double minSize;
}

class LayeredIcon {
  const LayeredIcon({
    required this.id,
    required this.kind,
    required this.layers,
    this.dynamic,
  });

  final String id;
  final IconKind kind;

  /// Dal basso verso l'alto: per le app il fondo e i primi piani, per i file l'artwork.
  final List<IconLayer> layers;
  final IconDynamic? dynamic;
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');
final RegExp _folderKeyPattern = RegExp(r'^[A-Z][A-Z0-9_]{0,31}$');
final RegExp _labelPattern = RegExp(r'^[a-z][a-z0-9-]{0,31}$');
const Set<String> _weights = {'light', 'regular', 'semibold'};
final RegExp _filePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}\.svg$');

/// Legge `icon.json` della cartella `dir`; null se il manifest non è valido o un file manca.
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
  );
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

/// `dynamic` di tipo `file-label` (il file generico, icon-format.md "File generico").
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
  // Le voci di `icons.mime`: un id, o `{icon, category}` (il file generico con una categoria).
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

/// `dynamic` di tipo `file-type-label`.
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

/// `dynamic` di tipo `folder-symbol`; null se una parte obbligatoria manca o è fuori misura.
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

/// Le cartelle con le icone, dalla più importante: `SILICA_ICONS_DIR` (sviluppo), poi
/// `silica/icons` nelle cartelle dei dati XDG.
List<String> silicaIconDirs(Map<String, String> env) => [
  if (env['SILICA_ICONS_DIR'] case final dir? when dir.isNotEmpty) dir,
  for (final dir in xdgDataDirs(env)) '$dir/silica/icons',
];

final Map<String, LayeredIcon?> _cache = {};

/// L'icona `id` (cartella `apps/<id>` o `files/<id>`), o null.
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

/// Le cartelle dei dati secondo la specifica XDG Base Directory: prima quella dell'utente.
List<String> xdgDataDirs(Map<String, String> env) {
  final home = env['HOME'] ?? '';
  final dataHome = env['XDG_DATA_HOME'] ?? '$home/.local/share';
  final dataDirs = (env['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share')
      .split(':')
      .where((d) => d.isNotEmpty);
  return [dataHome, ...dataDirs];
}

/// Le cartelle di xdg-user-dirs (`~/.config/user-dirs.dirs`), per chiave: DESKTOP,
/// DOCUMENTS, DOWNLOAD, MUSIC, PICTURES, VIDEOS, TEMPLATES, PUBLICSHARE. Una voce uguale alla
/// home è disattivata (specifica di xdg-user-dirs) e non compare.
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

/// La chiave della cartella speciale `path` (per `folders` della cartella generica): le chiavi
/// di xdg-user-dirs, poi `HOME`, `APPLICATIONS` (`~/Applications` e `applications` nelle
/// cartelle dei dati XDG) e `LIBRARY` (`~/.local/share`). `SHARED` e `NETWORK` non hanno un
/// percorso: li passa chi conosce la cartella. Null per una cartella qualsiasi.
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

/// La cartella da disegnare: l'icona (la cartella generica o quella semplice), il simbolo
/// inciso e la tinta.
class FolderIcon {
  const FolderIcon(this.icon, {this.symbol, this.tint});

  final LayeredIcon icon;

  /// Nome di un simbolo di `symbols/` (solo con la cartella generica).
  final String? symbol;
  final Color? tint;
}

/// L'icona della cartella `path`: il simbolo della cartella speciale (o `symbol`, che vince;
/// `key` per le cartelle senza percorso fisso, come `SHARED` e `NETWORK`) e la tinta (`#rrggbb`
/// o il nome di un'etichetta). Senza simbolo né tinta, o se il simbolo non esiste, la cartella
/// semplice (`fallback`). Null se non c'è nessuna icona di cartella.
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

/// L'id dell'icona di silica-icons per un file, dall'estensione del nome (senza estensione:
/// `file-unknown`; estensione sconosciuta: `file-generic`).
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

/// L'icona di un file (`fileIconId`), o quella generica se manca.
LayeredIcon? fileIconFor(String name, {Map<String, String>? env}) =>
    findSilicaIcon(fileIconId(name), env: env) ??
    findSilicaIcon('file-generic', env: env);
