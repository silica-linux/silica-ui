// Push buttons (normal, default, destructive; push, bevel, borderless and round bezels), the
// help button, toggle buttons and image buttons.
//
// Measured: push button 24 high with radius ~8, normal `#ececec` / `#373737`, default sRGB
// `#007aff` with white text (misc.md › Alert); small 22 high (MU-41); the toggle key of the
// Calculator lightens when on (calculator.md › States); image buttons of the Control Center media
// module: 30 × 30, glyph `#b7b8bd` at rest, `#bebfc4` under the pointer, white `#f7f7f8` pressed,
// `#9d9ea3` disabled, no pill and no size change (controlcenter.md › Now Playing).

import 'package:flutter/widgets.dart';

import 'control_style.dart';

/// What a button does: decides its color (Return for the default one is up to the app).
enum ButtonRole { normal, primary, destructive }

/// The shape of a button.
enum ButtonBezel {
  /// The rounded push button (radius ~8 at 24 pt).
  push,

  /// A squarer bezel for icons and options (radius 4, provisional).
  bevel,

  /// No bezel: only the text or the icon.
  borderless,

  /// A circle as wide as it is high (help, round icon buttons).
  circle,
}

/// The horizontal padding of the label (provisional; Save card: "Annulla" in 69 pt).
double _padding(ControlSize size) => switch (size) {
  ControlSize.mini => 6,
  ControlSize.small => 10,
  ControlSize.regular => 12,
  ControlSize.large => 14,
};

/// A push button: label and/or icon. `onPressed` null disables it. The action fires on release
/// inside the button, or with Space when it has the keyboard focus.
class SilicaButton extends StatelessWidget {
  const SilicaButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.role = ButtonRole.normal,
    this.bezel = ButtonBezel.push,
    this.size = ControlSize.regular,
    this.minWidth = 0,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(label != null || icon != null);

  final String? label;

  /// An icon drawn in the color it receives, before the label.
  final Widget Function(Color color)? icon;
  final VoidCallback? onPressed;
  final ButtonRole role;
  final ButtonBezel bezel;
  final ControlSize size;

  /// A minimum width (the alert buttons are 80 pt).
  final double minWidth;
  final FocusNode? focusNode;
  final bool autofocus;

  /// For accessibility, when there is no label (icon only).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel ?? label,
    child: ControlInteraction(
      enabled: onPressed != null,
      onActivate: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, state) => ButtonFace(
        state: state,
        role: role,
        bezel: bezel,
        size: size,
        minWidth: minWidth,
        child: _content(state),
      ),
    ),
  );

  Widget Function(Color) _content(ControlState state) => (color) {
    final icon = this.icon, label = this.label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) icon(color),
        if (icon != null && label != null) const SizedBox(width: 4),
        if (label != null)
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: controlTextStyle(size, color),
          ),
      ],
    );
  };
}

/// The face of a button in a state: bezel, fill and content color. Shared by the push, toggle,
/// help, pop-up and pull-down buttons.
class ButtonFace extends StatelessWidget {
  const ButtonFace({
    super.key,
    required this.state,
    required this.child,
    this.role = ButtonRole.normal,
    this.bezel = ButtonBezel.push,
    this.size = ControlSize.regular,
    this.on = false,
    this.minWidth = 0,
    this.width,
    this.padding,
    this.alignment = Alignment.center,
  });

  final ControlState state;
  final ButtonRole role;
  final ButtonBezel bezel;
  final ControlSize size;

  /// A toggle button that is on.
  final bool on;
  final double minWidth;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final Widget Function(Color color) child;

  @override
  Widget build(BuildContext context) {
    final colors = ControlColors.of(context);
    final (fill, color) = faceColors(context, colors);
    final height = buttonHeight(size);
    final radius = switch (bezel) {
      ButtonBezel.push || ButtonBezel.borderless => buttonRadius(size),
      ButtonBezel.bevel => 4.0,
      ButtonBezel.circle => height / 2,
    };
    final round = bezel == ButtonBezel.circle;
    return FocusRing(
      visible: state.focused,
      radius: radius,
      child: Container(
        key: const ValueKey('button face'),
        height: height,
        width: round ? height : width,
        constraints: round ? null : BoxConstraints(minWidth: minWidth),
        padding: round
            ? null
            : padding ?? EdgeInsets.symmetric(horizontal: _padding(size)),
        decoration: fill == null
            ? null
            : BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(radius),
              ),
        // The label carries no semantics of its own: the control has them.
        child: ExcludeSemantics(
          child: Align(
            alignment: alignment,
            widthFactor: width == null && !round ? 1 : null,
            child: child(color),
          ),
        ),
      ),
    );
  }

  /// The fill (null: none) and the content color.
  (Color?, Color) faceColors(BuildContext context, ControlColors colors) {
    final borderless = bezel == ButtonBezel.borderless;
    if (!state.enabled) {
      return (borderless ? null : colors.bezel, colors.textDisabled);
    }
    final pressed = state.pressed;
    if (borderless) {
      final rest = role == ButtonRole.primary && state.active
          ? ControlAccent.of(context)
          : role == ButtonRole.destructive
          ? colors.destructiveText
          : colors.text;
      // Pressed: the text darkens (lightens in dark), no fill (provisional).
      return (null, pressed ? pressedFill(rest, dark: !colors.dark) : rest);
    }
    switch (role) {
      // In an inactive window the default button loses the accent (provisional: the normal
      // button; the accent fills turn gray, calculator.md).
      case ButtonRole.primary when state.active:
        final accent = ControlAccent.of(context);
        return (
          pressed ? pressedFill(accent, dark: colors.dark) : accent,
          colors.accentText,
        );
      case ButtonRole.destructive:
        return (
          pressed
              ? pressedFill(colors.destructive, dark: colors.dark)
              : colors.destructive,
          colors.destructiveText,
        );
      default:
        return (
          pressed
              ? colors.bezelPressed
              : on
              ? colors.bezelOn
              : colors.bezel,
          colors.text,
        );
    }
  }
}

