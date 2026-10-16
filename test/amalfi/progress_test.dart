// Progress indicators against the kit (`Progress/*`). Checklist:
// docs/amalfi-checklist/progress.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/components/sliders/arc.dart';

import 'support/harness.dart';

const sizes = {
  'Small': AmalfiProgressSize.small,
  'Regular': AmalfiProgressSize.regular,
  'Large': AmalfiProgressSize.large,
};

/// The phase of the kit's indeterminate masters: the segment at x 0, 64 and 132.
double phaseAt(double x) =>
    (x + AmalfiProgressBarMetrics.segment) /
    (AmalfiProgressBarMetrics.length + AmalfiProgressBarMetrics.segment);

const phases = {'Phase 1': 0.0, 'Phase 2': 64.0, 'Phase 3': 132.0};

/// Thin round strokes: Sketch antialiases arcs and spokes a little differently.
const KitPixelTolerance roundTolerance = KitPixelTolerance(mean: 2.5, max: 96);

/// Where the master's origin is in its PNG: the kit exports some masters at their frame (a
/// ring's outer half-stroke and rotated spokes are not added), others at their render bounds
/// grown to whole points; the harness's bounds are not rounded.
Offset? pngOrigin(KitMaster master) {
  final bytes = master.png.readAsBytesSync();
  final width = ByteData.sublistView(bytes, 16, 20).getUint32(0);
  final height = ByteData.sublistView(bytes, 20, 24).getUint32(0);
  if (Size(width / 2, height / 2) == master.size) return Offset.zero;
  // Otherwise Sketch grows the render bounds out to whole points.
  final b = master.renderBounds;
  return -Offset(b.left.floorToDouble(), b.top.floorToDouble());
}

/// The bars' round ends: Sketch antialiases them differently (up to 81 on single pixels).
const KitPixelTolerance barTolerance = KitPixelTolerance(mean: 1, max: 96);

/// The quarters of [ring] (stroke [stroke]) an arc from the top over [sweep] of a turn
/// passes through, with its round ends.
List<Rect> arcMask(Rect ring, double stroke, double sweep) {
  final c = ring.center;
  final quarters = [
    Rect.fromLTRB(c.dx, ring.top, ring.right, c.dy),
    Rect.fromLTRB(c.dx, c.dy, ring.right, ring.bottom),
    Rect.fromLTRB(ring.left, c.dy, c.dx, ring.bottom),
    Rect.fromLTRB(ring.left, ring.top, c.dx, c.dy),
  ];
  return [
    for (var i = 0; i < 4 && i < (sweep * 4).ceil(); i++)
      quarters[i].inflate(stroke),
  ];
}

Finder decoratedIn(Finder of, int index) =>
    find.descendant(of: of, matching: find.byType(DecoratedBox)).at(index);

