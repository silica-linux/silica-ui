import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SilicaWindow.channel, (call) async {
          calls.add(call);
          return call.method == 'setFullSizeContent' ? true : null;
        });
  });

  test('full-size content', () async {
    expect(await SilicaWindow.setFullSizeContent(52), isTrue);
    expect(calls.single.method, 'setFullSizeContent');
    expect((calls.single.arguments as Map)['toolbarHeight'], 52);
  });

  testWidgets(
    'dragging the empty part moves the window; controls receive the click',
    (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WindowDragArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: toolbarHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ToolbarCapsule(
                    separators: true,
                    children: [
                      ToolbarSegment(
                        key: const ValueKey('a'),
                        icon: (c) => SizedBox(
                          width: 8,
                          height: 14,
                          child: ColoredBox(color: c),
                        ),
                        onTap: () => tapped++,
                      ),
                      ToolbarSegment(
                        icon: (c) => const SizedBox(width: 8, height: 14),
                        chosen: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ToolbarCapsule)).height,
        toolbarCapsuleHeight,
      );
      await tester.tap(find.byKey(const ValueKey('a')));
      expect(tapped, 1);
      // Dragging from a control does not move the window.
      final fromControl = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('a'))),
        kind: PointerDeviceKind.mouse,
      );
      await fromControl.moveBy(const Offset(-40, 0));
      await fromControl.up();
      await tester.pump();
      expect(calls, isEmpty);
      final gesture = await tester.startGesture(
        const Offset(20, 26),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(30, 0));
      await gesture.up();
      await tester.pump();
      expect(calls.map((c) => c.method), contains('startMove'));
    },
  );

  testWidgets('capsules follow the system appearance', (tester) async {
    Color? drawn;
    Future<void> pump(Brightness b) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(platformBrightness: b),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ToolbarCapsule(
              children: [
                ToolbarSegment(
                  icon: (color) {
                    drawn = color;
                    return const SizedBox(width: 10, height: 10);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await pump(Brightness.light);
    expect(drawn, ToolbarColors.light.icon);
    await pump(Brightness.dark);
    expect(drawn, ToolbarColors.dark.icon);
  });

  group('control states (MU-07)', () {
    late List<String> log;
    late Map<String, Color> glyphs;

    Widget segment(String name, {bool enabled = true, bool chosen = false}) =>
        ToolbarSegment(
          key: ValueKey(name),
          width: 36,
          enabled: enabled,
          chosen: chosen,
          onTap: () => log.add('tap $name'),
          onLongPress: () => log.add('long $name'),
          icon: (color) {
            glyphs[name] = color;
            return const SizedBox(width: 10, height: 10);
          },
        );

    Future<void> pump(WidgetTester tester, {bool active = true}) async {
      log = [];
      glyphs = {};
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ToolbarScope(
            active: active,
            child: Center(
              child: ToolbarCapsule(
                separators: true,
                children: [segment('back'), segment('forward', enabled: false)],
              ),
            ),
          ),
        ),
      );
    }

    Color? pill(WidgetTester tester, String name) {
      final found = find.descendant(
        of: find.byKey(ValueKey(name)),
        matching: find.byKey(const ValueKey('pill')),
      );
      if (found.evaluate().isEmpty) return null;
      return (tester.widget<Container>(found).decoration! as BoxDecoration)
          .color;
    }

    testWidgets('hover, press, release; separator hidden', (tester) async {
      await pump(tester);
      expect(pill(tester, 'back'), isNull);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('back'))));
      await tester.pump();
      expect(pill(tester, 'back'), ToolbarColors.light.hover);
      final separator = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxWidth == 1);
      expect(separator.single.color, isNull);
      await mouse.down(tester.getCenter(find.byKey(const ValueKey('back'))));
      await tester.pump();
      expect(pill(tester, 'back'), ToolbarColors.light.pressed);
      expect(glyphs['back'], ToolbarColors.light.iconPressed);
      expect(log, isEmpty);
      await mouse.up();
      await tester.pump();
      expect(log, ['tap back']);
      // Disabled: no pill, no action.
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('forward'))),
      );
      await tester.pump();
      expect(pill(tester, 'forward'), isNull);
      await mouse.down(tester.getCenter(find.byKey(const ValueKey('forward'))));
      await mouse.up();
      await tester.pump();
      expect(log, ['tap back']);
    });

    testWidgets('long press: the menu, and the release does not act', (
      tester,
    ) async {
      await pump(tester);
      final at = tester.getCenter(find.byKey(const ValueKey('back')));
      final g = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 120));
      expect(log, ['long back']);
      await g.up();
      await tester.pump();
      expect(log, ['long back']);
    });

    testWidgets('inactive window: dim glyph, hovering lights it up', (
      tester,
    ) async {
      await pump(tester, active: false);
      expect(glyphs['back'], ToolbarColors.light.iconInactive);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('back'))));
      await tester.pump();
      expect(glyphs['back'], ToolbarColors.light.icon);
      expect(pill(tester, 'back'), ToolbarColors.light.hoverInactive);
    });
  });
}
