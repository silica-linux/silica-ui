// A list of labelled toggles under a heading (kit `Toggles/Checkbox Group/List`,
// `Toggles/Radio Group/List`).

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import 'control_kit.dart';

/// The measures of a toggle group, from `Toggles/Checkbox Group/List`.
abstract final class AmalfiToggleGroupMetrics {
  /// Around the heading and the toggles.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 10, 8, 8);

  /// Between the heading and the first toggle, and between toggles.
  static const double gap = 4;
}

/// Labelled toggles ([children]: `AmalfiCheckbox` or `AmalfiRadio` with labels) in a column,
/// under an optional [heading] in Headline `Text/Primary`.
///
/// For radio buttons that choose one value, [AmalfiRadioGroup] builds this with the keyboard
/// handling of a group.
class AmalfiToggleGroup extends StatelessWidget {
  const AmalfiToggleGroup({super.key, this.heading, required this.children});

  final String? heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final heading = this.heading;
    final items = <Widget>[
      if (heading != null)
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
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmalfiType.headline(color: colors.textPrimary),
              ),
            ),
          ),
        ),
      ...children,
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: AmalfiToggleGroupMetrics.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0) const SizedBox(height: AmalfiToggleGroupMetrics.gap),
              item,
            ],
          ],
        ),
      ),
    );
  }
}
