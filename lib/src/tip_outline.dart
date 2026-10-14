// The measured outline of a glass tip (TIP-01, docs/spec/popovers.md): a concave fillet out of
// the body edge, a straight flank, a round apex, and the same mirrored. Ossido draws the glass
// from the same presets (silica-glass-v1 `add_tip`, picked by the tip rectangle); silica_ui uses
// the outline for what it draws itself: the shadow cut-out of menus and in-window popovers.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A tip outline from its four measured parameters.
@immutable
class TipOutline {
  const TipOutline({
    required this.flankDegrees,
    required this.apexRadius,
    required this.filletRadius,
    required this.depth,
  });

  /// The flank's angle from the body edge.
  final double flankDegrees;
  final double apexRadius;

  /// The concave arc joining the flank to the body edge.
  final double filletRadius;

  /// From the body edge to the apex.
  final double depth;

  /// Menu tip under the Dock icons (TIP-01): 31 × 10 pt.
  static const TipOutline menu = TipOutline(
    flankDegrees: 50.8,
    apexRadius: 5.295,
    filletRadius: 9.414,
    depth: 10.187,
  );

  /// Popover tip on the top or bottom edge (TIP-01): 32 × 11 pt.
  static const TipOutline popover = TipOutline(
    flankDegrees: 46.2,
    apexRadius: 5.58,
    filletRadius: 8.0,
    depth: 10.8,
  );

  /// Popover tip on the left or right edge (TIP-01): 39 × 12 pt.
  static const TipOutline popoverSide = TipOutline(
    flankDegrees: 46.1,
    apexRadius: 5.73,
    filletRadius: 13.6,
    depth: 11.74,
  );

  double get _sin => math.sin(flankDegrees * math.pi / 180);
  double get _cos => math.cos(flankDegrees * math.pi / 180);

  /// Half the base along the body edge, where the fillets start.
  double get halfBase =>
      (apexRadius + filletRadius - _cos * (filletRadius + apexRadius - depth)) /
      _sin;

  /// Where the fillet meets the left flank, with the body edge at y = 0 and the apex at
  /// y = [depth] (the tip pointing down).
  Offset get filletEnd => Offset(
    -halfBase + filletRadius * _sin,
    filletRadius - filletRadius * _cos,
  );

  /// Where the left flank meets the apex arc, in the same frame.
  Offset get apexStart =>
      Offset(-apexRadius * _sin, depth - apexRadius + apexRadius * _cos);

  /// The outline pointing down, centered on x = 0, with the body edge at y = 0. It reaches
  /// `overlap` pt into the body so the union with it leaves no seam.
  Path path({double overlap = 0.5}) {
    final h = halfBase;
    final f = filletEnd;
    final a = apexStart;
    return Path()
      ..moveTo(-h, -overlap)
      ..lineTo(-h, 0)
      ..arcToPoint(f, radius: Radius.circular(filletRadius))
      ..lineTo(a.dx, a.dy)
      ..arcToPoint(
        Offset(-a.dx, a.dy),
        radius: Radius.circular(apexRadius),
        clockwise: false,
      )
      ..lineTo(-f.dx, f.dy)
      ..arcToPoint(Offset(h, 0), radius: Radius.circular(filletRadius))
      ..lineTo(h, -overlap)
      ..close();
  }
}
