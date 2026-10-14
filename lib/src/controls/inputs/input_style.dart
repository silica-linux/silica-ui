// Shared look of the input controls: colors, the keyboard focus ring, the active-window state
// and the in-window menus they open.
//
// Measured (references in the comments): the text field focus ring and inner border (rename
// field), the toolbar focus ring, the slider track, fill and knob (icon-size slider), the
// accent blue. Everything else is the closest measured sibling and is marked provisional.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../silica_ui.dart' show uiFontFamily;
import '../../menu.dart';

/// The colors of the input controls in one appearance.
@immutable
class InputColors {
  const InputColors({
    required this.accent,
    required this.accentInactive,
    required this.fieldBackground,
    required this.fieldBorder,
    required this.fieldBorderFocused,
    required this.focusRing,
    required this.focusRingControl,
    required this.text,
    required this.secondaryText,
    required this.placeholder,
    required this.selection,
    required this.selectionInactive,
    required this.glyph,
    required this.track,
    required this.trackFill,
    required this.knob,
    required this.knobBorder,
    required this.knobShadow,
    required this.tick,
    required this.bezel,
    required this.bezelPressed,
    required this.bezelBorder,
    required this.tokenLabel,
    required this.tokenValue,
    required this.tokenText,
    required this.searchBackground,
    required this.panel,
    required this.levelEmpty,
  });

  /// The accent: the default blue (misc.md › Alert, `#007aff`) for fills, the icon slider fill
  /// for tracks (mustache.md › MU-04, `#0176f7` light, `#0d7bfb` dark).
  final Color accent;

  /// Accent fills in an inactive window. Provisional: AppKit turns them gray; the gray is the
  /// slider track one step darker, not measured.
  final Color accentInactive;
  final Color fieldBackground;
  final Color fieldBorder;

  /// The 1 pt inner border of a focused field (mustache.md › MU-32: `#649efa`, `#3586c5`).
  final Color fieldBorderFocused;

  /// The 3 pt text field ring (MU-32: `#8fb4fb`, `#296692`).
  final Color focusRing;

  /// The 4 pt ring of buttons and other controls (MU-10: `#89aff7`, `#3d7aa6`).
  final Color focusRingControl;
  final Color text;
  final Color secondaryText;
  final Color placeholder;

  /// Selected text (MU-32: `#b3d7ff`, `#40638b`); in an inactive window a neutral gray
  /// (spotlight.md › field selection without accent).
  final Color selection;
  final Color selectionInactive;

  /// Glyphs drawn inside fields (magnifier, clear button, caps lock, stepper arrows).
  final Color glyph;

  /// Slider and progress track (MU-04: `#e5e5e5`, `#434343`).
  final Color track;

  /// The filled part of a slider (MU-04: sRGB `#0176f7` light, `#0d7bfb` dark).
  final Color trackFill;

  /// The knob (MU-04: white with a shadow in light, solid `#dfdfdf` in dark).
  final Color knob;
  final Color knobBorder;
  final Color knobShadow;
  final Color tick;

  /// Bezel of small push parts (stepper, color well, calendar arrows). Provisional: the alert
  /// normal button in its opaque form (misc.md › Alert).
  final Color bezel;
  final Color bezelPressed;
  final Color bezelBorder;

  /// The two parts of a search token (mustache.md › MU-70: label `#bbbbbb` / `#8f8f8f`, the
  /// value on a lighter background, provisional).
  final Color tokenLabel;
  final Color tokenValue;
  final Color tokenText;

  /// The window search field background (controlcenter.md › Edit controls, `#d7d8db` on the
  /// gallery glass; dark provisional).
  final Color searchBackground;

  /// The background of panels (calendar, clock face, color picker): the Save card (dialogs.md).
  final Color panel;

  /// Empty segments and stars of a level indicator (provisional: the track).
  final Color levelEmpty;

