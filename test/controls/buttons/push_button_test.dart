import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/buttons/buttons.dart';

import 'harness.dart';

const face = ValueKey('button face');

void main() {
  tearDown(resetHighlight);

  testWidgets('measured sizes: 24 regular, 22 small', (tester) async {
    for (final (size, height) in [
      (ControlSize.mini, 16.0),
      (ControlSize.small, 22.0),
      (ControlSize.regular, 24.0),
      (ControlSize.large, 30.0),
    ]) {
      await tester.pumpWidget(
        harness(SilicaButton(label: 'OK', size: size, onPressed: () {})),
      );
      expect(tester.getSize(find.byKey(face)).height, height);
    }
    await tester.pumpWidget(
      harness(SilicaButton(label: 'OK', minWidth: 80, onPressed: () {})),
    );
    expect(tester.getSize(find.byKey(face)), const Size(80, 24));
  });

  testWidgets('colors at rest, light and dark (misc.md › Alert)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(SilicaButton(label: 'A', onPressed: () {})),
    );
    expect(fillOf(tester, face), const Color(0xFFECECEC));
    expect(textColor(tester, find.byKey(face)), const Color(0xFF242424));

    await tester.pumpWidget(
      harness(SilicaButton(label: 'A', onPressed: () {}), dark: true),
    );
    expect(fillOf(tester, face), const Color(0xFF373737));
    expect(textColor(tester, find.byKey(face)), const Color(0xFFE0E0E0));

    for (final dark in [false, true]) {
      await tester.pumpWidget(
        harness(
          SilicaButton(label: 'OK', role: ButtonRole.primary, onPressed: () {}),
          dark: dark,
        ),
      );
      expect(fillOf(tester, face), const Color(0xFF007AFF));
      expect(textColor(tester, find.byKey(face)), const Color(0xFFFFFFFF));
    }
  });

  testWidgets('destructive and borderless', (tester) async {
    await tester.pumpWidget(
      harness(
        SilicaButton(
          label: 'Delete',
          role: ButtonRole.destructive,
          onPressed: () {},
        ),
      ),
    );
    expect(fillOf(tester, face), ControlColors.light.destructive);
    expect(
      textColor(tester, find.byKey(face)),
      ControlColors.light.destructiveText,
    );

    await tester.pumpWidget(
      harness(
        SilicaButton(
          label: 'More',
          bezel: ButtonBezel.borderless,
          onPressed: () {},
        ),
      ),
    );
    expect(fillOf(tester, face), isNull);
  });

  testWidgets('the accent follows ControlAccent', (tester) async {
    await tester.pumpWidget(
      harness(
        ControlAccent(
          color: const Color(0xFFFF9230),
          child: SilicaButton(
            label: 'Save',
            role: ButtonRole.primary,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(fillOf(tester, face), const Color(0xFFFF9230));
  });

  testWidgets('inactive window: the default button loses the accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SilicaButton(label: 'OK', role: ButtonRole.primary, onPressed: () {}),
        active: false,
      ),
    );
    expect(fillOf(tester, face), ControlColors.light.bezel);
  });

  testWidgets(
    'pressed at once, follows the pointer, acts on release inside only',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(SilicaButton(label: 'Go', onPressed: () => taps++)),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(face)),
      );
      await tester.pump();
      expect(fillOf(tester, face), ControlColors.light.bezelPressed);
      expect(taps, 0);
      // Out of the button: back to rest; releasing there does nothing.
      await press.moveTo(const Offset(1, 1));
      await tester.pump();
      expect(fillOf(tester, face), ControlColors.light.bezel);
      await press.up();
      await tester.pump();
      expect(taps, 0);

      await tester.tap(find.byKey(face));
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets('dark pressed fill is ~12 % lighter (Clock)', (tester) async {
    await tester.pumpWidget(
      harness(
        SilicaButton(label: 'OK', role: ButtonRole.primary, onPressed: () {}),
        dark: true,
      ),
    );
    await tester.startGesture(tester.getCenter(find.byKey(face)));
    await tester.pump();
    expect(
      fillOf(tester, face),
      pressedFill(const Color(0xFF007AFF), dark: true),
    );
    final c = fillOf(tester, face)!;
    expect(
      c.computeLuminance(),
      greaterThan(const Color(0xFF007AFF).computeLuminance()),
    );
  });

  testWidgets('disabled: no action, disabled text', (tester) async {
    await tester.pumpWidget(
      harness(const SilicaButton(label: 'Nope', onPressed: null)),
    );
    await tester.tap(find.byKey(face));
    await tester.pump();
    expect(
      textColor(tester, find.byKey(face)),
      ControlColors.light.textDisabled,
    );
    expect(
      tester.getSemantics(find.byType(SilicaButton)),
      matchesSemantics(
        label: 'Nope',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isFocusable: false,
      ),
    );
  });

  testWidgets('keyboard: focus ring and Space', (tester) async {
    var taps = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      harness(
        SilicaButton(label: 'Go', focusNode: node, onPressed: () => taps++),
      ),
    );
    expect(find.byKey(const ValueKey('focus ring')), findsNothing);
    await keyboardFocus(tester, node);
    expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('help button: a circle with ?', (tester) async {
    var taps = 0;
    await tester.pumpWidget(harness(HelpButton(onPressed: () => taps++)));
    expect(find.text('?'), findsOneWidget);
    expect(tester.getSize(find.byKey(face)), const Size(24, 24));
    await tester.tap(find.byKey(face));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(HelpButton)),
      matchesSemantics(
        label: 'Help',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: false,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('toggle button: lighter when on, toggles on release', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => harness(
          ToggleButton(
            label: '2nd',
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
          dark: true,
        ),
      ),
    );
    expect(fillOf(tester, face), ControlColors.darkColors.bezel);
    await tester.tap(find.byKey(face));
    await tester.pump();
    expect(value, isTrue);
    expect(fillOf(tester, face), ControlColors.darkColors.bezelOn);
    expect(
      ControlColors.darkColors.bezelOn.computeLuminance(),
      greaterThan(ControlColors.darkColors.bezel.computeLuminance()),
    );
  });

  testWidgets('image button: only the glyph changes (CC media module)', (
    tester,
  ) async {
    Color? glyph;
    var taps = 0;
    await tester.pumpWidget(
      harness(
        ImageButton(
          semanticLabel: 'Pause',
          colors: ImageButtonColors.onGlass,
          onPressed: () => taps++,
          icon: (c) {
            glyph = c;
            return const SizedBox(width: 15, height: 20);
          },
        ),
      ),
    );
    expect(tester.getSize(find.byType(ImageButton)), const Size(30, 30));
    expect(glyph, const Color(0xFFB7B8BD));
    final mouse = await hover(tester, find.byType(ImageButton));
    expect(glyph, const Color(0xFFBEBFC4));
    await mouse.down(tester.getCenter(find.byType(ImageButton)));
    await tester.pump();
    expect(glyph, const Color(0xFFF7F7F8));
    await mouse.up();
    await tester.pump();
    expect(taps, 1);
    await mouse.removePointer();

    await tester.pumpWidget(
      harness(
        ImageButton(
          semanticLabel: 'Previous',
          colors: ImageButtonColors.onGlass,
          onPressed: null,
          icon: (c) {
            glyph = c;
            return const SizedBox(width: 22, height: 13);
          },
        ),
      ),
    );
    expect(glyph, const Color(0xFF9D9EA3));
  });
}
