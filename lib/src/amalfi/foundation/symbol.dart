// Icon Kit symbols chosen by an app at runtime (a toolbar button's icon, a sidebar row's
// glyph): read from the installed silica-icons, `<icons>/symbols/<weight>/<name>.svg`, where
// `<icons>` is each folder of `silicaIconDirs` (`SILICA_ICONS_DIR` first, then `silica/icons`
// in the XDG data folders), and drawn with the same painter as the built-in [AmalfiGlyphs].
//
// silica_ui does not bundle silica-icons (the icons are system files, CC BY-SA 4.0): the
// controls' own glyphs are the built-in [AmalfiGlyphs]; anything else goes through
// [AmalfiSymbol], which draws nothing (or its fallback) when the symbol is not installed.

import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../icons/silica_icons.dart' show silicaIconDirs;
import 'glyph.dart';
import 'silica_symbol_names.g.dart';

/// The weights of the Icon Kit (`symbols/<weight>/`).
enum AmalfiSymbolWeight {
  light('light'),
  regular('regular'),
  semibold('semibold');

  const AmalfiSymbolWeight(this.folder);

  /// The folder under `symbols/`.
  final String folder;

  /// The family of this weight in the bundled Silica Symbols font (one family per weight).
  String get fontFamily => switch (this) {
    light => 'SilicaSymbolsLight',
    regular => 'SilicaSymbols',
    semibold => 'SilicaSymbolsSemibold',
  };
}

/// The bundled Silica Symbols glyph [name] in [weight] as an icon (draw it with `Icon`, the
/// font size is the icon box), or null when the font has no such symbol.
IconData? silicaSymbolData(
  String name, {
  AmalfiSymbolWeight weight = AmalfiSymbolWeight.regular,
}) {
  final codepoint = silicaSymbolCodepoints[name];
  if (codepoint == null) return null;
  // A by-name lookup cannot be a constant: apps that use it build with
  // `--no-tree-shake-icons` (or only use the `SilicaSymbols*` constants).
  // ignore_for_file: non_const_argument_for_const_parameter
  return IconData(
    codepoint,
    fontFamily: weight.fontFamily,
    fontPackage: 'silica_ui',
  );
}

/// Finds and reads the installed Icon Kit symbols.
abstract final class AmalfiSymbols {
  static final Map<String, AmalfiGlyphData?> _cache = {};

  static final RegExp _name = RegExp(r'^[a-z0-9][a-z0-9.-]{0,63}$');

  /// The environment the symbols are looked up in; null: the process's. For tests.
  @visibleForTesting
  static Map<String, String>? debugEnvironment;

  /// The file of the symbol [name] in [weight], or null when no installed silica-icons has it.
  static String? file(
    String name, {
    AmalfiSymbolWeight weight = AmalfiSymbolWeight.regular,
    Map<String, String>? environment,
  }) {
    if (!_name.hasMatch(name) || name.contains('..')) return null;
    final env = environment ?? debugEnvironment ?? Platform.environment;
    for (final base in silicaIconDirs(env)) {
      final path = '$base/symbols/${weight.folder}/$name.svg';
      try {
        if (File(path).existsSync()) return path;
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }

  /// The symbol [name] in [weight] as a glyph, or null when it is not installed or cannot be
  /// read. Results are cached (also the missing ones) until [clearCache].
  static AmalfiGlyphData? load(
    String name, {
    AmalfiSymbolWeight weight = AmalfiSymbolWeight.regular,
    Map<String, String>? environment,
  }) {
    final key = '${weight.folder}/$name';
    final cacheable = environment == null && debugEnvironment == null;
    if (cacheable && _cache.containsKey(key)) return _cache[key];
    AmalfiGlyphData? glyph;
    final path = file(name, weight: weight, environment: environment);
    if (path != null) {
      try {
        final f = File(path);
        // Icon Kit symbols are a few hundred bytes; anything large is not one.
        if (f.lengthSync() <= 64 * 1024) {
          glyph = AmalfiGlyphData.fromSvg(name, f.readAsStringSync());
        }
      } on FileSystemException {
        glyph = null;
      } on FormatException {
        glyph = null;
      }
    }
    if (cacheable) _cache[key] = glyph;
    return glyph;
  }

  /// Forgets the symbols read so far (after silica-icons is updated).
  static void clearCache() => _cache.clear();
}

/// The Icon Kit symbol [name] in [weight], [size] points square in [color] (both default to
/// the ambient [IconTheme], as [AmalfiGlyph]). It is set in the bundled Silica Symbols font
/// (font size = icon box); a name the font lacks is read from the installed silica-icons
/// instead, with the weight's stroke scaled with the size.
///
/// When the symbol is in neither it draws [fallback], or an empty box of [size].
class AmalfiSymbol extends StatelessWidget {
  const AmalfiSymbol(
    this.name, {
    super.key,
    this.weight = AmalfiSymbolWeight.regular,
    this.size,
    this.color,
    this.fallback,
  });

  /// The symbol's name in silica-icons (`trash`, `square-and-arrow-up`).
  final String name;

  final AmalfiSymbolWeight weight;
  final double? size;
  final Color? color;

  /// Drawn instead when the symbol is missing.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final data = silicaSymbolData(name, weight: weight);
    if (data != null) return Icon(data, size: size, color: color);
    final glyph = AmalfiSymbols.load(name, weight: weight);
    if (glyph == null) {
      return fallback ??
          SizedBox.square(dimension: size ?? IconTheme.of(context).size ?? 16);
    }
    return AmalfiGlyph(glyph, size: size, color: color);
  }
}
