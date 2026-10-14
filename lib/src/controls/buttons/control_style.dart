// What the buttons and toggles share: sizes, colors (light and dark), the accent, the active
// window, the keyboard focus ring and the pointer and keyboard interaction.
//
// Measured (silica-reference): push button 24 high, radius ~8, normal fill `#ececec` / `#373737`
// with text `#242424` / `#e0e0e0`, default fill sRGB `#007aff` with white text (misc.md ›
// Alert); small buttons 22 high (mustache-spec MU-41); the control focus ring color sRGB
// `#89aff7` / `#3d7aa6` (MU-10); in an inactive window the accent fills turn gray (`#545555` in
// dark, calculator.md › Inactive window); pressed fills appear in the first frame and go back
// in the first frame after the release, with the action on release; a pressed fill in dark is
// ~12 % lighter (clock.md › Button and row states).
// Values marked "provisional" are not measured yet (silica-reference C-01, C-02): they come from
// the closest measured control and will be replaced once measured.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../window.dart' show ToolbarScope;

/// The size of a control, as in the system: mini, small, regular, large.
enum ControlSize { mini, small, regular, large }

/// The height of a push button (or pop-up, pull-down, combo box) of `size`: 24 regular
/// (measured), 22 small (measured, MU-41), 16 mini and 30 large (provisional).
double buttonHeight(ControlSize size) => switch (size) {
  ControlSize.mini => 16,
  ControlSize.small => 22,
  ControlSize.regular => 24,
  ControlSize.large => 30,
};

/// The corner radius of a push button: ~8 at 24 (measured), the others in proportion
/// (provisional).
double buttonRadius(ControlSize size) => switch (size) {
  ControlSize.mini => 5,
  ControlSize.small => 7,
  ControlSize.regular => 8,
  ControlSize.large => 10,
};

/// The label size: 13 regular and large, 11 small, 9 mini (provisional except 13).
double controlFontSize(ControlSize size) => switch (size) {
  ControlSize.mini => 9,
  ControlSize.small => 11,
  ControlSize.regular || ControlSize.large => 13,
};

