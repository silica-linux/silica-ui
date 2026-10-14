import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

const labels = SearchFieldLabels(
  placeholder: 'Search',
  clear: 'Clear',
  recentsTitle: 'Recent Searches',
  clearRecents: 'Clear Recent Searches',
  noRecents: 'No Recent Searches',
);

void main() {
  testWidgets('toolbar field is 242 × 38 with the toolbar material', (
    tester,
  ) async {
    await pumpControl(
      tester,
      const SilicaSearchField(labels: labels, style: SearchFieldStyle.toolbar),
    );
    expect(tester.getSize(find.byType(SilicaSearchField)), const Size(242, 38));
    ToolbarFieldPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<ToolbarFieldPainter>()
        .single;
    expect(painter().fill, ToolbarColors.light.fill);
    await pumpControl(
      tester,
      const SilicaSearchField(labels: labels, style: SearchFieldStyle.toolbar),
      active: false,
    );
    expect(painter().fill, ToolbarColors.light.fillInactive);
  });

  testWidgets('window field is 28 tall, dark background', (tester) async {
    await pumpControl(
      tester,
      const SilicaSearchField(labels: labels, width: 205),
      dark: true,
    );
    expect(tester.getSize(find.byType(SilicaSearchField)), const Size(205, 28));
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SilicaSearchField),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      InputColors.dark.searchBackground,
    );
  });

  testWidgets('clear button appears with text and empties the field', (
    tester,
  ) async {
    final controller = TextEditingController();
    var cancelled = false;
    await pumpControl(
      tester,
      SilicaSearchField(
        labels: labels,
        controller: controller,
        width: 200,
        onCancel: () => cancelled = true,
      ),
    );
    expect(find.byKey(const ValueKey('searchClear')), findsNothing);
    await tester.tap(find.byType(SilicaSearchField));
    await tester.enterText(find.byType(EditableText), 'report');
    await tester.pump();
    expect(find.byKey(const ValueKey('searchClear')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('searchClear')));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(cancelled, isTrue);
  });

  testWidgets('Esc empties the field', (tester) async {
    final controller = TextEditingController(text: 'abc');
    final focus = FocusNode();
    await pumpControl(
      tester,
      SilicaSearchField(
        labels: labels,
        controller: controller,
        focusNode: focus,
        width: 200,
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('focus ring on focus', (tester) async {
    final focus = FocusNode();
    await pumpControl(
      tester,
      SilicaSearchField(labels: labels, focusNode: focus, width: 200),
    );
    expect(ringFinder(), findsNothing);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(ringFinder(), findsOneWidget);
  });

  testWidgets('magnifier opens the recents menu; choosing fills the field', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? submitted;
    await pumpControl(
      tester,
      SilicaSearchField(
        labels: labels,
        controller: controller,
        width: 220,
        recents: const ['invoice', 'holiday'],
        onSubmitted: (v) => submitted = v,
      ),
    );
    await click(tester, find.byKey(const ValueKey('searchRecents')));
    expect(find.byType(MenuHost), findsOneWidget);
    expect(find.text('holiday'), findsOneWidget);
    expect(find.text('Clear Recent Searches'), findsOneWidget);
    await click(tester, find.text('holiday'));
    expect(controller.text, 'holiday');
    expect(submitted, 'holiday');
    expect(find.byType(MenuHost), findsNothing);
  });

  testWidgets('tokens: menu switches the label, ⌫ removes the last', (
    tester,
  ) async {
    var tokens = const [
      SearchToken(label: 'Name', value: 'report', options: ['Name', 'All']),
    ];
    final focus = FocusNode();
    await tester.runAsync(() async {});
    Widget build() => StatefulBuilder(
      builder: (context, setState) => SilicaSearchField(
        labels: labels,
        width: 260,
        focusNode: focus,
        tokens: tokens,
        onTokensChanged: (t) => setState(() => tokens = t),
      ),
    );
    await pumpControl(tester, build());
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('report'), findsOneWidget);
    expect(
      tester.getSize(find.byType(SearchTokenChip)).height,
      InputMetrics.searchTokenHeight,
    );
    await click(tester, find.text('NAME'));
    await click(tester, find.text('All'));
    expect(tokens.single.label, 'All');
    expect(find.text('ALL'), findsOneWidget);

    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(tokens, isEmpty);
  });

  testWidgets('disabled: no clear button, read-only', (tester) async {
    await pumpControl(
      tester,
      SilicaSearchField(
        labels: labels,
        enabled: false,
        controller: TextEditingController(text: 'x'),
        width: 200,
      ),
    );
    expect(find.byKey(const ValueKey('searchClear')), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });
}
