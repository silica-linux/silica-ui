// The Amalfi text area (kit `Fields/Text Area/Regular/*`): several lines of Body text in a
// 240 × 88 field with the text field's faces; the text scrolls when it outgrows the area.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'editable.dart';
import 'field_state.dart';
import 'metrics.dart';
import 'text_field.dart';

/// A multi-line text field, [size] large (240 × 88 by default).
///
/// The text wraps; Enter inserts a line break. When the text has more lines than fit, it
/// scrolls inside the area. A tap anywhere on the area puts the caret in it.
class AmalfiTextArea extends StatefulWidget implements AmalfiFieldWidget {
  const AmalfiTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = AmalfiTextAreaMetrics.size,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
    this.inputFormatters,
    this.onChanged,
    this.semanticLabel,
    this.statesController,
  });

  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;
  final String? placeholder;
  final Size size;
  @override
  final bool enabled;

  /// When set, the area shows the error look; screen readers read it as the hint.
  final String? errorText;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;
  @override
  final WidgetStatesController? statesController;

  @override
  State<AmalfiTextArea> createState() => _AmalfiTextAreaState();
}

class _AmalfiTextAreaState extends State<AmalfiTextArea>
    with AmalfiFieldStateMixin {
  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = widget.enabled;
    const token = AmalfiType.bodyToken;
    const padding = AmalfiTextAreaMetrics.padding;
    final lines =
        ((widget.size.height - padding.vertical) /
                (token.lineHeight ?? token.size))
            .floor()
            .clamp(1, 1 << 20);
    return Semantics(
      label: widget.semanticLabel ?? widget.placeholder,
      hint: widget.errorText,
      enabled: enabled,
      child: ExcludeFocus(
        excluding: !enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusFromTap,
          child: SizedBox.fromSize(
            size: widget.size,
            child: amalfiFieldFace(
              colors: colors,
              radius: AmalfiRadii.field,
              enabled: enabled,
              focused: focused && enabled,
              error: widget.errorText != null,
              child: Padding(
                padding: padding,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: AmalfiEditable(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    autofocus: widget.autofocus,
                    minLines: 1,
                    maxLines: lines,
                    placeholder: widget.placeholder,
                    style: token.style(color: colors.textPrimary),
                    placeholderStyle: token.style(color: colors.textTertiary),
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
