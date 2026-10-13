// L'icona di un file, di un volume e i badge, con le regole di silica-icons
// (docs/icon-format.md: "File generico", "Volumi", "Badge"). La mappa da tipo a icona è quella
// del manifest del file generico: qui non ce n'è una propria.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Rect;

import 'mime.dart';
import 'silica_icons.dart';

/// L'icona da disegnare per un file: l'icona del tipo, oppure il file generico con
/// l'estensione scritta (`label`) nel colore della categoria.
class FileIcon {
  const FileIcon(
    this.icon, {
    this.label,
    this.labelColor,
    this.labelBox,
    this.labelSize = 0,
    this.labelWeight = 600,
    this.labelMinSide = 0,
  });

  final LayeredIcon icon;
  final String? label;

  /// Colore dell'etichetta (chiaro, scuro).
  final (Color, Color)? labelColor;

  /// Riquadro (tela 1024), corpo e peso dell'etichetta; sotto `labelMinSide` pt non si scrive.
  final Rect? labelBox;
  final double labelSize;
  final int labelWeight;
  final double labelMinSide;
}

/// Tipi eseguibili: senza estensione e con il bit `x` prendono `file-executable`.
const Set<String> _executableTypes = {
  'application/x-executable',
  'application/x-pie-executable',
  'application/x-shellscript',
};

/// La categoria del colore dell'etichetta per un tipo MIME (icon-format.md).
String labelCategory(String type) {
  final (major, minor) = switch (type.split('/')) {
    [final a, final b] => (a, b),
    _ => (type, ''),
  };
  if (major == 'image' ||
      major == 'audio' ||
      major == 'video' ||
      major == 'font') {
    return 'media';
  }
  const data = [
    'json',
    'xml',
    'yaml',
    'csv',
    'sql',
    'sqlite',
    'toml',
    'calendar',
    'vcard',
  ];
  if (data.any(minor.contains)) return 'data';
  const archive = [
    'zip',
    'tar',
    'gzip',
    'bzip',
    'xz',
    'zstd',
    '7z',
    'rar',
    'compress',
    'archive',
    'package',
    'deb',
    'rpm',
    'iso9660',
    'disk-image',
    'cd-image',
  ];
  if (archive.any(minor.contains)) return 'archive';
  const code = [
    'script',
    'src',
    'source',
    'python',
    'perl',
    'ruby',
    'java',
    'javascript',
    'rust',
    'dart',
    'go',
    'c++',
    'csrc',
    'chdr',
    'php',
    'lua',
    'executable',
    'sharedlib',
    'html',
    'css',
  ];
  if (code.any(minor.contains)) return 'code';
  if (major == 'text' ||
      minor.contains('document') ||
      minor.contains('msword') ||
      minor.contains('opendocument') ||
      minor.contains('officedocument') ||
      minor.contains('epub') ||
      minor.contains('pdf')) {
    return 'document';
  }
  return 'other';
}

/// L'estensione per l'etichetta: l'ultima dopo il punto, in minuscolo; vuota per i nomi senza
/// estensione e per i file nascosti senza un altro punto.
String fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

MimeDatabase? _defaultMime;

/// Il database MIME del sistema, letto una volta.
MimeDatabase get systemMime => _defaultMime ??= MimeDatabase.load();

