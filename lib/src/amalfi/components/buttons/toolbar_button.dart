// Toolbar buttons (kit `Buttons/Toolbar/<Icon|Icon + Label>/<state>`): Glass/Regular items of
// a toolbar (`materials.md`: toolbar controls are Regular glass; `components.md`: a single icon
// button is a 32 × 32 circle).

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_surface.dart';

/// The measures of toolbar buttons, from the kit masters `Buttons/Toolbar/*`.
abstract final class AmalfiToolbarButtonMetrics {
  /// The icon-only button's side.
  static const double side = 32;

  /// The size of the button with a label (the label may make it wider).
  static const Size labeled = Size(56, 44);

  /// The corner radius of the labelled button (the icon-only one is a circle).
  static const double labeledRadius = 16;

  /// The glyph size.
  static const double glyph = AmalfiControlIcons.toolbar;

  /// The top of the glyph in the labelled button.
  static const double labeledGlyphTop = 6;

  /// The top of the label in the labelled button.
  static const double labelTop = 26;
}

/// A toolbar button: [icon] on Glass/Regular, a 32 pt circle; with a [label], 56 × 44 with the
/// label (Caption) under the glyph.
///
/// Hovered it gets a `Line/Separator` highlight, pressed a `Line/Border` one. Without a
/// [label], give it a [semanticLabel].
class AmalfiToolbarButton extends StatelessWidget {
  const AmalfiToolbarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;

  /// The text under the glyph; null: an icon-only button.
  final String? label;

  /// What screen readers announce; null: [label].
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final look = AmalfiButtonLook(
      glass: AmalfiMaterials.regular,
      hoverOverlay: colors.lineSeparator,
      pressOverlay: colors.lineBorder,
      content: colors.textPrimary,
      contentDisabled: colors.textTertiary,
    );
    final label = this.label;
    final shape = AmalfiSmoothBorder(
      radius: label == null
          ? AmalfiRadii.capsule(AmalfiToolbarButtonMetrics.side)
          : AmalfiToolbarButtonMetrics.labeledRadius,
    );
    return AmalfiButtonBehavior(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? label,
      builder: (context, visual) {
        final color = look.contentFor(visual);
        final glyph = AmalfiButtonIconTheme(
          color: color,
          size: AmalfiToolbarButtonMetrics.glyph,
          child: icon,
        );
        final Widget content;
        if (label == null) {
          content = SizedBox.square(
            dimension: AmalfiToolbarButtonMetrics.side,
            child: Center(child: glyph),
          );
        } else {
          content = ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: AmalfiToolbarButtonMetrics.labeled.width,
            ),
            child: SizedBox(
              height: AmalfiToolbarButtonMetrics.labeled.height,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: AmalfiToolbarButtonMetrics.labeledGlyphTop,
                  ),
                  glyph,
                  const SizedBox(
                    height:
                        AmalfiToolbarButtonMetrics.labelTop -
                        AmalfiToolbarButtonMetrics.labeledGlyphTop -
                        AmalfiToolbarButtonMetrics.glyph,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: AmalfiToolbarButtonMetrics.labeled.width,
                    ),
                    child: AmalfiGridWidth(
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: AmalfiType.caption(color: color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return AmalfiButtonSurface(
          look: look,
          shape: shape,
          visual: visual,
          child: content,
        );
      },
    );
  }
}
