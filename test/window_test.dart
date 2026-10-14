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
}
