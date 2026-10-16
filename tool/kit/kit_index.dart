// Reading a silica-design checkout: where it is, its commit, and `kit/index.json`.
//
// Shared by `tool/sync_kit.dart` and `tool/gen_checklist.dart`. Every malformed input stops
// with a [KitError] naming the file and the entry: the tools never guess.

import 'dart:convert';
import 'dart:io';

/// Input the kit tools cannot use.
class KitError implements Exception {
  KitError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One symbol master of the kit index.
class KitEntry {
  KitEntry({
    required this.name,
    required this.id,
    required this.json,
    required this.png,
  });

  /// The symbol name, `Category/Component/…/<Light|Dark>`.
  final String name;

  /// The Sketch id.
  final String id;

  /// The JSON file, relative to the checkout (`kit/symbols/…/Light.json`).
  final String json;

  /// The 2× PNG, relative to the checkout.
  final String png;

  /// The master's key: its JSON path below `kit/symbols/` without `.json`. It equals [name]
  /// except for masters sharing a name, whose files carry an id suffix (`Dark (7B023A23)`).
  String get key {
    const prefix = 'kit/symbols/';
    return json.substring(prefix.length, json.length - '.json'.length);
  }

  /// The kit category (the first name segment).
  String get category => name.split('/').first;
}

/// The parsed `kit/index.json` of a silica-design checkout.
class KitIndex {
  KitIndex._(this.root, this.entries);

  /// The checkout.
  final Directory root;

  /// Every symbol master, in index order.
  final List<KitEntry> entries;

  /// The entries named [name] (more than one for the few masters sharing a name).
  List<KitEntry> named(String name) =>
      entries.where((e) => e.name == name).toList();

  /// Reads the index of the checkout at [root].
  static KitIndex read(Directory root) {
    final file = File('${root.path}/kit/index.json');
    if (!file.existsSync()) {
      throw KitError(
        '${file.path} not found: is ${root.path} a silica-design checkout?',
      );
    }
    final Object? data;
    try {
      data = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw KitError('${file.path}: not JSON (${e.message})');
    }
    if (data is! Map<String, Object?> || data['symbols'] is! List) {
      throw KitError('${file.path}: no "symbols" list');
    }
    final entries = <KitEntry>[];
    final symbols = data['symbols']! as List;
    for (var i = 0; i < symbols.length; i++) {
      final s = symbols[i];
      String field(String key) {
        final value = s is Map ? s[key] : null;
        if (value is! String || value.isEmpty) {
          throw KitError('${file.path}: symbols[$i] has no "$key"');
        }
        return value;
      }

      final json = field('json');
      if (!json.startsWith('kit/symbols/') || !json.endsWith('.json')) {
        throw KitError(
          '${file.path}: symbols[$i] json "$json" is not kit/symbols/….json',
        );
      }
      entries.add(
        KitEntry(
          name: field('name'),
          id: field('id'),
          json: json,
          png: field('png'),
        ),
      );
    }
    return KitIndex._(root, entries);
  }
}

/// The silica-design checkout from `--design <dir>` in [args] or `SILICA_DESIGN_DIR`;
/// null when neither is given. Removes the option from [args].
Directory? designDirFrom(List<String> args) {
  final at = args.indexOf('--design');
  String? path;
  if (at >= 0) {
    if (at + 1 >= args.length) throw KitError('--design needs a directory');
    path = args[at + 1];
    args.removeRange(at, at + 2);
  } else {
    path = Platform.environment['SILICA_DESIGN_DIR'];
  }
  if (path == null || path.isEmpty) return null;
  final dir = Directory(path);
  if (!dir.existsSync()) throw KitError('$path: no such directory');
  return dir;
}

/// The commit checked out at [root], with `-dirty` when it has local changes.
String commitOf(Directory root) {
  ProcessResult git(List<String> args) =>
      Process.runSync('git', ['-C', root.path, ...args]);
  final head = git(['rev-parse', 'HEAD']);
  if (head.exitCode != 0) {
    throw KitError('${root.path} is not a git checkout: ${head.stderr}');
  }
  final status = git(['status', '--porcelain', '--', 'kit']);
  final dirty = (status.stdout as String).trim().isNotEmpty;
  return '${(head.stdout as String).trim()}${dirty ? '-dirty' : ''}';
}
