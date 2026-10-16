// The circular slider (kit `Sliders/Circular/Dial`): a 56 pt dial with a 4 pt
// `Surface/Sunken` ring, the value drawn as an `Accent/Amalfi` arc from the top clockwise
// (`Text/Tertiary` when disabled), and the round thumb on the ring at the value.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import 'arc.dart';
import 'lens.dart';
import 'slider_core.dart';
import 'thumb.dart';

/// A dial that sets a value between [min] and [max]: the value runs clockwise from the top,
/// a full turn from [min] to [max]. Drag the thumb (or press anywhere on the dial) around the
/// centre, or use the arrow keys (up and right increase; Home and End go to the ends). The
/// value does not wrap from one end to the other while dragging.
///
/// It is 56 × 56 (`AmalfiSliderMetrics.dial`); its thumb becomes a lens while dragged.
class AmalfiCircularSlider extends AmalfiSliderBase {
  const AmalfiCircularSlider({
    super.key,
    required super.value,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min,
    super.max,
    super.divisions,
    super.focusNode,
    super.autofocus,
    super.statesController,
    super.semanticLabel,
  });

  @override
  State<AmalfiCircularSlider> createState() => _AmalfiCircularSliderState();
}

class _AmalfiCircularSliderState
    extends AmalfiSliderBaseState<AmalfiCircularSlider> {
  static const double _side = AmalfiSliderMetrics.dial;
  static const Offset _centre = Offset(_side / 2, _side / 2);

  /// The thumb for [f], on whole points.
  Rect _thumb(double f) {
    final a = f * 2 * math.pi;
    final c =
        _centre +
        Offset(math.sin(a), -math.cos(a)) * AmalfiSliderMetrics.dialOrbit;
    const t = AmalfiSliderMetrics.thumb;
    return Rect.fromLTWH(
      (c.dx - t / 2).roundToDouble(),
      (c.dy - t / 2).roundToDouble(),
      t,
      t,
    );
  }

  @override
  Offset get thumbCentre => _thumb(fraction).center;

  @override
  double? fractionAt(Offset local, {required Offset grab}) {
    final v = local - grab - _centre;
    if (v.distance < 1) return null;
    var f = math.atan2(v.dx, -v.dy) / (2 * math.pi);
    if (f < 0) f += 1;
    // While dragging, no wrap across the top: past it, stay at the end the value is near.
    final now = fraction;
    if (states.contains(WidgetState.dragged) && (f - now).abs() > 0.5) {
      f = now > 0.5 ? 1 : 0;
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return interactive(face: _face(context), rtl: rtl);
  }

  Widget _face(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final states = this.states;
    final f = fraction;
    final thumb = _thumb(f);
    const ring = AmalfiSliderMetrics.dialTrack;
    const ringRect = Rect.fromLTWH(
      (_side - ring) / 2,
      (_side - ring) / 2,
      ring,
      ring,
    );
    final lensSize = AmalfiSliderMetrics.lens;
    final g = lensGrowth;
    final grown = Rect.fromCenter(
      center: thumb.center,
      width: thumb.width + (lensSize.width - thumb.width) * g,
      height: thumb.height + (lensSize.height - thumb.height) * g,
    );
    final lens = Rect.fromLTRB(
      grown.left.roundToDouble(),
      grown.top.roundToDouble(),
      grown.right.roundToDouble(),
      grown.bottom.roundToDouble(),
    );
    List<Widget> bed() => [
      Positioned.fromRect(
        rect: ringRect,
        child: CustomPaint(
          painter: AmalfiArcPainter(
            color: colors.surfaceSunken,
            width: AmalfiSliderMetrics.track,
          ),
        ),
      ),
      Positioned.fromRect(
        rect: ringRect,
        child: CustomPaint(
          painter: AmalfiArcPainter(
            color: widget.enabled ? colors.accentAmalfi : colors.textTertiary,
            width: AmalfiSliderMetrics.track,
            sweep: f,
            roundCaps: true,
          ),
        ),
      ),
    ];
    return SizedBox.square(
      dimension: _side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...bed(),
          if (!states.contains(WidgetState.dragged))
            Positioned.fromRect(
              rect: thumb,
              child: AmalfiSliderThumb(states: states),
            ),
          if (showsLens)
            Positioned.fromRect(
              rect: lens,
              child: IgnorePointer(
                child: Opacity(
                  opacity: lensOpacity,
                  child: AmalfiSliderLens(
                    under: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -lens.left,
                          top: -lens.top,
                          width: _side,
                          height: _side,
                          child: Stack(children: bed()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
