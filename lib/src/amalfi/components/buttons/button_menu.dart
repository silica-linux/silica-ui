// The menu that pop-up and pull-down buttons open (kit `Buttons/<Pop-up|Pull-down>/Open`, which
// nests `Menus/Menu/Simple`): Glass/Thick, radius 12, padding 4, 24 pt items, 4 below the
// button. Not exported: it stands in for the menus family's menu, which will replace it.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'glyph.dart';

/// The measures of the menu, from `Menus/Menu/Simple` and `Menus/Item/Plain`.
abstract final class AmalfiButtonMenuMetrics {
  /// The narrowest menu (it is at least as wide as its button).
  static const double minWidth = 200;

  /// Around the items.
  static const double padding = 4;

  /// An item's height.
  static const double itemHeight = 24;

  /// An item's horizontal padding.
  static const double itemPadding = 8;

  /// The check slot before the label.
  static const double check = 12;

  /// Between the check slot and the label.
  static const double gap = 4;

  /// The radius of the highlighted item.
  static const double highlightRadius = AmalfiRadii.smallControl;

  /// Between the button and the menu.
  static const double distance = 4;
}

/// One item of an [AmalfiButtonMenu].
@immutable
class AmalfiButtonMenuEntry {
  const AmalfiButtonMenuEntry({
    required this.label,
    this.checked = false,
    this.enabled = true,
  });

  final String label;
  final bool checked;
  final bool enabled;
}

/// The menu: [entries] with [highlighted] (−1: none) highlighted, on Glass/Thick, [width]
/// wide. Hovering an item highlights it; clicking it, or Return / Space on the highlighted
/// one, calls [onSelected]; the arrows move the highlight; Escape calls [onDismiss].
class AmalfiButtonMenu extends StatefulWidget {
  const AmalfiButtonMenu({
    super.key,
    required this.entries,
    required this.onSelected,
    required this.onDismiss,
    this.highlighted = -1,
    this.width = AmalfiButtonMenuMetrics.minWidth,
    this.focusNode,
  });

  final List<AmalfiButtonMenuEntry> entries;
  final ValueChanged<int> onSelected;
  final VoidCallback onDismiss;
  final int highlighted;
  final double width;
  final FocusNode? focusNode;

  /// The menu's height for [count] items.
  static double heightFor(int count) =>
      2 * AmalfiButtonMenuMetrics.padding +
      count * AmalfiButtonMenuMetrics.itemHeight;

  @override
  State<AmalfiButtonMenu> createState() => _AmalfiButtonMenuState();
}

class _AmalfiButtonMenuState extends State<AmalfiButtonMenu> {
  late int _highlighted = widget.highlighted;

  @override
  void didUpdateWidget(AmalfiButtonMenu old) {
    super.didUpdateWidget(old);
    if (old.highlighted != widget.highlighted) {
      _highlighted = widget.highlighted;
    }
    if (_highlighted >= widget.entries.length) _highlighted = -1;
  }

  void _move(int step) {
    final n = widget.entries.length;
    if (n == 0) return;
    var i = _highlighted;
    for (var k = 0; k < n; k++) {
      i = i < 0 ? (step > 0 ? 0 : n - 1) : (i + step) % n;
      if (i < 0) i += n;
      if (widget.entries[i].enabled) {
        setState(() => _highlighted = i);
        return;
      }
    }
  }

  void _select(int i) {
    if (i < 0 || i >= widget.entries.length) return;
    if (!widget.entries[i].enabled) return;
    widget.onSelected(i);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) _select(_highlighted);
    } else if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) widget.onDismiss();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: SizedBox(
          width: widget.width,
          height: AmalfiButtonMenu.heightFor(widget.entries.length),
          child: AmalfiGlass(
            material: AmalfiMaterials.thick,
            radius: AmalfiRadii.menu,
            child: Padding(
              padding: const EdgeInsets.all(AmalfiButtonMenuMetrics.padding),
              child: Column(
                children: [
                  for (var i = 0; i < widget.entries.length; i++)
                    _Item(
                      entry: widget.entries[i],
                      highlighted: i == _highlighted,
                      colors: colors,
                      onHover: () {
                        if (_highlighted != i && widget.entries[i].enabled) {
                          setState(() => _highlighted = i);
                        }
                      },
                      onTap: () => _select(i),
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

class _Item extends StatelessWidget {
  const _Item({
    required this.entry,
    required this.highlighted,
    required this.colors,
    required this.onHover,
    required this.onTap,
  });

  final AmalfiButtonMenuEntry entry;
  final bool highlighted;
  final AmalfiColors colors;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lit = highlighted && entry.enabled;
    final color = !entry.enabled
        ? colors.textTertiary
        : lit
        ? colors.textOnAccent
        : colors.textPrimary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AmalfiButtonMenuMetrics.itemPadding,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: AmalfiButtonMenuMetrics.check,
            child: entry.checked
                ? AmalfiGlyph(
                    AmalfiGlyphShape.checkmark,
                    size: AmalfiButtonMenuMetrics.check,
                    color: color,
                  )
                : null,
          ),
          const SizedBox(width: AmalfiButtonMenuMetrics.gap),
          Expanded(
            child: Text(
              entry.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.body(color: color),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: entry.checked,
      enabled: entry.enabled,
      label: entry.label,
      onTap: entry.enabled ? onTap : null,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => onHover(),
        onHover: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: entry.enabled ? onTap : null,
          child: SizedBox(
            height: AmalfiButtonMenuMetrics.itemHeight,
            child: lit
                ? DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.accentAmalfi,
                      shape: const AmalfiSmoothBorder(
                        radius: AmalfiButtonMenuMetrics.highlightRadius,
                      ),
                    ),
                    child: row,
                  )
                : row,
          ),
        ),
      ),
    );
  }
}
