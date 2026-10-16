// Where a tooltip goes next to its target (kit `Tooltips/Placement/Below|Above|Leading|Trailing`).
//
// The kit puts the tooltip 8 from the target on the placement side and centres it on the
// target across, on the 4 pt grid: the 116 × 24 tooltip over a 28 pt target at x 46 sits at
// x 0, not 2; beside a 28 pt target at y 0 it sits at y 0. We read that as "centred, then
// floored to the 4 pt grid" (an assumption: the kit has no case that tells floor from round).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import 'tooltip.dart';

/// The side of the target a tooltip goes to.
enum AmalfiTooltipPlacement {
  /// Under the target (the default).
  below,

  /// Over the target.
  above,

  /// Before the target in the reading direction (left in left-to-right text).
  leading,

  /// After the target in the reading direction.
  trailing,
}

/// The top-left corner of a tooltip of [size] for [target], both in the coordinates of an area
/// of [bounds] (the overlay) whose origin is on the 4 pt grid.
///
/// The tooltip goes [AmalfiTooltipMetrics.distance] from the target on the [placement] side,
/// or on the opposite side when it would leave [bounds] there and fits on the other; across,
/// it is centred on the target and floored to the grid. It is then kept inside [bounds].
Offset amalfiTooltipOffset({
  required Rect target,
  required Size size,
  required Size bounds,
  AmalfiTooltipPlacement placement = AmalfiTooltipPlacement.below,
  TextDirection textDirection = TextDirection.ltr,
}) {
  const gap = AmalfiTooltipMetrics.distance;
  final rtl = textDirection == TextDirection.rtl;
  final side = switch (placement) {
    AmalfiTooltipPlacement.below => AxisDirection.down,
    AmalfiTooltipPlacement.above => AxisDirection.up,
    AmalfiTooltipPlacement.leading =>
      rtl ? AxisDirection.right : AxisDirection.left,
    AmalfiTooltipPlacement.trailing =>
      rtl ? AxisDirection.left : AxisDirection.right,
  };
  double along(AxisDirection d) => switch (d) {
    AxisDirection.down => target.bottom + gap,
    AxisDirection.up => target.top - gap - size.height,
    AxisDirection.right => target.right + gap,
    AxisDirection.left => target.left - gap - size.width,
  };
  bool fits(AxisDirection d) {
    final v = along(d);
    return switch (d) {
      AxisDirection.down ||
      AxisDirection.up => v >= 0 && v + size.height <= bounds.height,
      AxisDirection.left ||
      AxisDirection.right => v >= 0 && v + size.width <= bounds.width,
    };
  }

  final chosen = fits(side) || !fits(flipAxisDirection(side))
      ? side
      : flipAxisDirection(side);
  double grid(double v) =>
      (v / AmalfiGrid.base).floorToDouble() * AmalfiGrid.base;
  double clamp(double v, double extent, double room) =>
      math.max(0, math.min(v, room - extent));

  final vertical = axisDirectionToAxis(chosen) == Axis.vertical;
  final x = vertical
      ? clamp(grid(target.center.dx - size.width / 2), size.width, bounds.width)
      : clamp(along(chosen), size.width, bounds.width);
  final y = vertical
      ? clamp(along(chosen), size.height, bounds.height)
      : clamp(
          grid(target.center.dy - size.height / 2),
          size.height,
          bounds.height,
        );
  return Offset(x, y);
}
