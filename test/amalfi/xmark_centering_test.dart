// The small round × buttons: the cross sits at the optical centre of its circle (#166).
// Checked on pixels (the glyph's ink centroid against its box) and on geometry (the glyph's
// box against the circle it sits in) for every × button of the package.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

Offset centroid(ByteData rgba, int width, int height) {
  var sx = 0.0, sy = 0.0, sum = 0.0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final a = rgba.getUint8((y * width + x) * 4 + 3) / 255;
      sx += (x + 0.5) * a;
      sy += (y + 0.5) * a;
      sum += a;
    }
  }
  return Offset(sx / sum, sy / sum);
}

void main() {
  setUpAll(loadAmalfiFonts);

  for (final size in [8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 24.0]) {
    testWidgets('xmark glyph at $size: ink centroid on the box centre', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpKitScene(
        tester,
        RepaintBoundary(
          key: key,
          child: AmalfiGlyph(
            AmalfiGlyphs.xmark,
            size: size,
            color: const Color(0xFF000000),
          ),
        ),
      );
      late final ui.Image image;
      late final ByteData data;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage(pixelRatio: 8);
        data = (await image.toByteData())!;
      });
      final c = centroid(data, image.width, image.height);
      expect(c.dx / 8, closeTo(size / 2, 0.02));
      expect(c.dy / 8, closeTo(size / 2, 0.02));
    });
  }

  Offset centre(WidgetTester tester, Finder f) => tester.getCenter(f);

  testWidgets('clear button: the glyph is centred in the disc', (tester) async {
    await pumpKitScene(tester, AmalfiClearButton(onPressed: () {}));
    final disc = centre(tester, find.byType(AmalfiClearButton));
    expect(centre(tester, find.byType(AmalfiGlyph)), disc);
  });

  testWidgets('window close dot: the glyph is centred in the disc', (
    tester,
  ) async {
    await pumpKitScene(
      tester,
      const AmalfiWindowDot(
        kind: AmalfiWindowControlKind.close,
        state: AmalfiWindowControlState.hover,
      ),
    );
    expect(
      centre(tester, find.byType(AmalfiGlyph)),
      centre(tester, find.byType(AmalfiWindowDot)),
    );
  });

  testWidgets('tab close: the glyph fills its slot', (tester) async {
    await pumpKitScene(
      tester,
      SizedBox(
        width: 200,
        child: AmalfiTab(label: 'Tab', selected: true, onClose: () {}),
      ),
    );
    final glyph = tester.getRect(find.byType(AmalfiGlyph));
    final slot = tester.getRect(
      find
          .ancestor(
            of: find.byType(AmalfiGlyph),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SizedBox &&
                  w.width == AmalfiTabMetrics.slot &&
                  w.height == AmalfiTabMetrics.slot,
            ),
          )
          .first,
    );
    expect(glyph, slot);
  });
}
