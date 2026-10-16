// The Amalfi radio button (kit `Toggles/Radio/*`): off and on, Small / Regular / Large, alone
// or with its label, and the radio group (`Toggles/Radio Group`).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../tokens.g.dart';
import '../../foundation/foundation.dart';
import 'toggle_box.dart';
import 'toggle_group.dart';

/// The look of a radio button in a given state, without any interaction: the box of [size],
/// with the dot when [selected], in [state].
///
/// [AmalfiRadio] draws this; use it directly only to show a state statically.
class AmalfiRadioFace extends StatelessWidget {
  const AmalfiRadioFace({
    super.key,
    required this.selected,
    this.size = AmalfiControlSize.regular,
    this.state = const AmalfiInteractionState(),
  });

  /// Whether the dot shows.
  final bool selected;

  /// Small, Regular or Large (Mini draws as Small).
  final AmalfiControlSize size;

  final AmalfiInteractionState state;

  @override
  Widget build(BuildContext context) {
    final metrics = AmalfiToggleBoxMetrics.radio(size);
    return AmalfiToggleBox(
      metrics: metrics,
      on: selected,
      state: state,
      mark: (color) => DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: color,
          shape: AmalfiSmoothBorder(radius: metrics.markSize / 2),
        ),
      ),
    );
  }
}

/// A radio button: one choice of several, [selected] when it is the chosen one.
///
/// A click or Space calls [onSelected] (an already selected button stays selected); with
/// [onSelected] null it is disabled. With a [label] the label follows the button
/// (`Toggles/Radio/With Label`). Several buttons for one value: [AmalfiRadioGroup].
class AmalfiRadio extends StatelessWidget {
  const AmalfiRadio({
    super.key,
    required this.selected,
    required this.onSelected,
    this.label,
    this.size = AmalfiControlSize.regular,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.onKey,
  });

  final bool selected;

  /// Called when the button is chosen; null: disabled.
  final VoidCallback? onSelected;

  /// The text after the button; null: the button alone.
  final String? label;

  /// Small, Regular or Large (Mini draws as Small).
  final AmalfiControlSize size;

  /// The name for screen readers when there is no [label].
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  /// Other keys with the keyboard focus (the group moves the choice with the arrows).
  final KeyEventResult Function(KeyEvent event)? onKey;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onSelected != null,
      label: label ?? semanticLabel,
      onTap: onSelected,
      child: ExcludeSemantics(
        child: AmalfiInteraction(
          onActivate: onSelected,
          onKey: onKey,
          focusNode: focusNode,
          autofocus: autofocus,
          builder: (context, state) {
            final box = AmalfiRadioFace(
              selected: selected,
              size: size,
              state: state,
            );
            return label == null
                ? box
                : AmalfiToggleRow(
                    box: box,
                    label: label,
                    enabled: state.enabled,
                  );
          },
        ),
      ),
    );
  }
}

/// One choice of an [AmalfiRadioGroup].
@immutable
class AmalfiRadioOption<T> {
  const AmalfiRadioOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

/// Labelled radio buttons for one [value], under an optional [heading]
/// (`Toggles/Radio Group/List`).
///
/// A click chooses an option; with the keyboard focus on one, the arrow keys move the choice
/// (and the focus) to the previous or next enabled option. With [onChanged] null every
/// option is disabled.
class AmalfiRadioGroup<T> extends StatefulWidget {
  const AmalfiRadioGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.heading,
  });

  /// The chosen value; null or a value of no option: none is chosen.
  final T? value;

  final List<AmalfiRadioOption<T>> options;

  final ValueChanged<T>? onChanged;

  /// The heading above the options; null: none.
  final String? heading;

  @override
  State<AmalfiRadioGroup<T>> createState() => _AmalfiRadioGroupState<T>();
}

class _AmalfiRadioGroupState<T> extends State<AmalfiRadioGroup<T>> {
  final List<FocusNode> _nodes = [];

  void _syncNodes() {
    while (_nodes.length < widget.options.length) {
      _nodes.add(FocusNode(debugLabel: 'AmalfiRadioGroup option'));
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
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
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
    final onChanged = widget.onChanged;
    if (onChanged == null) return KeyEventResult.ignored;
    for (var k = 1; k < options.length; k++) {
      final i = (index + step * k) % options.length;
      if (options[i].enabled) {
        onChanged(options[i].value);
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
    return AmalfiToggleGroup(
      heading: widget.heading,
      children: [
        for (final (i, option) in widget.options.indexed)
          AmalfiRadio(
            selected: option.value == widget.value,
            label: option.label,
            onSelected: onChanged == null || !option.enabled
                ? null
                : () => onChanged(option.value),
            focusNode: _nodes[i],
            onKey: (event) => _key(i, event),
          ),
      ],
    );
  }
}
