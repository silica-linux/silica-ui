// Copies kit masters from a silica-design checkout into `test/amalfi/kit/` as test fixtures.
//
// Usage, from the package root:
//
//   dart run tool/sync_kit.dart --design ~/silica/silica-design Buttons/Push Tooltips
//   SILICA_DESIGN_DIR=~/silica/silica-design dart run tool/sync_kit.dart
//
// Each argument is a name prefix on whole segments (`Buttons/Push` selects
// `Buttons/Push/Primary/Regular/Rest/Light`, not `Buttons/Pushy`). The prefixes are recorded in
// `test/amalfi/kit/_prefixes/` (one file per prefix, so that branches adding different
// prefixes merge without conflicts), and a run without prefixes re-syncs everything already
// there; a run with prefixes adds them to the recorded ones. `--remove <prefix>` drops one.
// `test/amalfi/kit/SOURCE.md` records the silica-design commit.
//
// For each selected master it copies the JSON and the @2x PNG to
// `test/amalfi/kit/<path below kit/symbols>`, plus the kit masters nested in it as symbol
// instances (transitively), so the harness can compute the full rendered bounds. Glyphs of
// the Icon Kit (`library`) are not kit masters and are not copied. Files that no longer
// belong to any prefix are deleted. Running it twice changes nothing.

import 'dart:convert';
import 'dart:io';

import 'kit/kit_index.dart';

const String fixturesPath = 'test/amalfi/kit';
const String sourcePath = '$fixturesPath/SOURCE.md';
const String prefixesPath = '$fixturesPath/_prefixes';

void main(List<String> arguments) {
  try {
    _run(arguments.toList());
  } on KitError catch (e) {
    stderr.writeln('sync_kit: $e');
    exitCode = 65;
  }
}

void _run(List<String> args) {
  final design = designDirFrom(args);
  if (design == null) {
    throw KitError(
      'no silica-design checkout: pass --design <dir> or set SILICA_DESIGN_DIR',
    );
  }
  final removed = <String>{};
  for (
    var at = args.indexOf('--remove');
    at >= 0;
    at = args.indexOf('--remove')
  ) {
    if (at + 1 >= args.length) throw KitError('--remove needs a prefix');
    removed.add(_clean(args[at + 1]));
    args.removeRange(at, at + 2);
  }
  final options = args.where((a) => a.startsWith('-')).toList();
  if (options.isNotEmpty) {
    throw KitError(
      'unknown options: ${options.join(' ')}\n'
      'usage: dart run tool/sync_kit.dart [--design <dir>] [--remove <prefix>] [prefix …]',
    );
  }
  final prefixes = {
    ..._recordedPrefixes(),
    ...args.map(_clean),
  }.difference(removed).toList()..sort();
  if (prefixes.isEmpty) throw KitError('no prefixes given or recorded');

  final index = KitIndex.read(design);
  final commit = commitOf(design);

  // The selected masters, then their nested kit masters.
  final selected = <String, KitEntry>{};
  for (final prefix in prefixes) {
    final matches = index.entries.where(
      (e) => _under(e.key, prefix) || _under(e.name, prefix),
    );
    if (matches.isEmpty) throw KitError('no kit master under "$prefix"');
    for (final e in matches) {
      selected[e.key] = e;
    }
  }
  final direct = selected.length;
  final queue = selected.values.toList();
  while (queue.isNotEmpty) {
    final entry = queue.removeLast();
    for (final nested in _nestedMasters(design, entry)) {
      final found = index.named(nested);
      if (found.isEmpty) {
        stderr.writeln(
          'sync_kit: warning: ${entry.name} nests "$nested", not in the index',
        );
      }
      for (final e in found) {
        if (selected.containsKey(e.key)) continue;
        selected[e.key] = e;
        queue.add(e);
      }
    }
  }

  // Copy what changed, delete what no longer belongs.
  final wanted = <String>{};
  var written = 0;
  for (final e in selected.values) {
    for (final (from, suffix) in [(e.json, '.json'), (e.png, '@2x.png')]) {
      final source = File('${design.path}/$from');
      if (!source.existsSync()) {
        throw KitError('${e.name}: ${source.path} is missing in the checkout');
      }
      final target = File('$fixturesPath/${e.key}$suffix');
      wanted.add(target.path);
      final bytes = source.readAsBytesSync();
      if (target.existsSync() && _same(target.readAsBytesSync(), bytes)) {
        continue;
      }
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(bytes);
      written++;
    }
  }
  var deleted = 0;
  final root = Directory(fixturesPath);
  if (root.existsSync()) {
    for (final f in root.listSync(recursive: true).whereType<File>()) {
      if (f.path == sourcePath ||
          f.path.startsWith('$prefixesPath/') ||
          wanted.contains(f.path)) {
        continue;
      }
      f.deleteSync();
      deleted++;
    }
    _removeEmptyDirectories(root);
  }

  written += _writeIfChanged(File(sourcePath), _sourceMarkdown(commit));
  final prefixDir = Directory(prefixesPath)..createSync(recursive: true);
  final prefixFiles = {for (final p in prefixes) _prefixFile(p).path: p};
  for (final f in prefixDir.listSync().whereType<File>()) {
    if (!prefixFiles.containsKey(f.path)) {
      f.deleteSync();
      deleted++;
    }
  }
  for (final MapEntry(key: path, value: prefix) in prefixFiles.entries) {
    written += _writeIfChanged(File(path), '$prefix\n');
  }
  stdout.writeln(
    'sync_kit: ${selected.length} masters ($direct selected), '
    '$written files written, $deleted deleted, silica-design $commit',
  );
}

