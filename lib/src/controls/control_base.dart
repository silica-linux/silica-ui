// What every control shares: the system palette (accent, focus rings, the inactive gray), the
// active-window state, the accent scope and the keyboard focus ring.
//
// Measured (docs/spec/focus-and-accent.md): the nine system accents, light and dark, each with
// its plain color (default button, progress fill), its control fill (about 2 % darker in light,
// slightly lighter in dark: toggles, selected segments, switches, checkboxes, radios, slider
// fills) and its focus ring (the accent at about 50 % over the window) (CT-CL-01); the keyboard
// focus ring 3 pt outside the control, jumping without animation from control to control, while
// a text field's ring fades in over ~200 ms (CT-TF-09, MU-70); in an inactive window every accent
// fill turns neutral gray, `#cfcfcf` / `#505051` (`#c5c5c5` / `#585859` for slider fills); a
// pressed fill is one step (10 %) darker in light, lighter in dark (INV-B).

import 'package:flutter/widgets.dart';

import '../window.dart' show ToolbarScope;
import '../appearance.dart';

/// The system colors the control groups share, light and dark.
abstract final class ControlPalette {
  /// The system accent (CT-CL-01: multicolor and blue, sRGB `#007aff` light and dark).
  static const Color accent = Color(0xFF007AFF);

  /// Accent fills in an inactive window (INV-B gallery: default button, toggle, segment,
  /// switch, checkbox and radio).
  static const Color inactiveAccentLight = Color(0xFFCFCFCF);
  static const Color inactiveAccentDark = Color(0xFF505051);

  /// Slider fills in an inactive window (INV-B gallery).
  static const Color inactiveTrackFillLight = Color(0xFFC5C5C5);
  static const Color inactiveTrackFillDark = Color(0xFF585859);

  /// The 3 pt ring of text fields (MU-32), the same as the controls' ring with the default
  /// accent (CT-TF-09).
  static const Color fieldRingLight = Color(0xFF8FB4FB);
  static const Color fieldRingDark = Color(0xFF296692);

  /// The ring of buttons and other controls with the default accent (CT-TF-09).
  static const Color controlRingLight = fieldRingLight;
  static const Color controlRingDark = fieldRingDark;

  /// A text field's ring fades in and out over ~200 ms (MU-70); controls' rings jump.
  static const Duration ringFade = Duration(milliseconds: 200);

  /// A pressed fill: one step, 10 % towards black in light and towards white in dark, for gray
  /// and accent fills alike (INV-B: `#ececec` → `#d5d5d5`, `#373738` → `#4b4b4c`, `#e6e6e6` →
  /// `#cfcfcf`, `#3c3c3d` → `#4f4f50`, the accent likewise).
  static const double pressedStep = 0.10;

  /// The accent gray of an inactive window in one appearance.
  static Color inactiveAccent({required bool dark}) =>
      dark ? inactiveAccentDark : inactiveAccentLight;

  /// The gray of an inactive window's slider fill.
  static Color inactiveTrackFill({required bool dark}) =>
      dark ? inactiveTrackFillDark : inactiveTrackFillLight;

  /// One pressed step of `fill`.
  static Color pressed(Color fill, {required bool dark}) => Color.lerp(
    fill,
    dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
    pressedStep,
  )!;
}

/// The nine system accent colors (CT-CL-01). [multicolor] looks blue in standard controls.
enum SilicaAccent {
  multicolor,
  blue,
  purple,
  pink,
  red,
  orange,
  yellow,
  green,
  graphite,
}

/// The colors of one accent in one appearance (CT-CL-01, sRGB).
@immutable
class AccentColors {
  const AccentColors({
    required this.plain,
    required this.fill,
    required this.ring,
  });

  /// The colors of an app's own accent (not one of the nine): the same color for the fills and
  /// a ring at 50 % over the window background.
  factory AccentColors.custom(Color color, {required bool dark}) =>
      AccentColors(
        plain: color,
        fill: color,
        ring: Color.lerp(
          color,
          dark ? const Color(0xFF272728) : const Color(0xFFFFFFFF),
          0.5,
        )!,
      );

  /// The exact system color: the default button and the progress fill.
  final Color plain;

  /// Toggles on, selected segments, switches on, checkboxes and radios on, slider fills: about
  /// 2 % darker than [plain] in light, slightly lighter in dark.
  final Color fill;

  /// The keyboard focus ring: the accent at about 50 % over the window.
  final Color ring;

  /// The measured colors of `accent`.
  static AccentColors of(SilicaAccent accent, {required bool dark}) =>
      (dark ? _dark : _light)[accent]!;

  @override
  bool operator ==(Object other) =>
      other is AccentColors &&
      other.plain == plain &&
      other.fill == fill &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(plain, fill, ring);

