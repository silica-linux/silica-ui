// Search fields: magnifier, clear button, menu of recent searches, search tokens.
//
// Measured: the toolbar field 242 × 38 with a focus ring that fades in ~200 ms (mustache.md ›
// MU-70); the window field 28 tall on `#d7d8db` (controlcenter.md › Edit controls); the
// token 15 pt tall in two parts, a small-caps label with ⌄ on `#bbbbbb` / `#8f8f8f` and the
// value on a lighter background, with a menu of the label options (MU-70); suggestions
// below the field. Provisional: the capsule shape of the window field, the glyph sizes,
// the token value background and radius, the recents menu layout.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../menu.dart';
import '../../window.dart' show ToolbarColors;
import 'editable.dart';
import 'input_style.dart';
import 'text_field.dart' show FieldBox;

/// Where a search field lives.
enum SearchFieldStyle {
  /// In a window or panel: 28 tall, filled.
  window,

  /// In the toolbar: a 38 pt capsule with the toolbar material, 242 wide when open.
  toolbar,
}

/// A search token: a criterion shown before the text, in two parts. Tapping the label opens
/// the menu of [options] (e.g. "Name", "Everything").
@immutable
class SearchToken {
  const SearchToken({
    required this.label,
    required this.value,
    this.options = const [],
  });

  /// The criterion ("Name"), shown in small capitals.
  final String label;

  /// The searched text.
  final String value;

  /// The criteria the token can switch to.
  final List<String> options;

  SearchToken copyWith({String? label, String? value}) => SearchToken(
    label: label ?? this.label,
    value: value ?? this.value,
    options: options,
  );
}

/// The texts of a search field, given by the app in its language.
@immutable
class SearchFieldLabels {
  const SearchFieldLabels({
    required this.placeholder,
    this.clear,
    this.recentsTitle,
    this.clearRecents,
    this.noRecents,
  });

  /// The placeholder ("Search").
  final String placeholder;

  /// Accessibility label of the clear button.
  final String? clear;

  /// The recents menu: its header, the item that empties it and the empty state.
  final String? recentsTitle;
  final String? clearRecents;
  final String? noRecents;
}

/// A search field.
class SilicaSearchField extends StatefulWidget {
  const SilicaSearchField({
    super.key,
    required this.labels,
    this.controller,
    this.focusNode,
    this.style = SearchFieldStyle.window,
    this.width,
    this.enabled = true,
    this.autofocus = false,
    this.tokens = const [],
    this.onTokensChanged,
    this.recents,
    this.onClearRecents,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
  });

  final SearchFieldLabels labels;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final SearchFieldStyle style;
  final double? width;
  final bool enabled;
  final bool autofocus;
  final List<SearchToken> tokens;

  /// Tokens removed (⌫ at the start of the text, clear button) or switched from their menu.
  final ValueChanged<List<SearchToken>>? onTokensChanged;

  /// Recent searches: with a list the magnifier opens the recents menu.
  final List<String>? recents;
  final VoidCallback? onClearRecents;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Esc or the clear button emptied the field.
  final VoidCallback? onCancel;

  @override
  State<SilicaSearchField> createState() => _SilicaSearchFieldState();
}

