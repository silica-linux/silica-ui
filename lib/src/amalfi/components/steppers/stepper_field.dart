// A value field with its stepper (kit `Steppers/With Field/Regular/*`): the 56 pt field,
// 8, then the regular stepper.

import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import 'stepper.dart';
import 'value_field.dart';

/// A number the user types in a field or steps with the stepper after it.
///
/// Typed text is applied on Return or when the field loses the focus: a number is clamped to
/// [min]–[max] (and rounded to [decimals]), anything else restores the value. In the field,
/// the up and down arrows step. [onChanged] null disables both.
class AmalfiStepperField extends StatefulWidget {
  const AmalfiStepperField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.decimals = 0,
    this.wraps = false,
    this.fieldWidth = AmalfiValueFieldMetrics.width,
    this.focusNode,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final double step;

  /// The digits after the decimal point shown and kept.
  final int decimals;

  /// Whether the stepper goes around from [max] to [min].
  final bool wraps;

  /// The width of the field.
  final double fieldWidth;

  /// The focus node of the field.
  final FocusNode? focusNode;

  /// What the value is, for screen readers.
  final String? semanticLabel;

  /// Between the field and the stepper.
  static const double gap = 8;

  @override
  State<AmalfiStepperField> createState() => _AmalfiStepperFieldState();
}

class _AmalfiStepperFieldState extends State<AmalfiStepperField> {
  late final TextEditingController _text = TextEditingController(
    text: _format(widget.value),
  );
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(AmalfiStepperField old) {
    super.didUpdateWidget(old);
    _sent = null;
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
    if (old.value != widget.value || old.decimals != widget.decimals) {
      _text.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (!v.isFinite) return '';
    final d = widget.decimals.clamp(0, 20);
    return v.toStringAsFixed(d);
  }

  void _focusChanged() {
    if (!_focus.hasFocus) _commit(_text.text);
  }

  void _commit(String text) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    final onChanged = widget.onChanged;
    if (parsed == null || !parsed.isFinite || onChanged == null) {
      _text.text = _format(widget.value);
      return;
    }
    final v =
        double.tryParse(
          _format(parsed.clamp(widget.min, widget.max).toDouble()),
        ) ??
        widget.value;
    _text.text = _format(v);
    if (v != (_sent ?? widget.value)) {
      _sent = v;
      onChanged(v);
    }
  }

  /// The last value sent, until the widget brings it (keys can repeat between frames).
  double? _sent;

  void _step(int direction) {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final now = _sent ?? widget.value;
    var v = now + direction * widget.step;
    if (widget.wraps) {
      if (v > widget.max) v = widget.min;
      if (v < widget.min) v = widget.max;
    }
    final next = double.tryParse(
      _format(v.clamp(widget.min, widget.max).toDouble()),
    );
    if (next == null || next == now) return;
    _sent = next;
    onChanged(next);
  }

  void _set(double v) {
    final rounded = double.tryParse(_format(v));
    if (rounded != null && rounded != widget.value) {
      widget.onChanged?.call(rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmalfiValueField(
          controller: _text,
          focusNode: _focus,
          enabled: enabled,
          width: widget.fieldWidth,
          onSubmitted: _commit,
          onStep: _step,
          semanticLabel: widget.semanticLabel,
        ),
        const SizedBox(width: AmalfiStepperField.gap),
        AmalfiStepper(
          value: widget.value,
          onChanged: enabled ? _set : null,
          min: widget.min,
          max: widget.max,
          step: widget.step,
          wraps: widget.wraps,
          size: AmalfiControlSize.regular,
          semanticLabel: widget.semanticLabel,
        ),
      ],
    );
  }
}
