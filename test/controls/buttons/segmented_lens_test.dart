import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

const sections = [
  Segment(label: 'World'),
  Segment(label: 'Alarms'),
  Segment(label: 'Stopwatch'),
  Segment(label: 'Timer'),
];

const lensKey = ValueKey('glass lens');
const pillKey = ValueKey('chosen pill');
const trackKey = ValueKey('segmented track');

/// Clock's section switch: large, four 94 pt segments, with the app's selection.
Widget clock({
  required int selected,
  required ValueChanged<int> onChanged,
  bool dark = true,
  bool reduceMotion = false,
  ControlSize size = ControlSize.large,
  bool? lens,
}) => harness(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: SegmentedControl(
        segments: sections,
        selected: {selected},
        size: size,
        segmentWidth: 94,
        lens: lens,
        onChanged: onChanged,
      ),
    ),
  ),
  dark: dark,
);

/// The control with its selection kept in a `StatefulBuilder`; `log` receives every change.
Future<void> pumpClock(
  WidgetTester tester,
  List<int> log, {
  int initial = 0,
  bool dark = true,
  bool reduceMotion = false,
}) async {
  var selected = initial;
  await tester.pumpWidget(
    StatefulBuilder(
      builder: (context, setState) => clock(
        selected: selected,
        dark: dark,
        reduceMotion: reduceMotion,
        onChanged: (i) {
          log.add(i);
          setState(() => selected = i);
        },
      ),
    ),
  );
}

Offset segmentCenter(WidgetTester tester, int i) {
  final track = tester.getTopLeft(find.byKey(trackKey));
  return track + Offset(4 + 94 * i + 47, 18);
}

double pillLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(pillKey)).dx -
    tester.getTopLeft(find.byKey(trackKey)).dx;

