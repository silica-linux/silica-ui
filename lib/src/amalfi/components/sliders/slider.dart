// The linear slider (kit `Sliders/Horizontal/Plain|Ticks|Glyphs|Dragging`,
// `Sliders/Vertical/Plain`): a 4 pt `Surface/Sunken` track with a `Line/Separator` rim, the
// part up to the value filled with `Accent/Amalfi`, and the round thumb; optional tick marks
// under the track (2 × 8, under the thumb's stops) and glyphs at the ends. While the thumb is
// dragged it becomes a Glass/Clear lens (`materials.md`). Disabled: the whole slider, glyphs
// included, at 35 % (`AmalfiStates.disabledOpacity`, user decision 2026-10-16).

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'lens.dart';
import 'slider_core.dart';
import 'thumb.dart';

/// A slider that sets a value between [min] and [max] by dragging its thumb along a track,
/// clicking the track, or with the arrow keys (Home and End go to the ends).
///
/// Horizontal sliders are as long as the width they are given (200 when unbounded) and 20
/// tall, 36 with [tickMarks]; vertical ones are 20 wide and as tall as they are given (160
/// when unbounded), with the minimum at the bottom. In right-to-left text a horizontal slider
/// runs from right to left.
///
/// [minimumGlyph] and [maximumGlyph] go 8 before and after a horizontal slider, in 16 pt
/// boxes, coloured `Text/Secondary` through [IconTheme].
class AmalfiSlider extends AmalfiSliderBase {
  const AmalfiSlider({
    super.key,
    required super.value,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min,
    super.max,
    super.divisions,
    this.tickMarks = false,
    this.axis = Axis.horizontal,
    this.minimumGlyph,
    this.maximumGlyph,
    super.focusNode,
    super.autofocus,
    super.statesController,
    super.semanticLabel,
  }) : indicator = false;

  /// A read-only indicator: the track and its fill, no thumb, at full strength (not dimmed
  /// like a disabled slider). It ignores the pointer and the keyboard and takes no focus. The
  /// shell's Control Center Display and Sound modules and its volume and brightness HUD draw
  /// their level like this.
  const AmalfiSlider.indicator({
    super.key,
    required super.value,
    super.min,
    super.max,
    this.axis = Axis.horizontal,
    super.semanticLabel,
  }) : tickMarks = false,
       minimumGlyph = null,
       maximumGlyph = null,
       indicator = true,
       super(onChanged: null);

  /// Whether this is a read-only indicator without a thumb ([AmalfiSlider.indicator]).
  final bool indicator;

  /// Whether to draw a tick mark under the track at each of the [divisions] stops (needs
  /// [divisions]).
  final bool tickMarks;

  /// The direction of the track.
  final Axis axis;

  /// The glyph before a horizontal slider (a quiet speaker); null: none.
  final Widget? minimumGlyph;

  /// The glyph after a horizontal slider (a loud speaker); null: none.
  final Widget? maximumGlyph;

  @override
  State<AmalfiSlider> createState() => _AmalfiSliderState();
}

/// Where the parts of a linear slider go.
class _Layout {
  _Layout({
    required this.axis,
    required this.length,
    required this.fraction,
    required this.rtl,
    required this.ticks,
  });

  final Axis axis;
  final double length;
  final double fraction;
  final bool rtl;

  /// The number of tick marks (0: none).
  final int ticks;

  bool get horizontal => axis == Axis.horizontal;

  static const double _thumb = AmalfiSliderMetrics.thumb;
  static const double _track = AmalfiSliderMetrics.track;
  static const double _trackAt = (_thumb - _track) / 2;

  Size get size {
    final across = ticks > 0
        ? AmalfiSliderMetrics.thicknessWithTicks
        : AmalfiSliderMetrics.thickness;
    return horizontal ? Size(length, across) : Size(across, length);
  }

  /// [along] (0 at the start of the value) and [across] as a point.
  Rect _rect(double along, double across, double extent, double thickness) =>
      horizontal
      ? Rect.fromLTWH(
          rtl ? length - along - extent : along,
          across,
          extent,
          thickness,
        )
      : Rect.fromLTWH(across, length - along - extent, thickness, extent);

  Rect get track => _rect(0, _trackAt, length, _track);

  Rect get fill =>
      _rect(0, _trackAt, (fraction * length).roundToDouble(), _track);

  Rect get thumb =>
      _rect((fraction * (length - _thumb)).roundToDouble(), 0, _thumb, _thumb);

  /// The thumb's centre for [f].
  double centreAlong(double f) => _thumb / 2 + f * (length - _thumb);

  List<Rect> get tickRects => [
    for (var i = 0; i < ticks; i++)
      _rect(
        (centreAlong(ticks == 1 ? 0 : i / (ticks - 1)) -
                AmalfiSliderMetrics.tick.width / 2)
            .roundToDouble(),
        _trackAt + _track + AmalfiSliderMetrics.tickGap,
        AmalfiSliderMetrics.tick.width,
        AmalfiSliderMetrics.tick.height,
      ),
  ];

