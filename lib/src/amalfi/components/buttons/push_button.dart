// Push buttons (kit `Buttons/Push/<Primary|Secondary|Destructive|Borderless|Glass>/<size>/
// <state>`): capsules 20 / 24 / 28 / 32 tall, as wide as their label.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_surface.dart';

/// The kinds of push button.
enum AmalfiPushButtonVariant {
  /// The default action: `Accent/Amalfi` fill, white label.
  primary,

  /// Any other action: `Surface/Control` with a border and a soft shadow.
  secondary,

  /// An action that destroys data: `Palette/Terracotta` fill, white label.
  destructive,

  /// No background until hovered: an `Accent/Amalfi` label.
  borderless,

  /// Glass/Regular, Glass/Thick while hovered or pressed: over content, media and wallpaper.
  glass,
}

/// The measures of push buttons per size, from the kit masters `Buttons/Push/*`.
abstract final class AmalfiPushButtonMetrics {
  /// The space before and after the content.
  static double padding(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini || AmalfiControlSize.small => 8,
    AmalfiControlSize.regular => 12,
    AmalfiControlSize.large => 16,
  };

  /// The label box is rounded up to a multiple of this ("Button" in Body Emphasis: 40.7
  /// wide, frame 48; the kit's push and link labels are all on the 8 pt grid).
  static const double labelStep = 8;

  /// Between the icon and the label.
  static double gap(AmalfiControlSize size) =>
      size == AmalfiControlSize.large ? 8 : 4;

  /// The label style: Caption, Label, Body Emphasis, Title 3.
  static TextStyle labelStyle(AmalfiControlSize size, Color color) =>
      switch (size) {
        AmalfiControlSize.mini => AmalfiType.caption(color: color),
        AmalfiControlSize.small => AmalfiType.label(color: color),
        AmalfiControlSize.regular => AmalfiType.bodyEmphasis(color: color),
        AmalfiControlSize.large => AmalfiType.title3(color: color),
      };
}

/// A push button: [label] (and an optional [icon] before it) in a capsule of [size], drawn as
/// [variant].
///
/// It is as wide as its content, the label box rounded up to the 4 pt grid as in the kit.
/// [onPressed] null disables it. Hover and press fade with `fade.quick` (60 ms out); the
/// focus halo shows for keyboard focus; Space and Return activate it.
class AmalfiPushButton extends StatelessWidget {
  const AmalfiPushButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AmalfiPushButtonVariant.secondary,
    this.size = AmalfiControlSize.regular,
    this.icon,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AmalfiPushButtonVariant variant;
  final AmalfiControlSize size;

  /// A glyph before the label, drawn at the size's icon size in the label colour (through
  /// [IconTheme]).
  final Widget? icon;

  /// What screen readers announce; null: [label].
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The look of [variant] in [colors].
  static AmalfiButtonLook lookOf(
    AmalfiPushButtonVariant variant,
    AmalfiColors colors,
    Brightness brightness,
  ) => switch (variant) {
    AmalfiPushButtonVariant.primary => AmalfiButtonLook(
      fill: colors.accentAmalfi,
      fillPressed: colors.accentAmalfiPressed,
      fillDisabled: colors.surfaceSunken,
      hoverOverlay: colors.stateHoverOverlay,
      content: colors.textOnAccent,
      contentDisabled: colors.textTertiary,
    ),
    AmalfiPushButtonVariant.secondary => amalfiControlLook(colors),
    AmalfiPushButtonVariant.destructive => AmalfiButtonLook(
      fill: colors.paletteTerracotta,
      fillDisabled: colors.surfaceSunken,
      hoverOverlay: colors.stateHoverOverlay,
      pressOverlay: colors.statePressOverlay,
      content: colors.textOnAccent,
      contentDisabled: colors.textTertiary,
    ),
    AmalfiPushButtonVariant.borderless => AmalfiButtonLook(
      fillHovered: colors.accentAmalfiSoft,
      fillPressed: colors.accentAmalfiSoft,
      content: colors.accentAmalfi,
      contentDisabled: colors.textTertiary,
    ),
    AmalfiPushButtonVariant.glass => AmalfiButtonLook(
      glass: AmalfiMaterials.regular,
      glassActive: AmalfiMaterials.thick,
      pressOverlay: colors.accentAmalfiSoft,
      content: colors.textPrimary,
      contentDisabled: colors.textTertiary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final look = lookOf(variant, theme.colors, theme.brightness);
    final height = size.height;
    final shape = AmalfiSmoothBorder(radius: AmalfiRadii.capsule(height));
    final icon = this.icon;
    return AmalfiButtonBehavior(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      builder: (context, visual) {
        final color = look.contentFor(visual);
        return AmalfiButtonSurface(
          look: look,
          shape: shape,
          visual: visual,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AmalfiPushButtonMetrics.padding(size),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    AmalfiButtonIconTheme(
                      color: color,
                      size: size.iconSize,
                      child: icon,
                    ),
                    SizedBox(width: AmalfiPushButtonMetrics.gap(size)),
                  ],
                  Flexible(
                    child: AmalfiGridWidth(
                      step: AmalfiPushButtonMetrics.labelStep,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AmalfiPushButtonMetrics.labelStyle(size, color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
