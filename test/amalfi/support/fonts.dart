// Loads the package fonts (Inter, JetBrains Mono) into the test engine, so that text in widget
// tests is drawn with the real glyphs and metrics instead of the Ahem test font.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool _loaded = false;

/// Whether [loadAmalfiFonts] has run.
bool get amalfiFontsLoaded => _loaded;

/// Loads Inter (400, 500, 600, 700) and JetBrains Mono under the names the package's text
/// styles use (`packages/silica_ui/Inter`). It loads once.
///
/// Call it from `setUpAll(loadAmalfiFonts)`: inside a `testWidgets` body the engine's font
/// loading does not complete in the fake clock; there use [ensureAmalfiFonts].
Future<void> loadAmalfiFonts() async {
  if (_loaded) return;
  ByteData read(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('$path not found: run the tests from the package root');
    }
    return ByteData.sublistView(file.readAsBytesSync());
  }

  final inter = FontLoader('packages/silica_ui/Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(Future.value(read('fonts/Inter-$weight.ttf')));
  }
  final mono = FontLoader('packages/silica_ui/JetBrains Mono')
    ..addFont(Future.value(read('fonts/JetBrainsMono-Regular.ttf')));
  await Future.wait([inter.load(), mono.load()]);
  _loaded = true;
}

/// Loads the fonts from inside a `testWidgets` body (with the real clock).
Future<void> ensureAmalfiFonts(WidgetTester tester) async {
  if (_loaded) return;
  await tester.runAsync(loadAmalfiFonts);
}
