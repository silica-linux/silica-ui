// The Amalfi checkbox (kit `Toggles/Checkbox/*`): off, on and mixed, Small / Regular / Large,
// alone or with its label.

import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import '../../foundation/foundation.dart';
import 'toggle_box.dart';

/// The look of a checkbox in a given state, without any interaction: the box of [size] for
/// [value] (`true` on, `false` off, null mixed) in [state].
///
/// [AmalfiCheckbox] draws this; use it directly only to show a state statically (a gallery,
/// a picture of a setting).
class AmalfiCheckboxFace extends StatelessWidget {
  const AmalfiCheckboxFace({
    super.key,
    required this.value,
    this.size = AmalfiControlSize.regular,
    this.state = const AmalfiInteractionState(),
  });

  /// `true` on, `false` off, null mixed.
  final bool? value;

  /// Small, Regular or Large (Mini draws as Small).
  final AmalfiControlSize size;

  final AmalfiInteractionState state;

  @override
  Widget build(BuildContext context) {
    final metrics = AmalfiToggleBoxMetrics.checkbox(size);
    return AmalfiToggleBox(
      metrics: metrics,
      on: value != false,
      state: state,
      mark: (color) => AmalfiGlyph(
        value == null ? AmalfiGlyphs.minus : AmalfiGlyphs.checkmark,
        size: metrics.markSize,
        color: color,
      ),
    );
  }
}

/// A checkbox: [value] `true` on, `false` off, null mixed.
///
/// A click (a release over it) or Space with the keyboard focus calls [onChanged] with the
/// new value: off → on, on → off, mixed → on. With [onChanged] null it is disabled. With a
/// [label] the label follows the box (`Toggles/Checkbox/With Label`) and a click on it
/// toggles the box too; hover and press show on the box.
class AmalfiCheckbox extends StatelessWidget {
  const AmalfiCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = AmalfiControlSize.regular,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// `true` on, `false` off, null mixed.
  final bool? value;

  /// Called with the new value; null: disabled.
  final ValueChanged<bool>? onChanged;

  /// The text after the box; null: the box alone.
  final String? label;

  /// Small, Regular or Large (Mini draws as Small). A labelled checkbox is Regular in the kit.
  final AmalfiControlSize size;

  /// The name for screen readers when there is no [label].
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final label = this.label;
    final activate = onChanged == null ? null : () => onChanged(value != true);
    return Semantics(
      checked: value ?? false,
      mixed: value == null,
      enabled: onChanged != null,
      label: label ?? semanticLabel,
      onTap: activate,
      child: ExcludeSemantics(
        child: AmalfiInteraction(
          onActivate: activate,
          focusNode: focusNode,
          autofocus: autofocus,
          builder: (context, state) {
            final box = AmalfiCheckboxFace(
              value: value,
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
