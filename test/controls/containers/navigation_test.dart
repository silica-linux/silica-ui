import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/src/controls/containers/containers.dart';

Widget app(Widget child, {Brightness brightness = Brightness.light}) =>
    MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  group('scroller', () {
    testWidgets('legacy is always visible, overlay only while scrolling', (
      tester,
    ) async {
      final controller = ScrollController();
      Widget list(ScrollerStyle style) => app(
        SilicaScrollbar(
          style: style,
          controller: controller,
          child: ListView(
            controller: controller,
            children: [for (var i = 0; i < 100; i++) SizedBox(height: 20)],
          ),
        ),
      );
      await tester.pumpWidget(list(ScrollerStyle.legacy));
      final legacy = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(legacy.thumbVisibility, isTrue);
      expect(legacy.thickness, ScrollerMetrics.track);
      expect(legacy.crossAxisMargin, ScrollerMetrics.margin);
      await tester.pumpWidget(list(ScrollerStyle.overlay));
      final overlay = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(overlay.thumbVisibility, isFalse);
      expect(overlay.thickness, ScrollerMetrics.thinThumb);
      // The pointer over it: the full track.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400, 300));
      await gesture.moveTo(const Offset(790, 300));
      await tester.pump();
      expect(
        tester.widget<RawScrollbar>(find.byType(RawScrollbar)).thickness,
        ScrollerMetrics.track,
      );
    });

    test('measured colors', () {
      expect(ScrollerColors.light.track, const Color(0xFFF3F3F3));
      expect(ScrollerColors.dark.thumb, const Color(0xFFA2A2A2));
    });
  });

  group('split view', () {
    test('the sidebar behavior snaps and hides', () {
      const b = SplitBehavior.sidebar;
      expect(b.dragSize(30, 1000), 0);
      expect(b.dragSize(100, 1000), 135);
      expect(b.dragSize(900, 1000), 1000 - 316);
      expect(b.releaseSize(195), 200);
      expect(b.releaseSize(250), 250);
    });

    testWidgets('dragging the divider resizes, double click collapses', (
      tester,
    ) async {
      double? reported;
      await tester.pumpWidget(
        app(
          SplitView(
            leading: const SizedBox.expand(key: ValueKey('left')),
            trailing: const SizedBox.expand(key: ValueKey('right')),
            initialSize: 200,
            behavior: SplitBehavior.sidebar,
            onSizeChanged: (s) => reported = s,
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('left'))).width, 200);
      await tester.drag(
        find.byKey(const ValueKey('split divider')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      expect(reported, closeTo(280, 1));
      expect(tester.getSize(find.byKey(const ValueKey('left'))).width, 280);
      final divider = find.byKey(const ValueKey('split divider'));
      await tester.tap(divider);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(divider);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('right'))).dx,
        closeTo(0, 0.5),
      );
    });

    testWidgets('the thick divider has its dot', (tester) async {
      await tester.pumpWidget(
        app(
          const SplitView(
            axis: Axis.vertical,
            divider: SplitDividerStyle.thick,
            leading: SizedBox.expand(key: ValueKey('top')),
            trailing: SizedBox.expand(key: ValueKey('bottom')),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('bottom'))).dy,
        200 + SplitView.thick,
      );
    });
  });

  group('tabs', () {
    testWidgets('window tabs select, close and add', (tester) async {
      var active = 0;
      final titles = ['One', 'Two', 'Three'];
      var added = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => app(
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 600,
                child: WindowTabBar(
                  titles: titles,
                  active: active,
                  onSelect: (i) => setState(() => active = i),
                  onClose: (i) => setState(() => titles.removeAt(i)),
                  onNew: () => added = true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('window tab bar'))).height,
        36,
      );
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(active, 1);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Three')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('window tab close 2')));
      await tester.pump();
      expect(titles, ['One', 'Two']);
      await tester.tap(find.byKey(const ValueKey('window tab new')));
      expect(added, isTrue);
    });

    testWidgets('the tab view switches with clicks and arrows', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => app(
            SilicaTabView(
              labels: const ['Text', 'Window', 'Shell'],
              selected: selected,
              onSelect: (i) => setState(() => selected = i),
              page: Text('page $selected'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Window'));
      await tester.pump();
      expect(find.text('page 1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected, 2);
    });
  });

  group('collection view', () {
    testWidgets('columns fill the width, the selection follows arrows', (
      tester,
    ) async {
      var selection = <int>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => app(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 783,
                child: CollectionView<int>(
                  items: [for (var i = 0; i < 20; i++) i],
                  icon: (context, item, size) => const SizedBox.expand(),
                  label: (i) => 'Item $i',
                  selection: selection,
                  onSelectionChanged: (s) => setState(() => selection = s),
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.getRect(
        find.byKey(const ValueKey('collection item 0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('collection item 1')),
      );
      final below = tester.getRect(
        find.byKey(const ValueKey('collection item 6')),
      );
      // 783 / 112 → 6 columns at a 130.5 pitch, 116 pt rows.
      expect(second.center.dx - first.center.dx, closeTo(783 / 6, 0.01));
      expect(below.top - first.top, 116);
      await tester.tap(find.text('Item 1'));
      await tester.pump();
      expect(selection, {1});
      expect(
        tester.getSize(find.byKey(const ValueKey('collection selection 1'))),
        const Size(72, 72),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selection, {7});
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('path control', () {
    test('middle segments shrink first, the last stays whole', () {
      final widths = pathControlWidths([80, 100, 100, 100, 90], 360);
      expect(widths.last, 90);
      expect(widths[0], 80);
      expect(widths.fold(0.0, (a, b) => a + b), closeTo(360, 1));
      expect(widths[1], widths[2]);
    });

    testWidgets('a click reports the segment', (tester) async {
      int? opened;
      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: 500,
              child: PathControl(
                items: const [
                  PathItem('Disk'),
                  PathItem('Users'),
                  PathItem('me'),
                ],
                onSelect: (i) => opened = i,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('path control'))).height,
        28,
      );
      await tester.tap(find.text('Users'));
      expect(opened, 1);
    });
  });
}
