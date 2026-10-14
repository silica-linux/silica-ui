import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart' show MenuAction, MenuHost, MenuPanel;
import 'package:silica_ui/src/controls/buttons/buttons.dart';

import 'harness.dart';

const sounds = [
  PopUpItem('radial', 'Radial'),
  PopUpItem('chime', 'Chime'),
  PopUpItem('bell', 'Bell', enabled: false),
  PopUpItem('pulse', 'Pulse'),
];

Widget popUp(String value, ValueChanged<String> onChanged, {FocusNode? node}) =>
    StatefulBuilder(
      builder: (context, setState) => harness(
        PopUpButton<String>(
          items: sounds,
          value: value,
          width: 224,
          focusNode: node,
          onChanged: (v) {
            onChanged(v);
            setState(() => value = v);
          },
        ),
      ),
    );

/// The choice blinks, then the menu fades (timers, then frames).
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  setUp(muteGlass);
  tearDown(resetHighlight);

  testWidgets('measured size; shows the chosen value', (tester) async {
    await tester.pumpWidget(popUp('chime', (_) {}));
    expect(
      tester.getSize(find.byKey(const ValueKey('button face'))),
      const Size(224, 24),
    );
    expect(find.text('Chime'), findsOneWidget);
    expect(find.byKey(const ValueKey('pop-up chevrons')), findsOneWidget);
  });

  testWidgets('opens on press with the chosen item over the button', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(popUp('chime', chosen.add));
    final button = find.byKey(const ValueKey('button face'));
    final buttonCenter = tester.getCenter(button);
    final press = await tester.startGesture(buttonCenter);
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
    // The checked row sits on the button: its text on the button's text.
    final row = find.descendant(
      of: find.byType(MenuPanel),
      matching: find.text('Chime'),
    );
    expect(tester.getCenter(row).dy, closeTo(buttonCenter.dy, 1));
    expect(
      tester.getTopLeft(row).dx,
      closeTo(tester.getTopLeft(button).dx + popUpPadding, 0.5),
    );
    // At least as wide as the button.
    expect(
      tester.getSize(find.byType(MenuPanel)).width,
      greaterThanOrEqualTo(224),
    );
    final panel = tester.widget<MenuPanel>(find.byType(MenuPanel));
    expect(
      panel.entries
          .whereType<MenuAction>()
          .where((a) => a.checked)
          .single
          .label,
      'Chime',
    );

    // Drag to Pulse and release: chosen (after the blink and the fade).
    final pulse = find.descendant(
      of: find.byType(MenuPanel),
      matching: find.text('Pulse'),
    );
    await press.moveTo(tester.getCenter(pulse));
    await tester.pump();
    await press.up();
    await settle(tester);
    expect(chosen, ['pulse']);
    expect(find.byType(MenuHost), findsNothing);
    expect(find.text('Pulse'), findsOneWidget);
  });

  testWidgets('click opens, click on an item chooses, disabled not', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(popUp('radial', chosen.add));
    await tester.tap(find.byKey(const ValueKey('button face')));
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(MenuPanel), matching: find.text('Bell')),
    );
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(MenuPanel), matching: find.text('Chime')),
    );
    await settle(tester);
    expect(chosen, ['chime']);
    expect(find.byType(MenuHost), findsNothing);
  });

  testWidgets('keyboard: ↓ opens, Return chooses, focus comes back', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final chosen = <String>[];
    await tester.pumpWidget(popUp('radial', chosen.add, node: node));
    await keyboardFocus(tester, node);
    expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(chosen, ['radial']);
    expect(node.hasFocus, isTrue);
  });

  testWidgets('Escape closes without choosing', (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(popUp('radial', chosen.add));
    await tester.tap(find.byKey(const ValueKey('button face')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byType(MenuHost), findsNothing);
    expect(chosen, isEmpty);
  });

  testWidgets('pull-down: menu below, actions run', (tester) async {
    var grouped = 0;
    await tester.pumpWidget(
      harness(
        PullDownButton(
          title: 'Group',
          entries: [
            MenuAction('By kind', onSelected: () => grouped++),
            const MenuAction('By date'),
          ],
        ),
      ),
    );
    final chevron = find.byKey(const ValueKey('pull-down chevron'));
    expect(tester.getSize(chevron), const Size(7, 4));
    final face = find.byKey(const ValueKey('button face'));
    await tester.tap(face);
    await tester.pump();
    final panel = find.byType(MenuPanel);
    expect(
      tester.getTopLeft(panel).dy,
      tester.getBottomLeft(face).dy + pullDownGap,
    );
    expect(tester.getTopLeft(panel).dx, tester.getTopLeft(face).dx);
    await tester.tap(
      find.descendant(of: panel, matching: find.text('By kind')),
    );
    await settle(tester);
    expect(grouped, 1);
  });

  testWidgets('pull-down disabled: no menu', (tester) async {
    await tester.pumpWidget(
      harness(
        const PullDownButton(
          title: 'Group',
          enabled: false,
          entries: [MenuAction('A')],
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('button face')));
    await tester.pump();
    expect(find.byType(MenuHost), findsNothing);
  });

  testWidgets('combo box: typing and choosing from the list', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await tester.pumpWidget(
      harness(
        ComboBox(
          items: const ['Rome', 'Milan', 'Naples'],
          controller: controller,
          onChanged: changes.add,
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('combo field'))),
      const Size(160, 24),
    );
    await tester.enterText(find.byType(EditableText), 'Ro');
    expect(changes.last, 'Ro');
    await tester.tap(find.byKey(const ValueKey('combo arrow')));
    await tester.pump();
    final panel = find.byType(MenuPanel);
    expect(tester.getSize(panel).width, greaterThanOrEqualTo(160));
    await tester.tap(find.descendant(of: panel, matching: find.text('Naples')));
    await settle(tester);
    expect(controller.text, 'Naples');
    expect(changes.last, 'Naples');
  });

  testWidgets('combo box: ↓ in the field opens the list', (tester) async {
    final controller = TextEditingController(text: 'Milan');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(ComboBox(items: const ['Rome', 'Milan'], controller: controller)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.byType(MenuHost), findsOneWidget);
    final panel = tester.widget<MenuPanel>(find.byType(MenuPanel));
    expect(
      panel.entries
          .whereType<MenuAction>()
          .where((a) => a.checked)
          .single
          .label,
      'Milan',
    );
  });
}
