import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/buttons/buttons.dart';

import 'harness.dart';

/// A control holding its own value, rebuilt on change.
Widget stateful<T>(
  T initial,
  Widget Function(T value, ValueChanged<T> set) build, {
  bool dark = false,
  bool active = true,
  void Function(T value)? onValue,
}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => harness(
      build(value, (v) {
        onValue?.call(v);
        setState(() => value = v);
      }),
      dark: dark,
      active: active,
    ),
  );
}

void main() {
  tearDown(resetHighlight);

  group('disclosure triangle', () {
    testWidgets('5 × 8 chevron in 15 pt, turns at once', (tester) async {
      bool? last;
      await tester.pumpWidget(
        stateful<bool>(
          false,
          (v, set) => DisclosureTriangle(expanded: v, onChanged: set),
          onValue: (v) => last = v,
        ),
      );
      expect(
        tester.getSize(find.byType(DisclosureTriangle)),
        const Size(15, 15),
      );
      final chevron = find.byKey(const ValueKey('disclosure chevron'));
      expect(tester.getSize(chevron), const Size(5, 8));
      Transform turn() => tester.widget<Transform>(
        find.ancestor(of: chevron, matching: find.byType(Transform)).first,
      );
      expect(turn().transform, Matrix4.rotationZ(0));
      await tester.tap(find.byType(DisclosureTriangle));
      // One frame: no animation.
      await tester.pump();
      expect(last, isTrue);
      final m = turn().transform;
      expect(m.storage[1], closeTo(math.sin(math.pi / 2), 1e-9));
    });

    testWidgets('→ opens and ← closes with the keyboard focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var expanded = false;
      await tester.pumpWidget(
        stateful<bool>(
          false,
          (v, set) =>
              DisclosureTriangle(expanded: v, onChanged: set, focusNode: node),
          onValue: (v) => expanded = v,
        ),
      );
      await keyboardFocus(tester, node);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(expanded, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(expanded, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(expanded, isTrue);
    });

    testWidgets('disclosure button: ⌄ then ∧, 24 × 24', (tester) async {
      var expanded = false;
      await tester.pumpWidget(
        stateful<bool>(
          false,
          (v, set) => DisclosureButton(expanded: v, onChanged: set),
          onValue: (v) => expanded = v,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('button face'))),
        const Size(24, 24),
      );
      ChevronDirection direction() =>
          (tester
                      .widget<CustomPaint>(
                        find.byKey(const ValueKey('disclosure chevron')),
                      )
                      .painter!
                  as ChevronPainter)
              .direction;
      expect(direction(), ChevronDirection.down);
      await tester.tap(find.byType(DisclosureButton));
      await tester.pump();
      expect(expanded, isTrue);
      expect(direction(), ChevronDirection.up);
    });
  });

  group('checkbox', () {
    testWidgets('off → on → off; mixed → on; the label clicks too', (
      tester,
    ) async {
      final values = <bool>[];
      await tester.pumpWidget(
        stateful<bool?>(
          false,
          (v, set) => SilicaCheckbox(
            value: v,
            label: 'Snooze',
            onChanged: (b) => set(b),
          ),
          onValue: (v) => values.add(v!),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('checkbox'))),
        const Size(14, 14),
      );
      await tester.tap(find.byKey(const ValueKey('checkbox')));
      await tester.pump();
      await tester.tap(find.text('Snooze'));
      await tester.pump();
      expect(values, [true, false]);

      await tester.pumpWidget(
        harness(SilicaCheckbox(value: null, onChanged: values.add)),
      );
      await tester.tap(find.byType(SilicaCheckbox));
      expect(values.last, isTrue);
    });

    testWidgets('semantics: checked, mixed, label', (tester) async {
      await tester.pumpWidget(
        harness(
          SilicaCheckbox(value: true, label: 'Locked', onChanged: (_) {}),
        ),
      );
      expect(
        tester.getSemantics(find.byType(SilicaCheckbox)),
        matchesSemantics(
          label: 'Locked',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      await tester.pumpWidget(
        harness(SilicaCheckbox(value: null, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.byType(SilicaCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isCheckStateMixed: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('on uses the accent; gray in an inactive window', (
      tester,
    ) async {
      Color fill() =>
          ((tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('checkbox')),
                          )
                          .painter!)
                      as dynamic)
                  .fill
              as Color;
      await tester.pumpWidget(
        harness(SilicaCheckbox(value: true, onChanged: (_) {})),
      );
      expect(fill(), ControlAccent.system);
      await tester.pumpWidget(
        harness(SilicaCheckbox(value: true, onChanged: (_) {}), active: false),
      );
      expect(fill(), ControlColors.light.inactiveAccent);
      await tester.pumpWidget(
        harness(
          SilicaCheckbox(value: true, onChanged: (_) {}),
          active: false,
          dark: true,
        ),
      );
      // Measured: the Calculator's accent keys in an inactive window.
      expect(fill(), const Color(0xFF545555));
      await tester.pumpWidget(
        harness(
          ControlAccent(
            color: const Color(0xFFFF9230),
            child: SilicaCheckbox(value: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(fill(), const Color(0xFFFF9230));
      await tester.pumpWidget(
        harness(SilicaCheckbox(value: false, onChanged: (_) {}), dark: true),
      );
      expect(fill(), ControlColors.darkColors.box);
    });

    testWidgets('disabled: no change, dimmed label', (tester) async {
      await tester.pumpWidget(
        harness(
          const SilicaCheckbox(value: false, label: 'Off', onChanged: null),
        ),
      );
      await tester.tap(find.byType(SilicaCheckbox));
      expect(
        tester.widget<Text>(find.text('Off')).style?.color,
        ControlColors.light.labelDisabled,
      );
    });

    testWidgets('Space toggles with the keyboard focus, ring shown', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = false;
      await tester.pumpWidget(
        stateful<bool?>(
          false,
          (v, set) => SilicaCheckbox(
            value: v,
            focusNode: node,
            onChanged: (b) => set(b),
          ),
          onValue: (v) => value = v!,
        ),
      );
      await keyboardFocus(tester, node);
      expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
    });
  });

  group('radio', () {
    testWidgets('a click chooses, the arrows move the choice', (tester) async {
      String? chosen = 'a';
      await tester.pumpWidget(
        stateful<String>(
          'a',
          (v, set) => SilicaRadioGroup<String>(
            value: v,
            onChanged: set,
            options: const [
              RadioOption('a', 'Alpha'),
              RadioOption('b', 'Beta', enabled: false),
              RadioOption('c', 'Gamma'),
            ],
          ),
          onValue: (v) => chosen = v,
        ),
      );
      expect(find.byType(SilicaRadio), findsNWidgets(3));
      await tester.tap(find.text('Gamma'));
      await tester.pump();
      expect(chosen, 'c');
      // Disabled: nothing.
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(chosen, 'c');

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      Focus.of(tester.element(find.text('Gamma'))).requestFocus();
      await tester.pump();
      // Down from Gamma wraps to Alpha, skipping the disabled Beta.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(chosen, 'a');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(chosen, 'c');
    });

    testWidgets('semantics: in a mutually exclusive group', (tester) async {
      await tester.pumpWidget(
        harness(SilicaRadio(selected: true, label: 'One', onSelected: () {})),
      );
      expect(
        tester.getSemantics(find.byType(SilicaRadio)),
        matchesSemantics(
          label: 'One',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('radio'))),
        const Size(14, 14),
      );
    });
  });

  group('switch', () {
    Color track(WidgetTester tester) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(const ValueKey('switch track')),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;

    testWidgets('measured: 54 × 24, knob 32 × 20, on #0074f8', (tester) async {
      var value = false;
      await tester.pumpWidget(
        stateful<bool>(
          false,
          (v, set) => SilicaSwitch(value: v, onChanged: set),
          onValue: (v) => value = v,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('switch track'))),
        const Size(54, 24),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('switch knob'))),
        const Size(32, 20),
      );
      expect(track(tester), ControlColors.light.switchOff);
      final left = tester.getTopLeft(find.byKey(const ValueKey('switch knob')));
      expect(
        left - tester.getTopLeft(find.byKey(const ValueKey('switch track'))),
        const Offset(2, 2),
      );
      await tester.tap(find.byType(SilicaSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(track(tester), const Color(0xFF0074F8));
      // The knob 2 pt from the right edge.
      expect(
        tester.getTopRight(find.byKey(const ValueKey('switch track'))).dx -
            tester.getTopRight(find.byKey(const ValueKey('switch knob'))).dx,
        2,
      );
    });

    testWidgets('large matches Clock (68 × 30); dark off measured', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          SilicaSwitch(
            value: false,
            size: ControlSize.large,
            onChanged: (_) {},
          ),
          dark: true,
        ),
      );
      final size = tester.getSize(find.byKey(const ValueKey('switch track')));
      expect(size.height, 30);
      expect(size.width, closeTo(68, 1));
      expect(track(tester), const Color(0xFF454545));
    });

    testWidgets('inactive window: gray track; semantics toggled', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          SilicaSwitch(value: true, semanticLabel: 'Wi-Fi', onChanged: (_) {}),
          active: false,
        ),
      );
      expect(track(tester), ControlColors.light.inactiveAccent);
      expect(
        tester.getSemantics(find.byType(SilicaSwitch)),
        matchesSemantics(
          label: 'Wi-Fi',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('Space toggles; disabled does nothing', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = false;
      await tester.pumpWidget(
        stateful<bool>(
          false,
          (v, set) => SilicaSwitch(value: v, onChanged: set, focusNode: node),
          onValue: (v) => value = v,
        ),
      );
      await keyboardFocus(tester, node);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(value, isTrue);

      await tester.pumpWidget(
        harness(const SilicaSwitch(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(SilicaSwitch));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.byKey(const ValueKey('switch track')),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0.5,
      );
    });
  });
}
