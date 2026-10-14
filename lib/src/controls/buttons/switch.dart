// The switch.
//
// Measured: regular 54 × 24 capsule with a white 32 × 20 knob, 2 pt from the edges, on in sRGB
// `#0074f8` (two levels darker than the accent `#007aff`), controlcenter.md › Wi-Fi switch; off in
// dark: track `#454545`, knob `#e3e3e3` (clock.md › Alarms, whose 68 × 30 switch matches the
// large size here, 54 × 24 scaled to 30 high). Off in light, pressed, disabled, the knob
// animation (duration and curve) and the small and mini sizes are provisional (silica-reference
// C-01).

import 'package:flutter/widgets.dart';

import 'control_style.dart';

/// The height of a switch: 24 regular (measured), 30 large (Clock), small and mini provisional.
double switchHeight(ControlSize size) => switch (size) {
  ControlSize.mini => 14,
  ControlSize.small => 18,
  ControlSize.regular => 24,
  ControlSize.large => 30,
};

/// The switch size for `size`: 54 × 24 scaled.
Size switchSize(ControlSize size) {
  final h = switchHeight(size);
  return Size(54 * h / 24, h);
}

/// The on color with the system accent (measured); another accent is used as is.
const Color switchOnSystem = Color(0xFF0074F8);

/// The knob animation (provisional).
const Duration switchDuration = Duration(milliseconds: 200);

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
          final dims = switchSize(size);
          final s = dims.height / 24;
          final accent = ControlAccent.of(context);
          final on = !state.active
              ? colors.inactiveAccent
              : accent == ControlAccent.system
              ? switchOnSystem
              : accent;
          final track = value ? on : colors.switchOff;
          final knob = value ? colors.knob : colors.knobOff;
          return FocusRing(
            visible: state.focused,
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
                      ? pressedFill(track, dark: colors.dark)
                      : track,
                  borderRadius: BorderRadius.circular(dims.height / 2),
                ),
                child: AnimatedAlign(
                  duration: switchDuration,
                  curve: Curves.easeOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    key: const ValueKey('switch knob'),
                    width: 32 * s,
                    height: 20 * s,
                    decoration: BoxDecoration(
                      color: state.pressed
                          ? pressedFill(knob, dark: false)
                          : knob,
                      borderRadius: BorderRadius.circular(10 * s),
                      boxShadow: const [
                        // Provisional.
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
