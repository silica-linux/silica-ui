import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

SliderPainter sliderPainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<SliderPainter>()
    .single;

void main() {
  late double value;

  Widget slider({
    SliderSize size = SliderSize.regular,
    int? divisions,
    bool ticks = false,
    bool enabled = true,
    List<String>? labels,
    FocusNode? focus,
  }) => StatefulBuilder(
    builder: (context, setState) => SilicaSlider(
      value: value,
      min: 0,
      max: 112,
      width: 80,
      size: size,
      divisions: divisions,
      ticks: ticks,
      labels: labels,
      enabled: enabled,
      focusNode: focus,
      semanticLabel: 'Icon size',
      onChanged: (v) => setState(() => value = v),
    ),
  );

  setUp(() => value = 24);

  testWidgets('small slider: 80 wide, 18 × 14 knob, 4 pt track', (
    tester,
  ) async {
    await pumpControl(tester, slider(size: SliderSize.small));
    expect(tester.getSize(find.byType(SilicaSlider)), const Size(80, 14));
    final p = sliderPainter(tester);
    expect(p.metrics.knob, const Size(18, 14));
    expect(p.metrics.track, 4);
    expect(p.fill, InputColors.light.trackFill);
    expect(p.track, InputColors.light.track);
    expect(p.knob, InputColors.light.knob);
  });

  testWidgets('regular slider: 20 × 16 knob, 6 pt track', (tester) async {
    await pumpControl(tester, slider());
    expect(sliderPainter(tester).metrics, SliderMetrics.regular);
  });

  testWidgets('dark and inactive colors', (tester) async {
    await pumpControl(tester, slider(), dark: true);
    expect(sliderPainter(tester).knob, InputColors.dark.knob);
    expect(sliderPainter(tester).fill, InputColors.dark.trackFill);
    await pumpControl(tester, slider(), active: false);
    expect(sliderPainter(tester).fill, InputColors.light.accentInactive);
  });

  testWidgets('tap and drag set the value, the knob center follows', (
    tester,
  ) async {
    await pumpControl(tester, slider());
    final rect = tester.getRect(find.byType(SilicaSlider));
    await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
    expect(value, 0);
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    expect(value, 112);
    await tester.dragFrom(
      Offset(rect.right - 10, rect.center.dy),
      const Offset(-30, 0),
    );
    expect(value, closeTo(112 - 30 / 60 * 112, 4));
  });

  testWidgets('divisions snap; ticks are drawn', (tester) async {
    await pumpControl(tester, slider(divisions: 4, ticks: true));
    expect(tester.getSize(find.byType(SilicaSlider)).height, 16 + 3 + 4);
    expect(sliderPainter(tester).ticks, 4);
    final rect = tester.getRect(find.byType(SilicaSlider));
    await tester.tapAt(Offset(rect.left + 35, rect.top + 8));
    expect(value % 28, 0);
  });

  testWidgets('keyboard: arrows, Home, End; focus ring on the knob', (
    tester,
  ) async {
    final focus = FocusNode();
    await pumpControl(tester, slider(focus: focus, divisions: 4));
    expect(ringFinder(), findsNothing);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
    value = 28;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 56);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 112);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 0);
  });

  testWidgets('disabled: no change, half opacity', (tester) async {
    await pumpControl(tester, slider(enabled: false));
    final rect = tester.getRect(find.byType(SilicaSlider));
    await tester.tapAt(Offset(rect.right - 5, rect.center.dy));
    expect(value, 24);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(SilicaSlider),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.5,
    );
  });

  testWidgets('labels under the ends', (tester) async {
    await pumpControl(tester, slider(labels: const ['Slow', 'Fast']));
    final slow = tester.getRect(find.text('Slow'));
    final fast = tester.getRect(find.text('Fast'));
    final rect = tester.getRect(find.byType(SilicaSlider));
    expect(slow.left, rect.left);
    expect(fast.right, rect.right);
  });

  testWidgets('semantics: slider with value and actions', (tester) async {
    final handle = tester.ensureSemantics();
    value = 56;
    await pumpControl(tester, slider());
    final node = tester.getSemantics(find.byType(SilicaSlider));
    expect(node.label, 'Icon size');
    expect(node.value, '50 %');
    expect(node.flagsCollection.isSlider, isTrue);
    tester.semantics.increase(find.semantics.byLabel('Icon size'));
    await tester.pump();
    expect(value, greaterThan(56));
    handle.dispose();
  });

  testWidgets('circular slider: drag around, keyboard', (tester) async {
    var angle = 0.0;
    final focus = FocusNode();
    await pumpControl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SilicaCircularSlider(
          value: angle,
          max: 360,
          focusNode: focus,
          onChanged: (v) => setState(() => angle = v),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(SilicaCircularSlider)),
      const Size(24, 24),
    );
    final rect = tester.getRect(find.byType(SilicaCircularSlider));
    // To the right of the center: a quarter turn.
    await tester.tapAt(rect.centerRight - const Offset(1, 0));
    await tester.pump();
    expect(angle, closeTo(90, 5));
    await tester.tapAt(rect.bottomCenter - const Offset(0, 1));
    await tester.pump();
    expect(angle, closeTo(180, 5));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(angle, closeTo(190, 5));
  });
}
