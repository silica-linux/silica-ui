import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

Future<Color> pixel(WidgetTester tester, GlobalKey key, Offset at) async {
  late Color color;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final i = ((at.dy.round()) * image.width + at.dx.round()) * 4;
    color = Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  });
  return color;
}

void main() {
  const fill = Color(0xFF2A2A2C);

  Widget sidebar({
    required ScrollController controller,
    Widget? bar,
    Color row = const Color(0xFFF13710),
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: 200,
        height: 600,
        child: SidebarScrollUnderBar(
          background: fill,
          veil: ToolbarVeil.dark,
          bar: bar,
          body: (context, padding) => ListView(
            controller: controller,
            padding: padding,
            children: [
              const SizedBox(key: ValueKey('first row'), height: 32),
              // Far from the bar, out of reach of the wide blur at rest.
              const SizedBox(height: 400),
              Container(height: 2000, color: row),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'the list starts below the bar, which is as tall as the toolbar',
    (tester) async {
      tester.view.physicalSize = const Size(200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(sidebar(controller: ScrollController()));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('first row'))).dy,
        toolbarHeight,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('sidebar bar'))),
        const Rect.fromLTWH(0, 0, 200, toolbarHeight),
      );
      // No glass in the sidebar: a fade mask, no veil.
      expect(find.byKey(const ValueKey('sidebar fade')), findsOneWidget);
      expect(find.byKey(const ValueKey('sidebar bar veil')), findsNothing);
      expect(find.byKey(const ValueKey('toolbar veil')), findsNothing);
      // The bar moves the window.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sidebar bar')),
          matching: find.byType(WindowDragArea),
        ),
        findsOneWidget,
      );
    },
  );

  test('the fade mask has the measured values', () {
    const samples = {
      62: 1.0, 60: 0.97, 56: 0.86, 52: 0.74, 48: 0.63, 44: 0.48, //
      40: 0.36, 36: 0.25, 32: 0.17, 30: 0.14, 0: 0.14, 100: 1.0,
    };
    samples.forEach((y, v) {
      expect(
        SidebarFade.visibilityAt(y.toDouble()),
        closeTo(v, 0.015),
        reason: '+$y',
      );
    });
    // Linear between the samples, constant above 62 and below 30.
    expect(SidebarFade.visibilityAt(46), closeTo(0.555, 0.01));
    expect(SidebarFade.visibilityAt(10), 0.14);
    expect(SidebarFade.blurAt(0), 2);
    expect(SidebarFade.blurAt(32), 2);
    expect(SidebarFade.blurAt(44), 1);
    expect(SidebarFade.blurAt(52), 0);
    expect(SidebarFade.blurAt(62), 0);
  });

  testWidgets(
    'at rest nothing is faded; scrolled, rows fade to 14 % under the bar, no tint',
    (tester) async {
      tester.view.physicalSize = const Size(200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      final controller = ScrollController();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: sidebar(controller: controller),
        ),
      );
      // The bar shows the sidebar fill unchanged.
      final rest = await pixel(tester, key, const Offset(150, 26));
      expect(rest.r * 255, closeTo(0x2A, 1));
      expect(rest.b * 255, closeTo(0x2C, 1));
      // Scrolled: the red slab is under the whole bar.
      controller.jumpTo(800);
      await tester.pump();
      const red = Color(0xFFF13710);
      double lift(Color c) => (c.r * 255 - 0x2A) / (0xF1 - 0x2A);
      // Above +62 the rows are untouched.
      expect(
        await pixel(tester, key, const Offset(150, 300)),
        isSameColorAs(red),
      );
      expect(
        lift(await pixel(tester, key, const Offset(150, 70))),
        closeTo(1, 0.02),
      );
      // Band: 14 % of the row over the sidebar colour (blur does not change a flat slab).
      expect(
        lift(await pixel(tester, key, const Offset(150, 20))),
        closeTo(0.14, 0.02),
      );
      expect(
        lift(await pixel(tester, key, const Offset(150, 52))),
        closeTo(0.74, 0.03),
      );
      expect(
        lift(await pixel(tester, key, const Offset(150, 44))),
        closeTo(0.48, 0.03),
      );
      // No tint: the fade only mixes the row with the sidebar colour.
      final band = await pixel(tester, key, const Offset(150, 10));
      expect(band.g * 255, closeTo(0x2A + 0.14 * (0x37 - 0x2A), 2));
    },
  );

  testWidgets('bar items sit over the rows and show them at their edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      sidebar(
        controller: ScrollController(),
        bar: Align(
          alignment: Alignment.centerRight,
          child: ToolbarCapsule(
            children: [ToolbarSegment(icon: (c) => const SizedBox())],
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ToolbarCapsule),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the layout slides the sidebar out and widens the content', (
    tester,
  ) async {
    Widget layout(double shown) => Directionality(
      textDirection: TextDirection.ltr,
      child: SidebarLayout(
        width: 200,
        shown: shown,
        sidebar: const SizedBox.expand(key: ValueKey('sidebar')),
        content: const SizedBox.expand(key: ValueKey('content')),
      ),
    );
    await tester.pumpWidget(layout(1));
    expect(tester.getRect(find.byKey(const ValueKey('sidebar'))).left, 0);
    expect(tester.getRect(find.byKey(const ValueKey('content'))).left, 200);
    await tester.pumpWidget(layout(0.5));
    expect(tester.getRect(find.byKey(const ValueKey('sidebar'))).left, -100);
    expect(tester.getRect(find.byKey(const ValueKey('sidebar'))).width, 200);
    expect(tester.getRect(find.byKey(const ValueKey('content'))).left, 100);
    await tester.pumpWidget(layout(0));
    expect(find.byKey(const ValueKey('sidebar')), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('content'))).left, 0);
    expect(SidebarLayout.contentLeadingInset(0), windowButtonsRight);
    expect(SidebarLayout.contentLeadingInset(200), 0);
  });
}
