// Sliders: linear (with or without tick marks and labels) and circular.
//
// Measured: the regular slider (INV-B gallery and controlcenter.md › CC · sliders: 6 pt track
// `#e6e6e6` / `#3c3c3d`, the accent's fill, a 20 × 16 capsule knob, white with a shadow in light
// and `#dfdfdf` in dark, the fill ending at the knob center: x0 + knob / 2 + v · (L − knob));
// the small one (mustache.md › MU-04: 4 pt track `#e5e5e5` / `#434343`, 18 × 14 knob); the tick
// marks are dots below the track, the whole slider 30 pt tall instead of 24; in an inactive
// window the fill turns `#c5c5c5` / `#585859`; the circular slider shows a 24 pt dial
// (CT-SL-03/04/05, INV-B). Provisional: the pressed knob, the tick dot size (3 pt, 3 pt below),
// the circular slider's dot, the disabled look (50 % opacity).

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'input_style.dart';

/// The size of a slider.
enum SliderSize {
  /// 6 pt track, 20 × 16 knob.
  regular,

  /// 4 pt track, 18 × 14 knob (the file manager icon-size slider).
  small,
}

/// Where the tick marks are drawn.
enum TickPosition { below, above }

/// A slider metrics set.
@immutable
class SliderMetrics {
  const SliderMetrics({required this.track, required this.knob});

  final double track;
  final Size knob;

  static const SliderMetrics regular = SliderMetrics(
    track: 6,
    knob: Size(20, 16),
  );
  static const SliderMetrics small = SliderMetrics(
    track: 4,
    knob: Size(18, 14),
  );

  static SliderMetrics of(SliderSize size) =>
      size == SliderSize.small ? small : regular;

  /// Tick marks: dots below the track (CT-SL-04); 3 pt, 3 pt from the knob (provisional).
  static const Size tick = Size(3, 3);
  static const double tickGap = 3;

  /// The regular track, light and dark (INV-B gallery).
  static const Color trackLight = Color(0xFFE6E6E6);
  static const Color trackDark = Color(0xFF3C3C3D);
}

/// The value change of a key on a slider, stepper or dial: arrows by one step, Page Up/Down
/// by a tenth, Home/End to the ends. Null if the key does not change the value.
double? keyboardValue(
  KeyEvent event, {
  required double value,
  required double min,
  required double max,
  required double step,
}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
  final key = event.logicalKey;
  final page = math.max(step, (max - min) / 10);
  final double next;
  if (key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowUp) {
    next = value + step;
  } else if (key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowDown) {
    next = value - step;
  } else if (key == LogicalKeyboardKey.pageUp) {
    next = value + page;
  } else if (key == LogicalKeyboardKey.pageDown) {
    next = value - page;
  } else if (key == LogicalKeyboardKey.home) {
    next = min;
  } else if (key == LogicalKeyboardKey.end) {
    next = max;
  } else {
    return null;
  }
  return next.clamp(min, max).toDouble();
}

double _snap(double v, double min, double max, int? divisions) {
  if (divisions == null || divisions <= 0) return v;
  final step = (max - min) / divisions;
  return (min + ((v - min) / step).round() * step).clamp(min, max);
}

/// A linear slider.
class SilicaSlider extends StatefulWidget {
  const SilicaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.ticks = false,
    this.tickPosition = TickPosition.below,
    this.labels,
    this.size = SliderSize.regular,
    this.width = 200,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticValue,
    this.onChangeStart,
    this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  /// Discrete steps: the knob snaps to them.
  final int? divisions;

  /// Tick marks at every division (needs [divisions]).
  final bool ticks;
  final TickPosition tickPosition;

  /// Labels spread evenly under the slider, the first at the start and the last at the end
  /// ("Slow", "Fast").
  final List<String>? labels;
  final SliderSize size;
  final double width;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  /// The value as read by accessibility ("50 %" by default).
  final String Function(double value)? semanticValue;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<SilicaSlider> createState() => _SilicaSliderState();
}

