// The box of a checkbox or a radio button (kit `Toggles/Checkbox/*`, `Toggles/Radio/*`): its
// measures per size, its colours per state, and the labelled row both controls share
// (`Toggles/Checkbox/With Label/*`, `Toggles/Radio/With Label/*`).

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import 'control_kit.dart';

/// The measures of a checkbox or radio box of one size.
@immutable
class AmalfiToggleBoxMetrics {
  const AmalfiToggleBoxMetrics({
    required this.side,
    required this.radius,
    required this.markSize,
  });

  /// The side of the (square) box.
  final double side;

  /// The corner radius of the box.
  final double radius;

  /// The side of the mark (checkmark, dash or dot), centred in the box.
  final double markSize;

  /// The inset of the mark from the box's edges.
  double get markInset => (side - markSize) / 2;

  /// A checkbox of [size] (`Toggles/Checkbox/*`): Small and Regular 16 (radius 4 and 5),
  /// Large 20 (radius 6); a 12 pt glyph, 16 at Large. Mini draws as Small.
  static AmalfiToggleBoxMetrics checkbox(AmalfiControlSize size) =>
      switch (size) {
        AmalfiControlSize.mini || AmalfiControlSize.small =>
          const AmalfiToggleBoxMetrics(side: 16, radius: 4, markSize: 12),
        AmalfiControlSize.regular => const AmalfiToggleBoxMetrics(
          side: 16,
          radius: 5,
          markSize: 12,
        ),
        AmalfiControlSize.large => const AmalfiToggleBoxMetrics(
          side: 20,
          radius: 6,
          markSize: 16,
        ),
      };

  /// A radio button of [size] (`Toggles/Radio/*`): Small 16 (radius 7), Regular 16 and
  /// Large 20 (circles); the dot is an 8 pt circle. Mini draws as Small.
  static AmalfiToggleBoxMetrics radio(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini || AmalfiControlSize.small =>
      const AmalfiToggleBoxMetrics(side: 16, radius: 7, markSize: 8),
    AmalfiControlSize.regular => const AmalfiToggleBoxMetrics(
      side: 16,
      radius: 8,
      markSize: 8,
    ),
    AmalfiControlSize.large => const AmalfiToggleBoxMetrics(
      side: 20,
      radius: 10,
      markSize: 8,
    ),
  };
}

/// The measures of a labelled checkbox or radio row (`Toggles/*/With Label`).
abstract final class AmalfiToggleRowMetrics {
  /// Before the box and after the label.
  static const double padding = 4;

  /// Between the box and the label.
  static const double gap = 8;

  /// The height of the row.
  static const double height = 20;

  /// The space the label's box keeps after its text (the kit's label frames are the text
  /// rounded up to the 4 pt grid plus 8: "Show hidden files" 120, "Sort by name" 92).
  static const double labelTrailing = 8;
}

/// Draws a checkbox or radio box in [state]: [on] fills it with the accent and shows [mark]
/// (built with its colour); off it is a raised box with a border.
class AmalfiToggleBox extends StatelessWidget {
  const AmalfiToggleBox({
    super.key,
    required this.metrics,
    required this.on,
    required this.state,
    required this.mark,
  });

  final AmalfiToggleBoxMetrics metrics;

  /// Whether the box is on (checked, mixed or selected).
  final bool on;

  final AmalfiInteractionState state;

  /// Builds the mark in the given colour; only called when [on].
  final Widget Function(Color color) mark;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = state.enabled;
    final pressed = enabled && state.pressed;
    final hovered = enabled && state.hovered && !pressed;
    final border = BorderSide(
      color: !on && (pressed || hovered) && enabled
          ? colors.accentAmalfi
          : colors.lineBorder,
    );
    final Color fill;
    BorderSide side = BorderSide.none;
    var shadows = const <BoxShadow>[];
    if (!enabled) {
      fill = colors.surfaceSunken;
      side = border;
    } else if (on) {
      fill = pressed ? colors.accentAmalfiPressed : colors.accentAmalfi;
    } else {
      fill = pressed ? colors.accentAmalfiSoft : colors.surfaceRaised;
      side = border;
      shadows = amalfiControlShadow(colors);
    }
    final radius = metrics.radius;
    return SizedBox.square(
      dimension: metrics.side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: AmalfiLayerKeys.body,
              decoration: AmalfiShapeDecoration(
                color: fill,
                shape: AmalfiSmoothBorder(radius: radius, side: side),
                shadows: shadows,
              ),
            ),
          ),
          if (on && hovered)
            Positioned.fill(
              child: DecoratedBox(
                key: AmalfiLayerKeys.state,
                decoration: AmalfiShapeDecoration(
                  color: colors.stateHoverOverlay,
                  shape: AmalfiSmoothBorder(radius: radius),
                ),
              ),
            ),
          if (state.focused && enabled)
            Positioned.fill(
              child: AmalfiToggleFocusHalo(radius: radius, colors: colors),
            ),
          if (on)
            Positioned(
              left: metrics.markInset,
              top: metrics.markInset,
              width: metrics.markSize,
              height: metrics.markSize,
              child: KeyedSubtree(
                key: AmalfiLayerKeys.mark,
                child: mark(
                  enabled ? colors.textOnAccent : colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A box with its label after it (`Toggles/*/With Label`): 4 pt padding, the box, 8 pt, the
/// label in Body (`Text/Primary`, `Text/Tertiary` when disabled), 20 pt tall. The label box
/// is its text rounded up to the 4 pt grid plus [AmalfiToggleRowMetrics.labelTrailing].
class AmalfiToggleRow extends StatelessWidget {
  const AmalfiToggleRow({
    super.key,
    required this.box,
    required this.label,
    required this.enabled,
  });

  final Widget box;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AmalfiToggleRowMetrics.padding,
      ),
      child: SizedBox(
        height: AmalfiToggleRowMetrics.height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(key: AmalfiLayerKeys.control, child: box),
            const SizedBox(width: AmalfiToggleRowMetrics.gap),
            Flexible(
              child: SizedBox(
                height:
                    AmalfiType.bodyToken.lineHeight ??
                    AmalfiToggleRowMetrics.height,
                child: AmalfiWholePoints(
                  key: AmalfiLayerKeys.label,
                  step: AmalfiGrid.base,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AmalfiToggleRowMetrics.labelTrailing,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmalfiType.body(
                        color: enabled
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
