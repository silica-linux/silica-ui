// A token (kit `Fields/Token/Rest|Selected`): a 20 pt capsule with a Label text and a
// remove cross, `Accent/Amalfi Soft` with accent text at rest, `Accent/Amalfi` with white
// text when selected.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../../foundation/foundation.dart';
import 'metrics.dart';

/// A token of a token or search field: [label], then a cross that runs [onRemove].
///
/// [selected] draws it filled with the accent (the token Backspace removes next). A click
/// on the token runs [onPressed]. Without [onRemove] the cross still shows (the kit's look)
/// but does nothing.
class AmalfiToken extends StatelessWidget {
  const AmalfiToken({
    super.key,
    required this.label,
    this.selected = false,
    this.onRemove,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onRemove;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final ink = selected ? colors.textOnAccent : colors.accentAmalfi;
    return Semantics(
      label: label,
      selected: selected,
      button: onPressed != null,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: AmalfiShapeDecoration(
            color: selected ? colors.accentAmalfi : colors.accentAmalfiSoft,
            shape: const AmalfiSmoothBorder(
              radius: AmalfiTokenMetrics.height / 2,
            ),
          ),
          child: SizedBox(
            height: AmalfiTokenMetrics.height,
            child: Padding(
              padding: AmalfiTokenMetrics.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: AmalfiType.labelToken.lineHeight,
                    child: AmalfiWholePoints(
                      step: AmalfiGrid.base,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: AmalfiType.label(color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: AmalfiFieldMetrics.gap),
                  Semantics(
                    button: true,
                    label: 'Remove $label',
                    onTap: onRemove,
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onRemove,
                        child: AmalfiGlyph(
                          AmalfiGlyphs.xmark,
                          size: AmalfiTokenMetrics.removeGlyph,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
