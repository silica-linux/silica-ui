// Progress indicators: bar (determinate and indeterminate), spinner, ring.
//
// Measured: the regular bar is an 8 pt capsule in a 20 pt frame, filled with the plain accent
// (`#007aff`, gray in an inactive window) on a `#f0f0f0` / `#383839` track; the spinner has
// 8 gray spokes, 32 pt regular and 16 pt small (CT-PR-01/03, INV-B gallery); the copy window bar
// 309 wide (mustache.md › MU-41 / MU-43); the Now Playing bar 154 × 12 with a 3–4 pt track and
// the elapsed part sRGB `#1482ff` (controlcenter.md › Now Playing); the timer ring, stroke 6 at
// 360 pt, orange sRGB `#ff9230` on `#3b3b3d`, shrinking from the top (clock.md › Timer).
// Provisional: the indeterminate sweep (a lighter third of the bar, 1.2 s) and the spinner's
// speed (1 turn per second).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'input_style.dart';
import '../../appearance.dart';

/// The size of a progress bar.
enum ProgressSize {
  /// 20 pt frame, 8 pt track (CT-PR-01).
  regular,

  /// 12 pt frame, 4 pt track (Now Playing).
  small,
}

/// A progress bar; with a null [value] it is indeterminate.
class SilicaProgressBar extends StatefulWidget {
  const SilicaProgressBar({
    super.key,
    required this.value,
    this.width = 309,
    this.size = ProgressSize.regular,
    this.color,
    this.semanticLabel,
    this.semanticValue,
  });

  /// 0–1, or null for an indeterminate bar.
  final double? value;
  final double width;
  final ProgressSize size;

  /// The fill; the accent when null.
  final Color? color;
  final String? semanticLabel;

  /// The value read by accessibility ("40 %" by default).
  final String Function(double value)? semanticValue;

  /// The indeterminate sweep period (provisional).
  static const Duration sweep = Duration(milliseconds: 1200);

  /// The track of the regular bar, light and dark (CT-PR-01).
  static const Color trackLight = Color(0xFFF0F0F0);
  static const Color trackDark = Color(0xFF383839);

  @override
  State<SilicaProgressBar> createState() => _SilicaProgressBarState();
}

class _SilicaProgressBarState extends State<SilicaProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: SilicaProgressBar.sweep,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SilicaProgressBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.value == null) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final small = widget.size == ProgressSize.small;
    final value = widget.value?.clamp(0.0, 1.0);
    final dark = SilicaAppearance.isDark(context);
    // The plain accent; gray in an inactive window, as the slider fill (INV-B gallery).
    final fill =
        widget.color ??
        (WindowActiveScope.of(context)
            ? ControlAccent.of(context)
            : ControlPalette.inactiveTrackFill(dark: dark));
    final track = small
        ? colors.track
        : (dark ? SilicaProgressBar.trackDark : SilicaProgressBar.trackLight);
    return Semantics(
      label: widget.semanticLabel,
      value: value == null
          ? null
          : widget.semanticValue?.call(value) ?? '${(value * 100).round()} %',
      child: SizedBox(
        width: widget.width,
        height: small ? 12 : 20,
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) => CustomPaint(
            painter: ProgressBarPainter(
              value: value,
              phase: _sweep.value,
              track: track,
              fill: fill,
              thickness: small ? 4 : 8,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a progress bar: the capsule track and the fill, or the indeterminate sweep.
class ProgressBarPainter extends CustomPainter {
  ProgressBarPainter({
    required this.value,
    required this.phase,
    required this.track,
    required this.fill,
    required this.thickness,
  });

  final double? value;
  final double phase;
  final Color track;
  final Color fill;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      (size.height - thickness) / 2,
      size.width,
      thickness,
    );
    final radius = Radius.circular(thickness / 2);
    final shape = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(shape, Paint()..color = track);
    canvas.save();
    canvas.clipRRect(shape);
    final v = value;
    if (v != null) {
      if (v > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              0,
              rect.top,
              math.max(thickness, v * size.width),
              thickness,
            ),
            radius,
          ),
          Paint()..color = fill,
        );
      }
    } else {
      final w = size.width / 3;
      final x = -w + phase * (size.width + w);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, rect.top, w, thickness),
          radius,
        ),
        Paint()..color = fill,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProgressBarPainter old) =>
      old.value != value ||
      old.phase != phase ||
      old.track != track ||
      old.fill != fill ||
      old.thickness != thickness;
}

/// The activity indicator: eight gray spokes turning, the brightest leading (CT-PR-03).
class SilicaSpinner extends StatefulWidget {
  const SilicaSpinner({
    super.key,
    this.size = 32,
    this.color,
    this.animating = true,
    this.semanticLabel,
  });

  /// 32 regular, 16 small (CT-PR-03).
  final double size;
  final Color? color;
  final bool animating;
  final String? semanticLabel;

  /// One turn (provisional).
  static const Duration period = Duration(seconds: 1);

  /// The number of spokes (CT-PR-03).
  static const int spokes = 8;

  @override
  State<SilicaSpinner> createState() => _SilicaSpinnerState();
}

class _SilicaSpinnerState extends State<SilicaSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: SilicaSpinner.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animating) _turn.repeat();
  }

  @override
  void didUpdateWidget(SilicaSpinner old) {
    super.didUpdateWidget(old);
    if (widget.animating && !_turn.isAnimating) _turn.repeat();
    if (!widget.animating) _turn.stop();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? InputColors.of(context).glyph;
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: SpinnerPainter(
            phase: (_turn.value * SilicaSpinner.spokes).floor(),
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Paints the spokes; `phase` is the leading spoke.
class SpinnerPainter extends CustomPainter {
  SpinnerPainter({required this.phase, required this.color});

  final int phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(r, r);
    final paint = Paint()
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    const n = SilicaSpinner.spokes;
    for (var i = 0; i < n; i++) {
      final age = (phase - i) % n;
      paint.color = color.withValues(alpha: color.a * (1 - age / n * 0.75));
      final a = i / n * 2 * math.pi;

      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * r * 0.5, c + dir * r * 0.92, paint);
    }
  }

  @override
  bool shouldRepaint(SpinnerPainter old) =>
      old.phase != phase || old.color != color;
}

/// A circular progress ring (the timer): the remaining part from the top, clockwise.
class SilicaProgressRing extends StatelessWidget {
  const SilicaProgressRing({
    super.key,
    required this.value,
    this.diameter = 360,
    this.stroke = 6,
    this.color = const Color(0xFFFF9230),
    this.track = const Color(0xFF3B3B3D),
    this.semanticLabel,
    this.child,
  });

  /// 0–1: the part still drawn.
  final double value;
  final double diameter;
  final double stroke;
  final Color color;
  final Color track;
  final String? semanticLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    value: '${(value.clamp(0.0, 1.0) * 100).round()} %',
    child: CustomPaint(
      size: Size.square(diameter),
      painter: ProgressRingPainter(
        value: value.clamp(0.0, 1.0),
        stroke: stroke,
        color: color,
        track: track,
      ),
      child: SizedBox.square(
        dimension: diameter,
        child: Center(child: child),
      ),
    ),
  );
}

/// Paints the ring: the track and the arc from the top.
class ProgressRingPainter extends CustomPainter {
  ProgressRingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      value * 2 * math.pi,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      old.value != value ||
      old.stroke != stroke ||
      old.color != color ||
      old.track != track;
}
