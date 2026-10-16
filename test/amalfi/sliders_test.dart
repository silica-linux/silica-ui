// Sliders against the kit (`Sliders/*`). Checklist: docs/amalfi-checklist/sliders.md.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/components/sliders/arc.dart';

import 'support/harness.dart';

/// Kit defect: the raised controls cast `#00000024` / `#00000052` (`Shadow/Soft`) with the
/// level 1 offset and blur; the tokens give level 1 (`#1A000000` / `#33000000`), which
/// `tokens.json` names for the slider thumb.
const String softShadow =
    'kit thumb shadow uses the Shadow/Soft colour, tokens level 1';

/// The kit draws the lens's refraction as a "Glass" blur, which the harness does not read;
/// AmalfiGlass draws Clear's 2 pt blur as a background blur.
const String lensBlur =
    'kit lens blur is a Glass blur, drawn as a 2 pt backdrop blur';

/// The kit snaps the tick marks to the 4 pt grid, up to 2 pt off the thumb's stops; the
/// ticks sit under the stops, on whole points.
const String tickGrid =
    'kit ticks on the 4 pt grid, ours under the thumb stops';

/// A 20 pt disc is mostly edge: Sketch antialiases the circle's outline differently (up to
/// 69 on single edge pixels), which lifts the mean over the default.
const KitPixelTolerance roundTolerance = KitPixelTolerance(mean: 1.5, max: 72);

Finder decoratedIn(Finder of, int index) =>
    find.descendant(of: of, matching: find.byType(DecoratedBox)).at(index);

/// A slider whose value follows its changes.
class Live extends StatefulWidget {
  const Live({super.key, required this.build, this.initial = 0.6});

  final double initial;
  final Widget Function(double value, ValueChanged<double> onChanged) build;

  @override
  State<Live> createState() => _LiveState();
}

class _LiveState extends State<Live> {
  late double value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.build(value, (v) => setState(() => value = v));
}

/// A mouse that stays for the test and is reset before each use.
class Mouse {
  TestGesture? _gesture;
  bool _down = false;

