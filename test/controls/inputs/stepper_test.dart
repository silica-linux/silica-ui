import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

void main() {
  late double value;

  Widget stepper({bool wraps = false, bool enabled = true, FocusNode? f}) =>
      StatefulBuilder(
        builder: (context, setState) => SilicaStepper(
          value: value,
          min: 0,
          max: 10,
          wraps: wraps,
          enabled: enabled,
          focusNode: f,
          semanticLabel: 'Count',
          onChanged: (v) => setState(() => value = v),
        ),
      );

  setUp(() => value = 5);

  testWidgets('20 × 24; arrows add and subtract', (tester) async {
    await pumpControl(tester, stepper());
    expect(tester.getSize(find.byType(SilicaStepper)), const Size(20, 24));

    await tester.tap(find.byKey(const ValueKey('stepperUp')));
    await tester.pump();
    expect(value, 6);
    await tester.tap(find.byKey(const ValueKey('stepperDown')));
    await tester.pump();
    expect(value, 5);
  });

  testWidgets('holding repeats after the delay', (tester) async {
    await pumpControl(tester, stepper());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('stepperUp'))),
    );
    await tester.pump();
    expect(value, 6);
    await tester.pump(StepperMetrics.repeatDelay);
    await tester.pump(StepperMetrics.repeatInterval * 2);
    expect(value, 8);
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(value, 8);
  });

  testWidgets('clamps at the ends, or wraps', (tester) async {
    value = 10;
    await pumpControl(tester, stepper());
    await tester.tap(find.byKey(const ValueKey('stepperUp')));
    await tester.pump();
    expect(value, 10);
    await pumpControl(tester, stepper(wraps: true));
    await tester.tap(find.byKey(const ValueKey('stepperUp')));
    await tester.pump();
    expect(value, 0);
  });

  testWidgets('keyboard and focus ring', (tester) async {
    final focus = FocusNode();
    await pumpControl(tester, stepper(f: focus));
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value, 6);
  });

  testWidgets('disabled does nothing; dark bezel', (tester) async {
    await pumpControl(tester, stepper(enabled: false), dark: true);
    await tester.tap(find.byKey(const ValueKey('stepperUp')));
    await tester.pump();
    expect(value, 5);
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(SilicaStepper),
        matching: find.byType(Container),
      ),
    );
    expect((box.decoration! as BoxDecoration).color, InputColors.dark.bezel);
  });

  testWidgets('semantics: value, increase and decrease', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpControl(tester, stepper());
    final node = tester.getSemantics(find.byType(SilicaStepper));
    expect(node.value, '5');
    expect(node.increasedValue, '6');
    expect(node.decreasedValue, '4');
    tester.semantics.decrease(find.semantics.byLabel('Count'));
    await tester.pump();
    expect(value, 4);
    handle.dispose();
  });
}
