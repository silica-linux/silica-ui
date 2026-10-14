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

  test('contenuto a tutta finestra', () async {
    expect(await SilicaWindow.setFullSizeContent(52), isTrue);
    expect(calls.single.method, 'setFullSizeContent');
    expect((calls.single.arguments as Map)['toolbarHeight'], 52);
  });

  testWidgets(
    'trascinare il vuoto sposta la finestra; i controlli ricevono il clic',
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

  testWidgets('le capsule seguono l\'aspetto del sistema', (tester) async {
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

  group('stati dei controlli (MU-07)', () {
    late List<String> log;
    late Map<String, Color> glyphs;

    Widget segment(String name, {bool enabled = true, bool chosen = false}) =>
        ToolbarSegment(
          key: ValueKey(name),
          width: 36,
          enabled: enabled,
          chosen: chosen,
          onTap: () => log.add('tap $name'),
          onLongPress: () => log.add('lungo $name'),
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
                children: [
                  segment('indietro'),
                  segment('avanti', enabled: false),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Color? pill(WidgetTester tester, String name) {
      final found = find.descendant(
        of: find.byKey(ValueKey(name)),
        matching: find.byKey(const ValueKey('pillola')),
      );
      if (found.evaluate().isEmpty) return null;
      return (tester.widget<Container>(found).decoration! as BoxDecoration)
          .color;
    }

    testWidgets('passaggio, pressione, rilascio; separatore nascosto', (
      tester,
    ) async {
      await pump(tester);
      expect(pill(tester, 'indietro'), isNull);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('indietro'))),
      );
      await tester.pump();
      expect(pill(tester, 'indietro'), ToolbarColors.light.hover);
      final separator = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxWidth == 1);
      expect(separator.single.color, isNull);
      await mouse.down(
        tester.getCenter(find.byKey(const ValueKey('indietro'))),
      );
      await tester.pump();
      expect(pill(tester, 'indietro'), ToolbarColors.light.pressed);
      expect(glyphs['indietro'], ToolbarColors.light.iconPressed);
      expect(log, isEmpty);
      await mouse.up();
      await tester.pump();
      expect(log, ['tap indietro']);
      // Disattivato: nessuna pillola, nessuna azione.
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('avanti'))),
      );
      await tester.pump();
      expect(pill(tester, 'avanti'), isNull);
      await mouse.down(tester.getCenter(find.byKey(const ValueKey('avanti'))));
      await mouse.up();
      await tester.pump();
      expect(log, ['tap indietro']);
    });

    testWidgets('pressione lunga: il menu, e il rilascio non agisce', (
      tester,
    ) async {
      await pump(tester);
      final at = tester.getCenter(find.byKey(const ValueKey('indietro')));
      final g = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 120));
      expect(log, ['lungo indietro']);
      await g.up();
      await tester.pump();
      expect(log, ['lungo indietro']);
    });

    testWidgets('finestra inattiva: glifo spento, il passaggio lo riaccende', (
      tester,
    ) async {
      await pump(tester, active: false);
      expect(glyphs['indietro'], ToolbarColors.light.iconInactive);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('indietro'))),
      );
      await tester.pump();
      expect(glyphs['indietro'], ToolbarColors.light.icon);
      expect(pill(tester, 'indietro'), ToolbarColors.light.hoverInactive);
    });
  });
}
