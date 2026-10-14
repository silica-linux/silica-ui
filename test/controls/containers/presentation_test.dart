import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

/// A window with an overlay, as `WidgetsApp` gives.
Widget window(Widget child, {Brightness brightness = Brightness.light}) =>
    MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [OverlayEntry(builder: (context) => child)],
        ),
      ),
    );

void main() {
  group('popover', () {
    const bounds = Rect.fromLTWH(0, 0, 800, 600);
    const size = Size(228, 226);

    test('below the anchor, the arrow on top points at its center', () {
      final p = placePopover(
        anchor: const Rect.fromLTWH(300, 20, 38, 38),
        size: size,
        bounds: bounds,
      );
      expect(p.edge, TipEdge.top);
      expect(p.rect.top, 58 + PopoverMetrics.tipDepth + PopoverMetrics.gap);
      expect(p.rect.left + p.tip, 319);
    });

    test('it flips when there is no room and slides inside the window', () {
      final p = placePopover(
        anchor: const Rect.fromLTWH(760, 540, 30, 30),
        size: size,
        bounds: bounds,
      );
      expect(p.edge, TipEdge.bottom);
      expect(p.rect.right, lessThanOrEqualTo(800 - PopoverMetrics.margin));
      // The arrow stays on the body, away from the corner.
      expect(
        p.tip,
        lessThanOrEqualTo(
          size.width - PopoverMetrics.radius - PopoverMetrics.tipBase / 2,
        ),
      );
    });

    test('left and right edges', () {
      final right = placePopover(
        anchor: const Rect.fromLTWH(100, 280, 30, 30),
        size: size,
        bounds: bounds,
        preferred: TipEdge.right,
      );
      expect(right.edge, TipEdge.left);
      expect(right.rect.top + right.tip, 295);
      final left = placePopover(
        anchor: const Rect.fromLTWH(100, 280, 30, 30),
        size: size,
        bounds: bounds,
        preferred: TipEdge.left,
      );
      // No room on the left: it flips to the right.
      expect(left.edge, TipEdge.left);
    });

    test('the arrow lies outside the body on every edge', () {
      for (final edge in TipEdge.values) {
        final path = popoverPath(const Size(200, 100), edge, 50);
        final b = path.getBounds();
        switch (edge) {
          case TipEdge.top:
            expect(b.top, lessThan(-9));
          case TipEdge.bottom:
            expect(b.bottom, greaterThan(109));
          case TipEdge.left:
            expect(b.left, lessThan(-9));
          case TipEdge.right:
            expect(b.right, greaterThan(209));
        }
      }
    });

    testWidgets('opens, closes on Esc and on a click outside', (tester) async {
      final key = GlobalKey<PopoverAnchorState>();
      var closed = 0;
      await tester.pumpWidget(
        window(
          Align(
            alignment: Alignment.topCenter,
            child: PopoverAnchor(
              key: key,
              size: size,
              onClosed: () => closed++,
              builder: (context) => const Text('Tags'),
              child: const SizedBox(width: 38, height: 38),
            ),
          ),
        ),
      );
      key.currentState!.show();
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('popover'))), size);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsNothing);
      expect(closed, 1);
      key.currentState!.show();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 580));
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsNothing);
      expect(closed, 2);
    });

    testWidgets('application-defined popovers stay', (tester) async {
      await tester.pumpWidget(
        window(
          const Center(
            child: PopoverAnchor(
              open: true,
              size: Size(100, 80),
              behavior: PopoverBehavior.applicationDefined,
              builder: _text,
              child: SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('pinned'), findsOneWidget);
    });
  });

  group('sheet', () {
    testWidgets('a card veils the window, closes with a value', (tester) async {
      late BuildContext host;
      await tester.pumpWidget(
        window(
          Builder(
            builder: (context) {
              host = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final result = showWindowSheet<String>(
        host,
        builder: (context, sheet) => GestureDetector(
          onTap: () => sheet.close('saved'),
          child: const SizedBox(width: 413, height: 218, child: Text('Save')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Halfway the card is still above its place, moving down.
      final moving = tester.getRect(find.byKey(const ValueKey('sheet card')));
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byKey(const ValueKey('sheet card')));
      expect(settled.size, const Size(413, 218));
      expect(settled.center, const Offset(400, 300));
      expect(moving.top, lessThan(settled.top));
      expect(find.byKey(const ValueKey('sheet veil')), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(await result, 'saved');
      expect(find.byKey(const ValueKey('sheet veil')), findsNothing);
    });

    testWidgets('Esc cancels; the attached sheet hangs from the toolbar', (
      tester,
    ) async {
      late BuildContext host;
      await tester.pumpWidget(
        window(
          Builder(
            builder: (context) {
              host = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final result = showWindowSheet<void>(
        host,
        style: SheetStyle.attached,
        builder: (context, sheet) => const SizedBox(width: 1066, height: 500),
      );
      await tester.pumpAndSettle();
      final sheet = tester.getRect(
        find.byKey(const ValueKey('sheet attached')),
      );
      expect(sheet.top, 52);
      expect(sheet.center.dx, 400);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await result;
      expect(find.byKey(const ValueKey('sheet attached')), findsNothing);
    });
  });

  group('panel', () {
    testWidgets('moves with its title bar and closes', (tester) async {
      var at = const Offset(100, 100);
      var open = true;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => window(
            Stack(
              children: [
                if (open)
                  FloatingPanel(
                    title: 'Info',
                    size: const Size(281, 400),
                    position: at,
                    onMove: (p) => setState(() => at = p),
                    onClose: () => setState(() => open = false),
                    child: const SizedBox(),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.drag(
        find.byKey(const ValueKey('panel title bar')),
        const Offset(50, 30),
      );
      await tester.pump();
      expect(at.dx, greaterThan(130));
      await tester.tap(find.byKey(const ValueKey('panel close')));
      await tester.pump();
      expect(open, isFalse);
    });

    testWidgets('the HUD style uses the glass', (tester) async {
      await tester.pumpWidget(
        window(
          const Stack(
            children: [
              FloatingPanel(
                title: 'HUD',
                size: Size(200, 100),
                style: PanelStyle.hud,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('tooltip', () {
    testWidgets('appears after a second at rest, hides on press', (
      tester,
    ) async {
      await tester.pumpWidget(
        window(
          const Center(
            child: SilicaTooltip(
              message: 'Show the alternate functions',
              child: SizedBox(width: 60, height: 40),
            ),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('tooltip')), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tooltip')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('tooltip'))).dy,
        300 + TooltipMetrics.below,
      );
      await gesture.down(const Offset(400, 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tooltip')), findsNothing);
      await gesture.up();
    });
  });

  group('customize toolbar', () {
    testWidgets('dims items in the bar, cycles the display, Done', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var display = ToolbarDisplay.iconsOnly;
      var done = false;
      final items = [
        for (final id in ['back', 'view', 'group', 'search'])
          ToolbarItemSpec(id: id, label: id),
      ];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => window(
            OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: 1100,
              maxHeight: 600,
              child: ToolbarCustomizeSheet(
                available: items,
                defaults: items.take(2).toList(),
                inBar: const {'view'},
                display: display,
                onDisplay: (d) => setState(() => display = d),
                onDone: () => done = true,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('toolbar customize'))),
        ToolbarCustomizeMetrics.sheet,
      );
      final dimmed = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const ValueKey('palette view')),
          matching: find.byType(Opacity),
        ),
      );
      expect(dimmed.opacity, ToolbarCustomizeMetrics.dimmed);
      await tester.tap(find.byKey(const ValueKey('toolbar customize show')));
      await tester.pump();
      expect(display, ToolbarDisplay.textOnly);
      await tester.tap(find.byKey(const ValueKey('toolbar customize done')));
      expect(done, isTrue);
    });
  });
}

Widget _text(BuildContext context) => const Text('pinned');
