// The lens rule (`materials.md`, user decision 2026-10-16: the kit wins): the Glass/Clear
// capsule over a pressed select-one segment or a dragged slider or switch thumb reaches
// [AmalfiLens.outset] beyond the control on each side and [AmalfiLens.rise] above and below
// it (a 72 × 20 segment gets an 88 × 44 lens), with a radius of half its height minus 1.
// The switch's lens is the exception the docs name: the thumb + 12 at Regular.

import 'package:flutter/widgets.dart';

/// The geometry of the lens.
abstract final class AmalfiLens {
  /// How far the lens reaches beyond the control on its left and right.
  static const double outset = 8;

  /// How far the lens reaches above and below the control.
  static const double rise = 12;

  /// How much the switch's lens exceeds its thumb, at Regular (`materials.md`).
  static const double switchGrowth = 12;

  /// The lens over [control] (the pressed segment, the dragged thumb).
  static Rect around(Rect control) => Rect.fromLTRB(
    control.left - outset,
    control.top - rise,
    control.right + outset,
    control.bottom + rise,
  );

  /// The size of the lens over a control of [size].
  static Size sizeAround(Size size) =>
      Size(size.width + 2 * outset, size.height + 2 * rise);

  /// The corner radius of a lens of [size]: half its height minus 1.
  static double radiusOf(Size size) {
    final r = size.shortestSide / 2 - 1;
    return r > 0 ? r : 0;
  }

  /// The lens at [presence] (0: the control's own rect, 1: the full lens).
  static Rect at(Rect control, double presence) {
    final p = presence.isFinite ? presence.clamp(0.0, 1.0) : 0.0;
    return Rect.lerp(control, around(control), p) ?? around(control);
  }
}
