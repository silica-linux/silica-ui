// A dashed smooth-cornered border: the drop zone of an empty image well (kit
// `Wells/Image Well/Empty/*/Rest|Disabled`: 1.5 pt `Line/Border`, dashes 6 on, 4 off).

import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../tokens.g.dart';

/// An [AmalfiSmoothBorder] whose side is drawn in dashes of [dash] points with [gap] points
/// between them, along the outline from its top edge.
class AmalfiDashedSmoothBorder extends AmalfiSmoothBorder {
  const AmalfiDashedSmoothBorder({
    super.side,
    super.radius,
    super.smoothing = AmalfiRadii.smoothing,
    this.dash = 6,
    this.gap = 4,
    this.phase = 0,
  });

  /// The length of a dash.
  final double dash;

  /// The space between two dashes.
  final double gap;

  /// How far into the pattern the outline starts (it starts at the top edge, where the
  /// top-left corner ends).
  final double phase;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    if (dash <= 0 || gap < 0) return super.paint(canvas, rect);
    final offset = side.strokeOffset / 2;
    final outline = smoothRectPath(
      rect.inflate(offset),
      radius + offset,
      smoothing,
    );
    final dashes = Path();
    for (final PathMetric metric in outline.computeMetrics()) {
      final period = dash + gap;
      final start = -(phase % period);
      for (var d = start; d < metric.length; d += period) {
        dashes.addPath(
          metric.extractPath(d < 0 ? 0 : d, d + dash),
          Offset.zero,
        );
      }
    }
    canvas.drawPath(dashes, side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is AmalfiDashedSmoothBorder &&
      super == other &&
      other.dash == dash &&
      other.gap == gap &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(super.hashCode, dash, gap, phase);
}
