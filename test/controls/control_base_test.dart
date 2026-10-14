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
    // INV-B: the gallery's inactive gray.
    expect(ControlPalette.inactiveAccentLight, const Color(0xFFCFCFCF));
    expect(ControlPalette.inactiveAccentDark, const Color(0xFF505051));
  });

  test('accents: the measured table (CT-CL-01)', () {
    expect(SilicaAccent.values, hasLength(9));
    final multi = AccentColors.of(SilicaAccent.multicolor, dark: false);
    expect(multi, AccentColors.of(SilicaAccent.blue, dark: false));
    expect(multi.plain, const Color(0xFF007AFF));
    expect(multi.fill, const Color(0xFF0077F9));
    expect(multi.ring, const Color(0xFF8FB4FB));
    final redDark = AccentColors.of(SilicaAccent.red, dark: true);
    expect(redDark.plain, const Color(0xFFFF5257));
    expect(redDark.fill, const Color(0xFFFF565B));
    expect(redDark.ring, const Color(0xFF945154));
    expect(
      AccentColors.of(SilicaAccent.graphite, dark: false).plain,
      const Color(0xFF989898),
    );
  });

  test('pressed: one 10 % step (INV-B)', () {
    expect(
      ControlPalette.pressed(const Color(0xFF373738), dark: true),
      isSameColorAs(const Color(0xFF4B4B4C)),
    );
    expect(
      ControlPalette.pressed(const Color(0xFFE6E6E6), dark: false),
      isSameColorAs(const Color(0xFFCFCFCF)),
    );
  });

  testWidgets('a system accent colors the controls and the ring', (
    tester,
  ) async {
    Color? fill, ring;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light),
        child: ControlAccent.palette(
          accent: SilicaAccent.red,
          child: Builder(
            builder: (context) {
              fill = ControlAccent.fillOf(context);
              ring = ControlAccent.colorsOf(context).ring;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(fill, const Color(0xFFDB373D));
    expect(ring, const Color(0xFFEC9894));
  });
}
