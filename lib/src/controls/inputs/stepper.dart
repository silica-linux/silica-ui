// Stepper: two arrows stacked in a small bezel, with auto-repeat while held.
//
// Measured (CT-SL-07, INV-B gallery): a 20 × 24 gray rounded pill with up and down chevrons.
// Provisional: the radius (half the width), the bezel and pressed colors (the alert normal
// button, misc.md › Alert), the repeat after 400 ms then every 80 ms.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'input_style.dart';
import 'slider.dart' show keyboardValue;

/// The stepper measurements: the size (CT-SL-07), the rest provisional.
abstract final class StepperMetrics {
  static const Size size = Size(20, 24);
  static const double radius = 10;
  static const Duration repeatDelay = Duration(milliseconds: 400);
  static const Duration repeatInterval = Duration(milliseconds: 80);
}

/// A stepper: ▲ adds [step], ▼ subtracts it, within [min]–[max] (or around with [wraps]).
class SilicaStepper extends StatefulWidget {
  const SilicaStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.wraps = false,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.semanticValue,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final double step;

  /// Past the end the value starts again from the other one.
  final bool wraps;
  final bool enabled;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final String Function(double value)? semanticValue;

  @override
  State<SilicaStepper> createState() => _SilicaStepperState();
}

class _SilicaStepperState extends State<SilicaStepper> {
  /// +1 while ▲ is held, −1 for ▼.
  int _pressed = 0;
  bool _focused = false;
  Timer? _repeat;
  late double _value = widget.value;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  @override
  void didUpdateWidget(SilicaStepper old) {
    super.didUpdateWidget(old);
    _value = widget.value;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  double _next(int direction) {
    var v = _value + direction * widget.step;
    if (v > widget.max) v = widget.wraps ? widget.min : widget.max;
    if (v < widget.min) v = widget.wraps ? widget.max : widget.min;
    return v;
  }

  void _stepBy(int direction) {
    final v = _next(direction);
    if (v == _value) return;
    _value = v;
    widget.onChanged?.call(v);
  }

  void _down(int direction) {
    setState(() => _pressed = direction);
    _stepBy(direction);
    _repeat?.cancel();
    _repeat = Timer(StepperMetrics.repeatDelay, () {
      _repeat = Timer.periodic(
        StepperMetrics.repeatInterval,
        (_) => _stepBy(direction),
      );
    });
  }

  void _up() {
    _repeat?.cancel();
    _repeat = null;
    if (mounted) setState(() => _pressed = 0);
  }

  String _semantic(double v) =>
      widget.semanticValue?.call(v) ??
      (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final size = StepperMetrics.size;
    Widget half(int direction) => Expanded(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _enabled ? (_) => _down(direction) : null,
        onPointerUp: _enabled ? (_) => _up() : null,
        onPointerCancel: _enabled ? (_) => _up() : null,
        child: CustomPaint(
          key: ValueKey(direction > 0 ? 'stepperUp' : 'stepperDown'),
          painter: _ArrowPainter(
            up: direction > 0,
            color: widget.enabled ? colors.glyph : colors.placeholder,
            pressed: _pressed == direction ? colors.bezelPressed : null,
          ),
        ),
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      value: _semantic(widget.value),
      increasedValue: _semantic(_next(1)),
      decreasedValue: _semantic(_next(-1)),
      enabled: _enabled,
      onIncrease: _enabled ? () => _stepBy(1) : null,
      onDecrease: _enabled ? () => _stepBy(-1) : null,
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: _enabled,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (!_enabled) return KeyEventResult.ignored;
          final next = keyboardValue(event, value: 0, min: -1, max: 1, step: 1);
          if (next == null || next == 0) return KeyEventResult.ignored;
          _stepBy(next > 0 ? 1 : -1);
          return KeyEventResult.handled;
        },
        child: FocusRing(
          visible: _focused,
          radius: StepperMetrics.radius,
          width: InputMetrics.controlRing,
          inset: InputMetrics.controlRingInset,
          color: colors.focusRingControl,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: colors.bezel,
              borderRadius: BorderRadius.circular(StepperMetrics.radius),
              border: Border.all(color: colors.bezelBorder, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(StepperMetrics.radius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [half(1), half(-1)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.up, required this.color, this.pressed});

  final bool up;
  final Color color;
  final Color? pressed;

  @override
  void paint(Canvas canvas, Size size) {
    if (pressed case final p?) {
      canvas.drawRect(Offset.zero & size, Paint()..color = p);
    }
    final cx = size.width / 2;
    final cy = size.height / 2 + (up ? 1 : -1);
    const w = 3.0, h = 2.0;
    final path = Path()
      ..moveTo(cx - w, up ? cy + h / 2 : cy - h / 2)
      ..lineTo(cx, up ? cy - h / 2 : cy + h / 2)
      ..lineTo(cx + w, up ? cy + h / 2 : cy - h / 2);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.up != up || old.color != color || old.pressed != pressed;
}
