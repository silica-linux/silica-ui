// Text fields: rounded or square bezel, secure with the caps lock indicator, multi-line.
//
// Measured: 26 pt height (dialogs.md › Save, the name field 232 × 26; clock.md › Alarms,
// the label field 224 × 26); 13 pt text 4 pt from the edge, 3 pt focus ring and 1 pt inner border
// (mustache.md › MU-32). Provisional: the bezel radius (6), the disabled look (text in the
// placeholder color), the caps lock glyph (not captured).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'editable.dart';
import 'input_style.dart';

/// The shape of a text field.
enum FieldBezel {
  /// Rounded corners (the default in windows and sheets).
  rounded,

  /// Square corners (inspectors, tables).
  square,
}

/// The box of a field: background, 1 pt border (accent-tinted when focused) and the focus
/// ring outside it. Shared by the text, search, token and date fields.
class FieldBox extends StatelessWidget {
  const FieldBox({
    super.key,
    required this.focused,
    required this.child,
    this.radius = InputMetrics.fieldRadius,
    this.background,
    this.border = true,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: InputMetrics.fieldPadding,
    ),
  });

  final bool focused;
  final double radius;
  final Color? background;
  final bool border;
  final bool enabled;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final active = WindowActiveScope.of(context);
    final ringOn = focused && enabled;
    return FocusRing(
      visible: ringOn,
      radius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? colors.fieldBackground,
          borderRadius: BorderRadius.circular(radius),
          border: border
              ? Border.all(
                  color: ringOn && active
                      ? colors.fieldBorderFocused
                      : colors.fieldBorder,
                )
              : null,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A text field.
class SilicaTextField extends StatefulWidget {
  const SilicaTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.semanticLabel,
    this.enabled = true,
    this.secure = false,
    this.capsLockLabel,
    this.autofocus = false,
    this.bezel = FieldBezel.rounded,
    this.width,
    this.maxLines = 1,
    this.minLines,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;

  /// The accessibility label (the field's caption, when it is outside the field).
  final String? semanticLabel;
  final bool enabled;

  /// A password field: bullets, no suggestions, and the caps lock indicator.
  final bool secure;

  /// The accessibility label of the caps lock indicator ("Caps Lock is on").
  final String? capsLockLabel;
  final bool autofocus;
  final FieldBezel bezel;
  final double? width;

  /// More than one line: a text area that grows from `minLines` to `maxLines` (null: no limit).
  final int? maxLines;
  final int? minLines;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SilicaTextField> createState() => _SilicaTextFieldState();
}

class _SilicaTextFieldState extends State<SilicaTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _capsLock = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    HardwareKeyboard.instance.addHandler(_keyboard);
    _capsLock = capsLockOn;
  }

  @override
  void didUpdateWidget(SilicaTextField old) {
    super.didUpdateWidget(old);
    final oldFocus = old.focusNode ?? _ownFocus;
    if (oldFocus != _focus) {
      oldFocus?.removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboard);
    _focus.removeListener(_focusChanged);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {});

  bool _keyboard(KeyEvent event) {
    final on = capsLockOn;
    if (on != _capsLock && mounted) setState(() => _capsLock = on);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final multiline = widget.maxLines != 1;
    final showCaps = widget.secure && _capsLock && _focus.hasFocus;
    final field = FieldBox(
      focused: _focus.hasFocus,
      enabled: widget.enabled,
      radius: widget.bezel == FieldBezel.rounded ? InputMetrics.fieldRadius : 0,
      padding: EdgeInsets.symmetric(
        horizontal: InputMetrics.fieldPadding,
        vertical: multiline ? InputMetrics.fieldPadding : 0,
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InputEditable(
              controller: _controller,
              focusNode: _focus,
              placeholder: widget.placeholder,
              enabled: widget.enabled,
              obscure: widget.secure,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              textAlign: widget.textAlign,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              inputFormatters: widget.inputFormatters,
            ),
          ),
          if (showCaps)
            Semantics(
              label: widget.capsLockLabel,
              child: CustomPaint(
                key: const ValueKey('capsLock'),
                size: const Size(14, 14),
                painter: CapsLockGlyph(colors.glyph),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      obscured: widget.secure,
      enabled: widget.enabled,
      multiline: multiline,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: SizedBox(
          width: widget.width,
          height: multiline ? null : InputMetrics.fieldHeight,
          child: field,
        ),
      ),
    );
  }
}

/// The caps lock glyph: an up arrow over a bar (provisional, not captured).
class CapsLockGlyph extends CustomPainter {
  CapsLockGlyph(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    final arrow = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.9, h * 0.5)
      ..lineTo(w * 0.68, h * 0.5)
      ..lineTo(w * 0.68, h * 0.7)
      ..lineTo(w * 0.32, h * 0.7)
      ..lineTo(w * 0.32, h * 0.5)
      ..lineTo(w * 0.1, h * 0.5)
      ..close();
    canvas.drawPath(arrow, stroke);
    canvas.drawRect(
      Rect.fromLTRB(w * 0.32, h * 0.8, w * 0.68, h * 0.92),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(CapsLockGlyph old) => old.color != color;
}
