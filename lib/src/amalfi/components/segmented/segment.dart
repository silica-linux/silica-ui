// A segment of an Amalfi segmented control or action capsule, and the small pieces both
// draw with: the glyph box, the label measure, the focus halo.

import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import '../../whole_points.dart';

/// One segment: a text label or an icon, with its own enabled state.
///
/// An icon is any widget (an Icon Kit glyph as an SVG, an [Icon]); it is laid out in a square
/// of the glyph size of the control and receives the colour of its state through
/// [IconTheme] (`IconTheme.of(context).color`), so an SVG should read it there.
@immutable
class AmalfiSegment {
  /// A text segment.
  const AmalfiSegment.text(
    String this.label, {
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
  }) : icon = null;

  /// An icon segment; [semanticLabel] is what screen readers say for it.
  const AmalfiSegment.icon(
    Widget this.icon, {
    required String this.semanticLabel,
    this.enabled = true,
    this.tooltip,
  }) : label = null;

  /// The text of a text segment; null for an icon segment.
  final String? label;

  /// The glyph of an icon segment; null for a text segment.
  final Widget? icon;

  /// Whether this segment can be pressed or chosen (the whole control may still be disabled).
  final bool enabled;

  /// The label for screen readers; null: [label].
  final String? semanticLabel;

  /// A tooltip shown when the pointer rests on the segment; null: none.
  final String? tooltip;

  /// Whether this is an icon segment.
  bool get isIcon => icon != null;

  /// What screen readers say for it.
  String get semanticsLabel => semanticLabel ?? label ?? '';
}

/// The width of [text] in [style], rounded up to the 4 pt grid as the kit draws label boxes.
double amalfiSegmentLabelWidth(
  BuildContext context,
  String text,
  TextStyle style,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return ceilToWholePoints(width, AmalfiGrid.base);
}

/// An icon in a square of [size], in [color].
class AmalfiSegmentGlyph extends StatelessWidget {
  const AmalfiSegmentGlyph({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: IconTheme.merge(
      data: IconThemeData(color: color, size: size),
      child: Center(child: child),
    ),
  );
}