class _SilicaSliderState extends State<SilicaSlider> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;
  SliderMetrics get _m => SliderMetrics.of(widget.size);

  double get _t {
    final span = widget.max - widget.min;
    if (span <= 0) return 0;
    return ((widget.value - widget.min) / span).clamp(0.0, 1.0);
  }

  double get _step => widget.divisions != null && widget.divisions! > 0
      ? (widget.max - widget.min) / widget.divisions!
      : (widget.max - widget.min) / 20;

  void _set(double v) {
    final next = _snap(
      v.clamp(widget.min, widget.max),
      widget.min,
      widget.max,
      widget.divisions,
    );
    if (next != widget.value) widget.onChanged?.call(next);
  }

  double _valueAt(double dx) {
    final knob = _m.knob.width;
    final travel = widget.width - knob;
    final t = travel <= 0 ? 0.0 : ((dx - knob / 2) / travel).clamp(0.0, 1.0);
    return widget.min + t * (widget.max - widget.min);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_enabled) return KeyEventResult.ignored;
    final next = keyboardValue(
      event,
      value: widget.value,
      min: widget.min,
      max: widget.max,
      step: _step,
    );
    if (next == null) return KeyEventResult.ignored;
    _set(next);
    return KeyEventResult.handled;
  }

  String _semanticValue(double v) =>
      widget.semanticValue?.call(v) ??
      '${((v - widget.min) / (widget.max - widget.min) * 100).round()} %';

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final active = WindowActiveScope.of(context);
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final m = _m;
    final tickRow = widget.ticks && (widget.divisions ?? 0) > 0;
    final tickSpace = tickRow
        ? SliderMetrics.tickGap + SliderMetrics.tick.height
        : 0.0;
    final above = tickRow && widget.tickPosition == TickPosition.above;
    final height = m.knob.height + tickSpace;
    final slider = SizedBox(
      width: widget.width,
      height: height,
      child: CustomPaint(
        painter: SliderPainter(
          t: _t,
          metrics: m,
          track: widget.size == SliderSize.small
              ? colors.track
              : (dark ? SliderMetrics.trackDark : SliderMetrics.trackLight),
          // The accent's fill; the small slider keeps its own measured blue (MU-04) with the
          // default accent.
          fill: !active
              ? ControlPalette.inactiveTrackFill(dark: dark)
              : widget.size == SliderSize.small &&
                    context
                            .dependOnInheritedWidgetOfExactType<
                              ControlAccent
                            >() ==
                        null
              ? colors.trackFill
              : ControlAccent.fillOf(context),
          knob: _pressed ? colors.bezelPressed : colors.knob,
          knobBorder: colors.knobBorder,
          knobShadow: colors.knobShadow,
          tick: colors.tick,
          ticks: tickRow ? widget.divisions! : 0,
          ticksAbove: above,
        ),
        child: _focused && active
            ? Align(
                alignment: Alignment(
                  -1 +
                      2 *
                          ((m.knob.width / 2 +
                                  _t * (widget.width - m.knob.width)) /
                              widget.width),
                  above ? 1 : -1,
                ),
                child: FocusRing(
                  visible: true,
                  width: InputMetrics.controlRing,
                  radius: m.knob.height / 2,
                  color: colors.focusRingControl,
                  child: SizedBox.fromSize(size: m.knob),
                ),
              )
            : null,
      ),
    );
    final labels = widget.labels;
    Widget body = slider;
    if (labels != null && labels.isNotEmpty) {
      final style = inputText(colors.secondaryText, size: 10);
      body = SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            slider,
            const SizedBox(height: 2),
            SizedBox(
              width: widget.width,
              height: 13,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Align(
                      alignment: Alignment(
                        labels.length == 1
                            ? 0
                            : -1 + 2 * i / (labels.length - 1),
                        0,
                      ),
                      child: Text(labels[i], style: style, maxLines: 1),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: _semanticValue(widget.value),
      increasedValue: _semanticValue(
        (widget.value + _step).clamp(widget.min, widget.max),
      ),
      decreasedValue: _semanticValue(
        (widget.value - _step).clamp(widget.min, widget.max),
      ),
      enabled: _enabled,
      onIncrease: _enabled ? () => _set(widget.value + _step) : null,
      onDecrease: _enabled ? () => _set(widget.value - _step) : null,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: _enabled,
        onKeyEvent: _key,
        onFocusChange: (f) => setState(() => _focused = f),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled
                ? (d) {
                    setState(() => _pressed = true);
                    widget.onChangeStart?.call(widget.value);
                    _set(_valueAt(d.localPosition.dx));
                  }
                : null,
            onTapUp: _enabled ? (_) => _end() : null,
            onTapCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            onHorizontalDragStart: _enabled
                ? (d) {
                    setState(() => _pressed = true);
                    _set(_valueAt(d.localPosition.dx));
                  }
                : null,
            onHorizontalDragUpdate: _enabled
                ? (d) => _set(_valueAt(d.localPosition.dx))
                : null,
            onHorizontalDragEnd: _enabled ? (_) => _end() : null,
            child: body,
          ),
        ),
      ),
    );
  }

  void _end() {
    setState(() => _pressed = false);
    widget.onChangeEnd?.call(widget.value);
  }
}

