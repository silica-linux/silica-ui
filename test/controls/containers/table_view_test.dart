import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

const columns = [
  TableColumnSpec(id: 'name', label: 'Name', width: 200),
  TableColumnSpec(
    id: 'size',
    label: 'Size',
    width: 97,
    alignRight: true,
    descendingFirst: true,
  ),
];

class Node {
  Node(this.name, [this.children = const []]);
  final String name;
  final List<Node> children;
  bool open = false;
}

void main() {
  Widget table({
    required Set<int> selection,
    required ValueChanged<Set<int>> onSelection,
    String? sort,
    ValueChanged<String>? onSort,
    bool active = true,
    ValueChanged<int>? onActivate,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 500,
      height: 300,
      child: TableView<String>(
        columns: columns,
        rows: const ['alpha', 'beta', 'gamma', 'delta'],
        selection: selection,
        onSelectionChanged: onSelection,
        sortColumn: sort,
        onSort: onSort,
        active: active,
        onActivate: onActivate,
        cell: (context, row, column, style) => Text(
          column.id == 'name' ? row : '${row.length}',
          style: style.text(secondary: column.id != 'name'),
        ),
      ),
    ),
  );

  testWidgets('header and rows follow the measured geometry', (tester) async {
    await tester.pumpWidget(
      table(selection: const {}, onSelection: (_) {}, sort: 'name'),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('table header'))).height,
      29,
    );
    final first = tester.getRect(find.byKey(const ValueKey('table row 0')));
    expect(first.top, 29 + 4);
    expect(first.height, 20);
    expect(find.byKey(const ValueKey('table sort arrow')), findsOneWidget);
  });

  testWidgets('click, ⌘click, ⇧click and arrows select', (tester) async {
    var selection = <int>{};
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => table(
          selection: selection,
          onSelection: (s) => setState(() => selection = s),
        ),
      ),
    );
    await tester.tap(find.text('beta'));
    await tester.pump();
    expect(selection, {1});
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('delta'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(selection, {1, 2, 3});
    // A block: the middle row has no rounded corners, a line below.
    expect(find.byKey(const ValueKey('table selection 2')), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.tap(find.text('gamma'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(selection, {1, 3});
    await tester.tap(find.text('alpha'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selection, {1});
  });

  testWidgets('a header click sorts, Return activates', (tester) async {
    String? sorted;
    int? activated;
    await tester.pumpWidget(
      table(
        selection: const {2},
        onSelection: (_) {},
        onSort: (id) => sorted = id,
        onActivate: (i) => activated = i,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('table header size')));
    expect(sorted, 'size');
    await tester.tap(find.text('gamma'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, 2);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('dragging a header separator resizes the column', (tester) async {
    await tester.pumpWidget(table(selection: const {}, onSelection: (_) {}));
    final before = tester.getRect(
      find.byKey(const ValueKey('table header size')),
    );
    await tester.drag(
      find.byKey(const ValueKey('table edge name')),
      const Offset(40, 0),
    );
    await tester.pump();
    final after = tester.getRect(
      find.byKey(const ValueKey('table header size')),
    );
    expect(after.left, greaterThan(before.left + 20));
  });

  testWidgets('an outline shows triangles and nested rows', (tester) async {
    final root = [
      Node('folder', [Node('inner')]),
      Node('file'),
    ];
    List<(Node, int)> flatten() {
      final out = <(Node, int)>[];
      void walk(List<Node> nodes, int depth) {
        for (final n in nodes) {
          out.add((n, depth));
          if (n.open) walk(n.children, depth + 1);
        }
      }

      walk(root, 0);
      return out;
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.ltr,
          child: TableView<(Node, int)>(
            columns: columns,
            rows: flatten(),
            outline: OutlineDelegate(
              depth: (r) => r.$2,
              expandable: (r) => r.$1.children.isNotEmpty,
              expanded: (r) => r.$1.open,
              onToggle: (r, open) => setState(() => r.$1.open = open),
            ),
            cell: (context, row, column, style) =>
                Text(row.$1.name, style: style.text()),
          ),
        ),
      ),
    );
    expect(find.text('inner'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('table disclose 0')));
    await tester.pump();
    expect(find.text('inner'), findsNWidgets(2));
    final folder = tester.getTopLeft(find.text('folder').first);
    final inner = tester.getTopLeft(find.text('inner').first);
    expect(inner.dx - folder.dx, TableMetrics.indent);
  });

  test('inactive selection is gray', () {
    expect(TableColors.light.inactiveSelection, const Color(0xFFDCDCDC));
    expect(TableColors.dark.selection, const Color(0xFF0059D1));
  });
}
