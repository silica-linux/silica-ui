import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/inputs/inputs.dart';

import 'harness.dart';

void main() {
  late Color color;

  Widget well({bool enabled = true, FocusNode? focus}) => StatefulBuilder(
    builder: (context, setState) => SilicaColorWell(
      color: color,
      enabled: enabled,
      focusNode: focus,
      semanticLabel: 'Background',
      onChanged: (c) => setState(() => color = c),
    ),
  );

  setUp(() => color = const Color(0xFF0021B2));

  testWidgets('44 × 23; tap opens the picker, a swatch picks', (tester) async {
    await pumpControl(tester, well());
    expect(tester.getSize(find.byType(SilicaColorWell)), const Size(44, 23));
    expect(find.byType(SilicaColorPicker), findsNothing);
    await tester.tap(find.byType(SilicaColorWell));
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsOneWidget);
    // Picking: accent border.
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('colorWell')),
    );
    final border = (box.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, InputColors.light.accent);
    await tester.tap(find.bySemanticsLabel('#65D27B'), warnIfMissed: false);
    await tester.pump();
    expect(color, const Color(0xFF65D27B));
  });

  testWidgets('the wheel sets hue and saturation', (tester) async {
    await pumpControl(tester, well());
    await tester.tap(find.byType(SilicaColorWell));
    await tester.pump();
    final wheel = tester.getRect(find.byKey(const ValueKey('colorWheel')));
    // The right edge of the wheel: hue 0 (red), full saturation.
    await tester.tapAt(wheel.centerRight - const Offset(1, 0));
    await tester.pump();
    final hsv = HSVColor.fromColor(color);
    expect(hsv.hue, closeTo(0, 2));
    expect(hsv.saturation, closeTo(1, 0.05));
    // The center: white at full brightness.
    await tester.tapAt(wheel.center);
    await tester.pump();
    expect(HSVColor.fromColor(color).saturation, closeTo(0, 0.05));
  });

  testWidgets('a tap outside closes the picker', (tester) async {
    await pumpControl(tester, well());
    await tester.tap(find.byType(SilicaColorWell));
    await tester.pump();
    await tester.tapAt(const Offset(700, 500));
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsNothing);
  });

  testWidgets('keyboard opens it; disabled does not', (tester) async {
    final focus = FocusNode();
    await pumpControl(tester, well(focus: focus));
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsNothing);

    await pumpControl(tester, well(enabled: false));
    await tester.tap(find.byType(SilicaColorWell));
    await tester.pump();
    expect(find.byType(SilicaColorPicker), findsNothing);
  });

  testWidgets('dark bezel and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpControl(tester, well(), dark: true);
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('colorWell')),
    );
    expect((box.decoration! as BoxDecoration).color, InputColors.dark.bezel);
    final node = tester.getSemantics(find.byType(SilicaColorWell));
    expect(node.label, 'Background');
    expect(node.value, '#0021B2');
    handle.dispose();
  });

  testWidgets('picker brightness slider', (tester) async {
    var c = const Color(0xFFFF0000);
    await pumpControl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SilicaColorPicker(
          color: c,
          onChanged: (n) => setState(() => c = n),
        ),
      ),
    );
    final slider = tester.getRect(
      find.byKey(const ValueKey('colorBrightness')),
    );
    await tester.tapAt(slider.centerLeft + const Offset(2, 0));
    await tester.pump();
    expect(HSVColor.fromColor(c).value, closeTo(0, 0.01));
  });
}
