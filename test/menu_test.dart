import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  setUp(() {
    // The glass talks to the compositor: here nobody answers.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
  });

  test('rows of 24, separators of 11, 5 pt above and below', () {
    const entries = [
      MenuAction('New'),
      MenuDivider(),
      MenuAction('Close', shortcut: '⌘W'),
    ];
    expect(menuRowTops(entries), [5, 29, 40]);
    expect(menuSize(entries).height, 5 + 24 + 11 + 24 + 5);
    expect(menuTextLeft(entries), 17);
    expect(menuTextLeft(const [MenuAction('A', checked: true)]), 29);
  });

  test('headers count as 13 pt items and sit on the item text', () {
    const label = 'Display content as';
    const withHeader = [MenuSection(label), MenuAction('Name', checked: true)];
    const asItem = [MenuAction(label), MenuAction('Name', checked: true)];
    // The same width it would have as a normal item (silica-reference SH-DK-25: 220 pt).
    expect(menuSize(withHeader).width, menuSize(asItem).width);
  });

  testWidgets('header aligned with the item text when there are checkmarks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MenuPanel(
            entries: [
              MenuSection('Sort by'),
              MenuAction('Name', checked: true),
            ],
            opaque: true,
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Sort by')).dx,
      tester.getTopLeft(find.text('Name')).dx,
    );
  });

  Future<List<String>> openMenu(
    WidgetTester tester,
    List<MenuEntry> Function(List<String> log) build,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: build(log),
          anchor: const Offset(100, 31),
          onDismissed: () => log.add('closed'),
        ),
      ),
    );
    return log;
  }

  testWidgets('the keyboard highlights and chooses: blink, action, fade', (
    tester,
  ) async {
    final log = await openMenu(
      tester,
      (log) => [
        MenuAction('Undo', onSelected: () => log.add('undo')),
        const MenuAction('Redo', enabled: false),
        const MenuDivider(),
        MenuAction('Cut', onSelected: () => log.add('cut')),
      ],
    );
    await tester.pump();
    // ↓ skips the disabled item and the separator.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, isEmpty);
    await tester.pump(const Duration(milliseconds: 80));
    expect(log, ['cut']);
    await tester.pump(const Duration(milliseconds: 250));
    expect(log, ['cut', 'closed']);
  });

  testWidgets('a letter jumps to the item; Esc closes without choosing', (
    tester,
  ) async {
    final log = await openMenu(
      tester,
      (log) => [
        MenuAction('Open', onSelected: () => log.add('open')),
        MenuAction('Put All in Front', onSelected: () => log.add('put')),
      ],
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    expect(log, ['closed']);
  });

  testWidgets(
    'the submenu opens after ~295 ms, overlapping the parent menu by 5 pt',
    (tester) async {
      final log = await openMenu(
        tester,
        (log) => [
          const MenuAction('First'),
          MenuAction(
            'Recent',
            submenu: [MenuAction('Document', onSelected: () => log.add('doc'))],
          ),
        ],
      );
      final size = menuSize(const [
        MenuAction('First'),
        MenuAction('Recent', submenu: []),
      ]);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      // On the submenu item (second row).
      await mouse.moveTo(const Offset(150, 31 + 5 + 24 + 12));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Document'), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Document'), findsOneWidget);
      final sub = tester.getTopLeft(find.text('Document'));
      expect(sub.dx, closeTo(100 + size.width - 5 + 17, 1));
      // Click on the submenu item.
      await mouse.down(tester.getCenter(find.text('Document')));
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 150));
      expect(log, ['doc']);
      await tester.pump(const Duration(milliseconds: 250));
      expect(log, ['doc', 'closed']);
    },
  );

  testWidgets(
    'with a tip the menu sits above: body 27 pt to the left, bottom 8 pt above',
    (tester) async {
      const entries = [MenuAction('Open')];
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MenuHost(
            entries: entries,
            anchor: Offset.zero,
            tip: Offset(500, 400),
          ),
        ),
      );
      final size = menuSize(entries);
      final text = tester.getTopLeft(find.text('Open'));
      expect(text.dx, closeTo(500 - 27 + 17, 0.5));
      final panel = tester.getRect(find.byType(MenuPanel));
      expect(panel.bottom, 400 - 8);
      expect(panel.height, size.height);
    },
  );

  testWidgets('onRectsChanged: the open submenu enters the rects', (
    tester,
  ) async {
    final seen = <List<Rect>>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: const [
            MenuAction('Options', submenu: [MenuAction('Remove')]),
          ],
          anchor: const Offset(100, 31),
          onRectsChanged: seen.add,
        ),
      ),
    );
    await tester.pump();
    expect(seen.length, 1);
    expect(seen.last.length, 1);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(const Offset(150, 31 + 5 + 12));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(seen.last.length, 2);
    expect(
      seen.last.last.contains(tester.getCenter(find.text('Remove'))),
      isTrue,
    );
  });

  testWidgets('a moving tip moves the menu (the surface stretches)', (
    tester,
  ) async {
    const entries = [MenuAction('Open')];
    Widget host(Offset tip) => Directionality(
      textDirection: TextDirection.ltr,
      child: MenuHost(entries: entries, anchor: Offset.zero, tip: tip),
    );
    await tester.pumpWidget(host(const Offset(500, 100)));
    final before = tester.getRect(find.byType(MenuPanel));
    await tester.pumpWidget(host(const Offset(500, 400)));
    final after = tester.getRect(find.byType(MenuPanel));
    expect(after.top - before.top, 300);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'dark appearance: light text from the system, Flutter glass in the window',
    (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.dark),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MenuHost(
              entries: [
                MenuAction('Open'),
                MenuAction('Close', enabled: false),
              ],
              anchor: Offset(10, 10),
              opaque: true,
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('in-window menu')),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.text('Open')).style?.color,
        MenuColors.dark.text,
      );
      expect(
        tester.widget<Text>(find.text('Close')).style?.color,
        MenuColors.dark.disabled,
      );
    },
  );

  test('the menu material on the reference gray (menubar.md)', () {
    void near(Color a, Color b) {
      for (final (x, y) in [(a.r, b.r), (a.g, b.g), (a.b, b.b)]) {
        expect((x - y).abs() * 255, lessThanOrEqualTo(3.01));
      }
    }

    const gray = Color(0xFF7A7B80);
    near(WindowGlassMaterial.thickLight.apply(gray), const Color(0xFFC7C8CD));
    near(WindowGlassMaterial.thickDark.apply(gray), const Color(0xFF6F7075));
    // On white the matrix saturates at 255: 3 levels above the measured `#fcfcfd`.
    near(
      WindowGlassMaterial.thickLight.apply(const Color(0xFFFFFFFF)),
      const Color(0xFFFCFCFD),
    );
  });

  testWidgets('in-window menu: Flutter glass, not Ossido glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: [MenuAction('Open')],
          anchor: Offset(10, 10),
          opaque: true,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('in-window menu')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
  });

  testWidgets('custom row: as high as it asks, closes the menu from its tap', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: [
            const MenuAction('Open'),
            MenuCustom(
              height: 25,
              width: 200,
              builder: (context, close) => GestureDetector(
                key: const ValueKey('circle'),
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: const SizedBox(width: 14, height: 14),
              ),
            ),
          ],
          anchor: const Offset(10, 10),
          onDismissed: () => closed = true,
        ),
      ),
    );
    expect(
      menuRowTops([
        const MenuAction('Open'),
        MenuCustom(height: 25, builder: (_, _) => const SizedBox()),
        const MenuAction('After'),
      ]),
      [5, 29, 54],
    );
    await tester.tap(find.byKey(const ValueKey('circle')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(closed, isTrue);
  });

  testWidgets(
    'tip up: the menu under the apex and the glass with the tip pointing up',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        GlassRegistry.channel,
        (call) async {
          calls.add(call);
          return true;
        },
      );
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MenuHost(
            entries: [MenuAction('Fill')],
            anchor: Offset.zero,
            tip: Offset(200, 100),
            tipUp: true,
          ),
        ),
      );
      await tester.pump();
      final panel = tester.getRect(find.byType(MenuPanel));
      expect(panel.top, 100 + MenuMetrics.tipHeight);
      expect(panel.left, 200 - MenuMetrics.tipBodyLeft);
      final regions = calls.last.arguments as List<Object?>;
      final tip = regions.cast<Map<Object?, Object?>>().firstWhere(
        (r) => r['shape'] == 'tip-up',
      );
      // The tip sits above the body, with the apex towards the given point.
      expect(
        (tip['y']! as num) + (tip['height']! as num),
        closeTo(panel.top, 0.5),
      );
      expect(
        (tip['x']! as num) + (tip['width']! as num) / 2,
        closeTo(200, 0.5),
      );
    },
  );
}
