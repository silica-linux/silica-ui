import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

T painterOf<T>(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<T>()
    .single;

void main() {
  testWidgets('determinate bar: 309 × 20, accent fill, semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpControl(
      tester,
      const SilicaProgressBar(value: 0.4, semanticLabel: 'Copying'),
    );
    expect(tester.getSize(find.byType(SilicaProgressBar)), const Size(309, 20));
    final p = painterOf<ProgressBarPainter>(tester);
    expect(p.value, 0.4);
    expect(p.thickness, 8);
    expect(p.fill, const Color(0xFF007AFF));
    expect(p.track, const Color(0xFFF0F0F0));
    final node = tester.getSemantics(find.byType(SilicaProgressBar));
    expect(node.label, 'Copying');
    expect(node.value, '40 %');
    handle.dispose();
  });

  testWidgets(
    'small bar 12 tall, 4 pt track; gray fill in an inactive window',
    (tester) async {
      await pumpControl(
        tester,
        const SilicaProgressBar(value: 1, width: 154, size: ProgressSize.small),
        dark: true,
      );
      expect(
        tester.getSize(find.byType(SilicaProgressBar)),
        const Size(154, 12),
      );
      expect(painterOf<ProgressBarPainter>(tester).thickness, 4);
      expect(
        painterOf<ProgressBarPainter>(tester).track,
        InputColors.dark.track,
      );
      await pumpControl(
        tester,
        const SilicaProgressBar(value: 0.5),
        active: false,
      );
      // Gray in an inactive window, as the slider fill (INV-B).
      expect(
        painterOf<ProgressBarPainter>(tester).fill,
        const Color(0xFFC5C5C5),
      );
    },
  );

  testWidgets('indeterminate bar sweeps', (tester) async {
    await pumpControl(tester, const SilicaProgressBar(value: null));
    final first = painterOf<ProgressBarPainter>(tester).phase;
    await tester.pump(const Duration(milliseconds: 300));
    final later = painterOf<ProgressBarPainter>(tester).phase;
    expect(later, isNot(first));
    expect(painterOf<ProgressBarPainter>(tester).value, isNull);
    // Becoming determinate stops the sweep.
    await pumpControl(tester, const SilicaProgressBar(value: 0.2));
    await tester.pumpAndSettle();
  });

  testWidgets('spinner turns, stops when not animating', (tester) async {
    await pumpControl(tester, const SilicaSpinner(size: 16));
    expect(tester.getSize(find.byType(SilicaSpinner)), const Size(16, 16));
    final first = painterOf<SpinnerPainter>(tester).phase;
    await tester.pump(const Duration(milliseconds: 250));
    expect(painterOf<SpinnerPainter>(tester).phase, isNot(first));
    await pumpControl(tester, const SilicaSpinner(animating: false));
    await tester.pumpAndSettle();
    // Eight spokes (CT-PR-03): the phase runs over 0–7.
    expect(SilicaSpinner.spokes, 8);
    expect(painterOf<SpinnerPainter>(tester).phase, lessThan(8));
  });

  testWidgets('ring: measured timer colors, value', (tester) async {
    await pumpControl(
      tester,
      const SilicaProgressRing(value: 0.25, diameter: 100),
    );
    final p = painterOf<ProgressRingPainter>(tester);
    expect(p.value, 0.25);
    expect(p.stroke, 6);
    expect(p.color, const Color(0xFFFF9230));
    expect(p.track, const Color(0xFF3B3B3D));
  });
}