  static const InputColors light = InputColors(
    accent: Color(0xFF007AFF),
    accentInactive: Color(0xFFB9B9B9),
    fieldBackground: Color(0xFFFFFFFF),
    // The labels popover field border (mustache.md › MU-62).
    fieldBorder: Color(0xFFE1E1E1),
    fieldBorderFocused: Color(0xFF649EFA),
    focusRing: Color(0xFF8FB4FB),
    focusRingControl: Color(0xFF89AFF7),
    text: Color(0xFF1A1A1A),
    secondaryText: Color(0xFF808080),
    // Provisional: the inactive status bar text (MU-04).
    placeholder: Color(0xFFBDBDBD),
    selection: Color(0xFFB3D7FF),
    selectionInactive: Color(0xFFDCDCDC),
    glyph: Color(0xFF808080),
    track: Color(0xFFE5E5E5),
    trackFill: Color(0xFF0176F7),
    knob: Color(0xFFFFFFFF),
    knobBorder: Color(0x1F000000),
    knobShadow: Color(0x40000000),
    tick: Color(0xFFB4B4B4),
    bezel: Color(0xFFFFFFFF),
    bezelPressed: Color(0xFFE8E8E8),
    bezelBorder: Color(0xFFD0D0D0),
    tokenLabel: Color(0xFFBBBBBB),
    tokenValue: Color(0xFFDDDDDD),
    tokenText: Color(0xFF1A1A1A),
    searchBackground: Color(0xFFD7D8DB),
    panel: Color(0xFFFFFFFF),
    levelEmpty: Color(0xFFE5E5E5),
  );

  static const InputColors dark = InputColors(
    accent: Color(0xFF007AFF),
    accentInactive: Color(0xFF5E5E5E),
    // The labels popover field in dark (MU-62).
    fieldBackground: Color(0xFF1D1D1D),
    fieldBorder: Color(0xFF3A3A3A),
    fieldBorderFocused: Color(0xFF3586C5),
    focusRing: Color(0xFF296692),
    focusRingControl: Color(0xFF3D7AA6),
    text: Color(0xFFEBEBEB),
    secondaryText: Color(0xFFA1A1A1),
    placeholder: Color(0xFF636363),
    selection: Color(0xFF40638B),
    selectionInactive: Color(0xFF464646),
    glyph: Color(0xFFA1A1A1),
    track: Color(0xFF434343),
    trackFill: Color(0xFF0D7BFB),
    knob: Color(0xFFDFDFDF),
    knobBorder: Color(0x00000000),
    knobShadow: Color(0x59000000),
    tick: Color(0xFF6A6A6A),
    bezel: Color(0xFF525253),
    bezelPressed: Color(0xFF6A6A6B),
    bezelBorder: Color(0xFF3A3A3A),
    tokenLabel: Color(0xFF8F8F8F),
    tokenValue: Color(0xFF5A5A5A),
    tokenText: Color(0xFFFFFFFF),
    searchBackground: Color(0xFF3A3A3C),
    panel: Color(0xFF272727),
    levelEmpty: Color(0xFF434343),
  );

  /// Following the system appearance (`MediaQuery.platformBrightness`).
  static InputColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;

  /// The fill of an accent-colored part, gray in an inactive window.
  Color accentFor({required bool active}) => active ? accent : accentInactive;
}

/// The input control measurements.
abstract final class InputMetrics {
  /// Rounded text field: 26 tall (dialogs.md › Save, clock.md › Alarms). Radius provisional.
  static const double fieldHeight = 26;
  static const double fieldRadius = 6;

  /// Text 4 pt from the edge, 13 pt type (mustache.md › MU-32).
  static const double fieldPadding = 4;
  static const double fontSize = 13;

  /// Focus rings: 3 pt around text fields (MU-32), 4 pt inset 1 around other controls (MU-10).
  static const double fieldRing = 3;
  static const double controlRing = 4;
  static const double controlRingInset = 1;

  /// The ring fades in over ~200 ms (mustache.md › MU-70).
  static const Duration ringFade = Duration(milliseconds: 200);

  /// The toolbar search field 242 × 38 (MU-70) and the window search field, 28 tall
  /// (controlcenter.md › Edit controls, 205 × 28).
  static const double searchToolbarHeight = 38;
  static const double searchToolbarWidth = 242;
  static const double searchHeight = 28;

  /// Search token 15 tall (MU-70); tag token 14 tall (MU-62).
  static const double searchTokenHeight = 15;
  static const double tagTokenHeight = 14;

