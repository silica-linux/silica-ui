// Icon buttons (kit `Buttons/Icon/<Round|Square>/<size>/<state>`) and the help button (kit
// `Buttons/Help/<state>`): square controls with the opaque control look.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_surface.dart';

/// The outline of an [AmalfiIconButton].
enum AmalfiIconButtonShape {
  /// A circle.
  round,

  /// A rounded square (radius 6 / 7 / 9 / 10 by size).
  square,
}

/// The measures of icon buttons per size, from the kit masters `Buttons/Icon/*`.
abstract final class AmalfiIconButtonMetrics {
  /// The glyph size: 12 for Mini, 16 for the others.
  static double glyph(AmalfiControlSize size) =>
      size == AmalfiControlSize.mini ? 12 : 16;

  /// The corner radius of [shape] at [size].
  static double radius(AmalfiIconButtonShape shape, AmalfiControlSize size) =>
      switch (shape) {
        AmalfiIconButtonShape.round => AmalfiRadii.capsule(size.height),
        AmalfiIconButtonShape.square => switch (size) {
          AmalfiControlSize.mini => 6,
          AmalfiControlSize.small => AmalfiRadii.smallControl,
          AmalfiControlSize.regular => AmalfiRadii.regularControl,
          AmalfiControlSize.large => 10,
        },
      };
}

/// A square button of [size] showing [icon] (an `AmalfiButtonGlyph`, an `Icon` or any widget that
/// reads [IconTheme]) centred, in the `Text/Primary` colour (`Text/Tertiary` disabled).
///
/// Give it a [semanticLabel]: the glyph alone says nothing to a screen reader.
class AmalfiIconButton extends StatelessWidget {
  const AmalfiIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.shape = AmalfiIconButtonShape.round,
    this.size = AmalfiControlSize.regular,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;

  /// What screen readers announce ("Add").
  final String semanticLabel;

  final AmalfiIconButtonShape shape;
  final AmalfiControlSize size;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final look = amalfiControlLook(AmalfiTheme.of(context).colors);
    final side = size.height;
    final border = AmalfiSmoothBorder(
      radius: AmalfiIconButtonMetrics.radius(shape, size),
    );
    return AmalfiButtonBehavior(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      builder: (context, visual) => AmalfiButtonSurface(
        look: look,
        shape: border,
        visual: visual,
        child: SizedBox.square(
          dimension: side,
          child: Center(
            child: AmalfiButtonIconTheme(
              color: look.contentFor(visual),
              size: AmalfiIconButtonMetrics.glyph(size),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// The help button: a 24 pt control with a "?" (Label), that opens help for what is around
/// it.
class AmalfiHelpButton extends StatelessWidget {
  const AmalfiHelpButton({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Help',
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  /// The side.
  static const double side = 24;

  /// The corner radius (kit: 11).
  static const double radius = 11;

  /// Where the "?" box starts (kit: 8, 5; the glyph is optically centred).
  static const Offset labelOffset = Offset(8, 5);

  @override
  Widget build(BuildContext context) {
    final look = amalfiControlLook(AmalfiTheme.of(context).colors);
    const shape = AmalfiSmoothBorder(radius: radius);
    return AmalfiButtonBehavior(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      builder: (context, visual) => AmalfiButtonSurface(
        look: look,
        shape: shape,
        visual: visual,
        child: SizedBox.square(
          dimension: side,
          child: Padding(
            padding: EdgeInsets.only(left: labelOffset.dx, top: labelOffset.dy),
            child: Align(
              alignment: Alignment.topLeft,
              child: AmalfiGridWidth(
                step: 1,
                child: Text(
                  '?',
                  maxLines: 1,
                  softWrap: false,
                  style: AmalfiType.label(color: look.contentFor(visual)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
