// What the buttons and toggles share: sizes, colors (light and dark), the accent, the active
// window, the keyboard focus ring and the pointer and keyboard interaction.
//
// Measured (docs/spec/buttons.md, toggles.md, focus-and-accent.md; INV-B gallery): push buttons
// are full capsules 28 / 24 / 20 / 16 pt tall (large, regular, small, mini), fill `#ececec` /
// `#373738` with text `#242424` / `#e0e0e0`, no border; the default button sRGB `#007aff` with
// white text; no hover look on any control; pressed = one fill step (10 %) darker in light,
// lighter in dark, in the first frame, with the action on release; in an inactive window every
// accent fill turns gray (`#cfcfcf` / `#505051`); checkboxes 16 / 14 / 12 pt, off `#e6e6e6` /
// `#3c3c3d`; glyph buttons `#808080` → `#262626` pressed (dark `#9e9e9e` → `#dfdfdf`).
// Values still marked "provisional" are not measured yet: they come from the closest measured
// control and will be replaced once measured.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../control_base.dart';
import '../../appearance.dart';

export '../control_base.dart';

/// The size of a control, as in the system: mini, small, regular, large.
enum ControlSize { mini, small, regular, large }

/// The height of a push button (or pop-up, pull-down, combo box) of `size`: 28 large, 24
/// regular, 20 small, 16 mini (CT-BTN-01/03).
double buttonHeight(ControlSize size) => switch (size) {
  ControlSize.mini => 16,
  ControlSize.small => 20,
  ControlSize.regular => 24,
  ControlSize.large => 28,
};

/// The corner radius of a push button: a full capsule, half the height (CT-BTN-01).
double buttonRadius(ControlSize size) => buttonHeight(size) / 2;

/// The label size: 13 regular and large, 11 small, 9 mini (provisional except 13).
double controlFontSize(ControlSize size) => switch (size) {
  ControlSize.mini => 9,
  ControlSize.small => 11,
  ControlSize.regular || ControlSize.large => 13,
};

/// The side of a checkbox or the diameter of a radio button: 16 regular, 14 small, 12 mini
/// (CT-CB-01, CT-RB-01); large as regular (provisional: no large checkbox in the gallery).
double toggleSide(ControlSize size) => switch (size) {
  ControlSize.mini => 12,
  ControlSize.small => 14,
  ControlSize.regular || ControlSize.large => 16,
};

/// A label style in Inter (this package's font).
TextStyle controlTextStyle(
  ControlSize size,
  Color color, {
  FontWeight? weight,
}) => TextStyle(
  fontFamily: 'Inter',
  package: 'silica_ui',
  fontSize: controlFontSize(size),
  fontWeight: weight,
  color: color,
  height: 1.2,
);

/// The pressed fill: one step, 10 % towards black in light and towards white in dark
/// ([ControlPalette.pressed], INV-B).
Color controlPressedFill(Color fill, {required bool dark}) =>
    ControlPalette.pressed(fill, dark: dark);

/// The colors of buttons and toggles, light and dark.
@immutable
class ControlColors {
  const ControlColors({
    required this.dark,
    required this.bezel,
    required this.bezelPressed,
    required this.bezelOn,
    required this.text,
    required this.textDisabled,
    required this.destructive,
    required this.destructiveText,
    required this.accentText,
    required this.inactiveAccent,
    required this.focusRing,
    required this.box,
    required this.boxPressed,
    required this.boxBorder,
    required this.switchOff,
    required this.knob,
    required this.knobOff,
    required this.label,
    required this.labelDisabled,
    required this.glyph,
    required this.glyphPressed,
    required this.field,
    required this.fieldBorder,
  });

  final bool dark;

  /// Push button fill: at rest and pressed (measured), and a toggle button on in an inactive
  /// window (the gray every accent fill takes; in an active window it is the accent).
  final Color bezel;
  final Color bezelPressed;
  final Color bezelOn;

  /// Text on the bezel (measured) and disabled (the toolbar's disabled glyph, measured).
  final Color text;
  final Color textDisabled;

  /// Destructive button: fill and text (from the alert, measured on glass).
  final Color destructive;
  final Color destructiveText;

  /// Text and marks on the accent.
  final Color accentText;

  /// An accent fill in an inactive window (measured).
  final Color inactiveAccent;

  /// The keyboard focus ring with the default accent (measured; [FocusRing] follows the accent).
  final Color focusRing;

  /// Checkbox and radio button off: fill and pressed (measured), border (provisional).
  final Color box;
  final Color boxPressed;
  final Color boxBorder;

  /// Switch: the track off (measured), the knob on and off.
  final Color switchOff;
  final Color knob;
  final Color knobOff;

  /// The text next to a checkbox, radio button or switch.
  final Color label;
  final Color labelDisabled;

  /// Glyphs without a bezel (disclosure chevron, image button): rest and pressed (measured).
  final Color glyph;
  final Color glyphPressed;

  /// The text part of a combo box: fill (measured) and border (provisional).
  final Color field;
  final Color fieldBorder;

  static const ControlColors light = ControlColors(
    dark: false,
    bezel: Color(0xFFECECEC),
    bezelPressed: Color(0xFFD5D5D5),
    bezelOn: ControlPalette.inactiveAccentLight,
    text: Color(0xFF242424),
    textDisabled: Color(0xFFADADAD),
    destructive: Color(0xFFFCCCCA),
    destructiveText: Color(0xFFFF383C),
    accentText: Color(0xFFFFFFFF),
    inactiveAccent: ControlPalette.inactiveAccentLight,
    focusRing: ControlPalette.controlRingLight,
    box: Color(0xFFE6E6E6),
    boxPressed: Color(0xFFCFCFCF),
    boxBorder: Color(0xFFC4C4C6), // provisional
    switchOff: Color(0xFFE2E2E2),
    knob: Color(0xFFFFFFFF),
    knobOff: Color(0xFFFFFFFF),
    label: Color(0xFF1A1A1A),
    labelDisabled: Color(0xFFADADAD),
    glyph: Color(0xFF808080),
    glyphPressed: Color(0xFF262626),
    field: Color(0xFFFFFFFF),
    fieldBorder: Color(0xFFD1D1D1), // provisional
  );