  Future<TestGesture> _get(WidgetTester tester) async {
    var g = _gesture;
    if (g == null) {
      g = _gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: const Offset(1, 1));
      addTearDown(release);
    }
    return g;
  }

  Future<void> release() async {
    final g = _gesture;
    if (g == null) return;
    if (_down) await g.up();
    _down = false;
    await g.removePointer();
    _gesture = null;
  }

  Future<void> hover(WidgetTester tester, Offset at) async {
    final g = await _get(tester);
    await g.moveTo(at);
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, Offset at) async {
    final g = await _get(tester);
    await g.moveTo(at);
    await g.down(at);
    _down = true;
    await tester.pump();
  }

  /// Presses at [at], drags past the slop and back, and lets the lens grow in.
  Future<void> drag(WidgetTester tester, Offset at) async {
    await press(tester, at);
    final g = _gesture!;
    await g.moveBy(const Offset(12, 0));
    await tester.pump();
    await g.moveBy(const Offset(-12, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Brings the slider found by [target] into [state] with real input.
Future<void> bringTo(
  WidgetTester tester,
  Mouse mouse,
  String state,
  Finder target,
) async {
  await mouse.release();
  switch (state) {
    case 'Hover':
      await mouse.hover(tester, tester.getCenter(target));
    case 'Pressed':
      await mouse.press(tester, tester.getCenter(target));
    case 'Dragging':
      await mouse.drag(tester, tester.getCenter(target));
    case 'Focused':
      await focusWithKeyboard(tester, target);
  }
}

/// Focuses the control around [target] as the keyboard would (the halo shows).
Future<void> focusWithKeyboard(WidgetTester tester, Finder target) async {
  final manager = FocusManager.instance;
  final before = manager.highlightStrategy;
  manager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => manager.highlightStrategy = before);
  Focus.of(tester.element(target)).requestFocus();
  await tester.pump();
  await tester.pump();
  expect(
    tester.widget<AmalfiSliderThumb>(target).states,
    contains(WidgetState.focused),
  );
}

/// The sliders: a 20 pt thumb is mostly edge, and Sketch antialiases the circle's outline
/// and the track's ends differently (up to 76 on single edge pixels).
const KitPixelTolerance sliderTolerance = KitPixelTolerance(mean: 1.5, max: 80);

/// The lens: Sketch draws Clear's refraction (distortion, chromatic aberration, specular
/// highlight), which AmalfiGlass does not.
const KitPixelTolerance lensTolerance = KitPixelTolerance(mean: 10, max: 212);

/// The dial: the kit's value arc is a hand-drawn path that is not concentric with the ring
/// (up to 2 pt wider on the right), so the arc's outer edge differs.
const KitPixelTolerance dialTolerance = KitPixelTolerance(mean: 14, max: 255);

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

  const states = ['Rest', 'Hover', 'Pressed', 'Focused', 'Disabled'];

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      group('thumb', () {
        for (final (state, set) in [
          ('Rest', <WidgetState>{}),
          ('Hover', {WidgetState.hovered}),
          ('Pressed', {WidgetState.pressed}),
          ('Focused', {WidgetState.focused}),
          ('Disabled', {WidgetState.disabled}),
        ]) {
          testWidgets('Round $state', (tester) async {
            final master = KitMaster.load(
              'Sliders/Thumb/Round/$state/$appearance',
            );
            final thumb = AmalfiSliderThumb(states: set);
            final root = await pumpKitScene(tester, thumb, master: master);
            final thumbs = find.byType(AmalfiSliderThumb);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Thumb': decoratedIn(thumbs, 0),
                if (state == 'Hover') 'State': decoratedIn(thumbs, 1),
                if (state == 'Focused') 'Focus Halo': decoratedIn(thumbs, 1),
              },
              deviations: {
                if (state != 'Disabled') 'Thumb#shadows': softShadow,
              },
            );
            await expectKitPixels(
              tester,
              master,
              thumb,
              tolerance: roundTolerance,
            );
          });
        }

        testWidgets('Lens Dragging', (tester) async {
          final master = KitMaster.load(
            'Sliders/Thumb/Lens/Dragging/$appearance',
          );
          const lens = SizedBox(
            width: 36,
            height: 28,
            child: AmalfiSliderLens(),
          );
          final root = await pumpKitScene(tester, lens, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Lens': find.byType(AmalfiGlass),
              'Core': decoratedIn(find.byType(AmalfiSliderThumb), 0),
            },
            deviations: {'Lens#blurs': lensBlur},
          );
          await expectKitPixels(tester, master, lens, tolerance: lensTolerance);
        });
      });

      for (final variant in ['Plain', 'Ticks', 'Glyphs']) {
        for (final state in states) {
          testWidgets('Horizontal $variant $state', (tester) async {
            final master = KitMaster.load(
              'Sliders/Horizontal/$variant/$state/$appearance',
            );
            final enabled = state != 'Disabled';
            Widget slider(double v, ValueChanged<double> onChanged) =>
                AmalfiSlider(
                  value: v,
                  onChanged: enabled ? onChanged : null,
                  divisions: variant == 'Ticks' ? 10 : null,
                  tickMarks: variant == 'Ticks',
                  minimumGlyph: variant == 'Glyphs'
                      ? const SizedBox.expand(key: ValueKey('min'))
                      : null,
                  maximumGlyph: variant == 'Glyphs'
                      ? const SizedBox.expand(key: ValueKey('max'))
                      : null,
                );
            final scene = SizedBox(
              width: master.size.width,
              child: Live(build: slider),
            );
            final mouse = Mouse();
            final root = await pumpKitScene(tester, scene, master: master);
            final thumb = find.byType(AmalfiSliderThumb);
            await bringTo(tester, mouse, state, thumb);
            final sliders = find.byType(AmalfiSlider);
            final face = find.descendant(
              of: sliders,
              matching: find.byType(GestureDetector),
            );
            if (variant == 'Glyphs') {
              final glyphColor = master.layer('Minimum glyph').icon?.color;
              expectKitGeometry(
                tester,
                master,
                root: root,
                layers: {
                  'Slider': face,
                  'Minimum glyph': find.byKey(const ValueKey('min')),
                  'Maximum glyph': find.byKey(const ValueKey('max')),
                },
              );
              for (final key in ['min', 'max']) {
                expect(
                  IconTheme.of(tester.element(find.byKey(ValueKey(key)))).color,
                  glyphColor,
                );
              }
            } else {
              final ticks = variant == 'Ticks';
              expectKitGeometry(
                tester,
                master,
                root: root,
                layers: {
                  'Track': decoratedIn(sliders, 0),
                  'Fill': decoratedIn(sliders, 1),
                  'Thumb': thumb,
                  if (ticks)
                    for (var i = 0; i <= 10; i++)
                      'Tick $i': find
                          .descendant(
                            of: sliders,
                            matching: find.byType(ColoredBox),
                          )
                          .at(i),
                },
                deviations: {
                  if (ticks)
                    for (final i in [0, 2, 4, 6, 8, 10]) 'Tick $i': tickGrid,
                },
              );
            }
            await mouse.release();
            await expectKitPixels(
              tester,
              master,
              scene,
              tolerance: sliderTolerance,
              // The ticks are compared by geometry (some sit 2 pt off the kit's).
              mask: [
                if (variant == 'Ticks') const Rect.fromLTWH(0, 20, 200, 8),
              ],
              maskLayers: [
                if (variant == 'Glyphs') ...['Minimum glyph', 'Maximum glyph'],
              ],
              prepare: (tester) =>
                  bringTo(tester, mouse, state, find.byType(AmalfiSliderThumb)),
            );
            await mouse.release();
          });
        }
      }

      testWidgets('Horizontal Dragging', (tester) async {
        final master = KitMaster.load(
          'Sliders/Horizontal/Dragging/Pressed/$appearance',
        );
        final scene = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: 200,
            child: Live(
              build: (v, onChanged) =>
                  AmalfiSlider(value: v, onChanged: onChanged),
            ),
          ),
        );
        final mouse = Mouse();
        final root = await pumpKitScene(tester, scene, master: master);
        await bringTo(
          tester,
          mouse,
          'Dragging',
          find.byType(AmalfiSliderThumb),
        );
        final sliders = find.byType(AmalfiSlider);
        expect(find.byType(AmalfiSliderThumb), findsOneWidget);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Track': decoratedIn(sliders, 0),
            'Fill': decoratedIn(sliders, 1),
            'Lens thumb': find.byType(AmalfiSliderLens),
          },
          deviations: {
            // Hidden under the core: the kit ends the fill at 116 here, at 120 at rest.
            'Fill': 'kit fill ends 4 pt short of the value while dragging',
          },
        );
        await mouse.release();
        await expectKitPixels(
          tester,
          master,
          scene,
          tolerance: lensTolerance,
          prepare: (tester) => bringTo(
            tester,
            mouse,
            'Dragging',
            find.byType(AmalfiSliderThumb),
          ),
        );
        await mouse.release();
      });

      for (final state in states) {
        testWidgets('Vertical $state', (tester) async {
          final master = KitMaster.load(
            'Sliders/Vertical/Plain/$state/$appearance',
          );
          final enabled = state != 'Disabled';
          final scene = SizedBox(
            height: 160,
            child: Live(
              build: (v, onChanged) => AmalfiSlider(
                value: v,
                onChanged: enabled ? onChanged : null,
                axis: Axis.vertical,
              ),
            ),
          );
          final mouse = Mouse();
          final root = await pumpKitScene(tester, scene, master: master);
          await bringTo(tester, mouse, state, find.byType(AmalfiSliderThumb));
          final sliders = find.byType(AmalfiSlider);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Track': decoratedIn(sliders, 0),
              'Fill': decoratedIn(sliders, 1),
              'Thumb': find.byType(AmalfiSliderThumb),
            },
            deviations: {
              // Hidden under the thumb.
              'Fill': 'kit fill 92 tall for 60 % of 160; ours 96',
            },
          );
          await mouse.release();
          await expectKitPixels(
            tester,
            master,
            scene,
            tolerance: sliderTolerance,
            prepare: (tester) =>
                bringTo(tester, mouse, state, find.byType(AmalfiSliderThumb)),
          );
          await mouse.release();
        });

        testWidgets('Circular $state', (tester) async {
          final master = KitMaster.load(
            'Sliders/Circular/Dial/$state/$appearance',
          );
          final enabled = state != 'Disabled';
          final scene = Live(
            initial: 0.625,
            build: (v, onChanged) => AmalfiCircularSlider(
              value: v,
              onChanged: enabled ? onChanged : null,
            ),
          );
          final mouse = Mouse();
          final root = await pumpKitScene(tester, scene, master: master);
          await bringTo(tester, mouse, state, find.byType(AmalfiSliderThumb));
          final paints = find.descendant(
            of: find.byType(AmalfiCircularSlider),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is AmalfiArcPainter,
            ),
          );
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Track': paints.at(0),
              'Progress': paints.at(1),
              'Thumb': find.byType(AmalfiSliderThumb),
            },
            deviations: {
              'Progress':
                  'the kit frames the arc by its bounds; ours is the ring',
            },
          );
          await mouse.release();
          await expectKitPixels(
            tester,
            master,
            scene,
            tolerance: dialTolerance,
            origin: Offset.zero,
            prepare: (tester) =>
                bringTo(tester, mouse, state, find.byType(AmalfiSliderThumb)),
          );
          await mouse.release();
        });
      }
    });
  }

  group('behaviour', () {
    Future<List<double>> pump(
      WidgetTester tester,
      Widget Function(double v, ValueChanged<double> c) build, {
      double initial = 0.6,
    }) async {
      final changes = <double>[];
      await pumpKitScene(
        tester,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 160),
          child: Live(
            initial: initial,
            build: (v, c) => build(v, (x) {
              changes.add(x);
              c(x);
            }),
          ),
        ),
      );
      return changes;
    }

    testWidgets('a click on the track moves the thumb there, a drag follows', (
      tester,
    ) async {
      final changes = await pump(
        tester,
        (v, c) => AmalfiSlider(value: v, onChanged: c),
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(changes.last, 0);
      await tester.dragFrom(const Offset(10, 10), const Offset(90, 0));
      await tester.pumpAndSettle();
      expect(changes.last, closeTo(0.5, 1e-9));
      expect(tester.getTopLeft(find.byType(AmalfiSliderThumb)).dx, 90);
    });

    testWidgets('the lens grows while dragging and fades on release', (
      tester,
    ) async {
      await pump(tester, (v, c) => AmalfiSlider(value: v, onChanged: c));
      final g = await tester.startGesture(const Offset(118, 10));
      await g.moveBy(const Offset(20, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AmalfiSliderLens), findsOneWidget);
      expect(tester.getSize(find.byType(AmalfiSliderLens)), const Size(36, 28));
      await g.up();
      await tester.pump();
      expect(find.byType(AmalfiSliderLens), findsOneWidget);
      await tester.pump(AmalfiFades.quick.duration * 2);
      expect(find.byType(AmalfiSliderLens), findsNothing);
    });

    testWidgets('divisions snap; keys step, Home and End jump', (tester) async {
      final changes = await pump(
        tester,
        (v, c) => AmalfiSlider(value: v, onChanged: c, divisions: 10),
      );
      await tester.tapAt(const Offset(40, 10));
      await tester.pump();
      expect(changes.last, closeTo(0.2, 1e-9));
      await focusWithKeyboard(tester, find.byType(AmalfiSliderThumb));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes.last, closeTo(0.3, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(changes.last, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(changes.last, 0);
    });

    testWidgets('vertical: the minimum is at the bottom; up increases', (
      tester,
    ) async {
      final changes = await pump(
        tester,
        (v, c) => AmalfiSlider(value: v, onChanged: c, axis: Axis.vertical),
      );
      await tester.tapAt(const Offset(10, 150));
      await tester.pump();
      expect(changes.last, 0);
      await focusWithKeyboard(tester, find.byType(AmalfiSliderThumb));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(changes.last, closeTo(0.05, 1e-9));
    });

    testWidgets('right to left runs from the right', (tester) async {
      final changes = <double>[];
      await pumpKitScene(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 200,
            child: AmalfiSlider(value: 0.25, onChanged: changes.add),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(AmalfiSliderThumb)).dx, 135);
      await tester.tapAt(const Offset(190, 10));
      expect(changes.last, 0);
    });

    testWidgets('the dial follows the angle and does not wrap', (tester) async {
      final changes = await pump(
        tester,
        initial: 0.9,
        (v, c) => AmalfiCircularSlider(value: v, onChanged: c),
      );
      // Right of the centre: a quarter turn.
      await tester.tapAt(const Offset(54, 28));
      await tester.pump();
      expect(changes.last, closeTo(0.25, 1e-9));
      // From near the end, crossing the top keeps the end.
      await tester.tapAt(const Offset(4, 28));
      await tester.pump();
      expect(changes.last, closeTo(0.75, 1e-9));
      final g = await tester.startGesture(
        tester.getCenter(find.byType(AmalfiSliderThumb)),
      );
      for (final p in const [Offset(14, 10), Offset(28, 2), Offset(42, 10)]) {
        await g.moveTo(p);
        await tester.pump();
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(changes.last, 1);
    });

    testWidgets('disabled ignores input; semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        const AmalfiSlider(
          value: 0.6,
          onChanged: null,
          semanticLabel: 'Volume',
        ),
      );
      await tester.tapAt(const Offset(10, 10));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Volume')),
        matchesSemantics(
          label: 'Volume',
          value: '60%',
          isSlider: true,
          hasEnabledState: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('odd constraints do not crash', (tester) async {
      await pumpKitScene(
        tester,
        const SizedBox(
          width: 4,
          height: 4,
          child: AmalfiSlider(value: double.nan, onChanged: null),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
