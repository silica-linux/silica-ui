// The scroll bar's face (kit `Scrollbars/Overlay/*`, `Scrollbars/Legacy/*`,
// `Scrollbars/Corner`).
//
// Overlay bars float over the content, 12 pt: thin, a 4 pt `Text/Tertiary` thumb without
// track; expanded (pointer over the bar), a `Surface/Sunken` capsule track with a
// `Line/Separator` rim and an 8 pt `Text/Secondary` thumb; dragged, the thumb turns
// `Text/Primary`. Legacy bars sit beside the content, 16 pt: a square `Surface/Sunken` track
// with a `Line/Separator` rim and an 8 pt thumb, `Text/Tertiary` at rest, `Text/Secondary`
// under the pointer; without a thumb when everything is visible.

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';

/// The two kinds of scroll bar.
enum AmalfiScrollbarStyle {
  /// Over the content, shown while scrolling (`Scrollbars/Overlay`).
  overlay,

  /// Beside the content, always shown (`Scrollbars/Legacy`).
  legacy,
}

/// The measures of the scroll bars, from `Scrollbars/*`.
abstract final class AmalfiScrollbarMetrics {
  /// The thickness of a bar of [style]: 12 (overlay), 16 (legacy).
  static double thicknessOf(AmalfiScrollbarStyle style) =>
      style == AmalfiScrollbarStyle.overlay ? 12 : 16;

  /// The thin overlay thumb's thickness.
  static const double thinThumb = 4;

  /// The thumb's thickness on a track (expanded overlay, legacy).
  static const double thumb = 8;

  /// The shortest thumb.
  static const double minThumb = 24;

  /// The side of the corner between two legacy bars.
  static const double corner = 16;
}

/// A scroll bar's face along [axis], as long as it is given: the track and a thumb from
/// [thumbOffset] over [thumbExtent] points along it (no thumb when [thumbExtent] is null).
///
/// For an overlay bar, [expansion] goes from 0 (thin) to 1 (expanded), in between while it
/// animates; [hovered] shows a legacy thumb under the pointer and [dragging] a dragged thumb.
/// `AmalfiScrollbar` draws it over or beside a scroll view; use it directly only to build a
/// custom scroller.
class AmalfiScrollbarTrack extends StatelessWidget {
  const AmalfiScrollbarTrack({
    super.key,
    required this.axis,
    this.style = AmalfiScrollbarStyle.overlay,
    this.expansion = 0,
    this.hovered = false,
    this.dragging = false,
    this.thumbOffset = 0,
    this.thumbExtent,
  });

  final Axis axis;
  final AmalfiScrollbarStyle style;

  /// How far an overlay bar is expanded, 0–1.
  final double expansion;

  /// Whether the pointer is over a legacy bar.
  final bool hovered;

  /// Whether the thumb is being dragged.
  final bool dragging;

  /// Where the thumb starts along the bar, in points.
  final double thumbOffset;

  /// The thumb's length along the bar, in points; null: no thumb.
  final double? thumbExtent;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final thickness = AmalfiScrollbarMetrics.thicknessOf(style);
    final overlay = style == AmalfiScrollbarStyle.overlay;
    final t = overlay
        ? (expansion.isFinite ? expansion.clamp(0.0, 1.0) : 0.0)
        : 1.0;
    final thumbThickness = overlay
        ? lerpDouble(
                AmalfiScrollbarMetrics.thinThumb,
                AmalfiScrollbarMetrics.thumb,
                t,
              ) ??
              AmalfiScrollbarMetrics.thumb
        : AmalfiScrollbarMetrics.thumb;
    final inset = ((thickness - thumbThickness) / 2).roundToDouble();
    final thumbColor = dragging
        ? colors.textPrimary
        : overlay
        ? Color.lerp(colors.textTertiary, colors.textSecondary, t) ??
              colors.textSecondary
        : hovered
        ? colors.textSecondary
        : colors.textTertiary;
    final extent = thumbExtent;
    final vertical = axis == Axis.vertical;

    Widget track = DecoratedBox(
      decoration: AmalfiShapeDecoration(
        color: colors.surfaceSunken,
        shape: AmalfiSmoothBorder(
          radius: overlay ? thickness / 2 : 0,
          side: BorderSide(
            color: colors.lineSeparator,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
    );
    if (overlay) track = Opacity(opacity: t, child: track);

    return SizedBox(
      width: vertical ? thickness : null,
      height: vertical ? null : thickness,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!overlay || t > 0) Positioned.fill(child: track),
          if (extent != null && extent > 0)
            Positioned(
              left: vertical ? inset : thumbOffset.roundToDouble(),
              top: vertical ? thumbOffset.roundToDouble() : inset,
              width: vertical ? thumbThickness : extent.roundToDouble(),
              height: vertical ? extent.roundToDouble() : thumbThickness,
              child: DecoratedBox(
                decoration: AmalfiShapeDecoration(
                  color: thumbColor,
                  shape: AmalfiSmoothBorder(radius: thumbThickness / 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The square between two legacy scroll bars (`Scrollbars/Corner`).
class AmalfiScrollbarCorner extends StatelessWidget {
  const AmalfiScrollbarCorner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return SizedBox.square(
      dimension: AmalfiScrollbarMetrics.corner,
      child: DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: colors.surfaceSunken,
          shape: AmalfiSmoothBorder(
            side: BorderSide(
              color: colors.lineSeparator,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
        ),
      ),
    );
  }
}
