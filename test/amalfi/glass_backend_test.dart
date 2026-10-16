// The glass backends of AmalfiGlass: Flutter draws everything; the compositor backend only
// declares a region (kind, shape, radius) and paints no tint.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

Widget _host(Widget child, {AmalfiGlassBackend? backend}) => Directionality(
  textDirection: TextDirection.ltr,
  child: AmalfiTheme(
    brightness: Brightness.light,
    child: Stack(
      children: [
        Positioned(
          left: 10,
          top: 20,
          child: backend == null
              ? child
              : AmalfiGlassBackendScope(backend: backend, child: child),
        ),
      ],
    ),
  ),
);

void main() {
  const box = SizedBox(width: 100, height: 50);

  testWidgets('compositor backend declares the region and paints no tint', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AmalfiGlass(
          material: AmalfiMaterials.thick,
          radius: 16,
          kind: AmalfiGlassKind.sheet,
          child: box,
        ),
        backend: AmalfiGlassBackend.compositor,
      ),
    );
    final regions = GlassRegistry.instance.regions;
    expect(regions, hasLength(1));
    final region = regions.single;
    expect(region['x'], 10);
    expect(region['y'], 20);
    expect(region['width'], 100);
    expect(region['height'], 50);
    expect(region['radius'], 16);
    expect(region['material'], 'thick');
    expect(region['profile'], 'sheet');
    expect(region['shadow'], true);
    // Nothing of Flutter's glass: no backdrop filter, no painted tint, rims or shadow.
    expect(find.byType(BackdropFilter), findsNothing);
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(AmalfiGlass),
            matching: find.byType(CustomPaint),
          ),
        )
        .where((p) => p.painter != null);
    expect(painters, isEmpty);
  });

  testWidgets(
    'flutter backend (default) draws the glass and declares nothing',
    (tester) async {
      await tester.pumpWidget(_host(const AmalfiGlass(radius: 16, child: box)));
      expect(GlassRegistry.instance.regions, isEmpty);
      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );

  testWidgets('default kinds follow the material', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            AmalfiGlass(material: AmalfiMaterials.thick, radius: 8, child: box),
            AmalfiGlass(
              material: AmalfiMaterials.regular,
              radius: 8,
              child: box,
            ),
          ],
        ),
        backend: AmalfiGlassBackend.compositor,
      ),
    );
    final regions = GlassRegistry.instance.regions;
    expect(regions.map((r) => r['profile']), ['menu', 'control']);
    expect(regions.map((r) => r['material']), ['thick', 'regular']);
  });

  testWidgets('a popover with an arrow declares its body and tip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 200,
          height: 108,
          child: AmalfiPopoverSurface(
            shape: AmalfiPopoverShape(edge: AmalfiPopoverArrowEdge.top),
            child: SizedBox.expand(),
          ),
        ),
        backend: AmalfiGlassBackend.compositor,
      ),
    );
    final regions = GlassRegistry.instance.regions;
    expect(regions, hasLength(2));
    expect(regions[0]['profile'], 'popover');
    expect(regions[0]['radius'], AmalfiPopoverMetrics.radius);
    // The body starts below the arrow's depth.
    expect(regions[0]['y'], 28);
    expect(regions[0]['height'], 100);
    expect(regions[1]['shape'], 'tip-up');
    expect(regions[1]['width'], 20);
    expect(regions[1]['height'], 8);
  });

  testWidgets('a menu on the compositor backend reports its open submenus', (
    tester,
  ) async {
    final reported = <List<Rect>>[];
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          height: 300,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: AmalfiMenu(
                    width: 200,
                    onSubmenusChanged: reported.add,
                    entries: const [
                      AmalfiMenuAction(
                        'More',
                        submenu: [AmalfiMenuAction('Inner')],
                      ),
                      AmalfiMenuAction('Other'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        backend: AmalfiGlassBackend.compositor,
      ),
    );
    expect(GlassRegistry.instance.regions.single['profile'], 'menu');
    expect(reported, isEmpty);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    final more = tester.getCenter(find.text('More'));
    await mouse.addPointer(location: more);
    await mouse.moveTo(more + const Offset(1, 0));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final regions = GlassRegistry.instance.regions;
    expect(regions, hasLength(2));
    expect(regions.last['group'], 1);
    expect(reported.last, hasLength(1));
    expect(reported.last.single.width, greaterThan(0));

    await mouse.moveTo(tester.getCenter(find.text('Other')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(reported.last, isEmpty);
  });
}
