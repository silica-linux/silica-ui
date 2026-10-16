// The circular progress indicator (kit `Progress/Circular/Determinate/<Small|Regular|Large>`):
// a `Surface/Sunken` ring and the part done as an `Accent/Amalfi` arc from the top clockwise
// with round ends (`Palette/Ulivo` once complete); disabled, the whole indicator at
// `AmalfiStates.disabledOpacity`.

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import '../sliders/arc.dart';
import 'progress_bar.dart' show AmalfiProgressSize;

/// The measures of the circular progress indicator, from `Progress/Circular/*`.
abstract final class AmalfiCircularProgressMetrics {
  /// The side of the indicator of [size]: 16, 24, 40.
  static double sideOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => 16,
    AmalfiProgressSize.regular => 24,
    AmalfiProgressSize.large => 40,
  };

  /// The ring of [size] (the centre line of its stroke) inside the indicator: half the
  /// stroke in from the edge.
  static Rect ringOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => const Rect.fromLTWH(1, 1, 14, 14),
    AmalfiProgressSize.regular => const Rect.fromLTWH(2, 2, 20, 20),
    AmalfiProgressSize.large => const Rect.fromLTWH(2, 2, 36, 36),
  };

  /// The stroke of [size]: 2, 3, 4.
  static double strokeOf(AmalfiProgressSize size) => switch (size) {
    AmalfiProgressSize.small => 2,
    AmalfiProgressSize.regular => 3,
    AmalfiProgressSize.large => 4,
  };
}

/// A ring that fills clockwise from the top as [value] goes from 0 to 1.
class AmalfiCircularProgress extends StatelessWidget {
  const AmalfiCircularProgress({
    super.key,
    required this.value,
    this.size = AmalfiProgressSize.regular,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The part done, 0–1.
  final double value;

  final AmalfiProgressSize size;

  /// Whether the task is active; a disabled ring is dimmed as a whole.
  final bool enabled;

  /// What is in progress, for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final v = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final side = AmalfiCircularProgressMetrics.sideOf(size);
    final ring = AmalfiCircularProgressMetrics.ringOf(size);
    final stroke = AmalfiCircularProgressMetrics.strokeOf(size);
    final color = v >= 1 ? colors.paletteUlivo : colors.accentAmalfi;
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : AmalfiStates.disabledOpacity,
        child: SizedBox.square(
          dimension: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: ring,
                child: CustomPaint(
                  painter: AmalfiArcPainter(
                    color: colors.surfaceSunken,
                    width: stroke,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: ring,
                child: CustomPaint(
                  painter: AmalfiArcPainter(
                    color: color,
                    width: stroke,
                    sweep: v,
                    roundCaps: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
