// The editing core shared by the text, search, token and date fields: Flutter's
// EditableText (text input reaches it through the embedder) with mouse selection gestures,
// the caret hidden and the selection gray in an inactive window.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'input_style.dart';

/// One line (or a few) of editable text in the input style, with a placeholder.
class InputEditable extends StatefulWidget {
  const InputEditable({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder,
    this.enabled = true,
    this.obscure = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.size = InputMetrics.fontSize,
    this.textAlign = TextAlign.start,
    this.color,
    this.selectionColor,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? placeholder;
  final bool enabled;
  final bool obscure;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final double size;
  final TextAlign textAlign;

  /// The text color; the input text color when null.
  final Color? color;

  /// The selection color; the measured one (gray in an inactive window) when null.
  final Color? selectionColor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<InputEditable> createState() => _InputEditableState();
}

class _InputEditableState extends State<InputEditable>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey();

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(InputEditable old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  // The placeholder follows the text.
  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final active = WindowActiveScope.of(context);
    final textColor = widget.enabled
        ? widget.color ?? colors.text
        : colors.placeholder;
    final style = inputText(textColor, size: widget.size);
    final editable = EditableText(
      key: editableTextKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: !widget.enabled,
      obscureText: widget.obscure,
      obscuringCharacter: '•',
      autocorrect: false,
      enableSuggestions: !widget.obscure,
      autofocus: widget.autofocus,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      minLines: widget.minLines,
      textAlign: widget.textAlign,
      style: style,
      // The caret: 1 pt in the text color at the field size (the system search panel one is 2 pt at
      // 26 pt type, spotlight.md); hidden in an inactive window.
      cursorColor: colors.text,
      cursorWidth: 1,
      showCursor: active && widget.enabled,
      backgroundCursorColor: colors.placeholder,
      selectionColor:
          widget.selectionColor ??
          (active ? colors.selection : colors.selectionInactive),
      rendererIgnoresPointer: true,
      enableInteractiveSelection: widget.enabled,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.maxLines == 1
          ? TextInputType.text
          : TextInputType.multiline,
      textInputAction: widget.maxLines == 1 ? TextInputAction.done : null,
    );
    final placeholder = widget.placeholder;
    return _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          if (placeholder != null && widget.controller.text.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: widget.maxLines == 1
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.topStart,
                  child: Text(
                    placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: widget.textAlign,
                    style: inputText(colors.placeholder, size: widget.size),
                  ),
                ),
              ),
            ),
          editable,
        ],
      ),
    );
  }
}
