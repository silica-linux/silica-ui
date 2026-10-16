// Toggles against the kit (`Toggles/*`): checkboxes, radio buttons, switches, labelled rows and
// groups, in every variant, size and state. Checklist: docs/amalfi-checklist/toggles.md.

import 'package:flutter/gestures.dart';
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'toggles_support.dart';

const appearances = ['Light', 'Dark'];
const states = ['Rest', 'Hover', 'Pressed', 'Disabled', 'Focused'];

AmalfiControlSize sizeOf(String name) => switch (name) {
  'Mini' => AmalfiControlSize.mini,
  'Small' => AmalfiControlSize.small,
  'Regular' => AmalfiControlSize.regular,
  _ => AmalfiControlSize.large,
};

void main() {
  setUpAll(loadAmalfiFonts);

  group('checkbox', () {
    for (final appearance in appearances) {
      for (final (variant, value) in [
        ('Off', false),
        ('On', true),
        ('Mixed', null),
      ]) {
        for (final size in ['Small', 'Regular', 'Large']) {
          for (final state in states) {
            final name = 'Toggles/Checkbox/$variant/$size/$state/$appearance';
            testWidgets(name, (tester) async {
              final kitState = KitState.parse(state);
              final widget = AmalfiCheckbox(
                value: value,
                size: sizeOf(size),
                onChanged: kitState.enabled ? (_) {} : null,
              );
              // Kit defect: the Small glyphs keep the 24 pt stroke (1.5) at 12 pt; the Icon
              // Kit rule scales it to 0.75 (README).
              final thickGlyph = size == 'Small' && value != false;
              final glyph = value == null ? 'Glyph Dash' : 'Glyph Check';
              await checkKit(
                tester,
                name,
                widget,
                state: kitState,
                layers: (root) => {
                  'Box': layerOf(root, AmalfiLayerKeys.body),
                  if (kitState == KitState.hover && value != false)
                    'State': layerOf(root, AmalfiLayerKeys.state),
                  if (kitState == KitState.focused)
                    'Focus Halo': layerOf(root, AmalfiLayerKeys.focusHalo),
                  if (value != false)
                    glyph: layerOf(root, AmalfiLayerKeys.mark),
                },
                maskLayers: [if (thickGlyph) glyph],
                maskMargin: 0,
                tolerance: tolerance(
                  accentRim: kitState == KitState.hover && value == false,
                  masked: thickGlyph,
                ),
              );
            });
          }
        }
      }
      for (final (variant, value) in [
        ('Off', false),
        ('On', true),
        ('Mixed', null),
      ]) {
        for (final state in states) {
          final name =
              'Toggles/Checkbox/With Label/$variant/$state/$appearance';
          testWidgets(name, (tester) async {
            final kitState = KitState.parse(state);
            await checkKit(
              tester,
              name,
              AmalfiCheckbox(
                value: value,
                label: 'Show hidden files',
                onChanged: kitState.enabled ? (_) {} : null,
              ),
              state: kitState,
              layers: (root) => {
                'Checkbox box': layerOf(root, AmalfiLayerKeys.control),
                'Label': layerOf(root, AmalfiLayerKeys.label),
              },
            );
          });
        }
      }
      testWidgets('Toggles/Checkbox Group/List/Rest/$appearance', (
        tester,
      ) async {
        final name = 'Toggles/Checkbox Group/List/Rest/$appearance';
        // Kit defect: two rows keep a stale width (156) instead of their label's, and the
        // group (172) is narrower than its widest row (168, which matches the code); the
        // code sizes each row to its label and the group to its rows.
        const rowWidth = 'kit rows keep stale instance widths';
        await checkKit(
          tester,
          name,
          AmalfiToggleGroup(
            heading: 'Browsing',
            children: [
              AmalfiCheckbox(
                key: const ValueKey('a'),
                value: null,
                label: 'Select all',
                onChanged: (_) {},
              ),
              AmalfiCheckbox(
                key: const ValueKey('b'),
                value: true,
                label: 'Show hidden files',
                onChanged: (_) {},
              ),
              AmalfiCheckbox(
                key: const ValueKey('c'),
                value: false,
                label: 'Open folders in tabs',
                onChanged: (_) {},
              ),
            ],
          ),
          layers: (root) => {
            'Heading': find.byKey(AmalfiLayerKeys.label).first,
            'Select all': find.byKey(const ValueKey('a')),
            'Show hidden files': find.byKey(const ValueKey('b')),
            'Open folders in tabs': find.byKey(const ValueKey('c')),
          },
          deviations: {
            '#frame': rowWidth,
            'Select all': rowWidth,
            'Show hidden files': rowWidth,
          },
          // The rows are checked by their own masters; the overflowing kit row is cut.
          pixels: false,
        );
      });
    }
  });

  group('radio', () {
    for (final appearance in appearances) {
      for (final (variant, selected) in [('Off', false), ('On', true)]) {
        for (final size in ['Small', 'Regular', 'Large']) {
          for (final state in states) {
            final name = 'Toggles/Radio/$variant/$size/$state/$appearance';
            testWidgets(name, (tester) async {
              final kitState = KitState.parse(state);
              // Kit defect: the Small and Regular dots have radius 3 (a rounded square);
              // the Large dot is a circle (radius 4). The code draws circles.
              final squareDot = selected && size != 'Large';
              await checkKit(
                tester,
                name,
                AmalfiRadio(
                  selected: selected,
                  size: sizeOf(size),
                  onSelected: kitState.enabled ? () {} : null,
                ),
                state: kitState,
                layers: (root) => {
                  'Box': layerOf(root, AmalfiLayerKeys.body),
                  if (kitState == KitState.hover && selected)
                    'State': layerOf(root, AmalfiLayerKeys.state),
                  if (kitState == KitState.focused)
                    'Focus Halo': layerOf(root, AmalfiLayerKeys.focusHalo),
                  if (selected)
                    'Dot': find.descendant(
                      of: layerOf(root, AmalfiLayerKeys.mark),
                      matching: find.byType(DecoratedBox),
                    ),
                },
                deviations: {
                  if (squareDot)
                    'Dot#corners': 'kit dot radius 3, not a circle',
                },
                maskLayers: [if (squareDot) 'Dot'],
                maskMargin: 0,
                tolerance: tolerance(
                  accentRim: kitState == KitState.hover && !selected,
                  masked: squareDot,
                ),
              );
            });
          }
        }
      }
      for (final (variant, selected) in [('Off', false), ('On', true)]) {
        for (final state in states) {
          final name = 'Toggles/Radio/With Label/$variant/$state/$appearance';
          testWidgets(name, (tester) async {
            final kitState = KitState.parse(state);
            await checkKit(
              tester,
              name,
              AmalfiRadio(
                selected: selected,
                label: 'Sort by name',
                onSelected: kitState.enabled ? () {} : null,
              ),
              state: kitState,
              layers: (root) => {
                'Radio box': layerOf(root, AmalfiLayerKeys.control),
                'Label': layerOf(root, AmalfiLayerKeys.label),
              },
              // Kit defect: the dot of the nested Regular radio (see above).
              mask: [if (selected) const Rect.fromLTWH(8, 6, 8, 8)],
            );
          });
        }
      }
      testWidgets('Toggles/Radio Group/List/Rest/$appearance', (tester) async {
        final name = 'Toggles/Radio Group/List/Rest/$appearance';
        const rowWidth = 'kit rows keep stale instance widths (140)';
        await checkKit(
          tester,
          name,
          AmalfiRadioGroup<String>(
            heading: 'Order',
            value: 'date',
            onChanged: (_) {},
            options: const [
              AmalfiRadioOption(value: 'name', label: 'Sort by name'),
              AmalfiRadioOption(value: 'date', label: 'Sort by date'),
              AmalfiRadioOption(value: 'size', label: 'Sort by size'),
            ],
          ),
          layers: (root) => {
            'Heading': find.byKey(AmalfiLayerKeys.label).first,
            for (final (i, label) in [
              'Sort by name',
              'Sort by date',
              'Sort by size',
            ].indexed)
              label: find.byType(AmalfiRadio).at(i),
          },
          deviations: {
            '#frame': rowWidth,
            'Sort by name': rowWidth,
            'Sort by date': rowWidth,
            'Sort by size': rowWidth,
            'Heading':
                'kit fixed-width heading frame 40 for "Order" (36 on the grid)',
          },
          pixels: false,
        );
      });
    }
  });

  group('switch', () {
    // Kit defect: the thumb is not inset evenly. At rest the kit puts it at x 0 (Mini,
    // Small) or 4 (Regular) when off and flush with the right edge when on, while it is 2
    // from the top and bottom; pressed, the Mini and Small thumbs do not stretch and move
    // instead. The code insets the thumb 2 on every side and stretches it by 4 towards the
    // middle when pressed.
    const thumbDefect = 'kit thumb not inset evenly (code: 2 on every side)';
    // Kit vs tokens: the disabled track and thumb are at 45 % opacity; the token
    // `AmalfiStates.disabledOpacity` (content at 35 %) wins.
    for (final appearance in appearances) {
      for (final (variant, value) in [('Off', false), ('On', true)]) {
        for (final size in ['Mini', 'Small', 'Regular']) {
          final metrics = AmalfiSwitchMetrics.of(sizeOf(size));
          for (final state in states) {
            final name = 'Toggles/Switch/$variant/$size/$state/$appearance';
            testWidgets(name, (tester) async {
              final kitState = KitState.parse(state);
              final master = KitMaster.load(name);
              // Both thumbs (the kit's and the code's) are left out of the pixels.
              final kitThumb = master.layer('Thumb').rectInMaster;
              final stretch = kitState == KitState.pressed
                  ? AmalfiSwitchMetrics.pressedStretch
                  : 0.0;
              final x = metrics.restX(value) - (value ? stretch : 0);
              final ours = Rect.fromLTWH(
                x,
                metrics.inset,
                metrics.thumb + stretch,
                metrics.thumb,
              );
              await checkKit(
                tester,
                name,
                AmalfiSwitch(
                  value: value,
                  size: sizeOf(size),
                  onChanged: kitState.enabled ? (_) {} : null,
                ),
                state: kitState,
                layers: (root) => {
                  'Track': layerOf(root, AmalfiLayerKeys.body),
                  if (kitState == KitState.hover)
                    'State': layerOf(root, AmalfiLayerKeys.state),
                  if (kitState == KitState.focused)
                    'Focus Halo': layerOf(root, AmalfiLayerKeys.focusHalo),
                  'Thumb': layerOf(root, AmalfiLayerKeys.thumb),
                },
                deviations: {'Thumb': thumbDefect},
                mask: [kitThumb.expandToInclude(ours).inflate(2)],
                // Disabled: the opacity differs from the kit (see above).
                pixels: kitState.enabled,
              );
            });
          }
          final name = 'Toggles/Switch/$variant/$size/Dragging/$appearance';
          testWidgets(name, (tester) async {
            final master = KitMaster.load(name);
            final track = master.layer('Track').rectInMaster;
            final kitLens = master.layer('Lens').rectInMaster;
            // Dragged to where the kit draws the lens: its centre over the thumb's.
            final target = kitLens.center.dx - track.left - metrics.thumb / 2;
            final widget = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: track.left,
                vertical: track.top,
              ),
              child: AmalfiSwitch(
                value: value,
                size: sizeOf(size),
                onChanged: (_) {},
              ),
            );
            Future<void> drag(WidgetTester tester) async {
              final thumb = find.byKey(AmalfiLayerKeys.thumb);
              final down = tester.getCenter(thumb);
              final gesture = await tester.startGesture(
                down,
                kind: PointerDeviceKind.mouse,
              );
              addTearDown(gesture.removePointer);
              await gesture.moveBy(const Offset(4, 0));
              await gesture.moveTo(
                down + Offset(target - metrics.restX(value), 0),
              );
              await tester.pumpAndSettle();
            }

            final root = await pumpKitScene(tester, widget, master: master);
            await drag(tester);
            final regular = size == 'Regular';
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Track': layerOf(root, AmalfiLayerKeys.body),
                'Lens': layerOf(root, AmalfiLayerKeys.lens),
              },
              deviations: {
                if (regular)
                  'Lens':
                      'kit lens 32 (thumb + 12); materials.md: thumb + 8 = 28',
                'Lens#corners':
                    'kit lens radius = side / 2 − 1; materials.md: capsule',
                'Lens#blurs':
                    'kit encodes the Clear lens as a Glass blur, not Background',
              },
            );
            await expectKitPixels(
              tester,
              master,
              widget,
              // The lens refracts in the kit; here it magnifies without refraction, so only
              // the track is compared.
              maskLayers: ['Lens'],
              tolerance: smallShapes,
              prepare: drag,
            );
          });
        }
      }
      for (final (variant, value) in [('Off', false), ('On', true)]) {
        for (final state in states) {
          final name = 'Toggles/Switch/With Label/$variant/$state/$appearance';
          testWidgets(name, (tester) async {
            final kitState = KitState.parse(state);
            final master = KitMaster.load(name);
            final at = master.layer('Switch').rectInMaster.topLeft;
            final metrics = AmalfiSwitchMetrics.of(AmalfiControlSize.regular);
            await checkKit(
              tester,
              name,
              SizedBox(
                width: master.size.width,
                child: AmalfiSwitch(
                  value: value,
                  label: 'Wi-Fi',
                  onChanged: kitState.enabled ? (_) {} : null,
                ),
              ),
              state: kitState,
              target: (root) => find.descendant(
                of: root,
                matching: find.byType(AmalfiSwitch),
              ),
              layers: (root) => {
                'Switch': layerOf(root, AmalfiLayerKeys.control),
                'Label': layerOf(root, AmalfiLayerKeys.label),
              },
              // The nested switch's thumb (see the switch's kit defect).
              mask: [
                Rect.fromLTWH(
                  at.dx,
                  at.dy,
                  metrics.track.width,
                  metrics.track.height,
                ).deflate(1),
              ],
              pixels: kitState.enabled,
            );
          });
        }
      }
    }
  });

  group('behaviour', () {
    testWidgets('a checkbox toggles on click, on its label and with Space', (
      tester,
    ) async {
      bool? value = false;
      await pumpKitScene(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AmalfiCheckbox(
            value: value,
            label: 'Show hidden files',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      await tester.tap(find.byType(AmalfiCheckboxFace));
      await tester.pump();
      expect(value, isTrue);
      await tester.tap(find.text('Show hidden files'));
      await tester.pump();
      expect(value, isFalse);
      await focusOn(tester, find.byType(AmalfiCheckbox));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('a mixed checkbox turns on; a disabled one ignores input', (
      tester,
    ) async {
      final changes = <bool>[];
      await pumpKitScene(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmalfiCheckbox(value: null, onChanged: changes.add),
            const AmalfiCheckbox(value: false, onChanged: null),
          ],
        ),
      );
      await tester.tap(find.byType(AmalfiCheckbox).first);
      await tester.tap(find.byType(AmalfiCheckbox).last);
      await tester.pump();
      expect(changes, [true]);
    });

    testWidgets('a release outside does not toggle', (tester) async {
      final changes = <bool>[];
      await pumpKitScene(
        tester,
        AmalfiCheckbox(value: false, onChanged: changes.add),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AmalfiCheckbox)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(const Offset(300, 300));
      await gesture.up();
      await tester.pump();
      expect(changes, isEmpty);
    });

    testWidgets('radio group: click and arrow keys choose', (tester) async {
      var value = 'name';
      await pumpKitScene(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AmalfiRadioGroup<String>(
            value: value,
            onChanged: (v) => setState(() => value = v),
            options: const [
              AmalfiRadioOption(value: 'name', label: 'Name'),
              AmalfiRadioOption(value: 'date', label: 'Date', enabled: false),
              AmalfiRadioOption(value: 'size', label: 'Size'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Size'));
      await tester.pump();
      expect(value, 'size');
      await focusOn(tester, find.byType(AmalfiRadio).first);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      // From Name (focused first) the next enabled option is Size (Date is disabled).
      expect(value, 'size');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, 'name');
    });

    testWidgets('a switch toggles on click, Space and on its row label', (
      tester,
    ) async {
      var value = false;
      await pumpKitScene(
        tester,
        SizedBox(
          width: 240,
          child: StatefulBuilder(
            builder: (context, setState) => AmalfiSwitch(
              value: value,
              label: 'Wi-Fi',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      final thumb = find.byKey(AmalfiLayerKeys.thumb);
      final off = tester.getTopLeft(thumb).dx;
      await tester.tap(find.byType(AmalfiSwitchFace));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      // The thumb travelled to the other end, inset 2.
      expect(tester.getTopLeft(thumb).dx - off, 40 - 20 - 2 * 2);
      await tester.tap(find.text('Wi-Fi'));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      await focusOn(tester, find.byType(AmalfiSwitch));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets(
      'dragging the thumb shows the lens and chooses the nearer end',
      (tester) async {
        final changes = <bool>[];
        await pumpKitScene(
          tester,
          AmalfiSwitch(value: false, onChanged: changes.add),
        );
        final thumb = find.byKey(AmalfiLayerKeys.thumb);
        final start = tester.getCenter(thumb);
        final gesture = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(6, 0));
        await tester.pumpAndSettle();
        expect(find.byKey(AmalfiLayerKeys.lens), findsOneWidget);
        expect(thumb, findsNothing);
        // Not past the middle: back to off, nothing changes.
        await gesture.up();
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
        expect(find.byKey(AmalfiLayerKeys.lens), findsNothing);
        final again = await tester.startGesture(
          tester.getCenter(thumb),
          kind: PointerDeviceKind.mouse,
        );
        await again.moveBy(const Offset(4, 0));
        await again.moveBy(const Offset(40, 0));
        await tester.pump();
        // The lens follows the pointer only as far as the track's end.
        final lens = tester.getRect(find.byKey(AmalfiLayerKeys.lens));
        expect(lens.center.dx, 40 - 10);
        await again.up();
        await tester.pumpAndSettle();
        expect(changes, [true]);
      },
    );

    testWidgets('a disabled switch ignores clicks and drags', (tester) async {
      await pumpKitScene(
        tester,
        const AmalfiSwitch(value: false, onChanged: null),
      );
      await tester.drag(find.byType(AmalfiSwitch), const Offset(30, 0));
      await tester.tap(find.byType(AmalfiSwitch));
      await tester.pumpAndSettle();
      expect(find.byKey(AmalfiLayerKeys.lens), findsNothing);
    });

    testWidgets('semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmalfiCheckbox(value: null, label: 'All', onChanged: (_) {}),
            AmalfiRadio(selected: true, label: 'One', onSelected: () {}),
            AmalfiSwitch(value: true, label: 'Wi-Fi', onChanged: (_) {}),
          ],
        ),
      );
      final all = tester.getSemantics(find.byType(AmalfiCheckbox));
      expect(all.label, 'All');
      expect(
        all.getSemanticsData().flagsCollection.isChecked,
        CheckedState.mixed,
      );
      final one = tester.getSemantics(find.byType(AmalfiRadio));
      expect(
        one.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup,
        isTrue,
      );
      expect(
        one.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      final wifi = tester.getSemantics(find.byType(AmalfiSwitch));
      expect(wifi.label, 'Wi-Fi');
      expect(
        wifi.getSemanticsData().flagsCollection.isToggled,
        Tristate.isTrue,
      );
      expect(wifi.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });
}
