// Pumping a widget for a geometry test against a kit master.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fonts.dart';
import 'kit.dart';

/// The key of the widget pumped by [pumpKitScene]: `find.byKey(kitSceneRoot)` is the root.
const Key kitSceneRoot = ValueKey('kit-scene-root');

/// Pumps [widget] at device pixel ratio 1 at the top left of a 1600 × 1200 view, with loose
/// constraints, in the appearance of [master] (or [brightness]), with the package fonts
/// loaded and a [Directionality], [MediaQuery] and [Overlay] above it. Returns the finder of
/// the widget, to pass as `root` to `expectKitGeometry`.
Future<Finder> pumpKitScene(
  WidgetTester tester,
  Widget widget, {
  KitMaster? master,
  Brightness? brightness,
  Size view = const Size(1600, 1200),
}) async {
  await ensureAmalfiFonts(tester);
  final appearance = brightness ?? master?.brightness ?? Brightness.light;
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = view;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: view, platformBrightness: appearance),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AmalfiTheme(
          brightness: appearance,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.topLeft,
                  child: KeyedSubtree(key: kitSceneRoot, child: widget),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return find.byKey(kitSceneRoot);
}
