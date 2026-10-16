// Steppers against the kit (`Steppers/*`). Checklist: docs/amalfi-checklist/steppers.md.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/components/steppers/chevron.dart';

import 'support/harness.dart';

/// The kit rounds the hover and press overlay of a half on all four corners, leaving notches
/// at the divider; ours fills the half, clipped to the bezel.
const String halfCorners = 'kit overlay rounded at the divider; ours clipped';

/// Kit inconsistency: at rest the chevrons are centred on the true halves (or, in mini,
/// shrunk to 8 pt when the down half is hovered); hovered and pressed, on the halves split by
/// the divider. Ours always sits in its half between the edge and the divider.
const String glyphHalf = 'kit chevron off its half (true half / 8 pt in mini)';

/// Small bezels: Sketch's smoothing of radii 7–10 on 16–28 pt shapes (and of the halo
/// outside them) differs from AmalfiSmoothBorder's on the edge pixels.
const KitPixelTolerance stepperTolerance = KitPixelTolerance(
  mean: 2.5,
  max: 96,
);

/// The 16 × 20 mini bezel is mostly corner: the smoothing difference weighs more.
const KitPixelTolerance miniTolerance = KitPixelTolerance(mean: 4, max: 96);

/// Kit defect: the hover and press overlay of a half spills over the bezel's rim and rounded
/// corners (it is drawn rounded on its own); ours stays inside the bezel.
const KitPixelTolerance overlayTolerance = KitPixelTolerance(mean: 8, max: 255);

/// Where the master's origin is in its PNG: the kit exports some masters at their frame,
/// clipping what overflows it (a mini chevron 1 pt above the bezel), so the harness's
/// render bounds would shift them.
Offset? pngOrigin(KitMaster master) {
  final bytes = master.png.readAsBytesSync();
  final width = ByteData.sublistView(bytes, 16, 20).getUint32(0);
  final height = ByteData.sublistView(bytes, 20, 24).getUint32(0);
  return Size(width / 2, height / 2) == master.size ? Offset.zero : null;
}

/// Where a chevron's stroke lies in its 12 pt box [r].
Rect chevronStroke(Rect r) => Rect.fromLTWH(r.left + 1, r.top + 2.5, 10, 7);

const sizes = {
  'Mini': AmalfiControlSize.mini,
  'Small': AmalfiControlSize.small,
  'Regular': AmalfiControlSize.regular,
  'Large': AmalfiControlSize.large,
};

const states = [
  'Rest',
  'Hover Up',
  'Hover Down',
  'Pressed Up',
  'Pressed Down',
  'Focused',
  'Disabled',
];

/// A stepper whose value follows its changes.
class Live extends StatefulWidget {
  const Live({super.key, required this.build});

  final Widget Function(double value, ValueChanged<double> onChanged) build;

  @override
  State<Live> createState() => _LiveState();
}

class _LiveState extends State<Live> {
  double value = 12;

  @override
  Widget build(BuildContext context) =>
      widget.build(value, (v) => setState(() => value = v));
}

/// A mouse that stays for the test.
class Mouse {
  TestGesture? _g;
  bool _down = false;

  Future<TestGesture> _get(WidgetTester tester) async {
    var g = _g;
    if (g == null) {
      g = _g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: const Offset(400, 400));
      addTearDown(release);
    }
    return g;
  }

  Future<void> release() async {
    final g = _g;
    if (g == null) return;
    if (_down) await g.up();
    _down = false;
    await g.removePointer();
    _g = null;
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
}

Future<void> focusWithKeyboard(WidgetTester tester, FocusNode node) async {
  final manager = FocusManager.instance;
  final before = manager.highlightStrategy;
  manager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => manager.highlightStrategy = before);
  node.requestFocus();
  await tester.pump();
  await tester.pump();
}

/// Brings the stepper found by [target] into [state] with real input.
Future<void> bringTo(
  WidgetTester tester,
  Mouse mouse,
  String state,
  Finder target,
) async {
  await mouse.release();
  final r = tester.getRect(target);
  final up = Offset(r.center.dx, r.top + 3);
  final down = Offset(r.center.dx, r.bottom - 3);
  switch (state) {
    case 'Hover Up':
      await mouse.hover(tester, up);
    case 'Hover Down':
      await mouse.hover(tester, down);
    case 'Pressed Up':
      await mouse.press(tester, up);
    case 'Pressed Down':
      await mouse.press(tester, down);
    case 'Focused':
      await focusWithKeyboard(tester, Focus.of(tester.element(target)));
  }
}

