// The system alert: 292 pt wide, thick glass with radius ~26, a 66 pt icon at the top left
// (19, 19), bold title at y 99 over 250 pt, message below, buttons 30 pt high.
// Buttons are stacked full width (262, 4 pt apart: Empty Trash, a busy volume, a single OK)
// or side by side (128 each, 6 pt apart: two equal choices, like keeping one of two file
// extensions, or Cancel / Delete). The default one is blue (sRGB `#007aff`, white text), a
// destructive action has a pinkish background and red text.
//
// Measurements: dock.md D-07 (Trash alert), mustache-spec R2.13, R8.4, R8.5, R9.11.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../silica_ui.dart' show uiFontFamily, uiText;
import 'glass.dart';
import 'liquid_glass.dart';
import 'appearance.dart';

const double alertWidth = 292;
const double alertRadius = 26;
const double alertIconSide = 66;
const double alertPadding = 19;
const double alertTextLeft = 21;
const double alertTextWidth = 250;
const double alertButtonHeight = 30;
const double alertStackedGap = 4;
const double alertSideGap = 6;

/// The role of a button: it decides color and key (Return the default one, Esc the cancel one).
enum AlertRole { normal, primary, cancel, destructive }

@immutable
class AlertButton {
  const AlertButton(this.label, {this.role = AlertRole.normal, this.onPressed});

  final String label;
  final AlertRole role;
  final VoidCallback? onPressed;
}

/// The colors of the alert buttons (light, dark).
@immutable
class AlertColors {
  const AlertColors._();

  static const Color primary = Color(0xFF007AFF);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color normalLight = Color(0x8CFFFFFF);
  static const Color normalDark = Color(0xFF525253);
  static const Color normalTextLight = Color(0xFF242424);
  static const Color normalTextDark = Color(0xFFE0E0E0);
  static const Color destructiveLight = Color(0xFFFCCCCA);
  static const Color destructiveDark = Color(0xFF734545);
  static const Color destructiveTextLight = Color(0xFFFF383C);
  static const Color destructiveTextDark = Color(0xFFF01D14);
  static const Color textLight = Color(0xFF1A1A1A);
  static const Color textDark = Color(0xFFEBEBEB);

  /// The solid background (misc.md) and the normal button on it (mustache-spec R9.11).
  static const Color opaqueLight = Color(0xFFFFFFFF);
  static const Color opaqueDark = Color(0xFF272727);
  static const Color normalOpaqueLight = Color(0xFFE8E8E8);
}

class SilicaAlert extends StatelessWidget {
  const SilicaAlert({
    super.key,
    required this.title,
    this.message,
    this.icon,
    required this.buttons,
    this.sideBySide = false,
    this.opaque = false,
  });

  final String title;
  final String? message;

  /// The 66 pt icon (usually the app's or the item's).
  final Widget? icon;
  final List<AlertButton> buttons;

  /// Buttons side by side (at most two) instead of stacked.
  final bool sideBySide;

  /// Solid background instead of glass: for an alert drawn inside a window, where the
  /// compositor's glass would sit under the content (misc.md, "Alert": white or `#272727`, outer
  /// hairline, ~10 pt shadow below).
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final dark = SilicaAppearance.isDark(context);
    final text = dark ? AlertColors.textDark : AlertColors.textLight;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final role = key == LogicalKeyboardKey.escape
            ? AlertRole.cancel
            : key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter
            ? AlertRole.primary
            : null;
        if (role == null) return KeyEventResult.ignored;
        final button = buttons.where((b) => b.role == role).firstOrNull;
        // Without a cancel button, Esc chooses the only button (an alert with OK).
        final chosen = button ?? (buttons.length == 1 ? buttons.first : null);
        if (chosen == null) return KeyEventResult.ignored;
        chosen.onPressed?.call();
        return KeyEventResult.handled;
      },
      child: SizedBox(
        width: alertWidth,
        child: _panel(
          dark,
          Padding(
            padding: const EdgeInsets.only(top: alertPadding, bottom: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: alertPadding),
                  child: SizedBox(
                    width: alertIconSide,
                    height: alertIconSide,
                    child: icon,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: alertTextLeft),
                  child: SizedBox(
                    width: alertTextWidth,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: uiFontFamily,
                        package: 'silica_ui',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: text,
                        height: 16.7 / 13,
                      ),
                    ),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: alertTextLeft),
                    child: SizedBox(
                      width: alertTextWidth,
                      child: Text(
                        message!,
                        style: uiText(size: 13, color: text),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: sideBySide ? _row(dark) : _stack(dark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(bool dark, Widget child) => opaque
      ? DecoratedBox(
          key: const ValueKey('solid alert'),
          decoration: BoxDecoration(
            color: dark ? AlertColors.opaqueDark : AlertColors.opaqueLight,
            borderRadius: BorderRadius.circular(alertRadius),
            border: Border.all(
              color: dark ? const Color(0xFF030303) : const Color(0x40000000),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 40,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        )
      : LiquidGlass(
          radius: alertRadius,
          material: GlassMaterial.thick,
          profile: GlassProfile.sheet,
          interactive: false,
          child: child,
        );

  Widget _stack(bool dark) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(height: alertStackedGap),
        _button(buttons[i], dark),
      ],
    ],
  );

  Widget _row(bool dark) => Row(
    children: [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: alertSideGap),
        Expanded(child: _button(buttons[i], dark)),
      ],
    ],
  );

  Widget _button(AlertButton button, bool dark) {
    final (fill, color) = switch (button.role) {
      AlertRole.primary => (AlertColors.primary, AlertColors.primaryText),
      AlertRole.destructive =>
        dark
            ? (AlertColors.destructiveDark, AlertColors.destructiveTextDark)
            : (AlertColors.destructiveLight, AlertColors.destructiveTextLight),
      _ =>
        dark
            ? (AlertColors.normalDark, AlertColors.normalTextDark)
            : (
                opaque
                    ? AlertColors.normalOpaqueLight
                    : AlertColors.normalLight,
                AlertColors.normalTextLight,
              ),
    };
    return GestureDetector(
      key: ValueKey('alert ${button.label}'),
      onTap: button.onPressed,
      child: Container(
        height: alertButtonHeight,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(alertButtonHeight / 2),
        ),
        alignment: Alignment.center,
        child: Text(button.label, style: uiText(size: 13, color: color)),
      ),
    );
  }
}
