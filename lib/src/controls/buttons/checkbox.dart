// Checkboxes (off, on, mixed) and radio buttons, alone or in a group, with their label.
//
// Measured (docs/spec/toggles.md, INV-B gallery): checkboxes are 16 / 14 / 12 pt rounded squares
// (radius ~4 at 16), radios 16 pt circles; off filled `#e6e6e6` / `#3c3c3d` without a border, on
// the accent fill with a white check, dash (mixed) or dot; pressed = one fill step; in an inactive
// window the accent fill turns gray (CT-CB-01/02, CT-RB-01). The focus ring surrounds only the
// box. Provisional: the label gap and the radio dot size.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'control_style.dart';

/// The gap between the box and its label (provisional).
const double toggleLabelGap = 6;

/// The fill and mark of a checkbox or radio button in a state: `(fill, border, mark)`.
(Color, Color?, Color) _boxColors(
  BuildContext context,
  ControlState state, {
  required bool on,
}) {
  final colors = ControlColors.of(context);
  if (!on) {
    return (
      state.pressed ? colors.boxPressed : colors.box,
      null,
      colors.accentText,
    );
  }
  final accent = state.active
      ? ControlAccent.fillOf(context)
      : colors.inactiveAccent;
  return (
    state.pressed ? controlPressedFill(accent, dark: colors.dark) : accent,
    null,
    colors.accentText,
  );
}

Widget _withLabel(
  BuildContext context,
  ControlState state,
  ControlSize size,
  Widget box,
  String? label, {
  required double? ringRadius,
}) {
  final withRing = FocusRing(
    visible: state.focused,
    kind: FocusRingKind.control,
    radius: ringRadius,
    child: box,
  );
  if (label == null) return withRing;
  final colors = ControlColors.of(context);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      withRing,
      const SizedBox(width: toggleLabelGap),
      Flexible(
        child: ExcludeSemantics(
          child: Text(
            label,
            style: controlTextStyle(
              size,
              state.enabled ? colors.label : colors.labelDisabled,
            ),
          ),
        ),
      ),
    ],
  );
}

/// A checkbox. `value` null is the mixed state; a click on a mixed box turns it on. A click on
/// the label toggles it too; Space toggles it with the keyboard focus.
class SilicaCheckbox extends StatelessWidget {
  const SilicaCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = ControlSize.regular,
    this.focusNode,
    this.autofocus = false,
  });

  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final ControlSize size;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      checked: value ?? false,
      mixed: value == null,
      enabled: onChanged != null,
      label: label,
      child: ControlInteraction(
        enabled: onChanged != null,
        onActivate: onChanged == null ? null : () => onChanged(value != true),
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, state) {
          final side = toggleSide(size);
          final (fill, border, mark) = _boxColors(
            context,
            state,
            on: value != false,
          );
          final box = Opacity(
            opacity: state.enabled ? 1 : 0.5,
            child: CustomPaint(
              key: const ValueKey('checkbox'),
              size: Size.square(side),
              painter: _CheckboxPainter(
                value: value,
                fill: fill,
                border: border,
                mark: mark,
              ),
            ),
          );
          return _withLabel(
            context,
            state,
            size,
            box,
            label,
            ringRadius: side * 0.28,
          );
        },
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  const _CheckboxPainter({
    required this.value,
    required this.fill,
    required this.border,
    required this.mark,
  });

  final bool? value;
  final Color fill;
  final Color? border;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Radius ~4 at 16 (CT-CB-01).
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.25),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    final border = this.border;
    if (border != null) {
      canvas.drawRRect(
        rrect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = border,
      );
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s / 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = mark;
    switch (value) {
      case true:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.26, s * 0.52)
            ..lineTo(s * 0.43, s * 0.70)
            ..lineTo(s * 0.74, s * 0.31),
          stroke,
        );
      case null:
        canvas.drawLine(
          Offset(s * 0.28, s / 2),
          Offset(s * 0.72, s / 2),
          stroke,
        );
      case false:
        break;
    }
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      old.value != value ||
      old.fill != fill ||
      old.border != border ||
      old.mark != mark;
}