String _clean(String prefix) =>
    prefix.trim().replaceAll(RegExp(r'^/+|/+$'), '');

bool _under(String name, String prefix) =>
    name == prefix || name.startsWith('$prefix/');

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The kit masters nested in [entry] as symbol instances (not library glyphs).
Iterable<String> _nestedMasters(Directory design, KitEntry entry) {
  final file = File('${design.path}/${entry.json}');
  final Object? data;
  try {
    data = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw KitError('${file.path}: not JSON (${e.message})');
  } on FileSystemException catch (e) {
    throw KitError('${file.path}: ${e.message}');
  }
  final names = <String>{};
  void walk(Object? layer) {
    if (layer is! Map) return;
    if (layer['type'] == 'SymbolInstance' &&
        layer['library'] == null &&
        layer['master'] is String) {
      names.add(layer['master'] as String);
    }
    final children = layer['children'];
    if (children is List) children.forEach(walk);
  }

  walk(data);
  return names;
}

/// The file recording [prefix]: `Buttons/Push` → `_prefixes/Buttons - Push.txt`.
File _prefixFile(String prefix) =>
    File('$prefixesPath/${prefix.replaceAll('/', ' - ')}.txt');

int _writeIfChanged(File file, String content) {
  if (file.existsSync() && file.readAsStringSync() == content) return 0;
  file
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content);
  return 1;
}

List<String> _recordedPrefixes() {
  final dir = Directory(prefixesPath);
  if (!dir.existsSync()) return const [];
  return [
    for (final f in dir.listSync().whereType<File>())
      if (f.path.endsWith('.txt'))
        if (f.readAsStringSync().trim() case final p when p.isNotEmpty) p,
  ];
}

String _sourceMarkdown(String commit) =>
    '''
# Kit fixtures

Copies of symbol masters of the Silica 1.0 "Amalfi" UI kit, from
[silica-design](https://github.com/silica-os/silica-design) (CC BY-SA 4.0, the Silica
project), made by `tool/sync_kit.dart`. Do not edit: re-run the tool.

silica-design commit: `$commit`

The selected name prefixes are the files in `_prefixes/`; the masters nested in them as
symbol instances are copied too.
''';

void _removeEmptyDirectories(Directory dir) {
  for (final child in dir.listSync().whereType<Directory>()) {
    _removeEmptyDirectories(child);
    if (child.listSync().isEmpty) child.deleteSync();
  }
}
