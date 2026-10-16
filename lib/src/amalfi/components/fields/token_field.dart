// The Amalfi token field (kit `Fields/Token Field/Regular/*`): tokens, then the text, in a
// 260 × 28 field with the text field's faces.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import 'editable.dart';
import 'field_state.dart';
import 'metrics.dart';
import 'text_field.dart';
import 'token_editing.dart';

/// A field of tokens ("tags"): typing text and pressing Enter, or typing a comma or a semicolon,
/// turns it into a token; Backspace at the start selects the last token, a second Backspace
/// removes it; a token's cross removes it.
///
/// [tokens] is the list shown and [onTokensChanged] receives every change. When the tokens
/// do not fit, they scroll so that the last one stays next to the text.
class AmalfiTokenField extends StatefulWidget implements AmalfiFieldWidget {
  const AmalfiTokenField({
    super.key,
    required this.tokens,
    required this.onTokensChanged,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.width = AmalfiTokenMetrics.fieldWidth,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    this.statesController,
  });

  final List<String> tokens;
  final ValueChanged<List<String>>? onTokensChanged;
  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;

  /// Shown while the text is empty ("Add tag").
  final String? placeholder;
  final double width;
  @override
  final bool enabled;
  final bool autofocus;
  final String? semanticLabel;
  @override
  final WidgetStatesController? statesController;

  @override
  State<AmalfiTokenField> createState() => _AmalfiTokenFieldState();
}

class _AmalfiTokenFieldState extends State<AmalfiTokenField>
    with AmalfiFieldStateMixin, AmalfiTokenEditingMixin {
  final ScrollController _scroll = ScrollController();

  @override
  List<String> get tokens => widget.tokens;

  @override
  ValueChanged<List<String>>? get onTokensChanged => widget.onTokensChanged;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmalfiTokenField old) {
    super.didUpdateWidget(old);
    if (old.tokens.length < widget.tokens.length) {
      // Keep the newest token in view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  /// Turns the text into a token.
  void _commit() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    widget.onTokensChanged?.call([...widget.tokens, text]);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) =>
      handleTokenKey(node, event);

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    const size = AmalfiFieldSize.regular;
    final enabled = widget.enabled;
    final tokenWidgets = buildTokens(enabled: enabled);
    return Semantics(
      label: widget.semanticLabel ?? widget.placeholder,
      enabled: enabled,
      child: ExcludeFocus(
        excluding: !enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusFromTap,
          child: SizedBox(
            width: widget.width,
            height: size.height,
            child: amalfiFieldFace(
              colors: colors,
              radius: size.radius,
              enabled: enabled,
              focused: focused && enabled,
              child: Padding(
                padding: AmalfiTokenMetrics.fieldPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final room =
                        constraints.maxWidth - AmalfiTokenMetrics.minTextWidth;
                    return Row(
                      children: [
                        if (tokenWidgets.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: room < 0 ? 0 : room,
                            ),
                            child: SingleChildScrollView(
                              controller: _scroll,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final token in tokenWidgets) ...[
                                    token,
                                    const SizedBox(
                                      width: AmalfiFieldMetrics.gap,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: _key,
                            child: AmalfiEditable(
                              controller: controller,
                              focusNode: focusNode,
                              enabled: enabled,
                              autofocus: widget.autofocus,
                              placeholder: widget.placeholder,
                              style: size.textStyle(colors.textPrimary),
                              placeholderStyle: size.textStyle(
                                colors.textTertiary,
                              ),
                              textInputAction: TextInputAction.done,
                              inputFormatters: [_TokenSeparators(_commit)],
                              onSubmitted: (_) {
                                _commit();
                                focusNode.requestFocus();
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Commits the text as a token when a comma or semicolon is typed (and drops it).
class _TokenSeparators extends TextInputFormatter {
  _TokenSeparators(this.commit);

  final VoidCallback commit;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cut = text.indexOf(RegExp('[,;]'));
    if (cut < 0) return newValue;
    final kept = text.substring(0, cut);
    WidgetsBinding.instance.addPostFrameCallback((_) => commit());
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }
}
