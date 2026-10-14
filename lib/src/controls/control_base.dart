// What every control shares: the system palette (accent, focus rings, the inactive gray), the
// active-window state, the accent scope and the keyboard focus ring.
//
// Measured (silica-reference): the accent sRGB `#007aff` (misc.md › Alert); the 3 pt text field
// ring `#8fb4fb` / `#296692` (mustache.md › MU-32); the control ring `#89aff7` / `#3d7aa6`
// (MU-10); the ring fades in over ~200 ms (MU-70); in an inactive window accent fills turn gray,
// `#545555` in dark (calculator.md › Inactive window).

import 'package:flutter/widgets.dart';

import '../window.dart' show ToolbarScope;

/// The system colors the control groups share, light and dark.
abstract final class ControlPalette {
  /// The system accent (misc.md › Alert: OK in sRGB `#007aff`, light and dark).
  static const Color accent = Color(0xFF007AFF);

  /// Accent fills in an inactive window: dark measured (calculator.md); light provisional (not
  /// measured: the dark gray's distance from the dark window background, mirrored).
  static const Color inactiveAccentLight = Color(0xFFB4B4B6);
  static const Color inactiveAccentDark = Color(0xFF545555);

  /// The 3 pt ring of text fields (MU-32).
  static const Color fieldRingLight = Color(0xFF8FB4FB);
  static const Color fieldRingDark = Color(0xFF296692);

  /// The ring of buttons and other controls (MU-10).
  static const Color controlRingLight = Color(0xFF89AFF7);
  static const Color controlRingDark = Color(0xFF3D7AA6);

  /// The ring fades in and out over ~200 ms (MU-70).
  static const Duration ringFade = Duration(milliseconds: 200);

  /// The accent gray of an inactive window in one appearance.
  static Color inactiveAccent({required bool dark}) =>
      dark ? inactiveAccentDark : inactiveAccentLight;
}

/// Whether the window of the controls under it is the active one.
///
/// [of] reads the nearest scope; without one it falls back to a [ToolbarScope] (which apps
/// with a toolbar already feed from `flutter/lifecycle`), and without that the window counts as
/// active. [WindowActiveScope.follow] tracks the app lifecycle, which the embedder drives from
/// the window activation. Controls with an explicit `active:` parameter use that first.
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
      ToolbarScope.maybeOf(context)?.active ??
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

/// The accent color of the controls under it (default button, checkbox, radio, switch on).
/// The system accent is [ControlPalette.accent]; an app may use its own (Clock uses orange).
class ControlAccent extends InheritedWidget {
  const ControlAccent({super.key, required this.color, required super.child});

  final Color color;

  /// The system accent.
  static const Color system = ControlPalette.accent;

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ControlAccent>()?.color ??
      system;

  @override
  bool updateShouldNotify(ControlAccent old) => old.color != color;
}

/// Which way a chevron points.
enum ChevronDirection { up, down, left, right }

/// A stroked chevron that fills its box (`>` is `right`).
class ChevronPainter extends CustomPainter {
  const ChevronPainter(this.direction, this.color, {this.stroke = 1.5});

  final ChevronDirection direction;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = stroke / 2;
    final points = switch (direction) {
      ChevronDirection.right => [
        Offset(s, s),
        Offset(w - s, h / 2),
        Offset(s, h - s),
      ],
      ChevronDirection.left => [
        Offset(w - s, s),
        Offset(s, h / 2),
        Offset(w - s, h - s),
      ],
      ChevronDirection.down => [
        Offset(s, s),
        Offset(w / 2, h - s),
        Offset(w - s, s),
      ],
      ChevronDirection.up => [
        Offset(s, h - s),
        Offset(w / 2, s),
        Offset(w - s, h - s),
      ],
    };
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ChevronPainter old) =>
      old.direction != direction || old.color != color || old.stroke != stroke;
}

/// Which measured ring color a [FocusRing] uses.
enum FocusRingKind {
  /// Text fields (MU-32).
  field,

  /// Buttons and the other controls (MU-10).
  control,
}

/// The keyboard focus ring: a band of `width` around the child's rounded rectangle, outside it.
/// It fades in and out ([ControlPalette.ringFade]) and is hidden in an inactive window.
///
/// `radius` is the child's corner radius; null makes a capsule (half the shorter side).
/// `inset` moves the ring into the child (the toolbar ring sits 1 pt inside its box).
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.radius,
    this.width = 3,
    this.inset = 0,
    this.kind = FocusRingKind.field,
    this.color,
    this.circle = false,
  });

  final bool visible;
  final double? radius;
  final double width;
  final double inset;
  final FocusRingKind kind;

  /// Overrides the color of [kind].
  final Color? color;
  final bool circle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = visible && WindowActiveScope.of(context);
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final ringColor =
        color ??
        switch (kind) {
          FocusRingKind.field =>
            dark ? ControlPalette.fieldRingDark : ControlPalette.fieldRingLight,
          FocusRingKind.control =>
            dark
                ? ControlPalette.controlRingDark
                : ControlPalette.controlRingLight,
        };
    return Stack(
      alignment: Alignment.topLeft,
      textDirection: TextDirection.ltr,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: shown ? 1 : 0),
              duration: ControlPalette.ringFade,
              // While shown the ring is in the tree from the first frame, fading in.
              builder: (context, t, _) => !shown && t == 0
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      key: const ValueKey('focus ring'),
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
  final double? radius;
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
    final r = ((radius ?? size.shortestSide / 2) - inset).clamp(
      0.0,
      double.infinity,
    );
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
