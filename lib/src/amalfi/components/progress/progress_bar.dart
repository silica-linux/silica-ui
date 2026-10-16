// The progress bar (kit `Progress/Bar/Determinate|Indeterminate/<Small|Regular|Large>/*`): a
// `Surface/Sunken` track with a `Line/Separator` rim; determinate, the done part is
// `Accent/Amalfi` (`Palette/Ulivo` once complete); indeterminate, a 72 pt segment sweeps
// across the track. Disabled, the fill is `Text/Tertiary` and nothing moves.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';

/// The sizes of the progress indicators.
enum AmalfiProgressSize {
  /// Bar 4 tall; circle 16; spinner 16.
  small,

  /// Bar 8 tall (radius 3); circle 24; spinner 24.
  regular,

  /// Bar 8 tall (round ends); circle 40; spinner 32.
  large,
}

/// The measures of the progress bar, from `Progress/Bar/*`.
abstract final class AmalfiProgressBarMetrics {
  /// The length of a bar that is not given one.
  static const double length = 200;

  /// The thickness of a bar of [size].
  static double thicknessOf(AmalfiProgressSize size) =>
      size == AmalfiProgressSize.small ? 4 : 8;

  /// The corner radius of a bar of [size].
  static double radiusOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => 2,
    AmalfiProgressSize.regular => 3,
    AmalfiProgressSize.large => 4,
  };

  /// The indeterminate segment's length.
  static const double segment = 72;

  /// One sweep of the indeterminate segment across the track. The reference is unmeasured:
  /// an assumption, three `fade.slow` long, eased with `ease-in-out`.
  static const Duration sweep = Duration(milliseconds: 1200);

  /// The easing of a sweep.
  static const Curve sweepCurve = AmalfiCurves.easeInOut;

  /// The segment at [phase] (0–1) of a sweep over a track [length] long: it enters from the
  /// start and leaves at the end, cut to the track, on whole points; null when it is outside.
  static ({double start, double end})? segmentAt(double phase, double length) {
    final p = phase.isFinite ? phase.clamp(0.0, 1.0) : 0.0;
    final x = (-segment + p * (length + segment)).roundToDouble();
    final start = x < 0 ? 0.0 : x;
    final end = x + segment > length ? length : x + segment;
    return end - start > 0 ? (start: start, end: end) : null;
  }
}

/// A progress bar: [value] from 0 to 1 fills the track (complete at 1, in `Palette/Ulivo`);
/// [value] null is indeterminate, a segment sweeping across the track over and over.
///
/// It is as long as the width it is given (200 when unbounded). The sweep runs only while
/// tickers are enabled (`TickerMode`: off in hidden routes), not when [enabled] is false and
/// not with reduced motion, where the segment rests in the middle. [phase] freezes the
/// segment at that point of its sweep (0–1).
class AmalfiProgressBar extends StatefulWidget {
  const AmalfiProgressBar({
    super.key,
    this.value,
    this.size = AmalfiProgressSize.regular,
    this.enabled = true,
    this.phase,
    this.semanticLabel,
  });

  /// The part done, 0–1; null: indeterminate.
  final double? value;

  final AmalfiProgressSize size;

  /// Whether the task is active; disabled bars are grey and still.
  final bool enabled;

  /// Where an indeterminate segment stands in its sweep, 0–1; null: it sweeps.
  final double? phase;

  /// What is in progress, for screen readers.
  final String? semanticLabel;

  @override
  State<AmalfiProgressBar> createState() => _AmalfiProgressBarState();
}

class _AmalfiProgressBarState extends State<AmalfiProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AmalfiProgressBarMetrics.sweep,
  );

  bool get _animates =>
      widget.value == null &&
      widget.enabled &&
      widget.phase == null &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(AmalfiProgressBar old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    if (_animates) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else if (_sweep.isAnimating) {
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
    final value = widget.value;
    final percent = value == null || !value.isFinite
        ? null
        : '${(value.clamp(0.0, 1.0) * 100).round()}%';
    return Semantics(
      label: widget.semanticLabel,
      value: percent,
      enabled: widget.enabled,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final length = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : AmalfiProgressBarMetrics.length;
          return AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) => _face(context, length),
          );
        },
      ),
    );
  }

  Widget _face(BuildContext context, double length) {
    final colors = AmalfiTheme.of(context).colors;
    final size = widget.size;
    final thickness = AmalfiProgressBarMetrics.thicknessOf(size);
    final radius = AmalfiProgressBarMetrics.radiusOf(size);
    final value = widget.value;
    final enabled = widget.enabled;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;

    ({double start, double end})? part;
    Color color;
    if (value == null) {
      final phase =
          widget.phase ??
          (_animates
              ? AmalfiProgressBarMetrics.sweepCurve.transform(_sweep.value)
              : 0.5);
      part = AmalfiProgressBarMetrics.segmentAt(enabled ? phase : 0.5, length);
      color = enabled ? colors.accentAmalfi : colors.textTertiary;
    } else {
      final v = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
      final end = AmalfiGrid.snap(v * length).clamp(0.0, length);
      part = end > 0 ? (start: 0.0, end: end) : null;
      color = !enabled
          ? colors.textTertiary
          : v >= 1
          ? colors.paletteUlivo
          : colors.accentAmalfi;
    }
    final fill = part;
    return SizedBox(
      width: length,
      height: thickness,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: AmalfiShapeDecoration(
                color: colors.surfaceSunken,
                shape: AmalfiSmoothBorder(
                  radius: radius,
                  side: BorderSide(
                    color: colors.lineSeparator,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
              ),
            ),
          ),
          if (fill != null)
            Positioned(
              left: rtl ? length - fill.end : fill.start,
              width: fill.end - fill.start,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: AmalfiShapeDecoration(
                  color: color,
                  shape: AmalfiSmoothBorder(radius: radius),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
