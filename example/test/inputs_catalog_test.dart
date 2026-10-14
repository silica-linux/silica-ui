import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui_example/catalog/inputs.dart';

void main() {
  Future<void> pumpCatalog(WidgetTester tester, {bool dark = false}) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(1400, 1800),
          platformBrightness: dark ? Brightness.dark : Brightness.light,
        ),
        child: WidgetsApp(
          color: const Color(0xFF007AFF),
          builder: (context, _) => inputsCatalog(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('every control is on the page, light and dark', (tester) async {
    for (final dark in [false, true]) {
      await pumpCatalog(tester, dark: dark);
      expect(tester.takeException(), isNull);
      for (final type in [
        SilicaTextField,
        SilicaSearchField,
        SilicaTokenField,
        SilicaSlider,
        SilicaCircularSlider,
        SilicaStepper,
        SilicaDateField,
        SilicaCalendar,
        SilicaClockFace,
        SilicaColorWell,
        SilicaLevelIndicator,
        SilicaProgressBar,
        SilicaSpinner,
        SilicaProgressRing,
      ]) {
        expect(find.byType(type), findsWidgets, reason: '$type');
      }
    }
  });

  testWidgets('the toggle disables the controls; the color well opens', (
    tester,
  ) async {
    await pumpCatalog(tester);
    await tester.tap(find.text('Enabled (tap to disable)'));
    await tester.pump();
    expect(find.text('Disabled (tap to enable)'), findsOneWidget);
    expect(
      tester.widget<SilicaSlider>(find.byType(SilicaSlider).first).enabled,
      isFalse,
    );
    await tester.tap(find.text('Disabled (tap to enable)'));
    await tester.pump();
    await tester.tap(find.byType(SilicaColorWell));
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsOneWidget);
  });
}
