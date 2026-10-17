// Helpers of the toggles, disclosure and group box kit tests: bring a control into the state
// of a master (hover, press, keyboard focus) with real input, and check a master's geometry
// and pixels in one call.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// The tolerance of small controls (16–24 pt, radius 4–12): their canvases are mostly edge,
/// and Sketch and [AmalfiSmoothBorder] antialias tight smooth corners a little differently
/// (the corner of a 1 pt accent border on white differs by up to ~100 on one channel, on a
/// few pixels; the means stay at 1–2). The 12 pt check, dash and chevron marks are drawn
/// from the Silica Symbols font in the kit, as here, but rasterised by CoreText: the mean
/// reaches 3.2 on the 16 pt checkbox.
const KitPixelTolerance smallShapes = KitPixelTolerance(mean: 3.5, max: 100);

/// The tolerance of a master: [smallShapes], looser where a 1 pt accent border meets white
/// ([accentRim]: the edge pixels under the border are antialiased by the fill and again by
/// the border, so they differ by up to ~125; means ≤ 3) or where a kit defect is masked
/// ([masked]: what is left is mostly edge pixels; means ≤ 3.1).
KitPixelTolerance tolerance({bool accentRim = false, bool masked = false}) =>
    accentRim
    ? const KitPixelTolerance(mean: 4, max: 128)
    : masked
    ? const KitPixelTolerance(mean: 4, max: 100)
    : smallShapes;

/// The pointer of the current test, if any (hovering or pressing).
TestGesture? _mouse;

Future<TestGesture> _pointer(WidgetTester tester) async {
  final old = _mouse;
  if (old != null) {
    _mouse = null;
    await old.removePointer();
  }
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  _mouse = mouse;
  addTearDown(() async {
    if (_mouse == mouse) {
      _mouse = null;
      await mouse.removePointer();
    }
  });
  await mouse.addPointer(location: const Offset(-50, -50));
  return mouse;
}

/// A state of a kit master and how to bring a control into it with real input.
enum KitState {
  rest,
  hover,
  pressed,
  disabled,
  focused;

  /// The state named as in the kit (`Rest`, `Hover`, …).
  static KitState parse(String name) => switch (name) {
    'Rest' => rest,
    'Hover' => hover,
    'Pressed' => pressed,
    'Disabled' => disabled,
    'Focused' => focused,
    _ => throw ArgumentError.value(name, 'state'),
  };

  /// Whether the control is enabled in this state.
  bool get enabled => this != disabled;

  /// Brings the control at [target] into this state: the pointer over it, pressed on it
  /// (held until the test ends), or the keyboard focus moved to it with Tab.
  Future<void> apply(WidgetTester tester, Finder target) async {
    switch (this) {
      case rest || disabled:
        break;
      case hover:
        final mouse = await _pointer(tester);
        await mouse.moveTo(tester.getCenter(target));
      case pressed:
        final mouse = await _pointer(tester);
        await mouse.moveTo(tester.getCenter(target));
        await mouse.down(tester.getCenter(target));
      case focused:
        // Keyboard navigation: the halo shows only in the traditional highlight mode.
        final manager = tester.binding.focusManager;
        manager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => manager.highlightStrategy = FocusHighlightStrategy.automatic,
        );
        final inside = find.descendant(
          of: target,
          matching: find.byType(Listener),
        );
        Focus.of(tester.element(inside.first)).requestFocus();
    }
    await tester.pumpAndSettle();
  }
}

/// Gives the keyboard focus to the control at [target], as keyboard navigation would.
Future<void> focusOn(WidgetTester tester, Finder target) async {
  final inside = find.descendant(of: target, matching: find.byType(Listener));
  Focus.of(tester.element(inside.first)).requestFocus();
  await tester.pump();
}

/// The finder of the layer drawn with [key] under [root].
Finder layerOf(Finder root, Key key) =>
    find.descendant(of: root, matching: find.byKey(key));

/// Checks [widget] against the master [name]: geometry with [layers] (built from the root
/// finder) after bringing it into [state] on [target] (by default the root), then pixels with
/// shapes only (text masked) and, when [withText], with the text.
Future<void> checkKit(
  WidgetTester tester,
  String name,
  Widget widget, {
  required Map<String, Finder> Function(Finder root) layers,
  KitState state = KitState.rest,
  Finder Function(Finder root)? target,
  Map<String, String> deviations = const {},
  List<String> maskLayers = const [],
  List<Rect> mask = const [],
  double maskMargin = 1,
  bool withText = false,
  KitPixelTolerance tolerance = smallShapes,
  bool pixels = true,
}) async {
  final master = KitMaster.load(name);
  final root = await pumpKitScene(tester, widget, master: master);
  Finder targetOf(Finder r) => target?.call(r) ?? r;
  await state.apply(tester, targetOf(root));
  expectKitGeometry(
    tester,
    master,
    root: root,
    layers: layers(root),
    deviations: deviations,
  );
  if (!pixels) return;
  Future<void> prepare(WidgetTester tester) async {
    final r = find.byWidget(widget);
    await state.apply(tester, targetOf(r));
  }

  await expectKitPixels(
    tester,
    master,
    widget,
    maskText: true,
    maskLayers: maskLayers,
    mask: mask,
    maskMargin: maskMargin,
    tolerance: tolerance,
    prepare: prepare,
  );
  if (withText) {
    await expectKitPixels(
      tester,
      master,
      widget,
      maskLayers: maskLayers,
      mask: mask,
      maskMargin: maskMargin,
      tolerance: KitPixelTolerance.withText,
      prepare: prepare,
    );
  }
}
