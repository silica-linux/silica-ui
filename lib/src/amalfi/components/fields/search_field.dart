// The Amalfi search field (kit `Fields/Search Field/*`): a Glass/Regular capsule with the
// magnifier, optional tokens, the text and, while there is text, the clear button. Focused,
// it shows the focus halo (no accent border); disabled, the rest look at 35 %.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'clear_button.dart';
import 'editable.dart';
import 'field_state.dart';
import '../../foundation/foundation.dart';
import 'metrics.dart';
import 'surface.dart';
import 'token_editing.dart';

/// A search field.
///
/// Esc or the clear button empties it (text and tokens) and runs [onCleared]. [tokens] are
/// shown before the text (search criteria): Backspace at the start of the text selects the
/// last one, a second Backspace removes it ([onTokensChanged]). Like every field it takes
/// selection, IME and the clipboard.
class AmalfiSearchField extends StatefulWidget implements AmalfiFieldWidget {
  const AmalfiSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.size = AmalfiFieldSize.regular,
    this.width = AmalfiFieldMetrics.width,
    this.enabled = true,
    this.tokens = const [],
    this.onTokensChanged,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.clearLabel = 'Clear',
    this.semanticLabel,
    this.statesController,
  });

  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;

  /// Shown while there is neither text nor a token.
  final String placeholder;
  final AmalfiFieldSize size;
  final double width;
  @override
  final bool enabled;

  /// The tokens before the text.
  final List<String> tokens;

  /// Called with the tokens left after one is removed or the field is cleared.
  final ValueChanged<List<String>>? onTokensChanged;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after Esc or the clear button emptied the field.
  final VoidCallback? onCleared;

  /// What screen readers call the clear button.
  final String clearLabel;
  final String? semanticLabel;
  @override
  final WidgetStatesController? statesController;

  @override
  State<AmalfiSearchField> createState() => _AmalfiSearchFieldState();
}

class _AmalfiSearchFieldState extends State<AmalfiSearchField>
    with AmalfiFieldStateMixin, AmalfiTokenEditingMixin {
  @override
  List<String> get tokens => widget.tokens;

  @override
  ValueChanged<List<String>>? get onTokensChanged => widget.onTokensChanged;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = controller.text.isNotEmpty;
    controller.addListener(_textChanged);
  }

  @override
  void didUpdateWidget(AmalfiSearchField old) {
    final before = old.controller;
    super.didUpdateWidget(old);
    if (before != widget.controller) {
      before?.removeListener(_textChanged);
      controller.addListener(_textChanged);
      _hasText = controller.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_textChanged);
    super.dispose();
  }

  void _textChanged() {
    final has = controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _clear() {
    final hadTokens = widget.tokens.isNotEmpty;
    controller.clear();
    widget.onChanged?.call('');
    if (hadTokens) widget.onTokensChanged?.call(const []);
    widget.onCleared?.call();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        (controller.text.isNotEmpty || widget.tokens.isNotEmpty)) {
      _clear();
      return KeyEventResult.handled;
    }
    return handleTokenKey(node, event);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final size = widget.size;
    final enabled = widget.enabled;
    final hasTokens = widget.tokens.isNotEmpty;
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
            child: AmalfiFieldEnabledScope(
              enabled: enabled,
              child: AmalfiFieldSurface(
                radius: AmalfiRadii.capsule(size.height),
                glass: AmalfiMaterials.regular,
                halo: colors.lineFocus,
                haloVisible: focused && enabled,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.padding),
                  child: Row(
                    children: [
                      AmalfiGlyph(
                        AmalfiGlyphs.search,
                        size: size.glyph,
                        color: colors.textSecondary,
                      ),
                      SizedBox(
                        width: size == AmalfiFieldSize.toolbar && !hasTokens
                            ? 2 * AmalfiFieldMetrics.gap
                            : AmalfiFieldMetrics.gap,
                      ),
                      for (final token in buildTokens(enabled: enabled)) ...[
                        token,
                        const SizedBox(width: AmalfiFieldMetrics.gap),
                      ],
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
                            placeholder: hasTokens ? null : widget.placeholder,
                            style: size.textStyle(colors.textPrimary),
                            placeholderStyle: size.textStyle(
                              colors.textTertiary,
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                          ),
                        ),
                      ),
                      if (_hasText && enabled) ...[
                        const SizedBox(width: AmalfiFieldMetrics.gap),
                        AmalfiClearButton(
                          onPressed: _clear,
                          semanticLabel: widget.clearLabel,
                        ),
                      ],
                    ],
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
