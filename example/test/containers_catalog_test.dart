import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui_example/catalog/containers.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the containers page builds ($brightness)', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF007AFF),
          builder: (context, _) => containersCatalog(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Toolbar over scrolling content'), findsOneWidget);
    });
  }
}
