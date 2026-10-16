// The Amalfi tooltip bubble (kit `Tooltips/Tooltip/One Line|Two Lines|Shortcut`): Glass/Thick,
// radius 8, Callout text, padding 4 × 8, an optional shortcut 8 after the label.

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';

/// The measures of the tooltip, from the kit masters `Tooltips/*`.
abstract final class AmalfiTooltipMetrics {
  /// The space around the content.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// Between the label and the shortcut.
  static const double shortcutGap = 8;

  /// The corner radius (`materials.md`: tooltips are Glass/Thick, radius 8).
  static const double radius = 8;

  /// The widest tooltip; longer text wraps (`Tooltips/Tooltip/Two Lines` is 224 wide).
  static const double maxWidth = 224;

  /// Between the tooltip and its target (`Tooltips/Placement/*`).
  static const double distance = 8;
}

/// A tooltip bubble: [message] in Callout `Text/Primary`, and [shortcut] (`⌘D`) in Callout
/// `Text/Secondary` after it, on Glass/Thick.
///
/// It is as wide as its text, up to [maxWidth]; longer messages wrap. Text boxes are rounded
/// up to the 4 pt grid, as in the kit, so every edge lands on the grid. To show one when the
/// pointer rests on a control, use `AmalfiTooltipRegion`.
class AmalfiTooltip extends StatelessWidget {
  const AmalfiTooltip({
    super.key,
    required this.message,
    this.shortcut,
    this.maxWidth = AmalfiTooltipMetrics.maxWidth,
    this.opaque = false,
  });

  /// The text.
  final String message;

  /// The keyboard shortcut shown after the text; null: none.
  final String? shortcut;

  /// The widest the tooltip gets, padding included.
  final double maxWidth;

  /// Whether the glass is drawn without blur (see [AmalfiGlass.opaque]).
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final shortcut = this.shortcut;
    return Semantics(
      container: true,
      label: shortcut == null ? message : '$message, $shortcut',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AmalfiGlass(
            material: AmalfiMaterials.thick,
            radius: AmalfiTooltipMetrics.radius,
            kind: AmalfiGlassKind.tooltip,
            opaque: opaque,
            child: Padding(
              padding: AmalfiTooltipMetrics.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: AmalfiWholePoints(
                      step: AmalfiGrid.base,
                      child: Text(
                        message,
                        style: AmalfiType.callout(color: colors.textPrimary),
                      ),
                    ),
                  ),
                  if (shortcut != null) ...[
                    const SizedBox(width: AmalfiTooltipMetrics.shortcutGap),
                    AmalfiWholePoints(
                      step: AmalfiGrid.base,
                      child: Text(
                        shortcut,
                        maxLines: 1,
                        softWrap: false,
                        style: AmalfiType.callout(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
