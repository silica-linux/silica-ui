// The Amalfi group box (kit `Group Boxes/Box/*`): related controls on a raised surface, with
// an optional title above it.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../../foundation/foundation.dart';

/// The measures of a group box, from `Group Boxes/Box/*`.
abstract final class AmalfiGroupBoxMetrics {
  /// Between the title and the box.
  static const double titleGap = 6;

  /// Inside the box, around its children.
  static const EdgeInsets padding = EdgeInsets.all(12);

  /// Between two children.
  static const double spacing = 8;

  /// The corner radius of the box.
  static const double radius = 12;
}

/// A box of related controls: [children] in a column (8 apart, aligned to the leading edge)
/// on `Surface/Raised` with a `Line/Border` rim, radius 12, padding 12; [title] above it in
/// Headline `Text/Secondary`.
///
/// The box is as wide as the width it is given (as wide as its widest child when the width
/// is unbounded). When not [enabled] the whole group (title, box and controls) is at
/// [AmalfiStates.disabledOpacity] and its controls ignore input: give it enabled controls,
/// so they are not dimmed twice. Boxes nest (`Group Boxes/Box/Nested`).
class AmalfiGroupBox extends StatelessWidget {
  const AmalfiGroupBox({
    super.key,
    this.title,
    required this.children,
    this.enabled = true,
  });

  /// The title above the box; null: an untitled box.
  final String? title;

  final List<Widget> children;

  /// Whether the group and its controls are enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final title = this.title;
    final box = DecoratedBox(
      key: AmalfiLayerKeys.body,
      decoration: AmalfiShapeDecoration(
        color: colors.surfaceRaised,
        shape: AmalfiSmoothBorder(
          radius: AmalfiGroupBoxMetrics.radius,
          side: BorderSide(color: colors.lineBorder),
        ),
      ),
      child: Padding(
        padding: AmalfiGroupBoxMetrics.padding,
        child: Column(
          key: AmalfiLayerKeys.content,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AmalfiGroupBoxMetrics.spacing),
              child,
            ],
          ],
        ),
      ),
    );
    final body = LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedWidth
          ? SizedBox(width: constraints.maxWidth, child: box)
          : box,
    );
    if (title == null) return _dimmed(Semantics(container: true, child: body));
    return _dimmed(
      Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: SizedBox(
                height:
                    AmalfiType.headlineToken.lineHeight ??
                    AmalfiType.headlineToken.size,
                child: AmalfiWholePoints(
                  key: AmalfiLayerKeys.label,
                  step: AmalfiGrid.base,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmalfiType.headline(color: colors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AmalfiGroupBoxMetrics.titleGap),
            body,
          ],
        ),
      ),
    );
  }

  /// [group] as a whole at [AmalfiStates.disabledOpacity], out of reach of the pointer, the
  /// keyboard focus and screen reader actions, when not [enabled].
  Widget _dimmed(Widget group) => enabled
      ? group
      : Opacity(
          opacity: AmalfiStates.disabledOpacity,
          child: IgnorePointer(child: ExcludeFocus(child: group)),
        );
}
