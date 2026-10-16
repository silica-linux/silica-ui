// Editing the tokens before the text of a token or search field: Backspace at the start of
// the text selects the last token (drawn selected), a second Backspace removes it, any other
// key deselects it; a click on a token selects it, its cross removes it.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'field_state.dart';
import 'token.dart';

/// The token editing of a field with [tokens] and [onTokensChanged].
mixin AmalfiTokenEditingMixin<T extends StatefulWidget>
    on State<T>, AmalfiFieldStateMixin<T> {
  /// The tokens shown.
  List<String> get tokens;

  /// Called with the new list when a token is removed (or added).
  ValueChanged<List<String>>? get onTokensChanged;

  int? _selected;

  /// The index of the selected token; null: none.
  int? get selectedToken => _selected;

  @override
  void onFocusChanged(bool focused) {
    if (!focused && _selected != null) setState(() => _selected = null);
  }

  /// Removes the token at [index].
  void removeToken(int index) {
    if (index < 0 || index >= tokens.length) return;
    final next = [...tokens]..removeAt(index);
    setState(() => _selected = null);
    onTokensChanged?.call(next);
  }

  /// Selects the token at [index] and focuses the field.
  void selectToken(int index) {
    setState(() => _selected = index);
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  /// Handles Backspace and Delete around the tokens; other keys deselect the token.
  KeyEventResult handleTokenKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final selected = _selected;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      if (selected != null) {
        removeToken(selected);
        return KeyEventResult.handled;
      }
      final selection = controller.selection;
      final atStart =
          !selection.isValid ||
          (selection.isCollapsed && selection.baseOffset == 0);
      if (key == LogicalKeyboardKey.backspace && atStart && tokens.isNotEmpty) {
        setState(() => _selected = tokens.length - 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (selected != null &&
        key != LogicalKeyboardKey.shift &&
        key != LogicalKeyboardKey.shiftLeft &&
        key != LogicalKeyboardKey.shiftRight) {
      setState(() => _selected = null);
    }
    return KeyEventResult.ignored;
  }

  /// The token widgets, with the selection and the remove crosses wired.
  List<Widget> buildTokens({required bool enabled}) => [
    for (var i = 0; i < tokens.length; i++)
      AmalfiToken(
        label: tokens[i],
        selected: _selected == i,
        onPressed: enabled ? () => selectToken(i) : null,
        onRemove: enabled ? () => removeToken(i) : null,
      ),
  ];
}
