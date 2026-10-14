// The MIME type of a file according to shared-mime-info (freedesktop specification "Shared
// MIME-info Database"): the globs of `mime/globs2` (weight, case), the hierarchies of
// `mime/subclasses` and the aliases of `mime/aliases`, in the XDG data folders (the user's first).
//
// From the content only what the globs do not tell and the icons need is recognized: ELF
// (executables and libraries), scripts with `#!`, plain text versus binary data. The rest of
// the magic database is not read.

import 'dart:io';
import 'dart:typed_data';

import 'silica_icons.dart' show xdgDataDirs;

/// The type of a file nothing is known about.
const String octetStream = 'application/octet-stream';

class _Glob {
  const _Glob(
    this.weight,
    this.type,
    this.pattern, {
    required this.caseSensitive,
  });
  final int weight;
  final String type;
  final String pattern;
  final bool caseSensitive;
}

class MimeDatabase {
  MimeDatabase._(this._globs, this._subclasses, this._aliases) {
    for (final glob in _globs) {
      final p = glob.pattern;
      // "*.ext" without other special characters: looked up by extension.
      if (p.startsWith('*.') && !_special(p.substring(2))) {
        final ext = p.substring(2);
        _byExtension
            .putIfAbsent(glob.caseSensitive ? ext : ext.toLowerCase(), () => [])
            .add(glob);
      } else if (!_special(p)) {
        _literal.putIfAbsent(p, () => []).add(glob);
      } else {
        _complex.add(glob);
      }
    }
  }

  /// The database from the `mime/` folders of the XDG data; empty if there is none (then only
  /// the content counts).
  factory MimeDatabase.load({Map<String, String>? env}) {
    final globs = <_Glob>[];
    final subclasses = <String, List<String>>{};
    final aliases = <String, String>{};
    final seenGlobs = <String>{};
    for (final dir in xdgDataDirs(env ?? Platform.environment)) {
      final mime = '$dir/mime';
      for (final line in _lines('$mime/globs2')) {
        if (line.startsWith('#')) continue;
        final parts = line.split(':');
        if (parts.length < 3) continue;
        final weight = int.tryParse(parts[0]) ?? 50;
        final key = '${parts[1]}:${parts[2]}';
        // The first folder wins (the user's).
        if (!seenGlobs.add(key)) continue;
        globs.add(
          _Glob(
            weight,
            parts[1],
            parts[2],
            caseSensitive:
                parts.length > 3 && parts[3].split(',').contains('cs'),
          ),
        );
      }
      for (final line in _lines('$mime/subclasses')) {
        final parts = line.split(' ');
        if (parts.length != 2) continue;
        final parents = subclasses.putIfAbsent(parts[0], () => []);
        if (!parents.contains(parts[1])) parents.add(parts[1]);
      }
      for (final line in _lines('$mime/aliases')) {
        final parts = line.split(' ');
        if (parts.length == 2) aliases.putIfAbsent(parts[0], () => parts[1]);
      }
    }
    return MimeDatabase._(globs, subclasses, aliases);
  }

  /// A database from the texts of the files (tests).
  factory MimeDatabase.fromText({
    String globs2 = '',
    String subclasses = '',
    String aliases = '',
  }) {
    final globs = <_Glob>[];
    for (final line in globs2.split('\n')) {
      final parts = line.split(':');
      if (line.startsWith('#') || parts.length < 3) continue;
      globs.add(
        _Glob(
          int.tryParse(parts[0]) ?? 50,
          parts[1],
          parts[2],
          caseSensitive: parts.length > 3 && parts[3].split(',').contains('cs'),
        ),
      );
    }
    final sub = <String, List<String>>{};
    for (final line in subclasses.split('\n')) {
      final parts = line.split(' ');
      if (parts.length == 2) sub.putIfAbsent(parts[0], () => []).add(parts[1]);
    }
    final alias = <String, String>{};
    for (final line in aliases.split('\n')) {
      final parts = line.split(' ');
      if (parts.length == 2) alias[parts[0]] = parts[1];
    }
    return MimeDatabase._(globs, sub, alias);
  }

  final List<_Glob> _globs;
  final Map<String, List<String>> _subclasses;
  final Map<String, String> _aliases;
  final Map<String, List<_Glob>> _byExtension = {};
  final Map<String, List<_Glob>> _literal = {};
  final List<_Glob> _complex = [];

  static List<String> _lines(String path) {
    try {
      return File(path).readAsLinesSync();
    } on FileSystemException {
      return const [];
    }
  }

  static bool _special(String s) =>
      s.contains('*') || s.contains('?') || s.contains('[');

  /// The canonical type (aliases lead to the real name).
  String canonical(String type) => _aliases[type] ?? type;

  /// Does the name give several types with the same weight and the same glob (e.g. `.ts`: Qt
  /// Linguist or MPEG-TS)? Then the name alone does not decide (icon-format.md, step 0b).
  bool isAmbiguousName(String name) {
    final candidates = _candidates(name);
    if (candidates.length < 2) return false;
    final first = candidates.first;
    return candidates.any(
      (g) =>
          g.weight == first.weight &&
          g.pattern.length == first.pattern.length &&
          canonical(g.type) != canonical(first.type),
    );
  }