/// Paints a linear slider: track, fill up to the knob center, ticks and the knob.
class SliderPainter extends CustomPainter {
  SliderPainter({
    required this.t,
    required this.metrics,
    required this.track,
    required this.fill,
    required this.knob,
    required this.knobBorder,
    required this.knobShadow,
    required this.tick,
    this.ticks = 0,
    this.ticksAbove = false,
  });

  final double t;
  final SliderMetrics metrics;
  final Color track;
  final Color fill;
  final Color knob;
  final Color knobBorder;
  final Color knobShadow;
  final Color tick;
  final int ticks;
  final bool ticksAbove;

  @override
  void paint(Canvas canvas, Size size) {
    final k = metrics.knob;
    final tickSpace = ticks > 0
        ? SliderMetrics.tickGap + SliderMetrics.tick.height
        : 0.0;
    final cy = (ticksAbove ? tickSpace : 0) + k.height / 2;
    final th = metrics.track;
    final trackRect = Rect.fromLTWH(0, cy - th / 2, size.width, th);
    final radius = Radius.circular(th / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, radius),
      Paint()..color = track,
    );
    final cx = k.width / 2 + t * (size.width - k.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, trackRect.top, cx, trackRect.bottom),
        radius,
      ),
      Paint()..color = fill,
    );
    if (ticks > 0) {
      final paint = Paint()..color = tick;
      final y = ticksAbove ? 0.0 : k.height + SliderMetrics.tickGap;
      for (var i = 0; i <= ticks; i++) {
        final x = k.width / 2 + i / ticks * (size.width - k.width);
        canvas.drawOval(
          Rect.fromLTWH(
            x - SliderMetrics.tick.width / 2,
            y,
            SliderMetrics.tick.width,
            SliderMetrics.tick.height,
          ),
          paint,
        );
      }
    }
    final knobRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: k.width,
      height: k.height,
    );
    final knobShape = RRect.fromRectAndRadius(
      knobRect,
      Radius.circular(k.height / 2),
    );
    canvas.drawRRect(
      knobShape.shift(const Offset(0, 0.5)),
      Paint()
        ..color = knobShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    canvas.drawRRect(knobShape, Paint()..color = knob);
    if (knobBorder.a > 0) {
      canvas.drawRRect(
        knobShape.deflate(0.25),
        Paint()
          ..color = knobBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(SliderPainter old) =>
      old.t != t ||
      old.metrics != metrics ||
      old.track != track ||
      old.fill != fill ||
      old.knob != knob ||
      old.ticks != ticks ||
      old.ticksAbove != ticksAbove ||
      old.tick != tick;
}

/// A circular slider (dial): a disc with a dot, the value growing clockwise from the top.
class SilicaCircularSlider extends StatefulWidget {
  const SilicaCircularSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.diameter = 24,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.semanticValue,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;

  /// 24 pt regular (provisional).
  final double diameter;
  final bool enabled;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final String Function(double value)? semanticValue;

  @override
  State<SilicaCircularSlider> createState() => _SilicaCircularSliderState();
}

class _SilicaCircularSliderState extends State<SilicaCircularSlider> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  double get _step => widget.divisions != null && widget.divisions! > 0
      ? (widget.max - widget.min) / widget.divisions!
      : (widget.max - widget.min) / 36;

  void _set(double v) {
    final next = _snap(
      v.clamp(widget.min, widget.max),
      widget.min,
      widget.max,
      widget.divisions,
    );
    if (next != widget.value) widget.onChanged?.call(next);
  }

  void _at(Offset p) {
    final c = Offset(widget.diameter / 2, widget.diameter / 2);
    final d = p - c;
    if (d.distance < 1) return;
    // Angle from the top, clockwise, 0..1.
    var a = math.atan2(d.dx, -d.dy) / (2 * math.pi);
    if (a < 0) a += 1;
    _set(widget.min + a * (widget.max - widget.min));
  }

  String _semanticValue(double v) =>
      widget.semanticValue?.call(v) ??
      '${((v - widget.min) / (widget.max - widget.min) * 360).round()}°';

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final active = WindowActiveScope.of(context);
    final span = widget.max - widget.min;
    final t = span <= 0 ? 0.0 : (widget.value - widget.min) / span;
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: _semanticValue(widget.value),
      increasedValue: _semanticValue(
        (widget.value + _step).clamp(widget.min, widget.max),
      ),
      decreasedValue: _semanticValue(
        (widget.value - _step).clamp(widget.min, widget.max),
      ),
      enabled: _enabled,
      onIncrease: _enabled ? () => _set(widget.value + _step) : null,
      onDecrease: _enabled ? () => _set(widget.value - _step) : null,
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: _enabled,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (!_enabled) return KeyEventResult.ignored;
          final next = keyboardValue(
            event,
            value: widget.value,
            min: widget.min,
            max: widget.max,
            step: _step,
          );
          if (next == null) return KeyEventResult.ignored;
          _set(next);
          return KeyEventResult.handled;
        },
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: GestureDetector(
            onPanDown: _enabled
                ? (d) {
                    setState(() => _pressed = true);
                    _at(d.localPosition);
                  }
                : null,
            onPanUpdate: _enabled ? (d) => _at(d.localPosition) : null,
            onPanEnd: _enabled ? (_) => setState(() => _pressed = false) : null,
            onPanCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            child: FocusRing(
              visible: _focused,
              circle: true,
              radius: widget.diameter / 2,
              width: InputMetrics.controlRing,
              color: colors.focusRingControl,
              child: CustomPaint(
                size: Size.square(widget.diameter),
                painter: DialPainter(
                  t: t,
                  disc: _pressed ? colors.bezelPressed : colors.knob,
                  border: colors.bezelBorder,
                  shadow: colors.knobShadow,
                  dot: active ? colors.trackFill : colors.glyph,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the dial: a disc with a shadow and the dot at the value angle.
class DialPainter extends CustomPainter {
  DialPainter({
    required this.t,
    required this.disc,
    required this.border,
    required this.shadow,
    required this.dot,
  });

  final double t;
  final Color disc;
  final Color border;
  final Color shadow;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(r, r);
    canvas.drawCircle(
      c + const Offset(0, 0.5),
      r - 0.5,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    canvas.drawCircle(c, r - 0.5, Paint()..color = disc);
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    final a = t * 2 * math.pi;
    final at = c + Offset(math.sin(a), -math.cos(a)) * (r - 6);
    canvas.drawCircle(at, 2, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(DialPainter old) =>
      old.t != t || old.disc != disc || old.dot != dot || old.border != border;
}
