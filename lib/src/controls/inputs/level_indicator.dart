// Level indicators: continuous and discrete capacity, rating.
//
// Not measured (inventory CT-LV-01 missing). Provisional: the continuous bar (6 pt capsule,
// like the progress track), the discrete segments (12 pt tall, 2 pt gap, radius 2), the stars
// (13 pt, 2 pt gap); the level colors are the label dot colors green, yellow and red
// (mustache.md › MU-62).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'input_style.dart';
import 'slider.dart' show keyboardValue;

/// The look of a level indicator.
enum LevelIndicatorStyle {
  /// One bar filled up to the value.
  continuous,

  /// One segment per unit between min and max.
  discrete,

  /// Stars, editable.
  rating,
}

/// The level colors (the label dots, MU-62).
abstract final class LevelColors {
  static const Color normalLight = Color(0xFF65D27B);
  static const Color normalDark = Color(0xFF65DA7C);
  static const Color warningLight = Color(0xFFFFD54C);
  static const Color warningDark = Color(0xFFFFDE4D);
  static const Color criticalLight = Color(0xFFFF6663);
  static const Color criticalDark = Color(0xFFFF6D6B);
}

/// A level indicator. The fill turns yellow at [warning] and red at [critical] (when given;
/// when `critical < warning` the scale is inverted, low values are the critical ones).
class SilicaLevelIndicator extends StatefulWidget {
  const SilicaLevelIndicator({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 5,
    this.style = LevelIndicatorStyle.continuous,
    this.warning,
    this.critical,
    this.width = 100,
    this.onChanged,
    this.focusNode,
    this.semanticLabel,
    this.semanticValue,
  });

  final double value;
  final double min;
  final double max;
  final LevelIndicatorStyle style;
  final double? warning;
  final double? critical;

  /// The width of the bar styles (the rating is as wide as its stars).
  final double width;

  /// Editable (clicks and arrows) when given: a rating, usually.
  final ValueChanged<double>? onChanged;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final String Function(double value)? semanticValue;

  /// Star side and gap (provisional).
  static const double star = 13;
  static const double starGap = 2;

  @override
  State<SilicaLevelIndicator> createState() => _SilicaLevelIndicatorState();
}

class _SilicaLevelIndicatorState extends State<SilicaLevelIndicator> {
  bool _focused = false;

  bool get _editable => widget.onChanged != null;

  Color _levelColor(bool dark) {
    final v = widget.value;
    final warning = widget.warning, critical = widget.critical;
    final inverted = warning != null && critical != null && critical < warning;
    bool past(double? t) => t != null && (inverted ? v <= t : v >= t);
    if (past(critical)) {
      return dark ? LevelColors.criticalDark : LevelColors.criticalLight;
    }
    if (past(warning)) {
      return dark ? LevelColors.warningDark : LevelColors.warningLight;
    }
    return dark ? LevelColors.normalDark : LevelColors.normalLight;
  }

  int get _units => math.max(1, (widget.max - widget.min).round());

  void _set(double v) {
    final next = v.clamp(widget.min, widget.max).toDouble();
    if (next != widget.value) widget.onChanged?.call(next);
  }