/// L'icona di un file regolare (icon-format.md, ordine di risoluzione). `type` evita di
/// ricalcolare il tipo; `executable` è il bit `x` (null: si guarda sul disco). Null se il file
/// generico non c'è (nessuna icona di silica-icons).
FileIcon? resolveFileIcon(
  String path, {
  String? type,
  bool? executable,
  MimeDatabase? mime,
  Map<String, String>? env,
}) {
  final generic = findSilicaIcon('file-generic', env: env);
  final rules = generic?.dynamic;
  final name = path.split('/').last;
  final ext = fileExtension(name);
  if (generic == null || rules is! FileLabelRules) {
    // Un repo senza le regole: la vecchia scelta per estensione.
    final icon = fileIconFor(name, env: env);
    return icon == null ? null : FileIcon(icon);
  }
  final db = mime ?? systemMime;
  // 0. Il nome canonico (gli alias di shared-mime-info).
  final mimeType = db.canonical(type ?? db.typeOf(path));
  // 5. Il file generico con l'etichetta, o il foglio con il punto di domanda.
  FileIcon labeled([String? category]) {
    if (ext.isEmpty || ext.length > rules.maxChars) {
      final fallback = findSilicaIcon(rules.fallback, env: env);
      return fallback == null ? FileIcon(generic) : FileIcon(fallback);
    }
    final override = rules.overrides[ext];
    // L'override dell'estensione vince sulla categoria della voce e su quella del tipo.
    final color = switch (override) {
      final Color c => (c, c),
      final String c => rules.colors[c],
      _ => rules.colors[category ?? labelCategory(mimeType)],
    };
    return FileIcon(
      generic,
      label: ext.toUpperCase(),
      labelColor: color ?? rules.colors['other'],
      labelBox: rules.box,
      labelSize: rules.size,
      // Peso 900 nel manifest: il pacchetto ha Inter fino al semibold.
      labelWeight: 600,
    );
  }

  /// Un'icona di tipo con la sua etichetta (`file-type-label`): l'estensione, o il testo per
  /// i file senza (null: nessuna etichetta).
  FileIcon typed(LayeredIcon icon) {
    final rule = icon.dynamic;
    if (rule is! TypeLabel) return FileIcon(icon);
    final text = ext.isNotEmpty && ext.length <= rule.maxChars
        ? ext.toUpperCase()
        : rule.noExtension;
    return FileIcon(
      icon,
      label: text,
      labelColor: (rule.color, rule.darkColor),
      labelBox: rule.box,
      labelSize: rule.size,
      labelWeight: 500,
      labelMinSide: rule.minSize,
    );
  }

  FileIcon? byId(String? id, [String? category]) {
    if (id == null) return null;
    // Una voce della mappa può mandare al file generico (application/json): con l'etichetta.
    if (id == generic.id) return labeled(category);
    final icon = findSilicaIcon(id, env: env);
    return icon == null ? null : typed(icon);
  }

  FileIcon? byMime(String key) {
    final entry = rules.mime[key];
    return entry == null ? null : byId(entry.$1, entry.$2);
  }

  // 1. Eseguibile senza estensione.
  if (ext.isEmpty && _executableTypes.contains(mimeType)) {
    final x = executable ?? _isExecutable(path);
    if (x) {
      if (byId('file-executable') case final icon?) return icon;
    }
  }
  // 1–3. Il tipo, il tipo con `*`, i genitori.
  for (final candidate in [mimeType, ...db.parentsOf(mimeType)]) {
    if (byMime(candidate) case final icon?) return icon;
    final major = candidate.split('/').first;
    if (byMime('$major/*') case final icon?) return icon;
  }
  // 4. L'estensione.
  if (byId(rules.extensions[ext]) case final icon?) return icon;
  return labeled();
}

bool _isExecutable(String path) {
  try {
    // Uno dei tre bit x.
    return FileStat.statSync(path).mode & 0x49 != 0;
  } on FileSystemException {
    return false;
  }
}

/// I badge (icon-format.md, "Badge").
/// Nell'ordine in cui vince quando ne resta uno solo (sotto 32 pt).
enum IconBadge { unreadable, alias, locked, cloud }

/// Le regole dei badge di `badges/badges.json` e i loro file.
class BadgeRules {
  const BadgeRules({
    required this.root,
    required this.files,
    required this.order,
  });

  final String root;

  /// Badge → (chiaro, scuro).
  final Map<IconBadge, (String, String?)> files;

  /// L'ordine quando resta un solo badge (sotto 32 pt).
  final List<IconBadge> order;

  String? pathFor(IconBadge badge, {required bool dark}) {
    final (light, darkPath) = files[badge] ?? (null, null);
    if (light == null) return null;
    return dark ? (darkPath ?? light) : light;
  }
}

final Map<String, BadgeRules?> _badgeCache = {};

/// Le regole dei badge della prima cartella di silica-icons che le ha.
BadgeRules? findBadgeRules({Map<String, String>? env}) {
  final key = env == null ? '' : jsonEncode(env);
  if (_badgeCache.containsKey(key)) return _badgeCache[key];
  BadgeRules? found;
  for (final dir in silicaIconDirs(env ?? Platform.environment)) {
    final root = '$dir/badges';
    try {
      final json = jsonDecode(File('$root/badges.json').readAsStringSync());
      if (json is! Map || json['format'] != 1) continue;
      final files = <IconBadge, (String, String?)>{};
      final badges = json['badges'];
      if (badges is Map) {
        for (final badge in IconBadge.values) {
          final raw = badges[badge.name];
          if (raw is! Map) continue;
          String? file(Object? name) =>
              name is String &&
                  RegExp(r'^[a-z0-9-]+\.svg$').hasMatch(name) &&
                  File('$root/$name').existsSync()
              ? '$root/$name'
              : null;
          final light = file(raw['file']);
          if (light != null) files[badge] = (light, file(raw['dark']));
        }
      }
      final order = [
        for (final name
            in (json['order'] is List ? json['order'] as List : const []))
          ?IconBadge.values.where((b) => b.name == name).firstOrNull,
      ];
      found = BadgeRules(
        root: root,
        files: files,
        order: order.isEmpty ? IconBadge.values : order,
      );
      break;
    } on Object {
      continue;
    }
  }
  if (env == null) _badgeCache[key] = found;
  return found;
}

/// I badge di un file dal disco: alias (collegamento), illeggibile (anche un collegamento rotto).
/// `locked` e `cloud` li dice chi elenca i file (`locked`: attributo immutabile o solo
/// aggiunta; `cloud`: contenuto non locale).
Set<IconBadge> badgesOf(
  String path, {
  bool locked = false,
  bool cloud = false,
}) {
  final out = <IconBadge>{};
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.link) {
    out.add(IconBadge.alias);
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      out.add(IconBadge.unreadable);
    }
  }
  if (!out.contains(IconBadge.unreadable) && !_readable(path)) {
    out.add(IconBadge.unreadable);
  }
  if (locked) out.add(IconBadge.locked);
  if (cloud) out.add(IconBadge.cloud);
  return out;
}

