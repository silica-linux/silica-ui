import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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

  group('lens (LENS, silica-reference #92)', () {
    Rect lensRect(WidgetTester tester) => tester.getRect(find.byKey(lensKey));
    Rect trackRect(WidgetTester tester) => tester.getRect(find.byKey(trackKey));
    Future<void> ms(WidgetTester tester, int t) =>
        tester.pump(Duration(milliseconds: t));

    testWidgets('a 91 x 48 capsule, 6 pt past the track at top and bottom', (
      tester,
    ) async {
      await pumpClock(tester, [], initial: 1);
      expect(find.byKey(lensKey), findsNothing);
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump();
      await ms(tester, 400);
      final lens = lensRect(tester);
      final track = trackRect(tester);
      expect(lens.width, closeTo(91, 0.01));
      expect(lens.height, closeTo(48, 0.01));
      expect(track.top - lens.top, closeTo(6, 0.01));
      expect(lens.bottom - track.bottom, closeTo(6, 0.01));
      expect(
        lens.center.dx,
        closeTo(tester.getRect(find.byKey(pillKey)).center.dx, 0.01),
      );
      // The labels under the lens are magnified 1.11 x.
      final magnified = find.descendant(
        of: find.byKey(lensKey),
        matching: find.byType(Transform),
      );
      final scale = tester.widget<Transform>(magnified.first).transform;
      expect(GlassLensMetrics.magnification, 1.11);
      expect(scale.getMaxScaleOnAxis(), closeTo(1.11, 0.001));
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('look: clear body, dark rim, light lines, fringes, control', (
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
        expect(painter.style, GlassLensStyle.clear, reason: 'same in $dark');
        expect(painter.style.fill.a, 0);
        expect(painter.style.edge.a, greaterThan(0));
        expect(painter.style.highlight.a, greaterThan(0));
        expect(painter.style.fringeWarm.a, greaterThan(0));
        expect(painter.style.fringeCool.a, greaterThan(0));
        final glass = tester.widget<Glass>(find.byType(Glass));
        expect(glass.material, GlassMaterial.regular);
        expect(glass.profile, GlassProfile.control);
        await press.up();
        await tester.pumpAndSettle();
        expect(find.byType(Glass), findsNothing);
      }
    });

    testWidgets('the pill is not drawn under the full lens', (tester) async {
      await pumpClock(tester, []);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      await ms(tester, 60);
      double pillAlpha() =>
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(pillKey),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!
              .a;
      expect(pillAlpha(), greaterThan(0.1));
      await ms(tester, 400);
      expect(pillAlpha(), closeTo(0, 0.01));
      await press.up();
      await tester.pumpAndSettle();
      expect(pillAlpha(), greaterThan(0.1));
    });

    testWidgets('press on the selected segment: +120 ms out, +240 ms full', (
      tester,
    ) async {
      await pumpClock(tester, [], initial: 1);
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump();
      await ms(tester, 100);
      // Not yet past the 36 pt track.
      expect(lensRect(tester).height, lessThan(36));
      await ms(tester, 20); // +120 ms
      expect(lensRect(tester).height, greaterThan(36));
      var tallest = 0.0;
      for (var t = 0; t < 7; t++) {
        await ms(tester, 17);
        tallest = tallest < lensRect(tester).height
            ? lensRect(tester).height
            : tallest;
      }
      // A small overshoot on the way to 48 pt.
      expect(tallest, greaterThan(48.2));
      expect(tallest, lessThan(50.5));
      await tester.pump(const Duration(milliseconds: 240));
      expect(lensRect(tester).height, closeTo(48, 0.01));
      // No slide: the lens stays on its segment.
      expect(pillLeft(tester), 4 + 94);
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('press on another segment: slide at +28 ms, lens on the way, '
        'settled by +400-500 ms', (tester) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final press = await tester.startGesture(segmentCenter(tester, 2));
      await tester.pump();
      await ms(tester, 24);
      expect(pillLeft(tester), 4, reason: 'no movement before +28 ms');
      await ms(tester, 30); // +54
      final early = pillLeft(tester);
      expect(early, greaterThan(4));
      await ms(tester, 66); // +120: already a lens, still travelling
      expect(lensRect(tester).height, greaterThan(36));
      expect(pillLeft(tester), greaterThan(early));
      expect(pillLeft(tester), lessThan(4 + 2 * 94 - 20));
      await ms(tester, 130); // +250: full size, still not there
      expect(lensRect(tester).height, closeTo(48, 0.01));
      expect(pillLeft(tester), lessThan(4 + 2 * 94 - 3));
      await ms(tester, 150); // +400
      expect(pillLeft(tester), closeTo(4 + 2 * 94, 5));
      await ms(tester, 110); // +510
      expect(pillLeft(tester), closeTo(4 + 2 * 94, 0.05));
      // The content changes only after the release.
      expect(log, isEmpty);
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [2]);
    });

    testWidgets('dragging: the lens follows the pointer continuously', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final start = segmentCenter(tester, 0);
      final press = await tester.startGesture(start);
      await tester.pump();
      await ms(tester, 600);
      for (final dx in [7.0, 31.0, 50.0, 93.0, 140.0]) {
        await press.moveTo(start + Offset(dx, 0));
        await tester.pump();
        expect(pillLeft(tester), closeTo(4 + dx, 0.01), reason: 'at $dx');
        expect(find.byKey(lensKey), findsOneWidget);
      }
      expect(log, isEmpty);
      // The lens centre is the pointer: it sits between segments.
      expect(pillLeft(tester) % 94, isNot(closeTo(4, 1)));
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [1]);
    });

    testWidgets('dragging is clamped between the first and last centres', (
      tester,
    ) async {
      await pumpClock(tester, []);
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump();
      await ms(tester, 600);
      await press.moveTo(segmentCenter(tester, 3) + const Offset(60, 0));
      await tester.pump();
      expect(pillLeft(tester), closeTo(4 + 3 * 94, 0.01));
      expect(lensRect(tester).right, lessThan(trackRect(tester).right));
      await press.moveTo(segmentCenter(tester, 0) - const Offset(80, 0));
      await tester.pump();
      expect(pillLeft(tester), closeTo(4, 0.01));
      // 60 pt below the control the lens stays big, at its last x.
      await press.moveTo(segmentCenter(tester, 2) + const Offset(0, 60));
      await tester.pump();
      expect(lensRect(tester).height, closeTo(48, 0.01));
      await press.cancel();
      await tester.pumpAndSettle();
    });

    testWidgets('release inside: the lens retracts in ~130 ms, then it is '
        'chosen', (tester) async {
      final log = <int>[];
      await pumpClock(tester, log, initial: 1);
      final press = await tester.startGesture(segmentCenter(tester, 1));
      await tester.pump();
      await ms(tester, 400);
      await press.up();
      await tester.pump();
      await ms(tester, 60);
      expect(find.byKey(lensKey), findsOneWidget);
      expect(lensRect(tester).height, lessThan(48));
      await ms(tester, 50); // +110
      expect(find.byKey(lensKey), findsOneWidget);
      await ms(tester, 25); // +135
      expect(find.byKey(lensKey), findsNothing);
      expect(find.byType(Glass), findsNothing);
      await tester.pumpAndSettle();
      expect(log, [1]);
    });

    testWidgets('release outside cancels: lens ~100 ms, pill back in ~200 ms', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      await press.moveTo(segmentCenter(tester, 3));
      await ms(tester, 600);
      expect(pillLeft(tester), closeTo(4 + 3 * 94, 0.5));
      await press.moveTo(segmentCenter(tester, 3) + const Offset(0, 80));
      await tester.pump();
      await press.up();
      await tester.pump();
      await ms(tester, 50);
      expect(find.byKey(lensKey), findsOneWidget);
      await ms(tester, 55); // +105
      expect(find.byKey(lensKey), findsNothing);
      expect(pillLeft(tester), inExclusiveRange(4.5, 4 + 3 * 94 - 5));
      await ms(tester, 100); // +205
      expect(pillLeft(tester), closeTo(4, 0.05));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
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

    testWidgets('hover is instant: no fade in or out', (tester) async {
      await pumpClock(tester, [], initial: 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(segmentCenter(tester, 2));
      await tester.pump();
      final hover = find.byKey(const ValueKey('hover 2'));
      expect(hover, findsOneWidget);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: hover,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color!.a, greaterThan(0.5));
      expect(tester.hasRunningAnimations, isFalse);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      expect(hover, findsNothing);
    });

    testWidgets('over a disabled segment the lens passes; release keeps the '
        'last enabled one', (tester) async {
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
      await ms(tester, 600);
      await press.moveTo(segmentCenter(tester, 1));
      await tester.pump();
      expect(pillLeft(tester), closeTo(4 + 94, 0.01));
      await press.up();
      await tester.pumpAndSettle();
      expect(log, [0]);
      final again = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      await ms(tester, 600);
      await again.moveTo(segmentCenter(tester, 2));
      await tester.pump();
      await again.up();
      await tester.pumpAndSettle();
      expect(log, [0, 2]);
    });

    testWidgets('reduced motion: the lens appears, follows and goes at once', (
      tester,
    ) async {
      final log = <int>[];
      await pumpClock(tester, log, reduceMotion: true);
      final press = await tester.startGesture(segmentCenter(tester, 0));
      await tester.pump();
      expect(lensRect(tester).height, closeTo(48, 0.01));
      await press.moveTo(segmentCenter(tester, 3));
      await tester.pump();
      expect(pillLeft(tester), closeTo(4 + 3 * 94, 0.01));
      expect(tester.hasRunningAnimations, isFalse);
      await press.up();
      await tester.pump();
      await tester.pump();
      expect(log, [3]);
      expect(find.byKey(lensKey), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
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
      await tester.pump(const Duration(milliseconds: 300));
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
          ..setFloat(3, GlassLensMetrics.refractionStrength)
          ..setFloat(4, GlassLensMetrics.chromaticOffset);
        expect(() => shader.setFloat(5, 0), throwsA(anything));
        shader.dispose();
      });
    });

    test('glassLensRect grows around the pill to 91 x 48', () {
      const pill = Rect.fromLTWH(10, 4, 94, 28);
      expect(glassLensRect(pill, 0), pill);
      final full = glassLensRect(pill, 1);
      expect((full.center - pill.center).distance, lessThan(1e-9));
      expect(full.width, closeTo(91, 1e-9));
      expect(full.height, closeTo(48, 1e-9));
      final half = glassLensRect(pill, 0.5);
      expect(half.height, closeTo(38, 1e-9));
    });

    test('the measured timing curves', () {
      expect(GlassLensMetrics.appearCurve.transform(0), 0);
      expect(GlassLensMetrics.appearCurve.transform(1), 1);
      expect(GlassLensMetrics.appearCurve.transform(0.67), greaterThan(1));
      expect(GlassLensMetrics.travelDelay.inMilliseconds, 28);
      expect(GlassLensMetrics.retractDuration.inMilliseconds, 130);
      expect(GlassLensMetrics.cancelReturnDuration.inMilliseconds, 200);
    });
  });
}
