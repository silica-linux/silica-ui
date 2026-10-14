// The switch.
//
// Measured (docs/spec/toggles.md, INV-B gallery and CT-CL-01): 64 × 28, 54 × 24, 44 × 20 and
// 36 × 16 pt (large, regular, small, mini); a white 32 × 20 knob at regular size, 2 pt from the
// edges (controlcenter.md › Wi-Fi switch); on = the accent's switch fill (sRGB `#0176f7` light,
// `#0b7cfc` dark with the default accent), gray in an inactive window; off light `#e2e2e2` with a
// white knob and a soft shadow, off dark `#454545` with a `#e3e3e3` knob and no shadow (clock.md ›
// Alarms); the knob stretches while pressed; disabled keeps the accent at reduced opacity
// (CT-SW-01/02/03). Provisional: the knob animation (duration and curve), how far the knob
// stretches, the shadow.

import 'package:flutter/widgets.dart';

import 'control_style.dart';

/// The size of a switch (CT-SW-01/02).
Size switchDimensions(ControlSize size) => switch (size) {
  ControlSize.mini => const Size(36, 16),
  ControlSize.small => const Size(44, 20),
  ControlSize.regular => const Size(54, 24),
  ControlSize.large => const Size(64, 28),
};

/// The height of a switch of `size`.
double switchHeight(ControlSize size) => switchDimensions(size).height;

/// The on color with the default accent, light (CT-CL-01); [switchOnSystemDark] in dark.
const Color switchOnSystem = Color(0xFF0176F7);
const Color switchOnSystemDark = Color(0xFF0B7CFC);

/// The knob animation (provisional).
const Duration switchDuration = Duration(milliseconds: 200);

/// How much wider the knob gets while the switch is pressed, at regular size (provisional).
const double switchKnobStretch = 6;

/// A switch. A click (release inside) or Space toggles it.
class SilicaSwitch extends StatelessWidget {
  const SilicaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = ControlSize.regular,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final ControlSize size;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  /// The on color of the accent in effect.
  static Color onColor(BuildContext context, {required bool dark}) {
    final scope = context.dependOnInheritedWidgetOfExactType<ControlAccent>();
    final defaultAccent =
        scope == null ||
        (scope.color == null &&
            (scope.accent == SilicaAccent.multicolor ||
                scope.accent == SilicaAccent.blue));
    if (defaultAccent) return dark ? switchOnSystemDark : switchOnSystem;
    return ControlAccent.fillOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: ControlInteraction(
        enabled: onChanged != null,
        onActivate: onChanged == null ? null : () => onChanged(!value),
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, state) {
          final colors = ControlColors.of(context);
          final dims = switchDimensions(size);
          final s = dims.height / 24;
          final on = state.active
              ? onColor(context, dark: colors.dark)
              : colors.inactiveAccent;
          final track = value ? on : colors.switchOff;
          final knob = value ? colors.knob : colors.knobOff;
          final knobWidth = (32 + (state.pressed ? switchKnobStretch : 0)) * s;
          return FocusRing(
            visible: state.focused,
            kind: FocusRingKind.control,
            radius: null,
            child: Opacity(
              opacity: state.enabled ? 1 : 0.5,
              child: AnimatedContainer(
                key: const ValueKey('switch track'),
                duration: switchDuration,
                curve: Curves.easeOut,
                width: dims.width,
                height: dims.height,
                padding: EdgeInsets.all(2 * s),
                decoration: BoxDecoration(
                  color: state.pressed
                      ? controlPressedFill(track, dark: colors.dark)
                      : track,
                  borderRadius: BorderRadius.circular(dims.height / 2),
                ),
                child: AnimatedAlign(
                  duration: switchDuration,
                  curve: Curves.easeOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    key: const ValueKey('switch knob'),
                    duration: switchDuration,
                    curve: Curves.easeOut,
                    width: knobWidth,
                    height: 20 * s,
                    decoration: BoxDecoration(
                      color: knob,
                      borderRadius: BorderRadius.circular(10 * s),
                      // A soft shadow in light, none in dark (CT-SW-01); its values provisional.
                      boxShadow: colors.dark
                          ? const []
                          : const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 2,
                                offset: Offset(0, 0.5),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