  /// The type from the file name, or null if no glob matches. The highest weight wins, then
  /// the longest glob (specification, "Recommended checking order").
  String? typeForName(String name) {
    final candidates = _candidates(name);
    return candidates.isEmpty ? null : canonical(candidates.first.type);
  }

  /// The globs matching the name, best first: highest weight, then longest glob.
  List<_Glob> _candidates(String name) {
    final candidates = <_Glob>[];
    candidates.addAll(_literal[name] ?? const []);
    // All the possible extensions: for "a.tar.gz" both "tar.gz" and "gz".
    for (
      var dot = name.indexOf('.');
      dot >= 0;
      dot = name.indexOf('.', dot + 1)
    ) {
      final ext = name.substring(dot + 1);
      if (ext.isEmpty) continue;
      for (final glob in _byExtension[ext.toLowerCase()] ?? const <_Glob>[]) {
        if (!glob.caseSensitive || glob.pattern.substring(2) == ext) {
          candidates.add(glob);
        }
      }
      for (final glob in _byExtension[ext] ?? const <_Glob>[]) {
        if (glob.caseSensitive && !candidates.contains(glob))
          candidates.add(glob);
      }
    }
    for (final glob in _complex) {
      if (_matches(glob.pattern, name, caseSensitive: glob.caseSensitive)) {
        candidates.add(glob);
      }
    }
    candidates.sort((a, b) {
      final weight = b.weight.compareTo(a.weight);
      return weight != 0
          ? weight
          : b.pattern.length.compareTo(a.pattern.length);
    });
    return candidates;
  }

  /// The parents of a type, nearest first (`sub-class-of`, then the implicit rules: every
  /// `text/*` is `text/plain`, every type is `application/octet-stream`, excluded).
  List<String> parentsOf(String type) {
    final out = <String>[];
    final queue = [canonical(type)];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final parent in _subclasses[current] ?? const <String>[]) {
        final p = canonical(parent);
        if (!out.contains(p) && p != type) {
          out.add(p);
          queue.add(p);
        }
      }
    }
    if (type.startsWith('text/') &&
        type != 'text/plain' &&
        !out.contains('text/plain')) {
      out.add('text/plain');
    }
    return out;
  }

  /// The type of a file on disk: from the name, and from the content when the name is not enough.
  String typeOf(String path) {
    final name = path.split('/').last;
    final byName = typeForName(name);
    if (byName != null) return byName;
    return _sniff(path);
  }

  String _sniff(String path) {
    Uint8List head;
    try {
      final file = File(path).openSync();
      try {
        head = file.readSync(512);
      } finally {
        file.closeSync();
      }
    } on FileSystemException {
      return octetStream;
    }
    if (head.isEmpty) return 'application/x-zerosize';
    if (head.length >= 4 &&
        head[0] == 0x7f &&
        head[1] == 0x45 &&
        head[2] == 0x4c &&
        head[3] == 0x46) {
      // ELF: e_type at 16 (1 relocatable, 2 executable, 3 shared: also a PIE executable).
      final type = head.length > 16 ? head[16] : 0;
      return switch (type) {
        2 => 'application/x-executable',
        3 => 'application/x-sharedlib',
        _ => 'application/x-object',
      };
    }
    if (head.length > 2 && head[0] == 0x23 && head[1] == 0x21) {
      final line = String.fromCharCodes(head.takeWhile((b) => b != 0x0a));
      if (RegExp(r'\b(ba|z|da|k|fi)?sh\b').hasMatch(line)) {
        return 'application/x-shellscript';
      }
      if (line.contains('python')) return 'text/x-python';
      if (line.contains('perl')) return 'application/x-perl';
      if (line.contains('ruby')) return 'application/x-ruby';
      return 'text/plain';
    }
    // Text if there are no null bytes nor control bytes other than tab, newline, carriage return.
    final binary = head.any(
      (b) => b == 0 || (b < 0x20 && b != 9 && b != 10 && b != 13 && b != 12),
    );
    return binary ? octetStream : 'text/plain';
  }
}

/// A glob with `*`, `?` and `[...]` classes on the whole name.
bool _matches(String pattern, String name, {required bool caseSensitive}) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    final c = pattern[i];
    switch (c) {
      case '*':
        buffer.write('.*');
      case '?':
        buffer.write('.');
      case '[':
        final end = pattern.indexOf(']', i + 1);
        if (end < 0) {
          buffer.write(RegExp.escape(c));
        } else {
          var cls = pattern.substring(i + 1, end);
          if (cls.startsWith('!')) cls = '^${cls.substring(1)}';
          buffer.write('[${cls.replaceAll(r'\', r'\\')}]');
          i = end;
        }
      default:
        buffer.write(RegExp.escape(c));
    }
  }
  buffer.write(r'$');
  try {
    return RegExp(
      buffer.toString(),
      caseSensitive: caseSensitive,
    ).hasMatch(name);
  } on FormatException {
    return false;
  }
}
