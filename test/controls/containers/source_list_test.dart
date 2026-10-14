import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

const sections = [
  SourceListSection('Favorites', [
    SourceListItem(id: 'home', label: 'Home', accent: false),
    SourceListItem(
      id: 'docs',
      label: 'Documents',
      badge: '3',
      children: [SourceListItem(id: 'work', label: 'Work')],
    ),
  ]),
  SourceListSection('Locations', [SourceListItem(id: 'disk', label: 'Disk')]),
];

Widget host({
  required String? selected,
  required ValueChanged<SourceListItem> onSelect,
  bool active = true,
  Brightness brightness = Brightness.light,
}) => MediaQuery(
  data: MediaQueryData(platformBrightness: brightness),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 192,
        child: SourceList(
          sections: sections,
          selected: selected,
          onSelect: onSelect,
          active: active,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('rows sit at the measured pitch, selection 10 pt in', (
    tester,
  ) async {
    await tester.pumpWidget(host(selected: 'home', onSelect: (_) {}));
    final home = tester.getRect(find.byKey(const ValueKey('source home')));
    final docs = tester.getRect(find.byKey(const ValueKey('source docs')));
    expect(home.height, 32);
    expect(docs.top - home.top, 32);
    expect(home.center.dy, 68);
    final selection = tester.getRect(
      find.byKey(const ValueKey('source selection home')),
    );
    expect(selection.left, 10);
    expect(selection.width, 192 - 20);
    expect(find.byKey(const ValueKey('source badge docs')), findsOneWidget);
  });

  testWidgets('a click selects, arrows move the selection', (tester) async {
    String? selected = 'home';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => host(
          selected: selected,
          onSelect: (item) => setState(() => selected = item.id),
        ),
      ),
    );
    await tester.tap(find.text('Documents'));
    await tester.pump();
    expect(selected, 'docs');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, 'disk');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(selected, 'docs');
    // → expands the nested row.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Work'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, 'work');
  });

  testWidgets('the heading chevron collapses its section', (tester) async {
    await tester.pumpWidget(host(selected: null, onSelect: (_) {}));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('source heading Locations'))),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('source collapse Locations')));
    await tester.pumpAndSettle();
    expect(find.text('Disk'), findsNothing);
  });

  test('inactive and dark colors differ from active light', () {
    final a = SourceListColors.of(dark: false, active: true);
    final i = SourceListColors.of(dark: false, active: false);
    final d = SourceListColors.of(dark: true, active: true);
    expect(a.selection, const Color(0xFFD7D7D7));
    expect(i.selection, isNot(a.selection));
    expect(d.fill, const Color(0xFF2A2A2C));
  });
}