class _SilicaSearchFieldState extends State<SilicaSearchField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  VoidCallback? _closeMenu;
  final GlobalKey _magnifierKey = GlobalKey();

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _closeMenu?.call();
    _focus.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clear();
      return KeyEventResult.handled;
    }
    final sel = _controller.selection;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.tokens.isNotEmpty &&
        sel.isCollapsed &&
        sel.baseOffset <= 0) {
      widget.onTokensChanged?.call(
        widget.tokens.sublist(0, widget.tokens.length - 1),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _clear() {
    _controller.clear();
    if (widget.tokens.isNotEmpty) widget.onTokensChanged?.call(const []);
    widget.onChanged?.call('');
    widget.onCancel?.call();
  }

  void _openRecents() {
    final recents = widget.recents;
    if (recents == null) return;
    final labels = widget.labels;
    final entries = <MenuEntry>[
      if (labels.recentsTitle != null) MenuSection(labels.recentsTitle!),
      if (recents.isEmpty && labels.noRecents != null)
        MenuAction(labels.noRecents!, enabled: false),
      for (final r in recents)
        MenuAction(
          r,
          onSelected: () {
            _controller.text = r;
            _controller.selection = TextSelection.collapsed(offset: r.length);
            widget.onChanged?.call(r);
            widget.onSubmitted?.call(r);
          },
        ),
      if (recents.isNotEmpty && labels.clearRecents != null) ...[
        const MenuDivider(),
        MenuAction(labels.clearRecents!, onSelected: widget.onClearRecents),
      ],
    ];
    _closeMenu = showInputMenu(
      context,
      entries: entries,
      anchor: Offset(0, _height + 4),
      onDismissed: () => _closeMenu = null,
    );
  }

  void _openTokenMenu(int index, BuildContext tokenContext) {
    final token = widget.tokens[index];
    final box = tokenContext.findRenderObject() as RenderBox?;
    final self = context.findRenderObject() as RenderBox?;
    var anchor = Offset(0, _height + 4);
    if (box != null && self != null) {
      final at = self.globalToLocal(box.localToGlobal(Offset.zero));
      anchor = Offset(at.dx, _height + 4);
    }
    _closeMenu = showInputMenu(
      context,
      anchor: anchor,
      onDismissed: () => _closeMenu = null,
      entries: [
        for (final option in token.options)
          MenuAction(
            option,
            checked: option == token.label,
            onSelected: () {
              final next = [...widget.tokens];
              next[index] = token.copyWith(label: option);
              widget.onTokensChanged?.call(next);
            },
          ),
      ],
    );
  }

  double get _height => widget.style == SearchFieldStyle.toolbar
      ? InputMetrics.searchToolbarHeight
      : InputMetrics.searchHeight;

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final toolbar = widget.style == SearchFieldStyle.toolbar;
    final height = _height;
    final glyphColor = widget.enabled ? colors.glyph : colors.placeholder;
    final hasContent = _controller.text.isNotEmpty || widget.tokens.isNotEmpty;
    final magnifier = SizedBox(
      key: _magnifierKey,
      width: toolbar ? 16 : 14,
      height: toolbar ? 16 : 14,
      child: CustomPaint(painter: MagnifierGlyph(glyphColor)),
    );
    final row = Row(
      children: [
        if (widget.recents != null && widget.enabled)
          GestureDetector(
            key: const ValueKey('searchRecents'),
            onTap: _openRecents,
            child: Semantics(
              button: true,
              label: widget.labels.recentsTitle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  magnifier,
                  SizedBox(
                    width: 7,
                    height: 5,
                    child: CustomPaint(painter: _SmallChevron(glyphColor)),
                  ),
                ],
              ),
            ),
          )
        else
          magnifier,
        SizedBox(width: toolbar ? 6 : 4),
        for (var i = 0; i < widget.tokens.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Builder(
              builder: (tokenContext) => SearchTokenChip(
                token: widget.tokens[i],
                onLabelTap: widget.tokens[i].options.isEmpty || !widget.enabled
                    ? null
                    : () => _openTokenMenu(i, tokenContext),
              ),
            ),
          ),
        Expanded(
          // Esc and ⌫ before the text reach this before the text editing shortcuts.
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _key,
            child: InputEditable(
              controller: _controller,
              focusNode: _focus,
              placeholder: widget.tokens.isEmpty
                  ? widget.labels.placeholder
                  : null,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ),
        if (hasContent && widget.enabled)
          GestureDetector(
            key: const ValueKey('searchClear'),
            onTap: _clear,
            child: Semantics(
              button: true,
              label: widget.labels.clear,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CustomPaint(painter: ClearGlyph(glyphColor)),
              ),
            ),
          ),
      ],
    );
    final radius = height / 2;
    Widget box;
    if (toolbar) {
      final bar = ToolbarColors.of(context);
      box = FocusRing(
        visible: _focus.hasFocus,
        radius: radius,
        child: CustomPaint(
          painter: ToolbarFieldPainter(
            fill: WindowActiveScope.of(context) ? bar.fill : bar.fillInactive,
            top: bar.borderTop,
            side: bar.borderSide,
            bottom: bar.borderBottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: row,
          ),
        ),
      );
    } else {
      box = FieldBox(
        focused: _focus.hasFocus,
        enabled: widget.enabled,
        radius: radius,
        border: false,
        background: colors.searchBackground,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: row,
      );
    }
    return Semantics(
      label: widget.labels.placeholder,
      textField: true,
      enabled: widget.enabled,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: SizedBox(
          width:
              widget.width ??
              (toolbar ? InputMetrics.searchToolbarWidth : null),
          height: height,
          child: box,
        ),
      ),
    );
  }
}