/// The help button: a round button with "?" (provisional size: the button height).
class HelpButton extends StatelessWidget {
  const HelpButton({
    super.key,
    required this.onPressed,
    this.size = ControlSize.regular,
    this.semanticLabel = 'Help',
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final ControlSize size;
  final String semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel,
    child: ControlInteraction(
      enabled: onPressed != null,
      onActivate: onPressed,
      focusNode: focusNode,
      builder: (context, state) => ButtonFace(
        state: state,
        bezel: ButtonBezel.circle,
        size: size,
        child: (color) => ExcludeSemantics(
          child: Text(
            '?',
            style: controlTextStyle(size, color, weight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}

/// A button that stays on or off (the Calculator's 2nd key): lighter when on.
class ToggleButton extends StatelessWidget {
  const ToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.icon,
    this.bezel = ButtonBezel.push,
    this.size = ControlSize.regular,
    this.minWidth = 0,
    this.focusNode,
    this.semanticLabel,
  }) : assert(label != null || icon != null);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final Widget Function(Color color)? icon;
  final ButtonBezel bezel;
  final ControlSize size;
  final double minWidth;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      button: true,
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel ?? label,
      child: ControlInteraction(
        enabled: onChanged != null,
        onActivate: onChanged == null ? null : () => onChanged(!value),
        focusNode: focusNode,
        builder: (context, state) => ButtonFace(
          state: state,
          bezel: bezel,
          size: size,
          on: value,
          minWidth: minWidth,
          child: (color) {
            final icon = this.icon, label = this.label;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) icon(color),
                if (icon != null && label != null) const SizedBox(width: 4),
                if (label != null)
                  Text(
                    label,
                    maxLines: 1,
                    style: controlTextStyle(size, color),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The glyph colors of an image button.
@immutable
class ImageButtonColors {
  const ImageButtonColors({
    required this.rest,
    required this.hover,
    required this.pressed,
    required this.disabled,
  });

  final Color rest;
  final Color hover;
  final Color pressed;
  final Color disabled;

  /// On a dark or gray glass module (the Control Center media module, measured).
  static const ImageButtonColors onGlass = ImageButtonColors(
    rest: Color(0xFFB7B8BD),
    hover: Color(0xFFBEBFC4),
    pressed: Color(0xFFF7F7F8),
    disabled: Color(0xFF9D9EA3),
  );

  /// On a light window background (provisional: the same steps, darker).
  static const ImageButtonColors light = ImageButtonColors(
    rest: Color(0xFF6E6E73),
    hover: Color(0xFF5F5F64),
    pressed: Color(0xFF1A1A1A),
    disabled: Color(0xFFB4B4B8),
  );

  /// On a dark window background: the measured module colors.
  static ImageButtonColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? onGlass
      : light;
}

/// A glyph without a bezel (transport buttons): only the glyph color changes, under the pointer
/// and pressed; the action on release.
class ImageButton extends StatelessWidget {
  const ImageButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.side = 30,
    this.colors,
    this.focusNode,
  });

  final Widget Function(Color color) icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  /// The square the button takes (30 in the media module).
  final double side;
  final ImageButtonColors? colors;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel,
    child: ControlInteraction(
      enabled: onPressed != null,
      onActivate: onPressed,
      focusNode: focusNode,
      builder: (context, state) {
        final c = colors ?? ImageButtonColors.of(context);
        final color = !state.enabled
            ? c.disabled
            : state.pressed
            ? c.pressed
            : state.hovered
            ? c.hover
            : c.rest;
        return FocusRing(
          visible: state.focused,
          radius: 6,
          child: SizedBox.square(
            dimension: side,
            child: Center(child: icon(color)),
          ),
        );
      },
    ),
  );
}
