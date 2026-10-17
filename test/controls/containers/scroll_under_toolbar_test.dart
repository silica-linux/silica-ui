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
  test('the veil presets are the measured bars', () {
    const light = ToolbarVeil.light, dark = ToolbarVeil.dark;
    // Light: opaque white, whatever is under it.
    expect(
      light.apply(const Color(0xFFF13710)),
      isSameColorAs(const Color(0xFFFFFFFF)),
    );
    expect(
      light.apply(const Color(0xFF000000)),
      isSameColorAs(const Color(0xFFFFFFFF)),
    );
    // Dark: 23 % of the content over a 40 lift: 39 → ~49, white → ~99.
    expect(dark.scale, 0.23);
    expect(dark.apply(const Color(0xFF272728)).r * 255, closeTo(49, 1.5));
    expect(dark.apply(const Color(0xFFFFFFFF)).r * 255, closeTo(99, 1.5));
    expect(dark.sharpSigma, inInclusiveRange(4, 5));
  });

  Widget darkWindow(ScrollController controller, {bool active = true}) =>
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF272728),
          child: ScrollUnderToolbar(
            veil: ToolbarVeil.dark,
            active: active,
            toolbar: const SizedBox(),
            body: (context, padding) => ListView(
              controller: controller,
              padding: padding,
              children: [
                Container(height: 2000, color: const Color(0xFFFFFFFF)),
              ],
            ),
          ),
        ),
      );

  testWidgets('dark: invisible at rest, then the content shows at 23 %', (
    tester,
  ) async {
    final key = GlobalKey();
    final controller = ScrollController();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: darkWindow(controller)),
    );
    // At rest: no veil, the band is the body (the white slab starts below it).
    expect(find.byKey(const ValueKey('toolbar veil')), findsNothing);
    expect(
      (await pixel(tester, key, const Offset(400, 26))).r * 255,
      closeTo(0x27, 1),
    );
    controller.jumpTo(300);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar veil')), findsOneWidget);
    // White slab under the bar: 0.23 · 255 + 40 ≈ 99.
    expect(
      (await pixel(tester, key, const Offset(400, 26))).r * 255,
      closeTo(99, 3),
    );
    // Hard edge: just below the band the slab is untouched.
    expect(
      await pixel(tester, key, const Offset(400, 60)),
      isSameColorAs(const Color(0xFFFFFFFF)),
    );
    controller.jumpTo(0);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar veil')), findsNothing);
  });

  Widget window({
    required ScrollController controller,
    bool active = true,
    Widget toolbar = const SizedBox(),
    Color content = const Color(0xFFF13710),
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: ScrollUnderToolbar(
        veil: ToolbarVeil.light,
        active: active,
        toolbar: toolbar,
        body: (context, padding) => ListView(
          controller: controller,
          padding: padding,
          children: [Container(height: 2000, color: content)],
        ),
      ),
    ),
  );

  testWidgets('light: invisible at rest, then opaque white with a line', (
    tester,
  ) async {
    final key = GlobalKey();
    final controller = ScrollController();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: window(controller: controller),
      ),
    );
    expect(find.byKey(const ValueKey('toolbar veil')), findsNothing);
    controller.jumpTo(300);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar veil')), findsOneWidget);
    // The red content is not visible at all under the bar.
    expect(
      await pixel(tester, key, const Offset(400, 26)),
      isSameColorAs(const Color(0xFFFFFFFF)),
    );
    expect(
      await pixel(tester, key, const Offset(400, 300)),
      isSameColorAs(const Color(0xFFF13710)),
    );
    // The 1 pt line at the edge (y 52): black at 10 %, white → 229.
    final line = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('toolbar line')),
    );
    expect(line.color, ToolbarVeil.light.line);
    expect(255 * (1 - line.color.a), closeTo(229, 1));
    expect(
      tester.getRect(find.byKey(const ValueKey('toolbar line'))).top,
      toolbarHeight,
    );
  });

  testWidgets('the line under the band appears once the content scrolls', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(window(controller: controller));
    expect(find.byKey(const ValueKey('toolbar line')), findsNothing);
    controller.jumpTo(10);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar line')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('toolbar line'))).top,
      toolbarHeight,
    );
    controller.jumpTo(0);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar line')), findsNothing);
  });

  testWidgets('an inactive window keeps the line', (tester) async {
    await tester.pumpWidget(
      window(controller: ScrollController(), active: false),
    );
    expect(find.byKey(const ValueKey('toolbar line')), findsOneWidget);
  });

  testWidgets('showLine: false never draws the line', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ScrollUnderToolbar(
          veil: ToolbarVeil.light,
          active: false,
          showLine: false,
          toolbar: const SizedBox(),
          body: (context, padding) => ListView(
            controller: controller,
            padding: padding,
            children: const [SizedBox(height: 2000)],
          ),
        ),
      ),
    );
    controller.jumpTo(10);
    await tester.pump();
    expect(find.byKey(const ValueKey('toolbar line')), findsNothing);
  });

  testWidgets(
    'a nested vertical list moves the line with the any-depth predicate',
    (tester) async {
      Widget nested(
        bool Function(ScrollMetrics, int) predicate,
        ScrollController c,
      ) => Directionality(
        textDirection: TextDirection.ltr,
        child: ScrollUnderToolbar(
          veil: ToolbarVeil.light,
          active: true,
          scrollPredicate: predicate,
          toolbar: const SizedBox(),
          body: (context, padding) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 300,
              height: 600,
              child: ListView(
                controller: c,
                padding: padding,
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      final a = ScrollController();
      await tester.pumpWidget(nested(defaultScrollUnderPredicate, a));
      a.jumpTo(10);
      await tester.pump();
      expect(find.byKey(const ValueKey('toolbar line')), findsNothing);
      final b = ScrollController();
      await tester.pumpWidget(nested(anyVerticalScrollUnderPredicate, b));
      // The new controller takes over the old position (10): move it further.
      b.jumpTo(20);
      await tester.pump();
      expect(find.byKey(const ValueKey('toolbar line')), findsOneWidget);
    },
  );

  testWidgets('the body starts below the band, header included', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ScrollUnderToolbar(
          toolbar: const SizedBox(),
          header: const SizedBox.expand(key: ValueKey('header')),
          headerHeight: 28,
          body: (context, padding) => ListView(
            padding: padding,
            children: const [SizedBox(key: ValueKey('first'), height: 20)],
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('first'))).dy, 80);
    expect(tester.getRect(find.byKey(const ValueKey('header'))).top, 52);
  });

  testWidgets('capsules over content show it at their edges', (tester) async {
    Widget capsule() => ToolbarCapsule(
      children: [ToolbarSegment(icon: (c) => const SizedBox())],
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: capsule()),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(
      window(
        controller: ScrollController(),
        toolbar: Center(child: capsule()),
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

  test('an anchored veil leaves the content background unchanged (#87)', () {
    const background = Color(0xFF1B1C1F);
    expect(ToolbarVeil.dark.apply(background), isNot(background));
    expect(
      ToolbarVeil.dark.anchoredTo(background).apply(background),
      background,
    );
  });
}
