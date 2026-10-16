import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui_example/main.dart';

Future<void> pumpCatalog(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
  tester.view.physicalSize = const Size(2400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const Catalog());
  await tester.pumpAndSettle();
}

bool activeAt(WidgetTester tester) =>
    WindowActiveScope.of(tester.element(find.byType(SourceList).first));

void main() {
  testWidgets('the sidebar switches pages, the toolbar the appearance', (
    tester,
  ) async {
    await pumpCatalog(tester);
    expect(find.byType(ScrollUnderToolbar), findsOneWidget);
    expect(find.byType(SilicaCheckbox), findsWidgets);

    // The inputs page has endless animations (spinner, indeterminate bar): no settling.
    await tester.tap(find.text('Inputs').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SilicaTextField), findsWidgets);

    await tester.tap(find.text('Containers').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SilicaTextField), findsNothing);
    expect(find.byType(SplitView), findsWidgets);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.platformBrightnessOf(
        tester.element(find.byType(SourceList).first),
      ),
      Brightness.dark,
    );

    // The Amalfi gallery opens in the catalog's appearance.
    await tester.tap(find.text('Amalfi gallery').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Amalfi · Tooltips'), findsOneWidget);
    expect(
      AmalfiTheme.of(
        tester.element(find.byType(AmalfiTooltip).first),
      ).brightness,
      Brightness.dark,
    );
  });

  testWidgets('the window state can be forced inactive', (tester) async {
    await pumpCatalog(tester);
    expect(activeAt(tester), isTrue);
    // Press on the pop-up, drag to the item, release on it.
    final mouse = await tester.startGesture(
      tester.getCenter(find.byType(PopUpButton<WindowMode>)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await mouse.moveTo(tester.getCenter(find.text('Inactive window').last));
    await tester.pump();
    await mouse.up();
    // A chosen menu item blinks before it acts.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(activeAt(tester), isFalse);
  });
}
