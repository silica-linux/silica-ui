import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  testWidgets('Glass sends its region to silica/glass', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 20,
              width: 100,
              height: 50,
              child: Glass(radius: 22, child: SizedBox.expand()),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(calls, isNotEmpty);
    final regions = calls.last.arguments as List<Object?>;
    expect(regions, hasLength(1));
    final region = regions.first! as Map<Object?, Object?>;
    expect(region['x'], 10);
    expect(region['y'], 20);
    expect(region['width'], 100);
    expect(region['height'], 50);
    expect(region['radius'], 22);
    expect(region['material'], 'clear');
    // Without a profile the region carries no profile keys.
    expect(region.containsKey('profile'), isFalse);
    expect(region.containsKey('shadow'), isFalse);

    // Without the widget, the regions empty.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls.last.arguments, isEmpty);
  });

  testWidgets(
    'an ancestor changing scale moves the glass even without repainting it',
    (tester) async {
      final sent = <Map<Object?, Object?>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        GlassRegistry.channel,
        (call) async {
          final regions = call.arguments as List<Object?>;
          if (regions.isNotEmpty) {
            sent.add(regions.first! as Map<Object?, Object?>);
          }
          return true;
        },
      );
      Widget at(double scale) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Transform.scale(
            scale: scale,
            // The glass does not repaint when only the transform changes.
            child: const RepaintBoundary(
              child: SizedBox(
                width: 100,
                height: 50,
                child: Glass(radius: 25, child: SizedBox.expand()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(at(1.5));
      await tester.pump();
      expect(sent.last['width'], 150);
      await tester.pumpWidget(at(1));
      await tester.pump();
      expect(sent.last['width'], 100);
      expect(sent.last['radius'], 25);
    },
  );

  testWidgets('the glass carries the ancestors\' opacity', (tester) async {
    final sent = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        final regions = call.arguments as List<Object?>;
        if (regions.isNotEmpty) {
          sent.add(regions.first! as Map<Object?, Object?>);
        }
        return true;
      },
    );
    Widget at(double opacity) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Opacity(
            opacity: 0.5,
            child: const SizedBox(
              width: 100,
              height: 50,
              child: Glass(radius: 25, child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(at(1));
    await tester.pump();
    expect(sent.last['opacity'], 0.5);
    // Only the ancestor's opacity changes: the glass follows without repainting.
    await tester.pumpWidget(at(0.5));
    await tester.pump();
    expect(sent.last['opacity'], 0.25);
  });

  testWidgets('the tip and the group arrive as regions', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 20,
              width: 100,
              height: 50,
              child: Glass(
                radius: 12,
                material: GlassMaterial.thick,
                group: 1,
                tip: GlassTip(x: 30, width: 24, height: 10),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final regions = calls.last.arguments as List<Object?>;
    expect(regions, hasLength(2));
    final body = regions.first! as Map<Object?, Object?>;
    final tip = regions.last! as Map<Object?, Object?>;
    expect(body['group'], 1);
    expect(tip['shape'], 'tip');
    expect(tip['group'], 1);
    expect(tip['material'], 'thick');
    expect([tip['x'], tip['y'], tip['width'], tip['height']], [28, 70, 24, 10]);
  });

  testWidgets('side tips: the rectangle beside the body, depth across', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    for (final (edge, shape, rect) in [
      (TipEdge.left, 'tip-left', [-10, 25, 10, 24]),
      (TipEdge.right, 'tip-right', [100, 25, 10, 24]),
      (TipEdge.top, 'tip-up', [25, -10, 24, 10]),
    ]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Glass(
              tip: GlassTip(x: 37, width: 24, height: 10, edge: edge),
              child: const SizedBox(width: 100, height: 70),
            ),
          ),
        ),
      );
      await tester.pump();
      final tip =
          (calls.last.arguments as List<Object?>).last!
              as Map<Object?, Object?>;
      expect(tip['shape'], shape);
      expect([tip['x'], tip['y'], tip['width'], tip['height']], rect);
    }
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      null,
    );
  });

  testWidgets('the submenu has a glass group of its own', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MenuHost(
          entries: [
            MenuAction('Options', submenu: [MenuAction('Remove')]),
          ],
          anchor: Offset(100, 31),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(const Offset(150, 31 + 5 + 12));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    final regions = (calls.last.arguments as List<Object?>)
        .cast<Map<Object?, Object?>>();
    expect(regions.map((r) => r['group'] ?? 0).toSet(), {0, 1});
  });

  testWidgets('a profile goes with the body and the tip', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GlassRegistry.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 20,
              width: 100,
              height: 50,
              child: Glass(
                radius: 12,
                material: GlassMaterial.thick,
                profile: GlassProfile.tooltip,
                profileShadow: true,
                tip: GlassTip(x: 50, width: 31, height: 10),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final regions = (calls.last.arguments as List<Object?>)
        .cast<Map<Object?, Object?>>();
    expect(regions, hasLength(2));
    for (final region in regions) {
      expect(region['profile'], 'tooltip');
      expect(region['shadow'], true);
    }
  });
}