/// The toolbar capsule of the search field: fill and a 1 pt outline, light at the top and
/// bottom and dark at the sides (the toolbar capsule convention, mustache-spec 1.2).
class ToolbarFieldPainter extends CustomPainter {
  ToolbarFieldPainter({
    required this.fill,
    required this.top,
    required this.side,
    required this.bottom,
  });

  final Color fill;
  final Color top;
  final Color side;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, side, side, bottom],
          stops: const [0, 0.3, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(ToolbarFieldPainter old) =>
      old.fill != fill ||
      old.top != top ||
      old.side != side ||
      old.bottom != bottom;
}

/// A search token in the field: label (small capitals, ⌄) and value.
class SearchTokenChip extends StatelessWidget {
  const SearchTokenChip({super.key, required this.token, this.onLabelTap});

  final SearchToken token;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    const radius = Radius.circular(3);
    final labelStyle = inputText(
      colors.tokenText,
      size: 9,
    ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3, height: 1);
    return Semantics(
      label: '${token.label}: ${token.value}',
      child: SizedBox(
        height: InputMetrics.searchTokenHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onLabelTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.tokenLabel,
                  borderRadius: const BorderRadius.horizontal(left: radius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(token.label.toUpperCase(), style: labelStyle),
                    if (token.options.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 5,
                        height: 3,
                        child: CustomPaint(
                          painter: _SmallChevron(colors.tokenText),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tokenValue,
                borderRadius: const BorderRadius.horizontal(right: radius),
              ),
              child: Text(
                token.value,
                style: inputText(
                  colors.tokenText,
                  size: 11,
                ).copyWith(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The magnifier: a ring and a handle towards the bottom right.
class MagnifierGlyph extends CustomPainter {
  MagnifierGlyph(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;
    final r = s * 0.32;
    final c = Offset(s * 0.42, s * 0.42);
    canvas.drawCircle(c, r, paint);
    final d = r / 1.4142;
    canvas.drawLine(
      c + Offset(d, d),
      Offset(s * 0.9, s * 0.9),
      paint..strokeWidth = s * 0.14,
    );
  }

  @override
  bool shouldRepaint(MagnifierGlyph old) => old.color != color;
}

/// The clear button: a filled disc with an × cut out.
class ClearGlyph extends CustomPainter {
  ClearGlyph(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s / 2, s / 2);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(c, s / 2, Paint()..color = color);
    final x = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round;
    final a = s * 0.18;
    canvas.drawLine(c + Offset(-a, -a), c + Offset(a, a), x);
    canvas.drawLine(c + Offset(a, -a), c + Offset(-a, a), x);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClearGlyph old) => old.color != color;
}

class _SmallChevron extends CustomPainter {
  _SmallChevron(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(0.5, 0.5)
        ..lineTo(size.width / 2, size.height - 0.5)
        ..lineTo(size.width - 0.5, 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SmallChevron old) => old.color != color;
}
