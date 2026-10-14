import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('measured height, placeholder, typing', (tester) async {
    final controller = TextEditingController();
    String? submitted;
    await pumpControl(
      tester,
      SilicaTextField(
        controller: controller,
        placeholder: 'Name',
        width: 232,
        onSubmitted: (v) => submitted = v,
      ),
    );
    expect(tester.getSize(find.byType(SilicaTextField)), const Size(232, 26));
    expect(find.text('Name'), findsOneWidget);
    await tester.tap(find.byType(SilicaTextField));
    await tester.enterText(find.byType(EditableText), 'hello');
    await tester.pump();
    expect(controller.text, 'hello');
    expect(find.text('Name'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'hello');
  });

  testWidgets('focus ring when focused, none in an inactive window', (
    tester,
  ) async {
    final focus = FocusNode();
    await pumpControl(tester, SilicaTextField(focusNode: focus, width: 200));
    expect(ringFinder(), findsNothing);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.showCursor, isTrue);
    expect(editable.selectionColor, InputColors.light.selection);

    await pumpControl(
      tester,
      SilicaTextField(focusNode: focus, width: 200),
      active: false,
    );
    await tester.pumpAndSettle();
    expect(ringFinder(), findsNothing);
    final inactive = tester.widget<EditableText>(find.byType(EditableText));
    expect(inactive.showCursor, isFalse);
    expect(inactive.selectionColor, InputColors.light.selectionInactive);
  });

  testWidgets('dark colors', (tester) async {
    await pumpControl(tester, const SilicaTextField(width: 200), dark: true);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(FieldBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      InputColors.dark.fieldBackground,
    );
  });

  testWidgets('a disabled field is read-only', (tester) async {
    await pumpControl(tester, const SilicaTextField(enabled: false));
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.readOnly, isTrue);
    expect(editable.style.color, InputColors.light.placeholder);
  });

  testWidgets('secure field obscures and shows caps lock', (tester) async {
    final focus = FocusNode();
    await pumpControl(
      tester,
      SilicaTextField(
        secure: true,
        focusNode: focus,
        capsLockLabel: 'Caps Lock is on',
      ),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    focus.requestFocus();
    await tester.pump();
    expect(find.byKey(const ValueKey('capsLock')), findsNothing);
    await simulateKeyDownEvent(LogicalKeyboardKey.capsLock);
    await tester.pump();
    expect(find.byKey(const ValueKey('capsLock')), findsOneWidget);
    await simulateKeyUpEvent(LogicalKeyboardKey.capsLock);
    await simulateKeyDownEvent(LogicalKeyboardKey.capsLock);
    await simulateKeyUpEvent(LogicalKeyboardKey.capsLock);
    await tester.pump();
    expect(find.byKey(const ValueKey('capsLock')), findsNothing);
  });

  testWidgets('a text area is taller than one line', (tester) async {
    await pumpControl(
      tester,
      const SilicaTextField(maxLines: 4, minLines: 3, width: 200),
    );
    expect(
      tester.getSize(find.byType(SilicaTextField)).height,
      greaterThan(InputMetrics.fieldHeight),
    );
  });

  testWidgets('semantics: text field, obscured, labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpControl(
      tester,
      const SilicaTextField(secure: true, semanticLabel: 'Password'),
    );
    final node = tester.getSemantics(find.byType(SilicaTextField));
    expect(node.label, contains('Password'));
    expect(node.flagsCollection.isTextField, isTrue);
    expect(node.flagsCollection.isObscured, isTrue);
    handle.dispose();
  });
}
