// The slider thumb (kit `Sliders/Thumb/Round/*`): a 20 pt disc of `Surface/Control` with a
// 1 pt `Line/Border` rim inside and the control shadow (level 1); hover lays
// `Accent/Amalfi Soft` over it, a press turns it `Surface/Control Pressed`, keyboard focus
// adds the 3 pt halo outside; disabled, the resting thumb at 35 %
// (`AmalfiStates.disabledOpacity`, user decision 2026-10-16).

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';

/// The measures of the sliders, from the kit masters `Sliders/*`.
abstract final class AmalfiSliderMetrics {
  /// The thumb diameter (`Sliders/Thumb/Round`).
  static const double thumb = 20;

  /// The track thickness; its ends are round.
  static const double track = 4;

  /// The length of a slider that is not given one (horizontal `Sliders/Horizontal/*`).
  static const double horizontalLength = 200;

  /// The length of a vertical slider that is not given one (`Sliders/Vertical/*`).
  static const double verticalLength = 160;

  /// The extent of a slider across its track (the thumb).
  static const double thickness = 20;

  /// The extent across of a slider with tick marks (`Sliders/Horizontal/Ticks`): the ticks
  /// start 8 below the track and leave 8 under them.
  static const double thicknessWithTicks = 36;

  /// Between the track and the tick marks.
  static const double tickGap = 8;

  /// A tick mark: 2 × 8, centred under a stop of the thumb.
  static const Size tick = Size(2, 8);

  /// The glyph at each end of `Sliders/Horizontal/Glyphs`.
  static const double glyph = 16;

  /// Between a glyph and the slider.
  static const double glyphGap = 8;

  /// The lens over a dragged thumb (`Sliders/Thumb/Lens/Dragging`), along the track ×
  /// across it: the lens rule ([AmalfiLens.sizeAround]) around the thumb's stretch of the
  /// track, the thumb's length by the track's thickness (36 × 28).
  static final Size lens = AmalfiLens.sizeAround(const Size(thumb, track));

  /// The circular slider (`Sliders/Circular/Dial`): its side.
  static const double dial = 56;

  /// The diameter of the dial's track, centred (the centre line of its 4 pt stroke).
  static const double dialTrack = 44;

  /// The distance from the dial's centre to the thumb's centre. The kit puts the thumb on
  /// the inner edge of the 4 pt track (19.8 measured), not on its centre line.
  static const double dialOrbit = 20;
}

/// A slider thumb in [states]: [WidgetState.hovered], [WidgetState.pressed],
/// [WidgetState.focused] (shows the focus halo), [WidgetState.disabled] (the resting thumb
/// at 35 %; a disabled slider dims as a whole and hands its thumb no states), and
/// [WidgetState.dragged]: the core of the lens of a dragged thumb (`AmalfiSliderLens`), flat
/// on the glass, without shadow, hover or press.
///
/// It is the face drawn by the Amalfi sliders; use it on its own only to build a custom
/// slider.
class AmalfiSliderThumb extends StatelessWidget {
  const AmalfiSliderThumb({super.key, this.states = const {}});

  /// The interaction states shown.
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final disabled = states.contains(WidgetState.disabled);
    final core = !disabled && states.contains(WidgetState.dragged);
    final pressed = !disabled && !core && states.contains(WidgetState.pressed);
    final hovered =
        !disabled && !core && !pressed && states.contains(WidgetState.hovered);
    final focused = !disabled && !core && states.contains(WidgetState.focused);
    const radius = AmalfiSliderMetrics.thumb / 2;
    final face = SizedBox.square(
      dimension: AmalfiSliderMetrics.thumb,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: AmalfiShapeDecoration(
              color: pressed
                  ? colors.surfaceControlPressed
                  : colors.surfaceControl,
              shape: AmalfiSmoothBorder(
                radius: radius,
                side: BorderSide(
                  color: colors.lineBorder,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              shadows: core ? null : amalfiControlShadows(colors),
            ),
          ),
          if (hovered)
            DecoratedBox(
              decoration: AmalfiShapeDecoration(
                color: colors.accentAmalfiSoft,
                shape: const AmalfiSmoothBorder(radius: radius),
              ),
            ),
          if (focused) const AmalfiFocusHalo(radius: radius),
        ],
      ),
    );
    if (!disabled) return face;
    return Opacity(opacity: AmalfiStates.disabledOpacity, child: face);
  }
}
