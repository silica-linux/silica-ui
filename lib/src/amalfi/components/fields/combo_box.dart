// The Amalfi combo box (kit `Fields/Combo Box/*`, `Fields/Combo Button/*`): a text field with
// a round button at its end that opens the list of options under it (`Fields/Combo Box/Open`:
// the list is `Menus/Menu/Simple`, 4 below the field and as wide): an `AmalfiMenu` of the
// menus family, one item per option, the option equal to the text checked.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menus/menu.dart';
import '../menus/menu_item.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'editable.dart';
import 'field_state.dart';
import '../../foundation/foundation.dart';
import 'metrics.dart';
import 'text_field.dart';

/// The measures of the combo box list (an [AmalfiMenu]; its items: [AmalfiMenuMetrics]).
abstract final class AmalfiComboListMetrics {
  /// Between the field and the list.
  static const double gap = 4;

  /// The most items shown before the list scrolls.
  static const int maxVisibleItems = 8;
}

/// The round button at the end of a combo box: a [AmalfiFieldSize.comboButton] disc of
/// `Surface/Sunken` with a chevron, `Surface/Control Pressed` while pressed.
///
/// [onPressed] null disables it: the rest look at 35 % (user decision 2026-10-16). Inside a
/// disabled combo box it keeps the rest look, dimmed once with the field.
class AmalfiComboButton extends StatefulWidget {
  const AmalfiComboButton({
    super.key,
    required this.onPressed,
    this.size = AmalfiFieldSize.regular,
    this.pressed = false,
    this.semanticLabel = 'Show options',
  });

  final VoidCallback? onPressed;
  final AmalfiFieldSize size;

  /// Draws it pressed (while its list is being opened by the pointer).
  final bool pressed;
  final String semanticLabel;

  @override
  State<AmalfiComboButton> createState() => _AmalfiComboButtonState();
}

class _AmalfiComboButtonState extends State<AmalfiComboButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final inField = !AmalfiFieldEnabledScope.enabledOf(context);
    final enabled = widget.onPressed != null && !inField;
    final pressed = enabled && (_down || widget.pressed);
    final side = widget.size.comboButton;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onPressed?.call();
                }
              : null,
          child: SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: AmalfiShapeDecoration(
                color: pressed
                    ? colors.surfaceControlPressed
                    : colors.surfaceSunken,
                shape: AmalfiSmoothBorder(radius: side / 2),
              ),
              child: Center(
                child: AmalfiGlyph(
                  AmalfiGlyphs.chevronDown,
                  size: widget.size.comboGlyph,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Opacity(
      opacity: enabled || inField ? 1 : AmalfiStates.disabledOpacity,
      child: button,
    );
  }
}

/// A combo box: editable text with a list of [options] to pick from.
///
/// The combo button, ↓ or ↑ open the list under the field; ↓ and ↑ move the highlight,
/// Enter picks the highlighted option, Esc or a click outside closes the list. A click on
/// an option picks it. Picking puts the option in the field and runs [onSelected]; the
/// option equal to the text is checked. While the list is open, typing highlights the first
/// option that starts with the text.
class AmalfiComboBox extends StatefulWidget implements AmalfiFieldWidget {
  const AmalfiComboBox({
    super.key,
    required this.options,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = AmalfiFieldSize.regular,
    this.width = AmalfiFieldMetrics.width,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onSelected,
    this.semanticLabel,
    this.statesController,
  });

  final List<String> options;
  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;
  final String? placeholder;
  final AmalfiFieldSize size;
  final double width;
  @override
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called with the option picked from the list.
  final ValueChanged<String>? onSelected;
  final String? semanticLabel;
  @override
  final WidgetStatesController? statesController;

  @override
  State<AmalfiComboBox> createState() => _AmalfiComboBoxState();
}

class _AmalfiComboBoxState extends State<AmalfiComboBox>
    with AmalfiFieldStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _tapGroup = Object();
  int? _highlight;

  bool get _open => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    controller.addListener(_textChanged);
  }

  @override
  void didUpdateWidget(AmalfiComboBox old) {
    final before = old.controller;
    super.didUpdateWidget(old);
    if (before != widget.controller) {
      before?.removeListener(_textChanged);
      controller.addListener(_textChanged);
    }
    if (!widget.enabled && _open) _close();
  }

  @override
  void dispose() {
    controller.removeListener(_textChanged);
    super.dispose();
  }

  String? _lastText;

  void _textChanged() {
    final text = controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (!_open || text.isEmpty) return;
    final lower = text.toLowerCase();
    final match = widget.options.indexWhere(
      (o) => o.toLowerCase().startsWith(lower),
    );
    if (match >= 0) setState(() => _highlight = match);
  }

  @override
  void onFocusChanged(bool focused) {
    if (!focused && _open) _close();
  }

  int? _indexOfText() {
    final i = widget.options.indexOf(controller.text);
    return i < 0 ? null : i;
  }

  void _show() {
    if (!widget.enabled || widget.options.isEmpty) return;
    setState(() {
      _highlight = _indexOfText() ?? 0;
      _portal.show();
    });
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void _close() {
    if (!_open) return;
    setState(() {
      _portal.hide();
      _highlight = null;
    });
  }

  void _toggle() => _open ? _close() : _show();

  void _pick(int index) {
    if (index < 0 || index >= widget.options.length) return;
    final option = widget.options[index];
    controller.value = TextEditingValue(
      text: option,
      selection: TextSelection.collapsed(offset: option.length),
    );
    _lastText = option;
    _close();
    widget.onChanged?.call(option);
    widget.onSelected?.call(option);
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void _move(int by) {
    final n = widget.options.length;
    if (n == 0) return;
    final from = _highlight ?? (by > 0 ? -1 : n);
    setState(() => _highlight = (from + by).clamp(0, n - 1));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _show();
      } else {
        _move(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      }
      return KeyEventResult.handled;
    }
    if (!_open) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final h = _highlight;
      if (h != null) {
        _pick(h);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final size = widget.size;
    final enabled = widget.enabled;
    final field = Semantics(
      label: widget.semanticLabel ?? widget.placeholder,
      enabled: enabled,
      expanded: _open,
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
                padding: EdgeInsets.symmetric(horizontal: size.padding),
                child: Row(
                  children: [
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
                          placeholderStyle: size.textStyle(colors.textTertiary),
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AmalfiFieldMetrics.gap),
                    AmalfiComboButton(
                      size: size,
                      onPressed: enabled ? _toggle : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _close(),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _list,
        child: field,
      ),
    );
  }

  Widget _list(BuildContext overlayContext) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final theme = AmalfiTheme.of(context);
    final checked = _indexOfText();
    return Positioned(
      left: origin.dx,
      top: origin.dy + box.size.height + AmalfiComboListMetrics.gap,
      width: box.size.width,
      child: AmalfiTheme(
        brightness: theme.brightness,
        child: TapRegion(
          groupId: _tapGroup,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight:
                  AmalfiComboListMetrics.maxVisibleItems *
                      AmalfiMenuMetrics.itemHeight +
                  2 * AmalfiMenuMetrics.padding,
            ),
            // The field keeps the keyboard focus (typing goes on while the list is open):
            // the arrows move [_highlight] here and the menu is rebuilt highlighting it.
            child: AmalfiMenu(
              key: ValueKey(_highlight),
              width: box.size.width,
              initialHighlight: _highlight,
              onDismiss: _close,
              entries: [
                for (var i = 0; i < widget.options.length; i++)
                  AmalfiMenuAction(
                    widget.options[i],
                    checked: i == checked,
                    onSelected: () => _pick(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
