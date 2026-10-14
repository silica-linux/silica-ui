import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

LevelPainter levelPainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<LevelPainter>()
    .single;

void main() {
  testWidgets('continuous: green, then yellow and red past the thresholds', (
    tester,
  ) async {
    Widget level(double v) =>
        SilicaLevelIndicator(value: v, max: 10, warning: 7, critical: 9);
    await pumpControl(tester, level(3));
    expect(
      tester.getSize(find.byType(SilicaLevelIndicator)),
      const Size(100, 6),
    );
    expect(levelPainter(tester).fill, LevelColors.normalLight);
    expect(levelPainter(tester).t, 0.3);
    await pumpControl(tester, level(7));
    expect(levelPainter(tester).fill, LevelColors.warningLight);
    await pumpControl(tester, level(9.5), dark: true);
    expect(levelPainter(tester).fill, LevelColors.criticalDark);
  });

  testWidgets('inverted thresholds: low is critical (battery)', (tester) async {
    await pumpControl(
      tester,
      const SilicaLevelIndicator(value: 1, max: 10, warning: 3, critical: 1),
    );
    expect(levelPainter(tester).fill, LevelColors.criticalLight);
  });

  testWidgets('discrete: one segment per unit', (tester) async {
    await pumpControl(
      tester,
      const SilicaLevelIndicator(
        value: 3,
        max: 8,
        style: LevelIndicatorStyle.discrete,
      ),
    );
    expect(levelPainter(tester).units, 8);
    expect(tester.getSize(find.byType(SilicaLevelIndicator)).height, 12);
  });

  testWidgets('rating: click and keyboard set the stars', (tester) async {
    var stars = 2.0;
    final focus = FocusNode();
    await pumpControl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SilicaLevelIndicator(
          value: stars,
          style: LevelIndicatorStyle.rating,
          focusNode: focus,
          semanticLabel: 'Rating',
          onChanged: (v) => setState(() => stars = v),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(SilicaLevelIndicator)),
      const Size(5 * 13 + 4 * 2, 13),
    );
    final rect = tester.getRect(find.byType(SilicaLevelIndicator));
    await tester.tapAt(rect.topLeft + const Offset(4 * 15 + 6, 6));
    await tester.pump();
    expect(stars, 5);
    await tester.tapAt(rect.topLeft + const Offset(6, 6));
    await tester.pump();
    expect(stars, 1);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(stars, 2);
  });

  testWidgets('read-only indicator is not focusable', (tester) async {
    final focus = FocusNode();
    await pumpControl(tester, SilicaLevelIndicator(value: 2, focusNode: focus));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('semantics value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpControl(
      tester,
      const SilicaLevelIndicator(value: 5, max: 10, semanticLabel: 'Disk'),
    );
    expect(
      tester.getSemantics(find.byType(SilicaLevelIndicator)).value,
      '50 %',
    );
    handle.dispose();
  });
}
