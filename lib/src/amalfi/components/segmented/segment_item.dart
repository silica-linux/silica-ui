// An item of a segmented control (kit `Segments/Text Item/*`, `Segments/Icon Item/*`): a
// capsule as tall as the track minus its padding, holding a label or a glyph.
//
// Rest: no fill. Hover: `Line/Separator`. Selected: `Surface/Control` with a 1 pt
// `Line/Border` inside and the level 1 shadow. Disabled: content in `Text/Tertiary`.
// Labels: Caption (Mini), Label (Small), Body (Regular, Large), centred; glyphs 12 (Mini,
// Small) or 16 (Regular, Large), centred.

import 'package:flutter/widgets.dart';

import 'capsule.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'metrics.dart';
import 'segment.dart';

/// One item of an [AmalfiSegmentedControl], drawn in a given state.
///
/// The control lays its items out and drives their state; use this widget directly only to
/// build a control of your own. [width] null: the kit width of [size] (or the label's, if
/// wider).
class AmalfiSegmentItem extends StatelessWidget {
  const AmalfiSegmentItem({
    super.key,
    required this.segment,
    this.size = AmalfiControlSize.regular,
    this.selected = false,
    this.hovered = false,
    this.enabled = true,
    this.showSelection = true,
    this.width,
    this.magnification = 1,
  });

  final AmalfiSegment segment;
  final AmalfiControlSize size;

  /// Whether the item is chosen.
  final bool selected;

  /// Whether the pointer is on it (only drawn when not [selected]).
  final bool hovered;

  /// Whether it can be chosen; false draws the content in `Text/Tertiary`. The segment's own
  /// [AmalfiSegment.enabled] also counts.
  final bool enabled;

  /// Whether a [selected] item draws its own selection capsule; a select-one control draws
  /// one sliding capsule for all its items instead.
  final bool showSelection;

  /// The item width; null: [preferredWidth].
  final double? width;

  /// The scale of the content (the lens magnifies the item under it); 1: none.
  final double magnification;

  /// The width of an item of [segment] in [size]: the kit's, or the label's with
  /// [AmalfiSegmentMetrics.textItemPadding] on each side if wider.
  static double preferredWidth(
    BuildContext context,
    AmalfiSegment segment,
    AmalfiControlSize size,
  ) {
    final m = AmalfiSegmentSizeMetrics.of(size);
    final label = segment.label;
    if (label == null) return m.iconItemWidth;
    final text = amalfiSegmentLabelWidth(context, label, m.itemLabelStyle());
    final w = text + 2 * AmalfiSegmentMetrics.textItemPadding;
    return w > m.textItemWidth ? w : m.textItemWidth;
  }

  /// The selection capsule of an item of [height] (`Surface/Control`, `Line/Border` inside,
  /// level 1 shadow).
  static ShapeDecoration selectionDecoration(
    AmalfiThemeData theme,
    double height,
  ) => ShapeDecoration(
    color: theme.colors.surfaceControl,
    shape: AmalfiCapsuleBorder(
      radius: height / 2,
      side: BorderSide(
        color: theme.colors.lineBorder,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    ),
    shadows: [
      for (final s in theme.shadows.level1) AmalfiSegmentShadow.from(s),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final m = AmalfiSegmentSizeMetrics.of(size);
    final h = m.itemHeight;
    final w = width ?? preferredWidth(context, segment, size);
    final on = enabled && segment.enabled;
    final color = on ? colors.textPrimary : colors.textTertiary;
    final decoration = selected && showSelection
        ? selectionDecoration(theme, h)
        : ShapeDecoration(
            color: hovered && on && !selected ? colors.lineSeparator : null,
            shape: AmalfiCapsuleBorder(radius: h / 2),
          );

    final Widget content;
    if (segment.icon case final icon?) {
      content = Positioned(
        left: (w - m.itemGlyph) / 2,
        top: (h - m.itemGlyph) / 2,
        child: AmalfiSegmentGlyph(
          key: const ValueKey('amalfi-segment-item-glyph'),
          size: m.itemGlyph,
          color: color,
          child: icon,
        ),
      );
    } else {
      final lineHeight = m.itemLabelToken.lineHeight ?? m.itemLabelToken.size;
      content = Positioned(
        left: 0,
        top: (h - lineHeight) / 2,
        width: w,
        height: lineHeight,
        child: Text(
          segment.label ?? '',
          key: const ValueKey('amalfi-segment-item-label'),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: m.itemLabelStyle(color: color),
        ),
      );
    }

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: const ValueKey('amalfi-segment-item-background'),
              decoration: decoration,
            ),
          ),
          if (magnification == 1)
            content
          else
            Positioned.fill(
              child: Transform.scale(
                scale: magnification,
                child: Stack(clipBehavior: Clip.none, children: [content]),
              ),
            ),
        ],
      ),
    );
  }
}

/// A drop shadow blurred as the kit blurs it: σ = blur / 2 (CSS `box-shadow`), where Flutter's
/// [BoxShadow] uses σ = 0.58 × blur + 0.5.
class AmalfiSegmentShadow extends BoxShadow {
  const AmalfiSegmentShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });

  /// [shadow] with the kit's blur.
  AmalfiSegmentShadow.from(BoxShadow shadow)
    : super(
        color: shadow.color,
        offset: shadow.offset,
        blurRadius: shadow.blurRadius,
        spreadRadius: shadow.spreadRadius,
        blurStyle: shadow.blurStyle,
      );

  @override
  double get blurSigma => blurRadius / 2;
}
