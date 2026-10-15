import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui_example/catalog/buttons.dart';

void main() {
  testWidgets('the buttons page builds in the four appearances', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: buttonsCatalog()),
    );
    expect(find.byType(SegmentedControl), findsNWidgets(16));
    expect(find.byType(PopUpButton<String>), findsNWidgets(4));
    // Pressing the section switch swells its lens; releasing chooses the segment under it.
    final press = await tester.startGesture(
      tester.getCenter(find.text('Alarms').first),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('glass lens')), findsOneWidget);
    await press.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('glass lens')), findsNothing);
    await tester.tap(find.byType(PopUpButton<String>).first);
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
  });
}