  static const Map<SilicaAccent, AccentColors> _light = {
    SilicaAccent.multicolor: AccentColors(
      plain: Color(0xFF007AFF),
      fill: Color(0xFF0077F9),
      ring: ControlPalette.controlRingLight,
    ),
    SilicaAccent.blue: AccentColors(
      plain: Color(0xFF007AFF),
      fill: Color(0xFF0077F9),
      ring: ControlPalette.controlRingLight,
    ),
    SilicaAccent.purple: AccentColors(
      plain: Color(0xFF953D96),
      fill: Color(0xFF913B92),
      ring: Color(0xFFC393C3),
    ),
    SilicaAccent.pink: AccentColors(
      plain: Color(0xFFF74F9F),
      fill: Color(0xFFF04E9A),
      ring: Color(0xFFF9A0C6),
    ),
    SilicaAccent.red: AccentColors(
      plain: Color(0xFFE0393E),
      fill: Color(0xFFDB373D),
      ring: Color(0xFFEC9894),
    ),
    SilicaAccent.orange: AccentColors(
      plain: Color(0xFFF98A17),
      fill: Color(0xFFF98A17),
      ring: Color(0xFFF8B88A),
    ),
    SilicaAccent.yellow: AccentColors(
      plain: Color(0xFFFFC727),
      fill: Color(0xFFF9C225),
      ring: Color(0xFFF9DC92),
    ),
    SilicaAccent.green: AccentColors(
      plain: Color(0xFF62BA46),
      fill: Color(0xFF5FB644),
      ring: Color(0xFFA9D59A),
    ),
    SilicaAccent.graphite: AccentColors(
      plain: Color(0xFF989898),
      fill: Color(0xFF949494),
      ring: Color(0xFF9A9A9E),
    ),
  };

  static const Map<SilicaAccent, AccentColors> _dark = {
    SilicaAccent.multicolor: AccentColors(
      plain: Color(0xFF007AFF),
      fill: Color(0xFF0D7DFF),
      ring: ControlPalette.controlRingDark,
    ),
    SilicaAccent.blue: AccentColors(
      plain: Color(0xFF007AFF),
      fill: Color(0xFF0D7DFF),
      ring: ControlPalette.controlRingDark,
    ),
    SilicaAccent.purple: AccentColors(
      plain: Color(0xFFA650A7),
      fill: Color(0xFFA755A9),
      ring: Color(0xFF825084),
    ),
    SilicaAccent.pink: AccentColors(
      plain: Color(0xFFF74F9F),
      fill: Color(0xFFF854A1),
      ring: Color(0xFF93507E),
    ),
    SilicaAccent.red: AccentColors(
      plain: Color(0xFFFF5257),
      fill: Color(0xFFFF565B),
      ring: Color(0xFF945154),
    ),
    SilicaAccent.orange: AccentColors(
      plain: Color(0xFFFF9F40),
      fill: Color(0xFFFF9F40),
      ring: Color(0xFF936E33),
    ),
    SilicaAccent.yellow: AccentColors(
      plain: Color(0xFFFFC601),
      fill: Color(0xFFFFC811),
      ring: Color(0xFF93912A),
    ),
    SilicaAccent.green: AccentColors(
      plain: Color(0xFF62BA46),
      fill: Color(0xFF66BC4A),
      ring: Color(0xFF5B8F4A),
    ),
    SilicaAccent.graphite: AccentColors(
      plain: Color(0xFF8C8C8C),
      fill: Color(0xFF8F8F8F),
      ring: Color(0xFF737374),
    ),
  };
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

/// The accent of the controls under it (default button, checkbox, radio, switch on, slider
/// fill, focus ring): one of the nine system accents ([ControlAccent.palette], what the system
/// appearance setting picks) or an app's own color (Clock uses orange). Without a scope the
/// controls use [SilicaAccent.multicolor].
class ControlAccent extends InheritedWidget {
  /// An app's own accent color.
  const ControlAccent({
    super.key,
    required Color this.color,
    required super.child,
  }) : accent = null;

  /// One of the system accents.
  const ControlAccent.palette({
    super.key,
    required SilicaAccent this.accent,
    required super.child,
  }) : color = null;

  /// The app's own color, or null for a system accent.
  final Color? color;

  /// The system accent, or null for an app's own color.
  final SilicaAccent? accent;

  /// The plain color of the default accent.
  static const Color system = ControlPalette.accent;

  /// The colors of the accent in effect, in the current appearance.
  static AccentColors colorsOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ControlAccent>();
    final dark = SilicaAppearance.isDark(context);
    if (scope?.color case final color?) {
      return AccentColors.custom(color, dark: dark);
    }
    return AccentColors.of(
      scope?.accent ?? SilicaAccent.multicolor,
      dark: dark,
    );
  }

  /// The plain accent color (the default button, the progress fill).
  static Color of(BuildContext context) => colorsOf(context).plain;

  /// The control fill of the accent (toggles, segments, switches, checkboxes, radios, slider).
  static Color fillOf(BuildContext context) => colorsOf(context).fill;

  @override
  bool updateShouldNotify(ControlAccent old) =>
      old.color != color || old.accent != accent;
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

/// What a [FocusRing] surrounds: the same color, different motion.
enum FocusRingKind {
  /// Text fields: the ring fades in and out (MU-70).
  field,

  /// Buttons and the other controls: the ring jumps in one frame (CT-TF-09).
  control,
}

/// The keyboard focus ring: a band of `width` around the child's rounded rectangle, outside it
/// (3 pt, CT-TF-09), in the ring color of the accent in effect ([ControlAccent]). A text field's
/// ring fades in and out ([ControlPalette.ringFade]); a control's ring appears and moves in one
/// frame. Hidden in an inactive window.
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
    final ringColor = color ?? ControlAccent.colorsOf(context).ring;
    return Stack(
      alignment: Alignment.topLeft,
      textDirection: TextDirection.ltr,
      // Pass the incoming constraints on: a loose Stack would hand the child loose
      // ones, so a child in a tight box (a field in its 38 pt capsule) shrank to its
      // content and sat at the top instead of filling the box.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: shown ? 1 : 0),
              duration: kind == FocusRingKind.field
                  ? ControlPalette.ringFade
                  : Duration.zero,
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