  /// The lens around the thumb, [growth] of the way from the thumb to the full lens
  /// ([AmalfiSliderMetrics.lens], the lens rule around the thumb's stretch of the track).
  Rect lens(double growth) {
    final full = AmalfiSliderMetrics.lens;
    final size = horizontal ? full : full.flipped;
    final r = thumb;
    final to = Rect.fromCenter(
      center: r.center,
      width: size.width,
      height: size.height,
    );
    return _whole(Rect.lerp(r, to, growth) ?? to);
  }

  /// The fraction under the thumb centre [p].
  double fractionAt(Offset p) {
    final span = length - _thumb;
    if (span <= 0) return 0;
    final along = horizontal ? (rtl ? length - p.dx : p.dx) : length - p.dy;
    return ((along - _thumb / 2) / span).clamp(0.0, 1.0);
  }
}

/// [r] with its edges rounded to whole points.
Rect _whole(Rect r) => Rect.fromLTRB(
  r.left.roundToDouble(),
  r.top.roundToDouble(),
  r.right.roundToDouble(),
  r.bottom.roundToDouble(),
);

class _AmalfiSliderState extends AmalfiSliderBaseState<AmalfiSlider> {
  _Layout? _layout;

  @override
  Offset get thumbCentre => _layout?.thumb.center ?? Offset.zero;

  @override
  double? fractionAt(Offset local, {required Offset grab}) =>
      _layout?.fractionAt(local - grab);

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final horizontal = widget.axis == Axis.horizontal;
    final hasGlyphs =
        horizontal &&
        (widget.minimumGlyph != null || widget.maximumGlyph != null);
    final slider = LayoutBuilder(
      builder: (context, constraints) {
        final room = horizontal ? constraints.maxWidth : constraints.maxHeight;
        final length = room.isFinite
            ? room
            : horizontal
            ? AmalfiSliderMetrics.horizontalLength
            : AmalfiSliderMetrics.verticalLength;
        final divisions = widget.divisions;
        final layout = _layout = _Layout(
          axis: widget.axis,
          length: length < AmalfiSliderMetrics.thumb
              ? AmalfiSliderMetrics.thumb
              : length,
          fraction: fraction,
          rtl: rtl,
          ticks: widget.tickMarks && divisions != null ? divisions + 1 : 0,
        );
        return interactive(face: _face(context, layout), rtl: rtl);
      },
    );
    if (!hasGlyphs) return _dimmed(slider);
    final colors = AmalfiTheme.of(context).colors;
    Widget glyph(Widget? child) => IconTheme(
      data: IconThemeData(
        size: AmalfiSliderMetrics.glyph,
        color: colors.textSecondary,
      ),
      child: SizedBox.square(
        dimension: AmalfiSliderMetrics.glyph,
        child: child,
      ),
    );
    return _dimmed(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph(widget.minimumGlyph),
          const SizedBox(width: AmalfiSliderMetrics.glyphGap),
          Flexible(child: slider),
          const SizedBox(width: AmalfiSliderMetrics.glyphGap),
          glyph(widget.maximumGlyph),
        ],
      ),
    );
  }

  /// [child] at 35 % when the slider is disabled.
  Widget _dimmed(Widget child) => widget.enabled || widget.indicator
      ? child
      : Opacity(opacity: AmalfiStates.disabledOpacity, child: child);

  /// The track, the fill and the ticks, in a box of the slider's size.
  List<Widget> _bed(AmalfiColors colors, _Layout layout) {
    return [
      Positioned.fromRect(
        rect: layout.track,
        child: DecoratedBox(
          decoration: AmalfiShapeDecoration(
            color: colors.surfaceSunken,
            shape: AmalfiSmoothBorder(
              radius: AmalfiSliderMetrics.track / 2,
              side: BorderSide(
                color: colors.lineSeparator,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        rect: layout.fill,
        child: DecoratedBox(
          decoration: AmalfiShapeDecoration(
            color: colors.accentAmalfi,
            shape: const AmalfiSmoothBorder(
              radius: AmalfiSliderMetrics.track / 2,
            ),
          ),
        ),
      ),
      for (final tick in layout.tickRects)
        Positioned.fromRect(
          rect: tick,
          child: ColoredBox(color: colors.textTertiary),
        ),
    ];
  }

  Widget _face(BuildContext context, _Layout layout) {
    final colors = AmalfiTheme.of(context).colors;
    final states = this.states;
    final dragged = states.contains(WidgetState.dragged);
    final size = layout.size;
    final lens = layout.lens(lensGrowth);
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._bed(colors, layout),
          if (!dragged && !widget.indicator)
            Positioned.fromRect(
              rect: layout.thumb,
              // Disabled, the whole slider dims: the thumb rests.
              child: AmalfiSliderThumb(
                states: widget.enabled ? states : const {},
              ),
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
                          width: size.width,
                          height: size.height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: _bed(colors, layout),
                          ),
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
