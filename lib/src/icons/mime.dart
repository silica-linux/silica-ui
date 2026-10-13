// Il tipo MIME di un file secondo shared-mime-info (specifica freedesktop "Shared MIME-info
// Database"): i glob di `mime/globs2` (peso, maiuscole), le gerarchie di `mime/subclasses` e
// gli alias di `mime/aliases`, nelle cartelle dei dati XDG (prima quella dell'utente).
//
// Dal contenuto si riconosce solo quello che i glob non dicono e che serve alle icone: ELF
// (eseguibili e librerie), script con `#!`, testo semplice contro dati binari. Il resto del
// database magic non è letto.

import 'dart:io';
import 'dart:typed_data';

import 'silica_icons.dart' show xdgDataDirs;

/// Il tipo di un file di cui non si sa niente.
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
      // "*.ext" senza altri caratteri speciali: si cerca per estensione.
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

  /// Il database dalle cartelle `mime/` dei dati XDG; vuoto se non c'è (allora conta solo il
  /// contenuto).
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
        // La prima cartella vince (quella dell'utente).
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

  /// Un database dai testi dei file (test).
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

  /// Il tipo canonico (gli alias portano al nome vero).
  String canonical(String type) => _aliases[type] ?? type;

  /// Il tipo dal nome del file, o null se nessun glob corrisponde. Vince il peso più alto, poi
  /// il glob più lungo (specifica, "Recommended checking order").
  String? typeForName(String name) {
    final candidates = <_Glob>[];
    candidates.addAll(_literal[name] ?? const []);
    // Tutte le estensioni possibili: per "a.tar.gz" sia "tar.gz" sia "gz".
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
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final weight = b.weight.compareTo(a.weight);
      return weight != 0
          ? weight
          : b.pattern.length.compareTo(a.pattern.length);
    });
    return canonical(candidates.first.type);
  }

  /// I genitori di un tipo, dal più vicino (`sub-class-of`, poi le regole implicite: ogni
  /// `text/*` è `text/plain`, ogni tipo è `application/octet-stream`, escluso).
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

  /// Il tipo di un file sul disco: dal nome, e dal contenuto quando il nome non basta.
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
      // ELF: e_type a 16 (1 rilocabile, 2 eseguibile, 3 condiviso: anche un eseguibile PIE).
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
    // Testo se non ci sono byte nulli né di controllo diversi da tab, a capo, ritorno.
    final binary = head.any(
      (b) => b == 0 || (b < 0x20 && b != 9 && b != 10 && b != 13 && b != 12),
    );
    return binary ? octetStream : 'text/plain';
  }
}

/// Un glob con `*`, `?` e classi `[...]` sul nome intero.
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