  void _pick(Offset p, Size size) {
    final double t;
    if (widget.style == LevelIndicatorStyle.rating) {
      t =
          (p.dx + SilicaLevelIndicator.starGap) /
          (SilicaLevelIndicator.star + SilicaLevelIndicator.starGap);
      _set(widget.min + t.ceilToDouble());
    } else {
      t = (p.dx / size.width).clamp(0.0, 1.0);
      final v = widget.min + t * (widget.max - widget.min);
      _set(widget.style == LevelIndicatorStyle.discrete ? v.ceilToDouble() : v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final rating = widget.style == LevelIndicatorStyle.rating;
    final size = rating
        ? Size(
            _units * SilicaLevelIndicator.star +
                (_units - 1) * SilicaLevelIndicator.starGap,
            SilicaLevelIndicator.star,
          )
        : Size(
            widget.width,
            widget.style == LevelIndicatorStyle.discrete ? 12 : 6,
          );
    final fill = rating
        ? (WindowActiveScope.of(context) ? colors.glyph : colors.placeholder)
        : _levelColor(dark);
    final span = widget.max - widget.min;
    final t = span <= 0
        ? 0.0
        : ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    Widget body = CustomPaint(
      size: size,
      painter: LevelPainter(
        style: widget.style,
        t: t,
        units: _units,
        fill: fill,
        empty: colors.levelEmpty,
      ),
    );
    if (_editable) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _pick(d.localPosition, size),
        onHorizontalDragUpdate: (d) => _pick(d.localPosition, size),
        child: FocusRing(
          visible: _focused,
          radius: 3,
          width: InputMetrics.controlRing,
          color: colors.focusRingControl,
          child: body,
        ),
      );
    }
    final valueText =
        widget.semanticValue?.call(widget.value) ??
        (rating
            ? '${widget.value.round()} / ${_units.toString()}'
            : '${(t * 100).round()} %');
    return Semantics(
      label: widget.semanticLabel,
      value: valueText,
      slider: _editable,
      onIncrease: _editable ? () => _set(widget.value + 1) : null,
      onDecrease: _editable ? () => _set(widget.value - 1) : null,
      increasedValue: _editable
          ? (widget.semanticValue?.call(
                  math.min(widget.max, widget.value + 1),
                ) ??
                '${math.min(widget.max, widget.value + 1).round()}')
          : null,
      decreasedValue: _editable
          ? (widget.semanticValue?.call(
                  math.max(widget.min, widget.value - 1),
                ) ??
                '${math.max(widget.min, widget.value - 1).round()}')
          : null,
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: _editable,
        skipTraversal: !_editable,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (!_editable) return KeyEventResult.ignored;
          final next = keyboardValue(
            event,
            value: widget.value,
            min: widget.min,
            max: widget.max,
            step: 1,
          );
          if (next == null) return KeyEventResult.ignored;
          _set(next);
          return KeyEventResult.handled;
        },
        child: body,
      ),
    );
  }
}

/// Paints a level indicator.
class LevelPainter extends CustomPainter {
  LevelPainter({
    required this.style,
    required this.t,
    required this.units,
    required this.fill,
    required this.empty,
  });

  final LevelIndicatorStyle style;
  final double t;
  final int units;
  final Color fill;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case LevelIndicatorStyle.continuous:
        final r = Radius.circular(size.height / 2);
        final shape = RRect.fromRectAndRadius(Offset.zero & size, r);
        canvas.drawRRect(shape, Paint()..color = empty);
        if (t > 0) {
          canvas.save();
          canvas.clipRRect(shape);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                0,
                0,
                math.max(size.height, t * size.width),
                size.height,
              ),
              r,
            ),
            Paint()..color = fill,
          );
          canvas.restore();
        }
      case LevelIndicatorStyle.discrete:
        const gap = 2.0;
        final w = (size.width - gap * (units - 1)) / units;
        final lit = (t * units).ceil();
        for (var i = 0; i < units; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(i * (w + gap), 0, w, size.height),
              const Radius.circular(2),
            ),
            Paint()..color = i < lit ? fill : empty,
          );
        }
      case LevelIndicatorStyle.rating:
        const s = SilicaLevelIndicator.star;
        final lit = (t * units).round();
        for (var i = 0; i < units; i++) {
          final path = _star(
            Offset(i * (s + SilicaLevelIndicator.starGap) + s / 2, s / 2),
            s / 2,
          );
          canvas.drawPath(path, Paint()..color = i < lit ? fill : empty);
        }
    }
  }

  static Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = i * math.pi / 5;
      final p = c + Offset(math.sin(a), -math.cos(a)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(LevelPainter old) =>
      old.style != style ||
      old.t != t ||
      old.units != units ||
      old.fill != fill ||
      old.empty != empty;
}
