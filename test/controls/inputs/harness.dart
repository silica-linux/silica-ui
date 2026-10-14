import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/inputs/inputs.dart';

/// A host for one control: an app (text editing shortcuts), an overlay (menus), the
/// appearance and the window state.
Future<void> pumpControl(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool active = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        platformBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: WindowActiveScope(
        active: active,
        child: _Slot(
          control: child,
          host: WidgetsApp(
            color: const Color(0xFF007AFF),
            builder: (context, _) => Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _Slot.of(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// The overlay keeps its first entries: the control reaches them through this.
class _Slot extends InheritedWidget {
  const _Slot({required Widget host, required this.control})
    : super(child: host);

  final Widget control;

  static Widget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Slot>()!.control;

  @override
  bool updateShouldNotify(_Slot old) => old.control != control;
}

/// The focus rings visible in the tree.
Finder ringFinder() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_RingPainter',
);

/// A mouse click (menus choose on the release of a hovering pointer).
Future<void> click(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pump();
  await gesture.down(tester.getCenter(finder));
  await tester.pump();
  await gesture.up();
  await gesture.removePointer();
  // A chosen menu item blinks and waits ~114 ms without frames.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