  /// Tag field 27 tall (dialogs.md › Save).
  static const double tokenFieldHeight = 27;
}

/// Whether the window of the controls is active. Without a scope the window counts as
/// active; [WindowActiveScope.follow] tracks the app lifecycle, which the embedder drives
/// from the window activation (`flutter/lifecycle`).
class WindowActiveScope extends InheritedWidget {
  const WindowActiveScope({
    super.key,
    required this.active,
    required super.child,
  });

  final bool active;

  /// A scope that follows the app lifecycle: `resumed` is active, anything else inactive.
  static Widget follow({Key? key, required Widget child}) =>
      _LifecycleActive(key: key, child: child);

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowActiveScope>()?.active ??
      true;

  @override
  bool updateShouldNotify(WindowActiveScope old) => old.active != active;
}

class _LifecycleActive extends StatefulWidget {
  const _LifecycleActive({super.key, required this.child});
  final Widget child;

  @override
  State<_LifecycleActive> createState() => _LifecycleActiveState();
}

class _LifecycleActiveState extends State<_LifecycleActive> {
  late final AppLifecycleListener _listener;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null || state == AppLifecycleState.resumed;
    _listener = AppLifecycleListener(
      onStateChange: (state) =>
          setState(() => _active = state == AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      WindowActiveScope(active: _active, child: widget.child);
}

/// The text style of the input controls.
TextStyle inputText(Color color, {double size = InputMetrics.fontSize}) =>
    TextStyle(
      fontFamily: uiFontFamily,
      package: 'silica_ui',
      fontSize: size,
      color: color,
      height: 1.2,
    );

/// The keyboard focus ring: a band of `width` around a rounded rectangle, outside the child.
/// It fades in and out ([InputMetrics.ringFade]); it is hidden in an inactive window.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    required this.radius,
    required this.child,
    this.width = InputMetrics.fieldRing,
    this.inset = 0,
    this.color,
    this.circle = false,
  });

  final bool visible;
  final double radius;
  final double width;

  /// How far the ring enters the child (the toolbar ring sits 1 pt inside the box).
  final double inset;
  final Color? color;
  final bool circle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = visible && WindowActiveScope.of(context);
    final ringColor = color ?? InputColors.of(context).focusRing;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: shown ? 1 : 0),
              duration: InputMetrics.ringFade,
              builder: (context, t, _) => t == 0
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      painter: _RingPainter(
                        color: ringColor.withValues(alpha: ringColor.a * t),
                        radius: radius,
                        width: width,
                        inset: inset,
                        circle: circle,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.radius,
    required this.width,
    required this.inset,
    required this.circle,
  });

  final Color color;
  final double radius;
  final double width;
  final double inset;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = (Offset.zero & size).deflate(inset);
    final outer = inner.inflate(width);
    final paint = Paint()..color = color;
    if (circle) {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(outer)
        ..addOval(inner);
      canvas.drawPath(path, paint);
      return;
    }
    final r = (radius - inset).clamp(0.0, double.infinity);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(RRect.fromRectAndRadius(outer, Radius.circular(r + width)))
      ..addRRect(RRect.fromRectAndRadius(inner, Radius.circular(r)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.width != width ||
      old.inset != inset ||
      old.circle != circle;
}

/// Opens an in-window menu (the recents of a search field, a token menu) in the nearest
/// [Overlay], with its top-left corner at `anchor` in the coordinates of `context`.
/// Returns a function that closes it.
VoidCallback showInputMenu(
  BuildContext context, {
  required List<MenuEntry> entries,
  required Offset anchor,
  VoidCallback? onDismissed,
}) {
  final overlay = Overlay.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  var at = anchor;
  if (box != null && overlayBox != null) {
    at = overlayBox.globalToLocal(box.localToGlobal(anchor));
  }
  late final OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
    onDismissed?.call();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: MenuHost(
        entries: entries,
        anchor: at,
        opaque: true,
        onDismissed: remove,
      ),
    ),
  );
  overlay.insert(entry);
  return remove;
}

/// Whether caps lock is on (for the secure field indicator).
bool get capsLockOn => HardwareKeyboard.instance.lockModesEnabled.contains(
  KeyboardLockMode.capsLock,
);
