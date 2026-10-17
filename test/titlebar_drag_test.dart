import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SilicaWindow.channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool sidebar,
    bool menu = false,
  }) async {
    tester.view.physicalSize = const Size(800, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final children = <Widget>[
      const AmalfiControlsPiece(),
      AmalfiToolbarPiece(
        child: SizedBox(
          key: const ValueKey('button'),
          width: 32,
          height: 28,
          child: AmalfiToolbarButton(
            icon: const AmalfiGlyph(AmalfiGlyphs.chevronDown, size: 16),
            semanticLabel: 'Back',
            onPressed: () => calls.add(const MethodCall('pressed')),
          ),
        ),
      ),
      const AmalfiSpacerPiece(),
      AmalfiTitlePiece(
        title: 'Title',
        subtitle: menu ? null : 'Subtitle',
        document: menu,
        onDocumentMenu: menu ? () => calls.add(const MethodCall('menu')) : null,
      ),
      const AmalfiSpacerPiece(),
    ];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AmalfiTheme(
          brightness: Brightness.light,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 800,
              child: WindowDragArea(
                child: sidebar
                    ? AmalfiToolbar.sidebarSection(children: children)
                    : AmalfiToolbar(children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> drag(WidgetTester tester, Offset at) async {
    final g = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
    await g.moveBy(const Offset(30, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final sidebar in [false, true]) {
    final name = sidebar ? 'sidebar section' : 'toolbar';
    testWidgets('$name: a drag on the title starts a move', (tester) async {
      await pump(tester, sidebar: sidebar);
      await drag(tester, tester.getCenter(find.text('Title')));
      expect(calls.map((c) => c.method), contains('startMove'));
    });

    testWidgets('$name: a drag on the subtitle starts a move', (tester) async {
      await pump(tester, sidebar: sidebar);
      await drag(tester, tester.getCenter(find.text('Subtitle')));
      expect(calls.map((c) => c.method), contains('startMove'));
    });

    testWidgets('$name: a drag on a gap starts a move', (tester) async {
      await pump(tester, sidebar: sidebar);
      await drag(tester, const Offset(300, 26));
      expect(calls.map((c) => c.method), contains('startMove'));
    });

    testWidgets('$name: a drag on a control does not', (tester) async {
      await pump(tester, sidebar: sidebar);
      await drag(
        tester,
        tester.getCenter(find.byKey(const ValueKey('button'))),
      );
      expect(calls.map((c) => c.method), isNot(contains('startMove')));
    });
  }

  testWidgets('a click on a control still works', (tester) async {
    await pump(tester, sidebar: false);
    await tester.tap(find.byKey(const ValueKey('button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls.map((c) => c.method), contains('pressed'));
  });
  testWidgets('a document title with a menu: click opens it, drag moves', (
    tester,
  ) async {
    await pump(tester, sidebar: false, menu: true);
    await tester.tap(find.text('Title'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls.map((c) => c.method), ['menu']);
    calls.clear();
    await drag(tester, tester.getCenter(find.text('Title')));
    expect(calls.map((c) => c.method), ['startMove']);
  });
  testWidgets('a subtitle wider than the title lines up at its leading edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AmalfiTheme(
          brightness: Brightness.light,
          child: Align(
            alignment: Alignment.topLeft,
            child: AmalfiTitlePiece(
              title: 'Inbox',
              subtitle: '12 messages, 3 unread',
            ),
          ),
        ),
      ),
    );
    final title = tester.getTopLeft(find.text('Inbox'));
    final subtitle = tester.getTopLeft(find.text('12 messages, 3 unread'));
    expect(subtitle.dx, title.dx);
  });
}
