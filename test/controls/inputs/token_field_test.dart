import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/inputs/inputs.dart';

import 'harness.dart';

const green = Color(0xFF8ADC98);

void main() {
  late List<FieldToken> tokens;
  late FocusNode focus;

  Widget field({bool enabled = true}) => StatefulBuilder(
    builder: (context, setState) => SilicaTokenField(
      tokens: tokens,
      focusNode: focus,
      width: 232,
      enabled: enabled,
      placeholder: 'Tags',
      complete: (p) =>
          'Green'.toLowerCase().startsWith(p.toLowerCase()) ? 'Green' : null,
      tokenize: (t) => FieldToken(t, color: t == 'Green' ? green : null),
      onChanged: (t) => setState(() => tokens = t),
    ),
  );

  setUp(() {
    tokens = [];
    focus = FocusNode();
  });

  testWidgets('27 pt tall; Return makes a 14 pt token', (tester) async {
    await pumpControl(tester, field());
    expect(tester.getSize(find.byType(SilicaTokenField)).height, 27);
    await tester.tap(find.byType(SilicaTokenField));
    await tester.enterText(find.byType(EditableText), 'Work');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tokens, [const FieldToken('Work')]);
    expect(tester.getSize(find.byType(TokenCapsule)).height, 14);
  });

  testWidgets('inline completion selects the remainder', (tester) async {
    await pumpControl(tester, field());
    await tester.tap(find.byType(SilicaTokenField));
    await tester.enterText(find.byType(EditableText), 'gr');
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, 'green'.replaceRange(0, 2, 'gr'));
    expect(
      editable.controller.selection,
      const TextSelection(baseOffset: 2, extentOffset: 5),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tokens.single.color, isNull);
  });

  testWidgets('⌫ selects the last token, then removes it', (tester) async {
    tokens = [const FieldToken('A'), const FieldToken('B', color: green)];
    await pumpControl(tester, field());
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    final selected = tester.widget<TokenCapsule>(
      find.widgetWithText(TokenCapsule, 'B'),
    );
    expect(selected.selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(tokens, [const FieldToken('A')]);
  });

  testWidgets('selected token is gray in an inactive window', (tester) async {
    tokens = [const FieldToken('A')];
    await pumpControl(tester, field(), active: false);
    await tester.tap(find.text('A'));
    await tester.pump();
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(TokenCapsule),
        matching: find.byType(Container),
      ),
    );
    expect(
      (box.decoration! as BoxDecoration).color,
      InputColors.light.accentInactive,
    );
  });

  testWidgets('semantics list the tokens', (tester) async {
    final handle = tester.ensureSemantics();
    tokens = [const FieldToken('A'), const FieldToken('B')];
    await pumpControl(tester, field());
    expect(find.bySemanticsLabel(RegExp('A')), findsWidgets);
    handle.dispose();
  });
}
