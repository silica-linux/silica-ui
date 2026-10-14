// The icon of a file, of a volume and the badges, with the rules of silica-icons
// (docs/icon-format.md: "Generic file", "Volumes", "Badges"). The type-to-icon map is the one
// in the manifest of the generic file: there is none of our own here.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Rect;

import 'mime.dart';
import 'silica_icons.dart';

/// The icon to draw for a file: the icon of the type, or the generic file with the
/// extension written on it (`label`) in the color of the category.
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

  /// Label color (light, dark).
  final (Color, Color)? labelColor;

  /// Box (1024 canvas), size and weight of the label; below `labelMinSide` pt it is not written.
  final Rect? labelBox;
  final double labelSize;
  final int labelWeight;
  final double labelMinSide;
}

/// Executable types: without an extension and with the `x` bit they take `file-executable`.
const Set<String> _executableTypes = {
  'application/x-executable',
  'application/x-pie-executable',
  'application/x-shellscript',
};

/// The label color category for a MIME type (icon-format.md).
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

/// The extension for the label: the last one after the dot, lowercase; empty for names without
/// an extension and for hidden files without another dot.
String fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

MimeDatabase? _defaultMime;

/// The system MIME database, read once.
MimeDatabase get systemMime => _defaultMime ??= MimeDatabase.load();

/// The icon of a regular file (icon-format.md, resolution order). `type` avoids computing
/// the type again; `executable` is the `x` bit (null: checked on disk). Null if the generic
/// file is missing (no silica-icons icon).
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
    // A repo without the rules: the old choice by extension.
    final icon = fileIconFor(name, env: env);
    return icon == null ? null : FileIcon(icon);
  }
  final db = mime ?? systemMime;
  // 0. The canonical name (shared-mime-info aliases).
  final mimeType = db.canonical(type ?? db.typeOf(path));
  // 5. The generic file with the label, or the sheet with the question mark.
  FileIcon labeled([String? category]) {
    if (ext.isEmpty || ext.length > rules.maxChars) {
      final fallback = findSilicaIcon(rules.fallback, env: env);
      return fallback == null ? FileIcon(generic) : FileIcon(fallback);
    }
    final override = rules.overrides[ext];
    // The extension override wins over the category of the entry and of the type.
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
      // Weight 900 in the manifest: the package has Inter up to semibold.
      labelWeight: 600,
    );
  }

  /// A type icon with its label (`file-type-label`): the extension, or the text for
  /// files without one (null: no label).
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
    // A map entry may point to the generic file (application/json): with the label.
    if (id == generic.id) return labeled(category);
    final icon = findSilicaIcon(id, env: env);
    return icon == null ? null : typed(icon);
  }

  FileIcon? byMime(String key) {
    final entry = rules.mime[key];
    return entry == null ? null : byId(entry.$1, entry.$2);
  }

  // 1. Executable without an extension.
  if (ext.isEmpty && _executableTypes.contains(mimeType)) {
    final x = executable ?? _isExecutable(path);
    if (x) {
      if (byId('file-executable') case final icon?) return icon;
    }
  }
  // 0b. The type comes only from the name and the name is ambiguous: the extension decides.
  if (type == null && db.isAmbiguousName(name)) {
    if (byId(rules.extensions[ext]) case final icon?) return icon;
  }
  // 1–3. The type, the type with `*`, the parents.
  for (final candidate in [mimeType, ...db.parentsOf(mimeType)]) {
    if (byMime(candidate) case final icon?) return icon;
    final major = candidate.split('/').first;
    if (byMime('$major/*') case final icon?) return icon;
  }
  // 4. The extension.
  if (byId(rules.extensions[ext]) case final icon?) return icon;
  return labeled();
}

bool _isExecutable(String path) {
  try {
    // One of the three x bits.
    return FileStat.statSync(path).mode & 0x49 != 0;
  } on FileSystemException {
    return false;
  }
}

/// The badges (icon-format.md, "Badges").
/// In the order in which one wins when only one remains (below 32 pt).
enum IconBadge { unreadable, alias, locked, cloud }

/// The badge rules of `badges/badges.json` and their files.
class BadgeRules {
  const BadgeRules({
    required this.root,
    required this.files,
    required this.order,
  });

  final String root;

  /// Badge → (light, dark).
  final Map<IconBadge, (String, String?)> files;

  /// The order when only one badge remains (below 32 pt).
  final List<IconBadge> order;

  String? pathFor(IconBadge badge, {required bool dark}) {
    final (light, darkPath) = files[badge] ?? (null, null);
    if (light == null) return null;
    return dark ? (darkPath ?? light) : light;
  }
}

final Map<String, BadgeRules?> _badgeCache = {};

/// The badge rules of the first silica-icons folder that has them.
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

/// The badges of a file on disk: alias (symlink), unreadable (also a broken symlink).
/// `locked` and `cloud` are told by whoever lists the files (`locked`: immutable or
/// append-only attribute; `cloud`: content not local).
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

/// Readable: a folder must be listable, a file openable.
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

/// The badges to draw for an icon side: from 32 pt one per corner (on the right the first of
/// unreadable, locked, cloud), between 16 and 31 just one (the first in the order), below none.
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

/// What is known about a mounted volume to choose its icon.
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

  /// File system type (mountinfo) and device (`/dev/sda1`, `/dev/loop0`…).
  final String fsType;
  final String device;

  /// GVfs scheme (`smb`, `sftp`…) for GVfs mounts.
  final String? scheme;

  /// The file behind a loop device (UDisks2 `Loop.BackingFile`).
  final String? backingFile;
  final bool optical;
  final bool removable;

  /// UDisks2 `Drive.ConnectionBus` (`usb`, `sdio`, `ieee1394`, empty for internal disks).
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

/// The icon of a volume: the first case that applies (icon-format.md, "Volumes").
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

/// A mount point from `/proc/self/mountinfo`.
class MountPoint {
  const MountPoint(this.path, this.fsType, this.device);
  final String path;
  final String fsType;
  final String device;
}

/// The mounts of `/proc/self/mountinfo` (text, for tests): path, type, device.
List<MountPoint> parseMountinfo(String text) {
  final out = <MountPoint>[];
  for (final line in text.split('\n')) {
    final fields = line.split(' ');
    final dash = fields.indexOf('-');
    if (dash < 0 || fields.length < dash + 3 || fields.length < 5) continue;
    // Spaces in paths are written as \040.
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

/// Is the disk removable (`/sys/block/<disk>/removable`)? For a partition the disk is checked.
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
    // Without /sys: not removable.
  }
  return false;
}