void main() {
  group('margins (#89): the chosen pill is inset equally on every side', () {
    for (final (size, inset) in [
      (ControlSize.large, 4.0),
      (ControlSize.regular, 2.0),
    ]) {
      testWidgets('${size.name}: first, middle and last', (tester) async {
        for (var i = 0; i < 4; i++) {
          await tester.pumpWidget(
            clock(selected: i, size: size, onChanged: (_) {}),
          );
          await tester.pumpAndSettle();
          final track = tester.getRect(find.byKey(trackKey));
          final pill = tester.getRect(find.byKey(pillKey));
          expect(pill.top - track.top, inset, reason: 'top of $i');
          expect(track.bottom - pill.bottom, inset, reason: 'bottom of $i');
          if (i == 0) expect(pill.left - track.left, inset);
          if (i == 3) expect(track.right - pill.right, inset);
          // Middle segments: the pill fills the segment, flush with its neighbours.
          expect(pill.left - track.left, inset + 94 * i);
          expect(pill.width, 94);
        }
      });
    }
  });

  group('lens (#88)', () {
    testWidgets('appears on press, swollen and magnifying; goes on release', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log, initial: 1);
      expect(find.byKey(lensKey), findsNothing);
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final lens = tester.getRect(find.byKey(lensKey));
      final pill = tester.getRect(find.byKey(pillKey));
      expect(lens.center.dx, closeTo(pill.center.dx, 0.01));
      expect(lens.width, closeTo(94 * GlassLensMetrics.widthScale, 0.5));
      expect(lens.height, closeTo(28 * GlassLensMetrics.heightScale, 0.5));
      // It rises past the 36 pt track.
      expect(lens.height, greaterThan(36));
      // The labels under the lens are drawn magnified.
      final magnified = find.descendant(
        of: find.byKey(lensKey),
        matching: find.byType(Transform),
      );
      final scale = tester.widget<Transform>(magnified.first).transform;
      expect(
        scale.getMaxScaleOnAxis(),
        closeTo(GlassLensMetrics.magnification, 0.01),
      );
      expect(log, isEmpty);
      await press.up();
      await tester.pump();
      expect(log, [1]);
      await tester.pumpAndSettle();
      expect(find.byKey(lensKey), findsNothing);
      expect(pillLeft(tester), 4 + 94);
    });

    testWidgets('swells with a slight overshoot', (tester) async {
      await pumpClock(tester, []);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      var tallest = 0.0;
      for (var t = 0; t < 30; t++) {
        await tester.pump(const Duration(milliseconds: 16));
        final h = tester.getSize(find.byKey(lensKey)).height;
        if (h > tallest) tallest = h;
      }
      final rest = 28 * GlassLensMetrics.heightScale;
      expect(tallest, greaterThan(rest + 0.1));
      expect(tallest, lessThan(rest * 1.1));
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('travels to the pressed segment on a spring', (tester) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final press = await tester.startGesture(segmentCenter(tester, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byKey(lensKey), findsOneWidget);
      final moving = pillLeft(tester);
      expect(moving, greaterThan(4));
      expect(moving, lessThan(4 + 2 * 94));
      // The spring overshoots a little past the target, then settles on it.
      var furthest = 0.0;
      for (var t = 0; t < 40; t++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (pillLeft(tester) > furthest) furthest = pillLeft(tester);
      }
      expect(furthest, greaterThan(4 + 2 * 94));
      expect(furthest, lessThan(4 + 2 * 94 + 0.1 * 2 * 94));
      await tester.pumpAndSettle();
      expect(pillLeft(tester), closeTo(4 + 2 * 94, 0.05));
      final lens = tester.getRect(find.byKey(lensKey));
      expect(
        lens.center.dx,
        closeTo(tester.getRect(find.byKey(pillKey)).center.dx, 0.01),
      );
      expect(log, isEmpty);
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [2]);
      expect(find.byKey(lensKey), findsNothing);
    });

    testWidgets('dragging jumps segment to segment; release chooses', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      for (final i in [1, 2, 3]) {
        await press.moveTo(segmentCenter(tester, i));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(pillLeft(tester), closeTo(4 + 94.0 * i, 0.05));
        expect(find.byKey(lensKey), findsOneWidget);
      }
      // Within a segment the lens stays put; past the end it holds the last one.
      await press.moveTo(segmentCenter(tester, 3) + const Offset(30, 0));
      await tester.pump();
      expect(pillLeft(tester), closeTo(4 + 94.0 * 3, 0.05));
      await press.moveTo(segmentCenter(tester, 1));
      await tester.pumpAndSettle();
      expect(pillLeft(tester), closeTo(4 + 94.0, 0.05));
      expect(log, isEmpty);
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [1]);
      expect(pillLeft(tester), closeTo(4 + 94.0, 0.05));
      expect(find.byKey(lensKey), findsNothing);
    });

    testWidgets('released outside: no choice, the pill goes back', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      await press.moveTo(segmentCenter(tester, 3));
      await tester.pumpAndSettle();
      await press.moveTo(segmentCenter(tester, 3) + const Offset(0, 80));
      await tester.pump();
      await press.up();
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(pillLeft(tester), closeTo(4, 0.05));
      expect(find.byKey(lensKey), findsNothing);
    });

    testWidgets('the app may refuse the choice: the pill returns', (
      tester,
    ) async {
      final log = <int>[];
      await tester.pumpWidget(clock(selected: 0, onChanged: log.add));
      final press = await tester.startGesture(segmentCenter(tester, 2));
      await tester.pumpAndSettle();
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [2]);
      expect(pillLeft(tester), closeTo(4, 0.05));
    });

    testWidgets('skips disabled segments while dragging', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(
        harness(
          SegmentedControl(
            segments: const [
              Segment(label: 'A'),
              Segment(label: 'B', enabled: false),
              Segment(label: 'C'),
            ],
            selected: const {0},
            size: ControlSize.large,
            segmentWidth: 94,
            onChanged: log.add,
          ),
          dark: true,
        ),
      );
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      await press.moveTo(segmentCenter(tester, 1));
      await tester.pumpAndSettle();
      expect(pillLeft(tester), closeTo(4, 0.05));
      await press.moveTo(segmentCenter(tester, 2));
      await tester.pumpAndSettle();
      expect(pillLeft(tester), closeTo(4 + 2 * 94, 0.05));
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [2]);
    });

    testWidgets('reduced motion: the lens appears, jumps and goes at once', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log, reduceMotion: true);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(lensKey)).height,
        closeTo(28 * GlassLensMetrics.heightScale, 0.01),
      );
      await press.moveTo(segmentCenter(tester, 3));
      await tester.pump();
      expect(pillLeft(tester), 4 + 3 * 94);
      expect(tester.hasRunningAnimations, isFalse);
      await press.up();
      await tester.pump();
      await tester.pump();
      expect(log, [3]);
      expect(find.byKey(lensKey), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('light and dark: the lens grows out of the pill colour', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        await pumpClock(tester, [], dark: dark);
        final press = await tester.startGesture(segmentCenter(tester, 0));
        await tester.pumpAndSettle();
        final painter =
            tester
                    .widget<CustomPaint>(
                      find
                          .descendant(
                            of: find.byKey(lensKey),
                            matching: find.byType(CustomPaint),
                          )
                          .first,
                    )
                    .painter!
                as GlassLensPainter;
        final colors = dark ? SegmentedColors.dark : SegmentedColors.light;
        final style = dark ? GlassLensStyle.dark : GlassLensStyle.light;
        expect(painter.style.fill, colors.pill);
        expect(painter.style.highlight, style.highlight);
        await press.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('off by default below large; on when asked', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(
        clock(selected: 0, size: ControlSize.regular, onChanged: log.add),
      );
      final track = tester.getTopLeft(find.byKey(trackKey));
      final press = await tester.startGesture(track + const Offset(50, 12));
      await tester.pump();
      expect(find.byKey(lensKey), findsNothing);
      await press.up();
      await tester.pumpWidget(
        clock(
          selected: 0,
          size: ControlSize.regular,
          lens: true,
          onChanged: log.add,
        ),
      );
      final again = await tester.startGesture(track + const Offset(50, 12));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(lensKey), findsOneWidget);
      await again.up();
      await tester.pumpAndSettle();
      expect(find.byKey(lensKey), findsNothing);
    });

    testWidgets('no lens in select any and momentary', (tester) async {
      await tester.pumpWidget(
        harness(
          SegmentedControl(
            segments: sections,
            mode: SegmentedMode.selectAny,
            size: ControlSize.large,
            segmentWidth: 94,
            selected: const {0},
            lens: true,
            onChanged: (_) {},
          ),
        ),
      );
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(lensKey), findsNothing);
      await press.up();
    });
  });

  group('GlassLens', () {
    testWidgets('nothing at presence 0; ignores the pointer and semantics', (
      tester,
    ) async {
      Widget lens(double presence) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 40,
            child: GlassLens(
              rect: const Rect.fromLTWH(50, 6, 60, 28),
              presence: presence,
              style: GlassLensStyle.light,
              content: const Text('label'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(lens(0));
      expect(find.byKey(lensKey), findsNothing);
      await tester.pumpWidget(lens(1));
      expect(find.byKey(lensKey), findsOneWidget);
      expect(tester.getSize(find.byKey(lensKey)), const Size(60, 28));
      expect(find.bySemanticsLabel('label'), findsNothing);
      // Without Impeller (the test engine) there is no refraction filter.
      expect(GlassLens.refractionSupported, isFalse);
      expect(find.byKey(const ValueKey('glass lens refraction')), findsNothing);
    });

    testWidgets('the lens shader is bundled and has the expected uniforms', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // A root asset here; `GlassLens.shaderAsset` in the apps that depend on silica_ui.
        final program = await ui.FragmentProgram.fromAsset(
          'shaders/glass_lens.frag',
        );
        final shader = program.fragmentShader()
          ..setFloat(0, 60)
          ..setFloat(1, 28)
          ..setFloat(2, GlassLensMetrics.refractionRim)
          ..setFloat(3, GlassLensMetrics.refractionStrength);
        expect(() => shader.setFloat(4, 0), throwsA(anything));
        shader.dispose();
      });
    });

    test('glassLensRect grows around the pill', () {
      const pill = Rect.fromLTWH(10, 4, 94, 28);
      expect(glassLensRect(pill, 0), pill);
      final full = glassLensRect(pill, 1);
      expect((full.center - pill.center).distance, lessThan(1e-9));
      expect(full.width, closeTo(94 * GlassLensMetrics.widthScale, 1e-9));
      expect(full.height, closeTo(28 * GlassLensMetrics.heightScale, 1e-9));
    });
  });
}