/// A radio button: `selected` shows the dot. A click (or Space) chooses it; it does not
/// deselect.
class SilicaRadio extends StatelessWidget {
  const SilicaRadio({
    super.key,
    required this.selected,
    required this.onSelected,
    this.label,
    this.size = ControlSize.regular,
    this.focusNode,
    this.onKey,
  });

  final bool selected;
  final VoidCallback? onSelected;
  final String? label;
  final ControlSize size;
  final FocusNode? focusNode;

  /// Other keys (the group uses the arrows).
  final KeyEventResult Function(KeyEvent event)? onKey;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    enabled: onSelected != null,
    label: label,
    child: ControlInteraction(
      enabled: onSelected != null,
      onActivate: onSelected,
      focusNode: focusNode,
      onKey: onKey,
      builder: (context, state) {
        final side = toggleSide(size);
        final (fill, border, mark) = _boxColors(context, state, on: selected);
        final box = Opacity(
          opacity: state.enabled ? 1 : 0.5,
          child: CustomPaint(
            key: const ValueKey('radio'),
            size: Size.square(side),
            painter: _RadioPainter(
              selected: selected,
              fill: fill,
              border: border,
              mark: mark,
            ),
          ),
        );
        return _withLabel(context, state, size, box, label, ringRadius: null);
      },
    ),
  );
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter({
    required this.selected,
    required this.fill,
    required this.border,
    required this.mark,
  });

  final bool selected;
  final Color fill;
  final Color? border;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = fill);
    final border = this.border;
    if (border != null) {
      canvas.drawCircle(
        c,
        r - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = border,
      );
    }
    // The dot: ~7 at 16 (provisional: not measured).
    if (selected)
      canvas.drawCircle(c, size.width * 0.215, Paint()..color = mark);
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.selected != selected ||
      old.fill != fill ||
      old.border != border ||
      old.mark != mark;
}

/// One choice of a [SilicaRadioGroup].
@immutable
class RadioOption<T> {
  const RadioOption(this.value, this.label, {this.enabled = true});
  final T value;
  final String label;
  final bool enabled;
}

/// Radio buttons for one value: a click chooses; with the keyboard focus the arrows move the
/// choice (and the focus) to the previous or next enabled option.
class SilicaRadioGroup<T> extends StatefulWidget {
  const SilicaRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.direction = Axis.vertical,
    this.spacing = 6,
    this.size = ControlSize.regular,
  });

  final List<RadioOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final Axis direction;
  final double spacing;
  final ControlSize size;

  @override
  State<SilicaRadioGroup<T>> createState() => _SilicaRadioGroupState<T>();
}

class _SilicaRadioGroupState<T> extends State<SilicaRadioGroup<T>> {
  final List<FocusNode> _nodes = [];

  void _syncNodes() {
    while (_nodes.length < widget.options.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.options.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!isKeyPress(event)) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final step =
        key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowLeft
        ? -1
        : 0;
    if (step == 0) return KeyEventResult.ignored;
    final options = widget.options;
    for (var k = 1; k < options.length; k++) {
      final i = (index + step * k) % options.length;
      if (options[i].enabled) {
        widget.onChanged?.call(options[i].value);
        _nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final onChanged = widget.onChanged;
    final children = <Widget>[
      for (var i = 0; i < widget.options.length; i++) ...[
        if (i > 0)
          SizedBox(
            width: widget.direction == Axis.horizontal ? widget.spacing : 0,
            height: widget.direction == Axis.vertical ? widget.spacing : 0,
          ),
        SilicaRadio(
          selected: widget.options[i].value == widget.value,
          onSelected: onChanged == null || !widget.options[i].enabled
              ? null
              : () => onChanged(widget.options[i].value),
          label: widget.options[i].label,
          size: widget.size,
          focusNode: _nodes[i],
          onKey: (event) => _key(i, event),
        ),
      ],
    ];
    return Semantics(
      container: true,
      child: Flex(
        direction: widget.direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
