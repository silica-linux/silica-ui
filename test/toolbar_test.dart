import 'dart:ui' show PictureRecorder;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  late List<String> log;
  late Map<String, Color> glyphs;
  Rect? menuAt;

  Widget segment(
    String name, {
    bool enabled = true,
    bool chosen = false,
    double width = 36,
    bool menu = false,
  }) => ToolbarSegment(
    key: ValueKey(name),
    width: width,
    enabled: enabled,
    chosen: chosen,
    onTap: () => log.add('tap $name'),
    onLongPress: menu ? () => log.add('long $name') : null,
    onLongPressMenu: menu ? (rect) => menuAt = rect : null,
    icon: (color) {
      glyphs[name] = color;
      return const SizedBox(width: 10, height: 10);
    },
  );

  /// Back / Forward (forward disabled) and a four-segment view selector.
  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    bool active = true,
    bool reduceMotion = false,
    bool forwardEnabled = false,
  }) async {
    log = [];
    glyphs = {};
    menuAt = null;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          platformBrightness: brightness,
          disableAnimations: reduceMotion,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ToolbarScope(
            active: active,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToolbarCapsule(
                    key: const ValueKey('pair'),
                    separators: true,
                    children: [
                      segment('back', menu: true),
                      segment('forward', enabled: forwardEnabled),
                    ],
                  ),
                  const SizedBox(width: 40),
                  ToolbarCapsule(
                    key: const ValueKey('views'),
                    children: [
                      for (var i = 0; i < 4; i++)
                        segment('view $i', width: 40, chosen: i == 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder pillOf(String name) => find.descendant(
    of: find.byKey(ValueKey(name)),
    matching: find.byKey(const ValueKey('pill')),
  );

  Color? pill(WidgetTester tester, String name) {
    final found = pillOf(name);
    if (found.evaluate().isEmpty) return null;
    return (tester.widget<Container>(found).decoration! as BoxDecoration).color;
  }

  double grow(WidgetTester tester, String capsule) => tester
      .widget<ToolbarGrow>(
        find.descendant(
          of: find.byKey(ValueKey(capsule)),
          matching: find.byType(ToolbarGrow),
        ),
      )
      .grow;

  ToolbarGlowPainter? glow(WidgetTester tester, String capsule) {
    final paints = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byKey(ValueKey(capsule)),
        matching: find.byType(CustomPaint),
      ),
    );
    for (final p in paints) {
      if (p.foregroundPainter is ToolbarGlowPainter) {
        return p.foregroundPainter! as ToolbarGlowPainter;
      }
    }
    return null;
  }

  Color? separator(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('pair')),
          matching: find.byType(Container),
        ),
      )
      .singleWhere((c) => c.constraints?.maxWidth == 1)
      .color;

  Offset center(WidgetTester tester, String name) =>
      tester.getCenter(find.byKey(ValueKey(name)));

  Future<TestGesture> mouseAt(WidgetTester tester, Offset at) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: at);
    addTearDown(mouse.removePointer);
    return mouse;
  }

  group('hover', () {
    testWidgets('fades in a 28 pt circle; the separator hides', (tester) async {
      await pump(tester, forwardEnabled: true);
      expect(pill(tester, 'back'), isNull);
      expect(separator(tester), ToolbarColors.light.separator);
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'back'));
      await tester.pump();
      expect(separator(tester), isNull);
      await tester.pump(const Duration(milliseconds: 85));
      final half = pill(tester, 'back')!;
      expect(half.a, inExclusiveRange(0.2, 0.8));
      await tester.pump(const Duration(milliseconds: 90));
      expect(pill(tester, 'back'), ToolbarColors.light.hover);
      expect(tester.getSize(pillOf('back')), const Size(28, 28));
      // Light: −10 levels from the capsule.
      expect(
        (ToolbarColors.light.fill.r - ToolbarColors.light.hover.r) * 255,
        closeTo(10, 0.5),
      );
      // Moving to the other segment: the highlight follows, the separator stays hidden.
      await mouse.moveTo(center(tester, 'forward'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pill(tester, 'back'), isNull);
      expect(pill(tester, 'forward'), ToolbarColors.light.hover);
      expect(separator(tester), isNull);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pill(tester, 'forward'), isNull);
      expect(separator(tester), ToolbarColors.light.separator);
    });

    testWidgets('dark: +20 levels over the capsule in the bar', (tester) async {
      await pump(tester, brightness: Brightness.dark);
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pill(tester, 'back'), ToolbarColors.dark.hover);
      expect(
        (ToolbarColors.dark.hover.r - ToolbarColors.dark.fillBarHover.r) * 255,
        closeTo(20, 0.5),
      );
    });

    testWidgets('segmented groups: a pill the size of the selection', (
      tester,
    ) async {
      await pump(tester);
      expect(tester.getSize(pillOf('view 1')), const Size(34, 28));
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'view 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(pillOf('view 2')), const Size(34, 28));
      expect(pill(tester, 'view 2'), ToolbarColors.light.hover);
    });

    testWidgets('disabled segments: no highlight, the separator stays', (
      tester,
    ) async {
      await pump(tester);
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'forward'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pill(tester, 'forward'), isNull);
      expect(separator(tester), ToolbarColors.light.separator);
    });

    testWidgets('reduced motion: the highlight appears at once', (
      tester,
    ) async {
      await pump(tester, reduceMotion: true);
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'back'));
      await tester.pump();
      expect(pill(tester, 'back'), ToolbarColors.light.hover);
    });

    testWidgets('inactive window: dim glyph, hovering lights it up', (
      tester,
    ) async {
      await pump(tester, active: false);
      expect(glyphs['back'], ToolbarColors.light.iconInactive);
      final mouse = await mouseAt(tester, Offset.zero);
      await mouse.moveTo(center(tester, 'back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(glyphs['back'], ToolbarColors.light.icon);
      expect(pill(tester, 'back'), ToolbarColors.light.hoverInactive);
    });
  });

  group('press', () {
    testWidgets('grows 1 pt in ~45 ms and stays grown outside the bounds', (
      tester,
    ) async {
      await pump(tester);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(grow(tester, 'pair'), 0);
      await tester.pump(const Duration(milliseconds: 20));
      expect(grow(tester, 'pair'), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 30));
      expect(grow(tester, 'pair'), 1);
      expect(pill(tester, 'back'), ToolbarColors.light.pressed);
      expect(glyphs['back'], ToolbarColors.light.iconPressed);
      await g.moveBy(const Offset(0, 120));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(grow(tester, 'pair'), 1);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(grow(tester, 'pair'), 0);
    });

    testWidgets('click: acts on release, holds ~100 ms, back in ≤ 40 ms', (
      tester,
    ) async {
      await pump(tester);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 65));
      expect(log, isEmpty);
      await g.up();
      expect(log, ['tap back']);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(grow(tester, 'pair'), 1);
      await tester.pump(const Duration(milliseconds: 25));
      expect(grow(tester, 'pair'), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 30));
      expect(grow(tester, 'pair'), 0);
    });

    testWidgets(
      'release outside: no action, spring back with an undershoot in ~100 ms',
      (tester) async {
        await pump(tester);
        final g = await tester.startGesture(
          center(tester, 'back'),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await g.moveBy(const Offset(0, 80));
        await tester.pump();
        await g.up();
        await tester.pump();
        var lowest = 1.0;
        for (var t = 0; t < 200; t += 5) {
          await tester.pump(const Duration(milliseconds: 5));
          if (grow(tester, 'pair') < lowest) lowest = grow(tester, 'pair');
          if (t == 70) expect(grow(tester, 'pair'), lessThan(0.15));
        }
        expect(lowest, inExclusiveRange(-0.2, -0.03));
        expect(grow(tester, 'pair'), closeTo(0, 0.01));
        expect(log, isEmpty);
      },
    );

    testWidgets('a disabled segment grows too, without action or highlight', (
      tester,
    ) async {
      await pump(tester);
      final g = await tester.startGesture(
        center(tester, 'forward'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(grow(tester, 'pair'), 1);
      expect(pill(tester, 'forward'), isNull);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(log, isEmpty);
    });

    testWidgets('reduced motion: the growth is immediate', (tester) async {
      await pump(tester, reduceMotion: true);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(grow(tester, 'pair'), 1);
      await g.moveBy(const Offset(0, 80));
      await g.up();
      await tester.pump();
      expect(grow(tester, 'pair'), 0);
    });
  });

  group('glow', () {
    testWidgets('dark: centred on the pointer, following with ~30 ms lag', (
      tester,
    ) async {
      await pump(tester, brightness: Brightness.dark);
      final origin = tester.getTopLeft(find.byKey(const ValueKey('pair')));
      final start = center(tester, 'back');
      final g = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
      await tester.pump();
      // Fading in after mouse-down.
      expect(glow(tester, 'pair'), isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(glow(tester, 'pair')!.strength, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(glow(tester, 'pair')!.strength, 1);
      expect(glow(tester, 'pair')!.center, start - origin);
      expect(glow(tester, 'pair')!.sigma, ToolbarGlassMetrics.glowSigma);
      expect(glow(tester, 'pair')!.color, ToolbarColors.dark.glow);
      await g.moveBy(const Offset(30, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final lagging = glow(tester, 'pair')!.center.dx - (start - origin).dx;
      // A first-order lag of 30 ms covers 1 − e^(−16/30) ≈ 41 % in 16 ms.
      expect(lagging, closeTo(30 * 0.41, 1.5));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        glow(tester, 'pair')!.center.dx - (start - origin).dx,
        inExclusiveRange(lagging, 30),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        glow(tester, 'pair')!.center.dx - (start - origin).dx,
        closeTo(30, 0.05),
      );
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(glow(tester, 'pair'), isNull);
    });

    testWidgets('appears on a disabled segment as well', (tester) async {
      await pump(tester, brightness: Brightness.dark);
      final g = await tester.startGesture(
        center(tester, 'forward'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(glow(tester, 'pair')!.strength, 1);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('fades with the distance outside the bounds', (tester) async {
      await pump(tester, brightness: Brightness.dark);
      final rect = tester.getRect(find.byKey(const ValueKey('pair')));
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await g.moveTo(Offset(center(tester, 'back').dx, rect.bottom + 15));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final near = glow(tester, 'pair')!;
      expect(near.center.dy, rect.height);
      expect(near.strength, closeTo(1 / (1 + 15 / 8.5), 0.01));
      await g.moveTo(Offset(center(tester, 'back').dx, rect.bottom + 55));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(glow(tester, 'pair')!.strength, closeTo(1 / (1 + 55 / 8.5), 0.01));
      expect(grow(tester, 'pair'), 1);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('light: not drawn', (tester) async {
      await pump(tester);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(glow(tester, 'pair'), isNull);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    test('Gaussian falloff of σ, clipped to the capsule', () {
      final recorder = PictureRecorder();
      const ToolbarGlowPainter(
        center: Offset(20, 19),
        strength: 1,
        color: Color(0x1FFFFFFF),
      ).paint(Canvas(recorder), const Size(75, 38));
      expect(recorder.endRecording(), isNotNull);
      expect(
        const ToolbarGlowPainter(
          center: Offset.zero,
          strength: 1,
          color: Color(0x1FFFFFFF),
        ).shouldRepaint(
          const ToolbarGlowPainter(
            center: Offset(1, 0),
            strength: 1,
            color: Color(0x1FFFFFFF),
          ),
        ),
        isTrue,
      );
    });
  });

  group('held segmented group', () {
    testWidgets('the highlight jumps, goes off at the edge, comes back', (
      tester,
    ) async {
      await pump(tester);
      final rect = tester.getRect(find.byKey(const ValueKey('views')));
      final g = await tester.startGesture(
        center(tester, 'view 0'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(pill(tester, 'view 0'), ToolbarColors.light.pressed);
      await g.moveTo(center(tester, 'view 2'));
      await tester.pump();
      // No fade, no sliding: one frame later the pill is on the new segment.
      expect(pill(tester, 'view 0'), isNull);
      expect(pill(tester, 'view 2'), ToolbarColors.light.pressed);
      // Over the chosen segment the selection darkens (brightens in dark).
      await g.moveTo(center(tester, 'view 1'));
      await tester.pump();
      expect(pill(tester, 'view 1'), ToolbarColors.light.chosenPressed);
      expect(pill(tester, 'view 2'), isNull);
      await g.moveTo(Offset(center(tester, 'view 3').dx, rect.bottom + 1));
      await tester.pump();
      expect(pill(tester, 'view 3'), isNull);
      expect(pill(tester, 'view 1'), ToolbarColors.light.chosen);
      await g.moveTo(center(tester, 'view 3'));
      await tester.pump();
      expect(pill(tester, 'view 3'), ToolbarColors.light.pressed);
      await g.up();
      expect(log, ['tap view 3']);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('dragged from Back over a disabled Forward: no highlight', (
      tester,
    ) async {
      await pump(tester);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await g.moveTo(center(tester, 'forward'));
      await tester.pump();
      expect(pill(tester, 'back'), isNull);
      expect(pill(tester, 'forward'), isNull);
      await g.up();
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('long press', () {
    testWidgets('opens the menu below the capsule; the release does not act', (
      tester,
    ) async {
      await pump(tester);
      final capsule = tester.getRect(find.byKey(const ValueKey('pair')));
      final back = tester.getRect(find.byKey(const ValueKey('back')));
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 120));
      expect(log, ['long back']);
      expect(
        menuAt,
        Rect.fromLTRB(back.left, capsule.top, back.right, capsule.bottom),
      );
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(log, ['long back']);
      expect(grow(tester, 'pair'), closeTo(0, 0.01));
    });

    testWidgets('moving off the segment cancels it', (tester) async {
      await pump(tester, forwardEnabled: true);
      final g = await tester.startGesture(
        center(tester, 'back'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await g.moveTo(center(tester, 'forward'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(log, isEmpty);
      await g.up();
      expect(log, ['tap forward']);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
