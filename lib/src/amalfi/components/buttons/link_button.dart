// The link button (kit `Buttons/Link/Link/<state>`): accent Body text, 24 tall, no background
// until pressed.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_surface.dart';
import 'push_button.dart';

/// A text link that acts as a button ("Learn more"): [label] in Body `Accent/Amalfi`, with 4
/// points on each side; pressed, an `Accent/Amalfi Soft` background (radius 7).
class AmalfiLinkButton extends StatelessWidget {
  const AmalfiLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  /// The height.
  static const double height = 24;

  /// The space on each side of the label.
  static const double padding = 4;

  /// The radius of the pressed background and of the focus halo.
  static const double radius = AmalfiRadii.smallControl;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final look = AmalfiButtonLook(
      fillPressed: colors.accentAmalfiSoft,
      content: colors.accentAmalfi,
      contentDisabled: colors.textTertiary,
    );
    const shape = AmalfiSmoothBorder(radius: radius);
    return AmalfiButtonBehavior(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, visual) => AmalfiButtonSurface(
        look: look,
        shape: shape,
        visual: visual,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AmalfiGridWidth(
                    step: AmalfiPushButtonMetrics.labelStep,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AmalfiType.body(color: look.contentFor(visual)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