void main() {
  setUpAll(loadAmalfiFonts);
  RenderedStyle.register((widget, context) {
    if (widget is! CustomPaint) return null;
    final p = widget.painter;
    if (p is! AmalfiArcPainter) return null;
    return RenderedStyle(
      borders: [RenderedBorder(p.color, p.width, BorderSide.strokeAlignCenter)],
      source: 'AmalfiArcPainter',
    );
  });

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
        for (final state in ['25', '60', '100', 'Disabled']) {
          testWidgets('Bar Determinate $sizeName $state', (tester) async {
            final master = KitMaster.load(
              'Progress/Bar/Determinate/$sizeName/$state/$appearance',
            );
            final scene = SizedBox(
              width: 200,
              child: AmalfiProgressBar(
                value: state == 'Disabled' ? 0.6 : int.parse(state) / 100,
                size: size,
                enabled: state != 'Disabled',
              ),
            );
            final root = await pumpKitScene(tester, scene, master: master);
            final bar = find.byType(AmalfiProgressBar);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Track': decoratedIn(bar, 0),
                'Fill': decoratedIn(bar, 1),
              },
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              origin: pngOrigin(master),
              tolerance: barTolerance,
            );
          });

          testWidgets('Circular $sizeName $state', (tester) async {
            final master = KitMaster.load(
              'Progress/Circular/Determinate/$sizeName/$state/$appearance',
            );
            final scene = AmalfiCircularProgress(
              value: state == 'Disabled' ? 0.6 : int.parse(state) / 100,
              size: size,
              enabled: state != 'Disabled',
            );
            final root = await pumpKitScene(tester, scene, master: master);
            final arcs = find.descendant(
              of: find.byType(AmalfiCircularProgress),
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is AmalfiArcPainter,
              ),
            );
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {'Track': arcs.at(0), 'Progress': arcs.at(1)},
              deviations: {
                if (state != '100')
                  'Progress':
                      'the kit frames the arc by its bounds; ours is the ring',
              },
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              origin: pngOrigin(master),
              tolerance: roundTolerance,
              // Kit defect: a partial arc is a hand-drawn path, not concentric with the
              // ring (up to 2 pt off on the right): compared by geometry, the ring by pixels.
              maskLayers: [if (state != '100') 'Progress'],
              mask: state == '100'
                  ? const []
                  : arcMask(
                      AmalfiCircularProgressMetrics.ringOf(size),
                      AmalfiCircularProgressMetrics.strokeOf(size),
                      state == '25' ? 0.25 : 0.6,
                    ),
            );
          });
        }

        for (final state in ['Phase 1', 'Phase 2', 'Phase 3', 'Disabled']) {
          testWidgets('Bar Indeterminate $sizeName $state', (tester) async {
            final master = KitMaster.load(
              'Progress/Bar/Indeterminate/$sizeName/$state/$appearance',
            );
            final x = phases[state];
            final scene = SizedBox(
              width: 200,
              child: AmalfiProgressBar(
                size: size,
                enabled: state != 'Disabled',
                phase: x == null ? null : phaseAt(x),
              ),
            );
            final root = await pumpKitScene(tester, scene, master: master);
            final bar = find.byType(AmalfiProgressBar);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Track': decoratedIn(bar, 0),
                'Segment': decoratedIn(bar, 1),
              },
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              origin: pngOrigin(master),
              tolerance: barTolerance,
            );
          });
        }

        for (final state in ['Rest', 'Disabled']) {
          testWidgets('Spinner $sizeName $state', (tester) async {
            final master = KitMaster.load(
              'Progress/Spinner/$sizeName/$state/$appearance',
            );
            final scene = AmalfiSpinner(
              size: size,
              enabled: state != 'Disabled',
            );
            final root = await pumpKitScene(tester, scene, master: master);
            expectKitGeometry(tester, master, root: root);
            expect(
              AmalfiSpinnerMetrics.spokeOf(size).size,
              master.layer('Spoke 1/Tick').frame.size,
            );
            // Kit defect: the small spinner's spokes are 1.5 wide at x 8, 0.75 pt off the
            // centre, so the kit's wheel is lopsided; ours is centred. No pixel test.
            if (size == AmalfiProgressSize.small) return;
            await expectKitPixels(
              tester,
              master,
              scene,
              origin: pngOrigin(master),
              tolerance: roundTolerance,
            );
          });
        }
      }
    });
  }

  group('behaviour', () {
    testWidgets('the segment sweeps and stops when disabled or hidden', (
      tester,
    ) async {
      double? left() {
        final boxes = find.descendant(
          of: find.byType(AmalfiProgressBar),
          matching: find.byType(DecoratedBox),
        );
        return boxes.evaluate().length < 2
            ? null
            : tester.getTopLeft(boxes.at(1)).dx;
      }

      // The scene's Overlay keeps its first entry: switch inside it.
      final setting = ValueNotifier((enabled: true, ticking: true));
      addTearDown(setting.dispose);
      await pumpKitScene(
        tester,
        ValueListenableBuilder(
          valueListenable: setting,
          builder: (context, s, _) => TickerMode(
            enabled: s.ticking,
            child: SizedBox(
              width: 200,
              child: AmalfiProgressBar(enabled: s.enabled),
            ),
          ),
        ),
      );
      final seen = <double?>{};
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        seen.add(left());
      }
      expect(seen.length, greaterThan(5));
      setting.value = (enabled: false, ticking: true);
      await tester.pump();
      expect(left(), 64);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      setting.value = (enabled: true, ticking: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.binding.hasScheduledFrame, isFalse);
      setting.value = (enabled: true, ticking: true);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('the spinner steps clockwise and stops when disabled', (
      tester,
    ) async {
      int head() => tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(AmalfiSpinner),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter
          .let((p) => (p! as AmalfiSpinnerPainter).head);
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      await pumpKitScene(
        tester,
        ValueListenableBuilder(
          valueListenable: enabled,
          builder: (context, on, _) => AmalfiSpinner(enabled: on),
        ),
      );
      expect(head(), 0);
      await tester.pump(AmalfiSpinnerMetrics.turn ~/ 12 * 2.5);
      expect(head(), 2);
      enabled.value = false;
      await tester.pump();
      expect(head(), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('values: fill on the grid, complete, odd values', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 200, child: AmalfiProgressBar(value: double.nan)),
            SizedBox(width: 3, child: AmalfiProgressBar(value: 2)),
            AmalfiCircularProgress(value: double.infinity),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        const SizedBox(
          width: 200,
          child: AmalfiProgressBar(value: 0.25, semanticLabel: 'Copying'),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Copying')),
        matchesSemantics(
          label: 'Copying',
          value: '25%',
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      semantics.dispose();
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
