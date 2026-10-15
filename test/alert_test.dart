import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
  });

  Future<List<String>> pump(
    WidgetTester tester, {
    required bool sideBySide,
  }) async {
    final log = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SilicaAlert(
            title: 'Use .md?',
            message: 'The file may open with another app.',
            sideBySide: sideBySide,
            buttons: [
              AlertButton(
                'Keep',
                role: AlertRole.cancel,
                onPressed: () => log.add('keep'),
              ),
              AlertButton(
                'Use',
                role: AlertRole.primary,
                onPressed: () => log.add('use'),
              ),
            ],
          ),
        ),
      ),
    );
    return log;
  }

  testWidgets('the alert glass declares the sheet profile', (tester) async {
    await pump(tester, sideBySide: false);
    final glass = tester.widget<Glass>(find.byType(Glass));
    expect(glass.profile, GlassProfile.sheet);
  });

  testWidgets('292 pt, title at 99, buttons stacked or side by side', (
    tester,
  ) async {
    await pump(tester, sideBySide: false);
    expect(tester.getSize(find.byType(SilicaAlert)).width, alertWidth);
    expect(tester.getTopLeft(find.text('Use .md?')), const Offset(21, 99));
    final keep = tester.getRect(find.byKey(const ValueKey('alert Keep')));
    final use = tester.getRect(find.byKey(const ValueKey('alert Use')));
    expect(keep.size, const Size(262, 30));
    expect(keep.left, 15);
    expect(use.top - keep.bottom, alertStackedGap);

    await pump(tester, sideBySide: true);
    final keep2 = tester.getRect(find.byKey(const ValueKey('alert Keep')));
    final use2 = tester.getRect(find.byKey(const ValueKey('alert Use')));
    expect(keep2.size, const Size(128, 30));
    expect(use2.left - keep2.right, alertSideGap);
  });

  testWidgets('Return chooses the default, Esc cancels', (tester) async {
    final log = await pump(tester, sideBySide: true);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tap(find.byKey(const ValueKey('alert Keep')));
    expect(log, ['use', 'keep', 'keep']);
  });

  testWidgets('solid: no glass, gray normal button', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SilicaAlert(
            title: 'Title',
            opaque: true,
            buttons: [
              AlertButton('OK', role: AlertRole.cancel, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('solid alert')), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    final ok = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('alert OK')),
        matching: find.byType(Container),
      ),
    );
    expect(
      (ok.decoration! as BoxDecoration).color,
      AlertColors.normalOpaqueLight,
    );
  });
}
