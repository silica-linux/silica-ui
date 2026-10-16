// The spinner (kit `Progress/Spinner/<Small|Regular|Large>/Rest|Disabled`): twelve spokes of
// `Text/Secondary` around the centre, the one at the top opaque and each next one
// counter-clockwise 7.5 % fainter; the bright spoke steps clockwise. Disabled: every spoke
// `Text/Tertiary` at 50 %, still.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'progress_bar.dart' show AmalfiProgressSize;

/// The measures of the spinner, from `Progress/Spinner/*`.
abstract final class AmalfiSpinnerMetrics {
  /// The side of the spinner of [size]: 16, 24, 32.
  static double sideOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => 16,
    AmalfiProgressSize.regular => 24,
    AmalfiProgressSize.large => 32,
  };

  /// The spoke at the top of the spinner of [size], centred across, from the top edge.
  static Rect spokeOf(AmalfiProgressSize size) {
    final side = sideOf(size);
    final (w, h) = size == AmalfiProgressSize.small ? (1.5, 4.0) : (4.0, 8.0);
    return Rect.fromLTWH((side - w) / 2, 0, w, h);
  }

  /// The corner radius of a spoke of [size].
  static double spokeRadiusOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => 0.75,
    AmalfiProgressSize.regular => 1.02,
    AmalfiProgressSize.large => 1.36,
  };

  /// The number of spokes.
  static const int spokes = 12;

  /// How much fainter each spoke is than the one before it.
  static const double fade = 0.075;

  /// The opacity of every spoke of a disabled spinner.
  static const double disabledOpacity = 0.5;

  /// One turn of the bright spoke. The reference is unmeasured: an assumption, twelve steps
  /// of about 83 ms (the key repeat of `docs/spec/hud.md`).
  static const Duration turn = Duration(milliseconds: 1000);
}

/// An indeterminate spinner. It turns only while tickers are enabled (`TickerMode`: off in
/// hidden routes), when [enabled], and without reduced motion.
class AmalfiSpinner extends StatefulWidget {
  const AmalfiSpinner({
    super.key,
    this.size = AmalfiProgressSize.regular,
    this.enabled = true,
    this.semanticLabel,
  });

  final AmalfiProgressSize size;

  /// Whether the task is active; disabled spinners are grey and still.
  final bool enabled;

  /// What is in progress, for screen readers.
  final String? semanticLabel;

  @override
  State<AmalfiSpinner> createState() => _AmalfiSpinnerState();
}

class _AmalfiSpinnerState extends State<AmalfiSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AmalfiSpinnerMetrics.turn,
  );

  bool get _animates =>
      widget.enabled &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(AmalfiSpinner old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    if (_animates) {
      if (!_turn.isAnimating) _turn.repeat();
    } else if (_turn.isAnimating) {
      _turn.stop();
      _turn.value = 0;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final side = AmalfiSpinnerMetrics.sideOf(widget.size);
    return Semantics(
      label: widget.semanticLabel,
      enabled: widget.enabled,
      child: SizedBox.square(
        dimension: side,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) => CustomPaint(
            painter: AmalfiSpinnerPainter(
              size: widget.size,
              color: widget.enabled
                  ? colors.textSecondary
                  : colors.textTertiary,
              head:
                  (_turn.value * AmalfiSpinnerMetrics.spokes).floor() %
                  AmalfiSpinnerMetrics.spokes,
              enabled: widget.enabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the spokes of a spinner of [size], the brightest at [head] (0 at the top, then
/// clockwise).
class AmalfiSpinnerPainter extends CustomPainter {
  const AmalfiSpinnerPainter({
    required this.size,
    required this.color,
    this.head = 0,
    this.enabled = true,
  });

  final AmalfiProgressSize size;
  final Color color;
  final int head;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size box) {
    final side = AmalfiSpinnerMetrics.sideOf(size);
    final spoke = AmalfiSpinnerMetrics.spokeOf(size);
    final path = smoothRectPath(
      spoke,
      AmalfiSpinnerMetrics.spokeRadiusOf(size),
      AmalfiRadii.smoothing,
    );
    const n = AmalfiSpinnerMetrics.spokes;
    for (var i = 0; i < n; i++) {
      // Spoke i stands i steps clockwise from the top; its age counts back from the head.
      final age = (head - i) % n;
      final opacity = enabled
          ? 1 - AmalfiSpinnerMetrics.fade * age
          : AmalfiSpinnerMetrics.disabledOpacity;
      canvas
        ..save()
        ..translate(side / 2, side / 2)
        ..rotate(i * 2 * math.pi / n)
        ..translate(-side / 2, -side / 2)
        ..drawPath(
          path,
          Paint()..color = color.withValues(alpha: color.a * opacity),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(AmalfiSpinnerPainter old) =>
      old.size != size ||
      old.color != color ||
      old.head != head ||
      old.enabled != enabled;
}
