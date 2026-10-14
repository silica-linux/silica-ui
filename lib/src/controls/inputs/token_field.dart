// Token field (tags): capsule tokens before the text, inline completion, ⌫ selects then
// removes the last token.
//
// Measured: the field 27 tall (dialogs.md › Save, "Tag" 232 × 27); the token a capsule 14 pt
// tall colored with the tag color; typing completes inline with the remainder selected, and
// Return turns the text into a token (mustache.md › MU-62). Provisional: the token text size
// (11), the selected-token look (accent fill, white text), the wrap to more lines.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'editable.dart';
import 'input_style.dart';
import 'text_field.dart' show FieldBox;

/// A token of a [SilicaTokenField].
@immutable
class FieldToken {
  const FieldToken(this.label, {this.color});

  final String label;

  /// The capsule color (a tag color); the neutral token color when null.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is FieldToken && other.label == label && other.color == color;

  @override
  int get hashCode => Object.hash(label, color);
}

/// A field of tokens.
class SilicaTokenField extends StatefulWidget {
  const SilicaTokenField({
    super.key,
    required this.tokens,
    required this.onChanged,
    this.tokenize,
    this.complete,
    this.placeholder,
    this.semanticLabel,
    this.width,
    this.enabled = true,
    this.focusNode,
  });

  final List<FieldToken> tokens;
  final ValueChanged<List<FieldToken>> onChanged;

  /// Turns the typed text into a token on Return (null: no token). By default a neutral
  /// token with the text.
  final FieldToken? Function(String text)? tokenize;

  /// Inline completion: the full text for the typed prefix, or null.
  final String? Function(String prefix)? complete;
  final String? placeholder;
  final String? semanticLabel;
  final double? width;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<SilicaTokenField> createState() => _SilicaTokenFieldState();
}

class _SilicaTokenFieldState extends State<SilicaTokenField> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownFocus;
  int? _selected;
  String _typed = '';

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _controller.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {
    if (!_focus.hasFocus) _selected = null;
  });

  void _textChanged(String text) {
    final grew = text.length > _typed.length && text.startsWith(_typed);
    _typed = text;
    setState(() => _selected = null);
    final complete = widget.complete;
    if (!grew || complete == null || text.isEmpty) return;
    final full = complete(text);
    if (full == null ||
        full.length <= text.length ||
        !full.toLowerCase().startsWith(text.toLowerCase())) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text + full.substring(text.length),
      selection: TextSelection(
        baseOffset: text.length,
        extentOffset: full.length,
      ),
    );
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final token = (widget.tokenize ?? (t) => FieldToken(t))(trimmed);
    if (token == null) return;
    widget.onChanged([...widget.tokens, token]);
    _controller.clear();
    _typed = '';
    _focus.requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final selected = _selected;
    if (selected != null &&
        (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete)) {
      final next = [...widget.tokens]..removeAt(selected);
      setState(() => _selected = null);
      widget.onChanged(next);
      return KeyEventResult.handled;
    }
    final sel = _controller.selection;
    final atStart = sel.isCollapsed && sel.baseOffset <= 0;
    if (atStart && widget.tokens.isNotEmpty) {
      if (key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.arrowLeft && selected == null) {
        setState(() => _selected = widget.tokens.length - 1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft && selected != null) {
        if (selected > 0) setState(() => _selected = selected - 1);
        return KeyEventResult.handled;
      }
    }
    if (selected != null && key == LogicalKeyboardKey.arrowRight) {
      setState(
        () => _selected = selected + 1 < widget.tokens.length
            ? selected + 1
            : null,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // The text grows with what is typed (the placeholder when there are no tokens).
  double _editorWidth(bool withPlaceholder) {
    final text = _controller.text.isNotEmpty
        ? _controller.text
        : withPlaceholder
        ? widget.placeholder ?? ''
        : '';
    final painter = TextPainter(
      text: TextSpan(text: text, style: inputText(const Color(0xFF000000))),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width + 8;
    painter.dispose();
    return width < 40 ? 40 : width;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    return Semantics(
      label: widget.semanticLabel,
      value: tokens.map((t) => t.label).join(', '),
      textField: true,
      enabled: widget.enabled,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: SizedBox(
          width: widget.width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: InputMetrics.tokenFieldHeight,
            ),
            child: FieldBox(
              focused: _focus.hasFocus,
              enabled: widget.enabled,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < tokens.length; i++)
                    GestureDetector(
                      onTap: widget.enabled
                          ? () {
                              _focus.requestFocus();
                              setState(() => _selected = i);
                            }
                          : null,
                      child: TokenCapsule(
                        token: tokens[i],
                        selected: _selected == i,
                      ),
                    ),
                  SizedBox(
                    width: _editorWidth(tokens.isEmpty),
                    height: 18,
                    child: Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: _key,
                      child: InputEditable(
                        controller: _controller,
                        focusNode: _focus,
                        placeholder: tokens.isEmpty ? widget.placeholder : null,
                        enabled: widget.enabled,
                        onChanged: _textChanged,
                        onSubmitted: _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A token capsule, 14 pt tall, in its color; selected in the accent color.
class TokenCapsule extends StatelessWidget {
  const TokenCapsule({super.key, required this.token, this.selected = false});

  final FieldToken token;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final active = WindowActiveScope.of(context);
    final fill = selected
        ? colors.accentFor(active: active)
        : token.color ?? colors.tokenValue;
    final text = selected ? const Color(0xFFFFFFFF) : colors.tokenText;
    return Semantics(
      label: token.label,
      selected: selected,
      child: Container(
        height: InputMetrics.tagTokenHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(InputMetrics.tagTokenHeight / 2),
        ),
        child: Text(
          token.label,
          maxLines: 1,
          style: inputText(text, size: 11).copyWith(height: 1),
        ),
      ),
    );
  }
}
