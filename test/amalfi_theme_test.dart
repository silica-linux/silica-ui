// The smooth-corner border and the Amalfi theme.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 1e-3));
  expect(actual.top, closeTo(expected.top, 1e-3));
  expect(actual.right, closeTo(expected.right, 1e-3));
  expect(actual.bottom, closeTo(expected.bottom, 1e-3));
}

void main() {
  group('AmalfiSmoothBorder', () {
    const rect = Rect.fromLTWH(10, 20, 100, 60);

    test('the path fills the rect exactly', () {
      final path = const AmalfiSmoothBorder(radius: 20).getOuterPath(rect);
      _expectRect(path.getBounds(), rect);
      expect(path.contains(rect.center), isTrue);
    });

    test('corners are rounded outward, smoother than a circular arc', () {
      final smooth = smoothRectPath(rect, 20, 0.6);
      final circular = smoothRectPath(rect, 20, 0);
      final vertex = rect.topLeft;
      // The vertex area is cut away, the inside of the corner is kept.
      expect(smooth.contains(vertex + const Offset(1, 1)), isFalse);
      expect(smooth.contains(vertex + const Offset(12, 12)), isTrue);
      // Straight sides: just inside the top edge, past where the corner starts.
      expect(smooth.contains(vertex + const Offset(50, 0.5)), isTrue);
      // With smoothing the corner starts farther from the vertex ((1 + 0.6) × 20 = 32
      // instead of 20): where the circular arc meets the top edge, the smooth one is
      // still below it.
      expect(circular.contains(vertex + const Offset(20, 0.1)), isTrue);
      expect(smooth.contains(vertex + const Offset(20, 0.1)), isFalse);
      // Smoothing 0 is a circular arc: on the diagonal at r (1 − 1/√2) ≈ 5.86 from each side.
      expect(circular.contains(vertex + const Offset(5.5, 5.5)), isFalse);
      expect(circular.contains(vertex + const Offset(6.3, 6.3)), isTrue);
      // The four corners are the same.
      for (final corner in [rect.topRight, rect.bottomLeft, rect.bottomRight]) {
        final inward = Offset(
          corner.dx == rect.left ? 1 : -1,
          corner.dy == rect.top ? 1 : -1,
        );
        expect(smooth.contains(corner + inward), isFalse);
        expect(smooth.contains(corner + inward * 12), isTrue);
      }
    });

    test('a radius too large gives a capsule, small shapes stay finite', () {
      const pill = Rect.fromLTWH(0, 0, 80, 32);
      final capsule = smoothRectPath(pill, 100, 0.6);
      _expectRect(capsule.getBounds(), pill);
      expect(capsule.contains(const Offset(16, 16)), isTrue);
      expect(capsule.contains(const Offset(2, 2)), isFalse);
      const tiny = Rect.fromLTWH(0, 0, 30, 20);
      _expectRect(smoothRectPath(tiny, 9, 0.6).getBounds(), tiny);
    });

    test('degenerate input never throws', () {
      expect(smoothRectPath(Rect.zero, 10, 0.6).getBounds(), Rect.zero);
      expect(
        smoothRectPath(const Rect.fromLTWH(0, 0, -5, 10), 10, 0.6).getBounds(),
        Rect.zero,
      );
      _expectRect(smoothRectPath(rect, 0, 0.6).getBounds(), rect);
      _expectRect(smoothRectPath(rect, double.nan, 0.6).getBounds(), rect);
      _expectRect(smoothRectPath(rect, 20, double.infinity).getBounds(), rect);
      _expectRect(smoothRectPath(rect, -4, 2).getBounds(), rect);
    });

    test('inner path, paint, scale, lerp', () {
      const border = AmalfiSmoothBorder(
        radius: 12,
        side: BorderSide(width: 2, color: Color(0xFF000000)),
      );
      _expectRect(border.getInnerPath(rect).getBounds(), rect.deflate(2));
      expect(border.dimensions, const EdgeInsets.all(2));
      final recorder = ui.PictureRecorder();
      border.paint(Canvas(recorder), rect);
      recorder.endRecording().dispose();
      expect(border.scale(2).radius, 24);
      expect(border.copyWith(radius: 4).radius, 4);
      final mid = ShapeBorder.lerp(
        const AmalfiSmoothBorder(radius: 0),
        const AmalfiSmoothBorder(radius: 20),
        0.5,
      );
      expect(mid, const AmalfiSmoothBorder(radius: 10));
      expect(const AmalfiSmoothBorder().smoothing, AmalfiRadii.smoothing);
    });

    testWidgets('draws as a decoration', (tester) async {
      await tester.pumpWidget(
        const Center(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Color(0xFF0E77E6),
              shape: AmalfiSmoothBorder(
                radius: AmalfiRadii.window,
                side: BorderSide(color: Color(0x1A000000)),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x2E000000),
                  offset: Offset(0, 12),
                  blurRadius: 32,
                ),
              ],
            ),
            child: SizedBox(width: 200, height: 120),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AmalfiTheme', () {
    Widget host(Brightness system, Widget child) => MediaQuery(
      data: MediaQueryData(platformBrightness: system),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

    testWidgets('without a theme it follows the appearance in effect', (
      tester,
    ) async {
      late AmalfiThemeData data;
      await tester.pumpWidget(
        host(
          Brightness.dark,
          Builder(
            builder: (context) {
              data = AmalfiTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(data.brightness, Brightness.dark);
      expect(data.colors, same(AmalfiColors.dark));
      expect(data.shadows, same(AmalfiShadows.dark));
      expect(data.appColors, isNull);
    });

    testWidgets(
      'forces a brightness and an app palette; nested themes keep the app',
      (tester) async {
        late AmalfiThemeData outer;
        late AmalfiThemeData inner;
        await tester.pumpWidget(
          host(
            Brightness.light,
            AmalfiTheme(
              brightness: Brightness.dark,
              app: 'Mail',
              child: Builder(
                builder: (context) {
                  outer = AmalfiTheme.of(context);
                  return AmalfiTheme(
                    brightness: Brightness.light,
                    child: Builder(
                      builder: (context) {
                        inner = AmalfiTheme.of(context);
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
        expect(outer.isDark, isTrue);
        expect(outer.appColor('Flag'), AmalfiColors.dark.mail.flag);
        expect(outer.appColors, same(AmalfiColors.dark.mail));
        expect(inner.isDark, isFalse);
        expect(inner.app, 'Mail');
        expect(inner.appColor('Flag'), AmalfiColors.light.mail.flag);
        expect(inner.appColor('Nope'), isNull);
      },
    );

    testWidgets('follows SilicaAppearanceScope', (tester) async {
      late AmalfiThemeData data;
      await tester.pumpWidget(
        host(
          Brightness.light,
          SilicaAppearanceScope(
            appearance: SilicaAppearance.dark,
            child: AmalfiTheme(
              app: 'Clock',
              child: Builder(
                builder: (context) {
                  data = AmalfiTheme.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(data.brightness, Brightness.dark);
      expect(data.appColors?.app, 'Clock');
      expect(data.appColor('Accent'), AmalfiColors.dark.clock.accent);
    });

    test('an unknown app has no palette', () {
      const data = AmalfiThemeData.light(app: 'Unknown');
      expect(data.appColors, isNull);
      expect(data.appColor('Accent'), isNull);
      expect(
        data,
        const AmalfiThemeData(brightness: Brightness.light, app: 'Unknown'),
      );
    });
  });
}