Finder within(Finder of, Type type) =>
    find.descendant(of: of, matching: find.byType(type));

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
        for (final state in states) {
          testWidgets('Stepper $sizeName $state', (tester) async {
            final master = KitMaster.load(
              'Steppers/Stepper/$sizeName/$state/$appearance',
            );
            final enabled = state != 'Disabled';
            final scene = Live(
              build: (v, c) => AmalfiStepper(
                value: v,
                onChanged: enabled ? c : null,
                size: size,
              ),
            );
            final mouse = Mouse();
            final root = await pumpKitScene(tester, scene, master: master);
            final stepper = find.byType(AmalfiStepper);
            final face = find
                .descendant(of: stepper, matching: find.byType(Listener))
                .first;
            await bringTo(tester, mouse, state, face);
            final colored = within(stepper, ColoredBox);
            final hasState = master.maybeLayer('State') != null;
            final chevrons = find.descendant(
              of: stepper,
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is AmalfiChevronPainter,
              ),
            );
            Rect mine(int i) =>
                tester.getRect(chevrons.at(i)).shift(-tester.getTopLeft(root));
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Background': within(stepper, DecoratedBox).first,
                if (hasState) 'State': colored.at(0),
                'Divider': colored.at(hasState ? 1 : 0),
                if (state == 'Focused')
                  'Focus Halo': find.byType(AmalfiSliderFocusHalo),
                'Glyph Chevron Up': chevrons.at(0),
                'Glyph Chevron Down': chevrons.at(1),
              },
              deviations: {
                if (hasState) 'State#corners': halfCorners,
                for (final (i, name) in [
                  (0, 'Glyph Chevron Up'),
                  (1, 'Glyph Chevron Down'),
                ])
                  if (master.layer(name).rectInMaster != mine(i))
                    name: glyphHalf,
              },
            );
            await mouse.release();
            await expectKitPixels(
              tester,
              master,
              scene,
              origin: pngOrigin(master),
              tolerance:
                  state.startsWith('Hover') || state.startsWith('Pressed')
                  ? overlayTolerance
                  : size == AmalfiControlSize.mini
                  ? miniTolerance
                  : stepperTolerance,
              // The kit's chevrons carry the 24 pt stroke (1.5) at 12 pt; ours the 12 pt
              // stroke (0.75, README "How to read the kit"): compared by geometry.
              mask: [
                for (final (i, name) in [
                  (0, 'Glyph Chevron Up'),
                  (1, 'Glyph Chevron Down'),
                ])
                  for (final r in [master.layer(name).rectInMaster, mine(i)])
                    chevronStroke(r),
              ],
              prepare: (tester) => bringTo(
                tester,
                mouse,
                state,
                find
                    .descendant(
                      of: find.byType(AmalfiStepper),
                      matching: find.byType(Listener),
                    )
                    .first,
              ),
            );
            await mouse.release();
          });
        }
      }

      for (final state in ['Rest', 'Focused', 'Disabled']) {
        testWidgets('Value Field $state', (tester) async {
          final master = KitMaster.load(
            'Steppers/Value Field/Regular/$state/$appearance',
          );
          final controller = TextEditingController(text: '12');
          addTearDown(controller.dispose);
          final focus = FocusNode();
          addTearDown(focus.dispose);
          final scene = AmalfiValueField(
            controller: controller,
            focusNode: focus,
            enabled: state != 'Disabled',
          );
          final root = await pumpKitScene(tester, scene, master: master);
          if (state == 'Focused') await focusWithKeyboard(tester, focus);
          final field = find.byType(AmalfiValueField);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Background': within(field, DecoratedBox).first,
              if (state == 'Focused')
                'Focus Halo': find.byType(AmalfiSliderFocusHalo),
              'Value': find.byType(EditableText),
            },
            deviations: {
              'Value#text':
                  'EditableText paints without a RichText (checked below)',
            },
          );
          final value = master.layer('Value');
          final editable = tester.widget<EditableText>(
            find.byType(EditableText),
          );
          final ref = value.textStyle;
          expect(editable.controller.text, value.text);
          expect(ref, isNotNull);
          expect(editable.style, ref?.style.style(color: ref.color));
          expect(ref?.color, value.font?.color);
          focus.unfocus();
          await tester.pump();
          await expectKitPixels(
            tester,
            master,
            scene,
            maskText: true,
            tolerance: stepperTolerance,
            prepare: (tester) async {
              if (state == 'Focused') await focusWithKeyboard(tester, focus);
            },
          );
        });

        testWidgets('With Field $state', (tester) async {
          final master = KitMaster.load(
            'Steppers/With Field/Regular/$state/$appearance',
          );
          final focus = FocusNode();
          addTearDown(focus.dispose);
          final scene = Live(
            build: (v, c) => AmalfiStepperField(
              value: v,
              onChanged: state == 'Disabled' ? null : c,
              focusNode: focus,
            ),
          );
          final root = await pumpKitScene(tester, scene, master: master);
          if (state == 'Focused') await focusWithKeyboard(tester, focus);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Value field': find.byType(AmalfiValueField),
              'Stepper': find.byType(AmalfiStepper),
            },
          );
          focus.unfocus();
          await tester.pump();
          await expectKitPixels(
            tester,
            master,
            scene,
            maskText: true,
            tolerance: stepperTolerance,
            mask: [
              // The stepper's chevrons (see the stepper tests).
              chevronStroke(const Rect.fromLTWH(70, 1, 12, 12)),
              chevronStroke(const Rect.fromLTWH(70, 2, 12, 12)),
              chevronStroke(const Rect.fromLTWH(70, 15, 12, 12)),
              chevronStroke(const Rect.fromLTWH(70, 16, 12, 12)),
            ],
            prepare: (tester) async {
              if (state == 'Focused') await focusWithKeyboard(tester, focus);
            },
          );
        });
      }
    });
  }

  group('behaviour', () {
    testWidgets('each half steps, holding repeats, limits stop', (
      tester,
    ) async {
      final values = <double>[];
      await pumpKitScene(
        tester,
        Live(
          build: (v, c) => AmalfiStepper(
            value: v,
            max: 20,
            onChanged: (x) {
              values.add(x);
              c(x);
            },
          ),
        ),
      );
      await tester.tapAt(const Offset(12, 4));
      await tester.pump();
      expect(values, [13]);
      await tester.tapAt(const Offset(12, 24));
      await tester.pump();
      expect(values, [13, 12]);
      final g = await tester.startGesture(const Offset(12, 4));
      await tester.pump(AmalfiStepperMetrics.repeatDelay);
      await tester.pump(AmalfiStepperMetrics.repeatInterval * 3);
      await tester.pump(AmalfiStepperMetrics.repeatInterval * 20);
      await g.up();
      await tester.pump();
      expect(values.last, 20);
      expect(values.where((v) => v == 20), hasLength(1));
    });

    testWidgets('arrow keys step with the focus; semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      final values = <double>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpKitScene(
        tester,
        Live(
          build: (v, c) => AmalfiStepper(
            value: v,
            focusNode: focus,
            semanticLabel: 'Copies',
            onChanged: (x) {
              values.add(x);
              c(x);
            },
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      // Between frames too: the stepper counts from the value it last sent.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(values, [13, 14, 13]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Copies')),
        matchesSemantics(
          label: 'Copies',
          value: '13',
          increasedValue: '14',
          decreasedValue: '12',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isFocused: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the field applies typed numbers, clamps and restores', (
      tester,
    ) async {
      final values = <double>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpKitScene(
        tester,
        Live(
          build: (v, c) => AmalfiStepperField(
            value: v,
            max: 50,
            focusNode: focus,
            onChanged: (x) {
              values.add(x);
              c(x);
            },
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, [30]);
      await tester.enterText(find.byType(EditableText), '99');
      focus.unfocus();
      await tester.pump();
      expect(values, [30, 50]);
      expect(find.text('50'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, [30, 50]);
      expect(find.text('50'), findsOneWidget);
      await tester.showKeyboard(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(values, [30, 50, 49]);
      // The stepper after the field.
      await tester.tapAt(
        tester.getTopLeft(find.byType(AmalfiStepper)) + const Offset(12, 4),
      );
      await tester.pump();
      expect(values.last, 50);
    });

    testWidgets('odd values and constraints do not crash', (tester) async {
      await pumpKitScene(
        tester,
        const SizedBox(
          width: 4,
          height: 4,
          child: AmalfiStepper(value: double.nan, onChanged: null),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