/// Leggibile: per una cartella si deve poterla elencare, per un file aprirlo.
bool _readable(String path) {
  try {
    switch (FileSystemEntity.typeSync(path)) {
      case FileSystemEntityType.directory:
        Directory(path).listSync().take(1);
      case FileSystemEntityType.notFound:
        return true;
      default:
        File(path).openSync().closeSync();
    }
    return true;
  } on FileSystemException {
    return false;
  }
}

/// I badge da disegnare per un lato del corpo: da 32 pt uno per angolo (a destra il primo fra
/// illeggibile, bloccato, nuvola), fra 16 e 31 uno solo (il primo dell'ordine), sotto niente.
List<IconBadge> visibleBadges(
  Set<IconBadge> badges,
  double side, {
  List<IconBadge> order = IconBadge.values,
}) {
  if (side < 16 || badges.isEmpty) return const [];
  if (side < 32) {
    final first = order.where(badges.contains).firstOrNull;
    return first == null ? const [] : [first];
  }
  final right = const [
    IconBadge.unreadable,
    IconBadge.locked,
    IconBadge.cloud,
  ].where(badges.contains).firstOrNull;
  return [if (badges.contains(IconBadge.alias)) IconBadge.alias, ?right];
}

/// Quel che si sa di un volume montato per sceglierne l'icona.
class VolumeInfo {
  const VolumeInfo({
    this.fsType = '',
    this.device = '',
    this.scheme,
    this.backingFile,
    this.optical = false,
    this.removable = false,
    this.connectionBus = '',
  });

  /// Tipo di file system (mountinfo) e dispositivo (`/dev/sda1`, `/dev/loop0`…).
  final String fsType;
  final String device;

  /// Schema GVfs (`smb`, `sftp`…) per i mount di GVfs.
  final String? scheme;

  /// Il file dietro un dispositivo loop (UDisks2 `Loop.BackingFile`).
  final String? backingFile;
  final bool optical;
  final bool removable;

  /// UDisks2 `Drive.ConnectionBus` (`usb`, `sdio`, `ieee1394`, vuoto per i dischi interni).
  final String connectionBus;
}

const Set<String> _networkFs = {
  'nfs',
  'nfs4',
  'cifs',
  'smb3',
  '9p',
  'fuse.sshfs',
  'fuse.rclone',
  'davfs',
};
const Set<String> _networkSchemes = {
  'smb',
  'sftp',
  'ftp',
  'ftps',
  'dav',
  'davs',
  'nfs',
  'afp',
};

/// L'icona di un volume: il primo caso che vale (icon-format.md, "Volumi").
String volumeIconId(VolumeInfo v) {
  if (_networkFs.contains(v.fsType) || _networkSchemes.contains(v.scheme)) {
    return 'volume-network';
  }
  if (v.device.startsWith('/dev/loop') && (v.backingFile?.isNotEmpty ?? true)) {
    return 'volume-disk-image';
  }
  if (v.optical || v.device.startsWith('/dev/sr')) return 'volume-optical';
  if (v.removable ||
      const {'usb', 'sdio', 'ieee1394'}.contains(v.connectionBus)) {
    return 'volume-external';
  }
  return 'volume-internal';
}

/// Un punto di montaggio da `/proc/self/mountinfo`.
class MountPoint {
  const MountPoint(this.path, this.fsType, this.device);
  final String path;
  final String fsType;
  final String device;
}

/// I mount di `/proc/self/mountinfo` (testo, per i test): percorso, tipo, dispositivo.
List<MountPoint> parseMountinfo(String text) {
  final out = <MountPoint>[];
  for (final line in text.split('\n')) {
    final fields = line.split(' ');
    final dash = fields.indexOf('-');
    if (dash < 0 || fields.length < dash + 3 || fields.length < 5) continue;
    // Gli spazi nei percorsi sono scritti come \040.
    String unescape(String s) => s.replaceAllMapped(
      RegExp(r'\\([0-7]{3})'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 8)),
    );
    out.add(
      MountPoint(unescape(fields[4]), fields[dash + 1], fields[dash + 2]),
    );
  }
  return out;
}

/// Il disco è rimovibile (`/sys/block/<disco>/removable`)? Per una partizione si guarda il disco.
bool blockRemovable(String device, {String sys = '/sys/block'}) {
  final name = device.split('/').last;
  if (name.isEmpty) return false;
  try {
    for (final entry in Directory(sys).listSync()) {
      final disk = entry.path.split('/').last;
      if (name == disk ||
          (name.startsWith(disk) && name.length > disk.length)) {
        return File('${entry.path}/removable').readAsStringSync().trim() == '1';
      }
    }
  } on FileSystemException {
    // Senza /sys: non rimovibile.
  }
  return false;
}
