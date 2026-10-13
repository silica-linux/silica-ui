import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  setUp(() {
    // Il vetro parla con il compositor: qui nessuno risponde.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(GlassRegistry.channel, (call) async => true);
  });

  test('righe da 24, separatori da 11, 5 pt sopra e sotto', () {
    const entries = [
      MenuAction('Nuova'),
      MenuDivider(),
      MenuAction('Chiudi', shortcut: '⌘W'),
    ];
    expect(menuRowTops(entries), [5, 29, 40]);
    expect(menuSize(entries).height, 5 + 24 + 11 + 24 + 5);
    expect(menuTextLeft(entries), 17);
    expect(menuTextLeft(const [MenuAction('A', checked: true)]), 29);
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
          onDismissed: () => log.add('chiuso'),
        ),
      ),
    );
    return log;
  }

  testWidgets(
    'la tastiera evidenzia e sceglie: lampeggio, azione, dissolvenza',
    (tester) async {
      final log = await openMenu(
        tester,
        (log) => [
          MenuAction('Annulla', onSelected: () => log.add('annulla')),
          const MenuAction('Ripeti', enabled: false),
          const MenuDivider(),
          MenuAction('Taglia', onSelected: () => log.add('taglia')),
        ],
      );
      await tester.pump();
      // ↓ salta la voce disattivata e il separatore.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 80));
      expect(log, ['taglia']);
      await tester.pump(const Duration(milliseconds: 250));
      expect(log, ['taglia', 'chiuso']);
    },
  );

  testWidgets('una lettera salta alla voce; Esc chiude senza scegliere', (
    tester,
  ) async {
    final log = await openMenu(
      tester,
      (log) => [
        MenuAction('Apri', onSelected: () => log.add('apri')),
        MenuAction(
          'Porta tutto in primo piano',
          onSelected: () => log.add('porta'),
        ),
      ],
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    expect(log, ['chiuso']);
  });

  testWidgets(
    'il sottomenu si apre dopo ~295 ms, 5 pt sovrapposto al menu madre',
    (tester) async {
      final log = await openMenu(
        tester,
        (log) => [
          const MenuAction('Primo'),
          MenuAction(
            'Recenti',
            submenu: [
              MenuAction('Documento', onSelected: () => log.add('doc')),
            ],
          ),
        ],
      );
      final size = menuSize(const [
        MenuAction('Primo'),
        MenuAction('Recenti', submenu: []),
      ]);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      // Sulla voce del sottomenu (seconda riga).
      await mouse.moveTo(const Offset(150, 31 + 5 + 24 + 12));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Documento'), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Documento'), findsOneWidget);
      final sub = tester.getTopLeft(find.text('Documento'));
      expect(sub.dx, closeTo(100 + size.width - 5 + 17, 1));
      // Clic sulla voce del sottomenu.
      await mouse.down(tester.getCenter(find.text('Documento')));
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 150));
      expect(log, ['doc']);
      await tester.pump(const Duration(milliseconds: 250));
      expect(log, ['doc', 'chiuso']);
    },
  );

  testWidgets(
    'con la punta il menu sta sopra: corpo 27 pt a sinistra, fondo 8 pt sopra',
    (tester) async {
      const entries = [MenuAction('Apri')];
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
      final text = tester.getTopLeft(find.text('Apri'));
      expect(text.dx, closeTo(500 - 27 + 17, 0.5));
      final panel = tester.getRect(find.byType(MenuPanel));
      expect(panel.bottom, 400 - 8);
      expect(panel.height, size.height);
    },
  );

  testWidgets('onRectsChanged: il sottomenu aperto entra nei rettangoli', (
    tester,
  ) async {
    final seen = <List<Rect>>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: const [
            MenuAction('Opzioni', submenu: [MenuAction('Rimuovi')]),
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
      seen.last.last.contains(tester.getCenter(find.text('Rimuovi'))),
      isTrue,
    );
  });

  testWidgets(
    'la punta che si sposta sposta il menu (la superficie si allunga)',
    (tester) async {
      const entries = [MenuAction('Apri')];
      Widget host(Offset tip) => Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(entries: entries, anchor: Offset.zero, tip: tip),
      );
      await tester.pumpWidget(host(const Offset(500, 100)));
      final before = tester.getRect(find.byType(MenuPanel));
      await tester.pumpWidget(host(const Offset(500, 400)));
      final after = tester.getRect(find.byType(MenuPanel));
      expect(after.top - before.top, 300);
      expect(find.text('Apri'), findsOneWidget);
    },
  );
}
