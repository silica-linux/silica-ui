import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  Future<bool> activeUnder(
    WidgetTester tester,
    Widget Function(Widget) wrap,
  ) async {
    late bool active;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            active = WindowActiveScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return active;
  }

  testWidgets('window state: scope, then the toolbar scope, then active', (
    tester,
  ) async {
    expect(await activeUnder(tester, (c) => c), isTrue);
    expect(
      await activeUnder(tester, (c) => ToolbarScope(active: false, child: c)),
      isFalse,
    );
    expect(
      await activeUnder(
        tester,
        (c) => ToolbarScope(
          active: false,
          child: WindowActiveScope(active: true, child: c),
        ),
      ),
      isTrue,
    );
  });

  Future<void> ring(
    WidgetTester tester, {
    required bool active,
    FocusRingKind kind = FocusRingKind.field,
    bool dark = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        platformBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: WindowActiveScope(
        active: active,
        child: Center(
          child: FocusRing(
            visible: true,
            kind: kind,
            child: const SizedBox(width: 40, height: 20),
          ),
        ),
      ),
    ),
  );

  testWidgets('focus ring: shown from the first frame, hidden when inactive', (
    tester,
  ) async {
    await ring(tester, active: true);
    expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
    await ring(tester, active: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus ring')), findsNothing);
  });

  test('palette: one accent and one inactive gray for every group', () {
    expect(
      ControlColors.light.inactiveAccent,
      InputColors.light.accentInactive,
    );
    expect(
      ControlColors.darkColors.inactiveAccent,
      InputColors.dark.accentInactive,
    );
    expect(ControlColors.light.focusRing, InputColors.light.focusRingControl);
    expect(InputColors.light.accent, ControlAccent.system);
  });
}