/// The side of a checkbox or the diameter of a radio button (provisional: 14 regular).
double toggleSide(ControlSize size) => switch (size) {
  ControlSize.mini => 10,
  ControlSize.small => 12,
  ControlSize.regular => 14,
  ControlSize.large => 16,
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

/// The accent color of the controls under it (default button, checkbox, radio, switch on).
/// The system accent is sRGB `#007aff`; an app may use its own (Clock uses orange).
class ControlAccent extends InheritedWidget {
  const ControlAccent({super.key, required this.color, required super.child});

  final Color color;

  /// The system accent (misc.md › Alert: OK in sRGB `#007aff`, light and dark).
  static const Color system = Color(0xFF007AFF);

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ControlAccent>()?.color ??
      system;

  @override
  bool updateShouldNotify(ControlAccent old) => old.color != color;
}

/// Whether the window of `context` is the active one (from [ToolbarScope], which the app
/// feeds from `flutter/lifecycle`); true when nobody says otherwise.
bool controlWindowActive(BuildContext context) =>
    ToolbarScope.maybeOf(context)?.active ?? true;

/// The pressed fill: ~12 % towards white in dark (measured on Clock's capsules), ~12 % towards
/// black in light (provisional).
Color pressedFill(Color fill, {required bool dark}) => Color.lerp(
  fill,
  dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
  0.12,
)!;

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

  /// Push button fill: at rest (measured), pressed and a toggle button on (provisional; the
  /// Calculator's 2nd key lightens by ~38 levels when on).
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

  /// An accent fill in an inactive window (dark measured, light provisional).
  final Color inactiveAccent;

  /// The keyboard focus ring (measured color).
  final Color focusRing;

  /// Checkbox and radio button off: fill, pressed and border (provisional).
  final Color box;
  final Color boxPressed;
  final Color boxBorder;

  /// Switch: the track off (dark measured on Clock), the knob on and off.
  final Color switchOff;
  final Color knob;
  final Color knobOff;

  /// The text next to a checkbox, radio button or switch.
  final Color label;
  final Color labelDisabled;

  /// Glyphs without a bezel (disclosure triangle, image button): rest and pressed.
  final Color glyph;
  final Color glyphPressed;

  /// The text part of a combo box (provisional).
  final Color field;
  final Color fieldBorder;

  static const ControlColors light = ControlColors(
    dark: false,
    bezel: Color(0xFFECECEC),
    bezelPressed: Color(0xFFD0D0D0), // ~12 % towards black, provisional
    bezelOn: Color(0xFFD4D4D4), // provisional
    text: Color(0xFF242424),
    textDisabled: Color(0xFFADADAD),
    destructive: Color(0xFFFCCCCA),
    destructiveText: Color(0xFFFF383C),
    accentText: Color(0xFFFFFFFF),
    inactiveAccent: Color(0xFFB4B4B6), // provisional
    focusRing: Color(0xFF89AFF7),
    box: Color(0xFFFFFFFF), // provisional
    boxPressed: Color(0xFFE6E6E6), // provisional
    boxBorder: Color(0xFFC4C4C6), // provisional
    switchOff: Color(0xFFE3E3E5), // provisional
    knob: Color(0xFFFFFFFF),
    knobOff: Color(0xFFFFFFFF), // provisional
    label: Color(0xFF1A1A1A),
    labelDisabled: Color(0xFFADADAD),
    glyph: Color(0xFF808080), // the list header's gray, provisional
    glyphPressed: Color(0xFF4D4D4D), // provisional
    field: Color(0xFFFFFFFF), // provisional
    fieldBorder: Color(0xFFD1D1D1), // provisional
  );

  static const ControlColors darkColors = ControlColors(
    dark: true,
    bezel: Color(0xFF373737),
    bezelPressed: Color(0xFF4F4F4F), // the 12 % rule of Clock
    bezelOn: Color(0xFF5D5D5D), // provisional
    text: Color(0xFFE0E0E0),
    textDisabled: Color(0xFF787879),
    destructive: Color(0xFF734545),
    destructiveText: Color(0xFFF01D14),
    accentText: Color(0xFFFFFFFF),
    inactiveAccent: Color(0xFF545555),
    focusRing: Color(0xFF3D7AA6),
    box: Color(0xFF454547), // provisional
    boxPressed: Color(0xFF5C5C5E), // provisional
    boxBorder: Color(0xFF5E5E60), // provisional
    switchOff: Color(0xFF454545),
    knob: Color(0xFFFFFFFF),
    knobOff: Color(0xFFE3E3E3),
    label: Color(0xFFEBEBEB),
    labelDisabled: Color(0xFF787879),
    glyph: Color(0xFFABABAB), // provisional
    glyphPressed: Color(0xFFFFFFFF), // provisional
    field: Color(0xFF2B2B2B), // provisional
    fieldBorder: Color(0xFF4A4A4A), // provisional
  );

  /// Following the system appearance (`MediaQuery.platformBrightness`).
  static ControlColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? darkColors
      : light;
}

/// The focus ring: 3 pt around the control's shape, outside it (provisional thickness and
/// distance; the measured toolbar ring is 4 pt inside the capsule).
const double focusRingWidth = 3;

/// Draws the focus ring around `child` when `visible`: `radius` is the control's corner
/// radius (`null`: a circle or capsule, half the height).
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.radius,
  });

  final bool visible;
  final double? radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    final color = ControlColors.of(context).focusRing;
    return CustomPaint(
      key: const ValueKey('focus ring'),
      foregroundPainter: _RingPainter(color, radius),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color, this.radius);
  final Color color;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    const half = focusRingWidth / 2;
    final rect = (Offset.zero & size).inflate(half);
    final r = (radius ?? size.shortestSide / 2) + half;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focusRingWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.radius != radius;
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
      active: controlWindowActive(context),
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
