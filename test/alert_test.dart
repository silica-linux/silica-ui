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
            title: 'Vuoi usare .md?',
            message: 'Il file potrebbe aprirsi con un\'altra app.',
            sideBySide: sideBySide,
            buttons: [
              AlertButton(
                'Mantieni',
                role: AlertRole.cancel,
                onPressed: () => log.add('mantieni'),
              ),
              AlertButton(
                'Usa',
                role: AlertRole.primary,
                onPressed: () => log.add('usa'),
              ),
            ],
          ),
        ),
      ),
    );
    return log;
  }

  testWidgets('292 pt, titolo a 99, pulsanti impilati o affiancati', (
    tester,
  ) async {
    await pump(tester, sideBySide: false);
    expect(tester.getSize(find.byType(SilicaAlert)).width, alertWidth);
    expect(
      tester.getTopLeft(find.text('Vuoi usare .md?')),
      const Offset(21, 99),
    );
    final keep = tester.getRect(find.byKey(const ValueKey('avviso Mantieni')));
    final use = tester.getRect(find.byKey(const ValueKey('avviso Usa')));
    expect(keep.size, const Size(262, 30));
    expect(keep.left, 15);
    expect(use.top - keep.bottom, alertStackedGap);

    await pump(tester, sideBySide: true);
    final keep2 = tester.getRect(find.byKey(const ValueKey('avviso Mantieni')));
    final use2 = tester.getRect(find.byKey(const ValueKey('avviso Usa')));
    expect(keep2.size, const Size(128, 30));
    expect(use2.left - keep2.right, alertSideGap);
  });

  testWidgets('Invio sceglie il predefinito, Esc annulla', (tester) async {
    final log = await pump(tester, sideBySide: true);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tap(find.byKey(const ValueKey('avviso Mantieni')));
    expect(log, ['usa', 'mantieni', 'mantieni']);
  });

  testWidgets('pieno: niente vetro, pulsante normale grigio', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SilicaAlert(
            title: 'Titolo',
            opaque: true,
            buttons: [
              AlertButton('OK', role: AlertRole.cancel, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('avviso pieno')), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    final ok = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('avviso OK')),
        matching: find.byType(Container),
      ),
    );
    expect(
      (ok.decoration! as BoxDecoration).color,
      AlertColors.normalOpaqueLight,
    );
  });
}