  static const ControlColors darkColors = ControlColors(
    dark: true,
    bezel: Color(0xFF373738),
    bezelPressed: Color(0xFF4B4B4C),
    bezelOn: ControlPalette.inactiveAccentDark,
    text: Color(0xFFE0E0E0),
    textDisabled: Color(0xFF787879),
    destructive: Color(0xFF734545),
    destructiveText: Color(0xFFF01D14),
    accentText: Color(0xFFFFFFFF),
    inactiveAccent: ControlPalette.inactiveAccentDark,
    focusRing: ControlPalette.controlRingDark,
    box: Color(0xFF3C3C3D),
    boxPressed: Color(0xFF4F4F50),
    boxBorder: Color(0xFF5E5E60), // provisional
    switchOff: Color(0xFF454545),
    knob: Color(0xFFFFFFFF),
    knobOff: Color(0xFFE3E3E3),
    label: Color(0xFFEBEBEB),
    labelDisabled: Color(0xFF787879),
    glyph: Color(0xFF9E9E9E),
    glyphPressed: Color(0xFFDFDFDF),
    field: Color(0xFF191919),
    fieldBorder: Color(0xFF4A4A4A), // provisional
  );

  /// Following the appearance in effect (the override, otherwise the system's).
  static ControlColors of(BuildContext context) =>
      SilicaAppearance.isDark(context) ? darkColors : light;
}

/// The interaction state of a control.
@immutable
class ControlState {
  const ControlState({
    required this.enabled,
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.active,
  });

  final bool enabled;
  final bool hovered;

  /// The pointer is down on the control and still inside it.
  final bool pressed;

  /// Keyboard focus, shown with the ring (only when the keyboard is in use).
  final bool focused;

  /// The window is the active one.
  final bool active;
}

/// Pointer and keyboard for a control: hover, press (it follows the pointer in and out while
/// held), the action on release inside, Space on keyboard focus, extra keys.
class ControlInteraction extends StatefulWidget {
  const ControlInteraction({
    super.key,
    required this.enabled,
    required this.builder,
    this.onActivate,
    this.onPressDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onKey,
    this.focusNode,
    this.autofocus = false,
    this.cursor = MouseCursor.defer,
  });

  final bool enabled;
  final Widget Function(BuildContext context, ControlState state) builder;

  /// Release inside the control, or Space with the keyboard focus.
  final VoidCallback? onActivate;

  /// The primary button goes down on the control (menus open on press). Returning true takes
  /// the press: no pressed state and no action on release.
  final bool Function()? onPressDown;

  /// The pointer held down after a press, in global coordinates (a menu opened on press follows
  /// it) and its release.
  final ValueChanged<Offset>? onPointerMove;
  final ValueChanged<Offset>? onPointerUp;

  /// Other keys with the keyboard focus.
  final KeyEventResult Function(KeyEvent event)? onKey;
  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor cursor;

  @override
  State<ControlInteraction> createState() => _ControlInteractionState();
}

class _ControlInteractionState extends State<ControlInteraction> {
  bool _hovered = false;
  bool _focused = false;
  bool _down = false;
  bool _inside = false;
  bool _taken = false;

  @override
  void didUpdateWidget(ControlInteraction old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && (_down || _hovered)) {
      _down = false;
      _hovered = false;
    }
  }

  bool _contains(Offset local) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize && box.size.contains(local);
  }

  void _pointerDown(PointerDownEvent e) {
    if (!widget.enabled || e.buttons & kPrimaryButton == 0) return;
    _taken = widget.onPressDown?.call() ?? false;
    setState(() {
      _down = !_taken;
      _inside = true;
    });
  }

  void _pointerMove(PointerMoveEvent e) {
    if (_taken) {
      widget.onPointerMove?.call(e.position);
      return;
    }
    if (!_down) return;
    final inside = _contains(e.localPosition);
    if (inside != _inside) setState(() => _inside = inside);
  }

  void _pointerUp(PointerUpEvent e) {
    if (_taken) {
      _taken = false;
      widget.onPointerUp?.call(e.position);
      return;
    }
    if (!_down) return;
    final fire = _inside && _contains(e.localPosition);
    setState(() => _down = false);
    if (fire && widget.enabled) widget.onActivate?.call();
  }

  void _pointerCancel() {
    _taken = false;
    if (_down) setState(() => _down = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ControlState(
      enabled: widget.enabled,
      hovered: widget.enabled && _hovered,
      pressed: widget.enabled && _down && _inside,
      focused: widget.enabled && _focused,
      active: WindowActiveScope.of(context),
    );
    final onKey = widget.onKey;
    Widget child = FocusableActionDetector(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: widget.cursor,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (on) {
        if (on != _focused) setState(() => _focused = on);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: (_) => _pointerCancel(),
          child: widget.builder(context, state),
        ),
      ),
    );
    if (onKey != null) {
      child = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) =>
            widget.enabled ? onKey(event) : KeyEventResult.ignored,
        child: child,
      );
    }
    return child;
  }
}

/// Key down or repeat (the events the controls act on).
bool isKeyPress(KeyEvent event) =>
    event is KeyDownEvent || event is KeyRepeatEvent;
