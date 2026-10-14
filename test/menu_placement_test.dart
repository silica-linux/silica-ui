import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
  });

  const m = MenuMetrics.edgeMargin;
  const area = Size(800, 600);
  const size = Size(200, 100);

  group('placeMenu', () {
    test('fits: top-left corner at the pointer', () {
      final r = placeMenu(
        anchor: const Offset(100, 50),
        size: size,
        area: area,
      );
      expect(r, const Offset(100, 50) & size);
    });

    test('upwards: bottom edge at the anchor', () {
      final r = placeMenu(
        anchor: const Offset(100, 300),
        size: size,
        area: area,
        upwards: true,
      );
      expect(r.bottom, 300);
      expect(r.left, 100);
    });

    test('does not fit on the right: right edge at the pointer', () {
      final r = placeMenu(
        anchor: const Offset(700, 50),
        size: size,
        area: area,
      );
      expect(r.right, 700);
      expect(r.top, 50);
    });

    test('does not fit below: shifts up, keeping the margin', () {
      final r = placeMenu(
        anchor: const Offset(100, 580),
        size: size,
        area: area,
      );
      expect(r.left, 100);
      expect(r.bottom, area.height - m);
    });

    test('taller than the area: starts at top + margin', () {
      final r = placeMenu(
        anchor: const Offset(100, 200),
        size: const Size(200, 900),
        area: area,
        top: 31,
      );
      expect(r.top, 31 + m);
    });

    test('shifted menus never go above top', () {
      final r = placeMenu(
        anchor: const Offset(100, 590),
        size: const Size(200, 560),
        area: area,
        top: 31,
      );
      expect(r.top, 31 + m);
    });

    test('bottom-right corner: left of the pointer and shifted up', () {
      final r = placeMenu(
        anchor: const Offset(795, 595),
        size: size,
        area: area,
      );
      expect(r.right, 795);
      expect(r.bottom, area.height - m);
    });

    test('wider than the area: starts at the margin', () {
      final r = placeMenu(
        anchor: const Offset(100, 50),
        size: const Size(900, 100),
        area: area,
      );
      expect(r.left, m);
    });
  });

  group('placeSubmenu', () {
    final parent = const Offset(100, 50) & const Size(200, 150);

    test('to the right, overlapping by 5 pt, 5 pt above the row', () {
      final r = placeSubmenu(
        parent: parent,
        rowTop: 80,
        size: size,
        area: area,
      );
      expect(r.left, parent.right - MenuMetrics.submenuOverlap);
      expect(r.top, 80 - MenuMetrics.padding);
    });

    test('flips to the left of the parent, overlapping by 5 pt', () {
      final p = const Offset(650, 50) & const Size(200 - 50, 150);
      final r = placeSubmenu(parent: p, rowTop: 80, size: size, area: area);
      expect(r.right, p.left + MenuMetrics.submenuOverlap);
    });

    test('shifts up to stay on screen', () {
      final r = placeSubmenu(
        parent: parent,
        rowTop: 580,
        size: size,
        area: area,
      );
      expect(r.bottom, area.height - m);
      expect(r.left, parent.right - MenuMetrics.submenuOverlap);
    });
  });

  Future<List<Rect>> pumpHost(
    WidgetTester tester, {
    required List<MenuEntry> entries,
    required Offset anchor,
    bool upwards = false,
    Offset? tip,
    double top = 0,
  }) async {
    final seen = <List<Rect>>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: entries,
          anchor: anchor,
          upwards: upwards,
          tip: tip,
          top: top,
          onRectsChanged: seen.add,
        ),
      ),
    );
    await tester.pump();
    return seen.last;
  }

  const items = [MenuAction('New'), MenuAction('Open'), MenuAction('Close')];

  testWidgets('pointer fit: the menu opens at the pointer', (tester) async {
    final rects = await pumpHost(
      tester,
      entries: items,
      anchor: const Offset(100, 50),
    );
    expect(rects.single.topLeft, const Offset(100, 50));
    expect(
      tester.getRect(find.byType(MenuPanel)).topLeft,
      const Offset(100, 50),
    );
  });

  testWidgets('right edge: the menu opens to the left of the pointer', (
    tester,
  ) async {
    final rects = await pumpHost(
      tester,
      entries: items,
      anchor: const Offset(790, 50),
    );
    expect(rects.single.right, 790);
    expect(tester.getRect(find.byType(MenuPanel)).right, closeTo(790, 0.5));
  });

  testWidgets('bottom edge: the menu shifts up', (tester) async {
    final rects = await pumpHost(
      tester,
      entries: items,
      anchor: const Offset(100, 590),
    );
    expect(rects.single.bottom, 600 - m);
    expect(rects.single.left, 100);
  });

  testWidgets('taller than the area: stays below top', (tester) async {
    final many = [for (var i = 0; i < 40; i++) MenuAction('Item $i')];
    final rects = await pumpHost(
      tester,
      entries: many,
      anchor: const Offset(100, 300),
      top: 31,
    );
    expect(menuSize(many).height, greaterThan(600));
    expect(rects.single.top, 31 + m);
  });

  testWidgets('bottom-right corner', (tester) async {
    final rects = await pumpHost(
      tester,
      entries: items,
      anchor: const Offset(795, 595),
    );
    expect(rects.single.right, 795);
    expect(rects.single.bottom, 600 - m);
  });

  testWidgets('Dock tip menu near the right edge only clamps horizontally', (
    tester,
  ) async {
    final size = menuSize(items);
    final rects = await pumpHost(
      tester,
      entries: items,
      anchor: Offset.zero,
      tip: const Offset(790, 500),
    );
    final r = rects.single;
    expect(r.right, 800 - m);
    expect(r.width, size.width);
    // Vertical position is that of the tip, not moved.
    expect(r.bottom, 500 - MenuMetrics.tipHeight);
  });

  const sub = [MenuAction('Entry 0'), MenuAction('Entry 1')];
  final tallSub = [for (var i = 0; i < 20; i++) MenuAction('Entry $i')];

  Future<List<Rect>> openSubmenu(
    WidgetTester tester, {
    required List<MenuAction> submenu,
    required Offset anchor,
  }) async {
    final seen = <List<Rect>>[];
    final entries = [
      const MenuAction('Plain'),
      MenuAction('Recent', submenu: submenu),
    ];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: entries,
          anchor: anchor,
          onRectsChanged: seen.add,
        ),
      ),
    );
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    // On the second row, which opens the submenu.
    await mouse.moveTo(seen.last.first.topLeft + const Offset(10, 5 + 24 + 12));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    return seen.last;
  }

  testWidgets('submenu opens to the right of the parent', (tester) async {
    final rects = await openSubmenu(
      tester,
      submenu: sub,
      anchor: const Offset(100, 50),
    );
    expect(rects.length, 2);
    expect(rects[1].left, rects[0].right - MenuMetrics.submenuOverlap);
    expect(rects[1].top, rects[0].top + 5 + 24 - MenuMetrics.padding);
  });

  testWidgets('submenu flips to the left near the right edge', (tester) async {
    final rects = await openSubmenu(
      tester,
      submenu: sub,
      anchor: const Offset(600, 50),
    );
    expect(rects.length, 2);
    expect(rects[0].right + menuSize(sub).width, greaterThan(800 - m));
    expect(rects[1].right, rects[0].left + MenuMetrics.submenuOverlap);
    expect(tester.getRect(find.text('Entry 0')).left, lessThan(rects[0].left));
  });

  testWidgets('a tall submenu shifts up to stay on screen', (tester) async {
    final rects = await openSubmenu(
      tester,
      submenu: tallSub,
      anchor: const Offset(100, 200),
    );
    expect(rects.length, 2);
    expect(rects[1].bottom, 600 - m);
    expect(rects[1].left, rects[0].right - MenuMetrics.submenuOverlap);
  });
}
