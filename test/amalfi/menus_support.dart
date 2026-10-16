// Shared helpers of the menus, popovers, alerts, dialogs and sheets tests: a mouse that
// stays for the test, finders of label boxes, the style extractors of the surfaces these
// families paint themselves, and the pixel tolerances they share.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// The 7 pt smooth corners of the highlight antialias up to 51 apart from Sketch's on one
/// corner pixel (alpha 196 against 145); the rest of the shape agrees (mean ≤ 0.3).
const highlightCorners = KitPixelTolerance(max: 56);

/// A 24 pt row is mostly 13 pt text, rasterised differently by CoreText: with the text
/// compared, the mean reaches ~4.9 (the tooltips, with more surface around their text,
/// stay under 2.5). The text is in place (the best shift of the rendered row is 0, 0).
const denseText = KitPixelTolerance(mean: 5, max: 255);

/// Large smooth corners (radius 16–20): Sketch's outline sits up to half a pixel inside the
/// code's at the corners' ends, and single edge pixels differ by up to 82 (alpha 135 against
/// 217); the rest of the shape agrees (mean ≤ 0.15).
const largeCorners = KitPixelTolerance(max: 96);

TestGesture? _mouse;

/// Moves a mouse (created once per test and removed at its end) to [position].
Future<void> moveMouse(WidgetTester tester, Offset position) async {
  var mouse = _mouse;
  if (mouse == null) {
    mouse = _mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      await _mouse?.removePointer();
      _mouse = null;
    });
    await mouse.addPointer(location: const Offset(1, 1));
  }
  await mouse.moveTo(position);
  await tester.pump();
}

/// Hovers the centre of [finder] (coming from the top-left corner, so a hover always
/// enters it) and lets a frame pass.
Future<void> hover(WidgetTester tester, Finder finder) async {
  await moveMouse(tester, const Offset(1, 1));
  await moveMouse(tester, tester.getCenter(finder));
}

/// The menu item showing [label].
Finder menuItem(String label) =>
    find.widgetWithText(AmalfiMenuItem, label).first;

/// The text widget of [text] (its box is the text frame).
Finder textBox(String text) => find.text(text).first;

/// Registers the style extractors of the surfaces of these families (once).
void registerSurfaceStyles() {
  if (_registered) return;
  _registered = true;
  RenderedStyle.register((widget, context) {
    if (widget is AmalfiAlertSurface) {
      final colors = AmalfiTheme.of(context).colors;
      final brightness = AmalfiTheme.of(context).brightness;
      return RenderedStyle(
        fills: [widget.color ?? colors.surfaceRaised],
        borders: [
          RenderedBorder(
            widget.borderColor ?? colors.lineBorder,
            1,
            BorderSide.strokeAlignInside,
          ),
        ],
        shadows: widget.shadow
            ? AmalfiShadows.of(brightness).level(3) ?? const []
            : const [],
        radii: List.filled(4, widget.radius),
        smoothing: AmalfiRadii.smoothing,
        source: 'AmalfiAlertSurface',
      );
    }
    if (widget is AmalfiPopoverSurface) {
      final brightness = AmalfiTheme.of(context).brightness;
      const m = AmalfiMaterials.thick;
      return RenderedStyle(
        fills: [
          if (widget.opaque) AmalfiTheme.of(context).colors.surfaceWindow,
          if (m.tint(brightness) case final tint?) tint,
        ],
        borders: [
          RenderedBorder(
            m.rimInside(brightness),
            m.rimInsideWidth,
            BorderSide.strokeAlignInside,
          ),
        ],
        shadows: AmalfiGlass.shadowsOf(m, brightness),
        innerShadows: [
          BoxShadow(
            color: m.rimLight(brightness),
            offset: m.rimLightOffset,
            blurRadius: m.rimLightBlur,
          ),
        ],
        radii: widget.shape.cornerRadii,
        smoothing: AmalfiRadii.smoothing,
        blurs: [if (!widget.opaque) RenderedBlur.glass(m, brightness)],
        source: 'AmalfiPopoverSurface',
      );
    }
    if (widget is AmalfiSheetScrim) {
      return RenderedStyle(
        fills: [AmalfiSheetScrim.color],
        radii: [0, 0, widget.radius, widget.radius],
        smoothing: AmalfiRadii.smoothing,
        source: 'AmalfiSheetScrim',
      );
    }
    return null;
  });
}

bool _registered = false;
