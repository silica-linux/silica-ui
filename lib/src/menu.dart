// Pull-down and context menus: a thick glass panel with 24 pt items, 11 pt separators,
// section headers, checkmarks, shortcuts and submenus.
//
// Metrics (pt): inner margin 5 above and below; text at 17 from the edge (38 with icons, 50
// with checkmarks and icons), size 13; shortcuts and the submenu arrow ending 20 from the
// right edge; blue highlight (#007aff) 5 pt from the sides, radius 8, white text;
// 1 pt separator in the middle of its 11, 16 pt from the sides; panel radius 12.
// A submenu opens ~295 ms after the pointer reaches its item, 5 pt above the item and
// overlapping the parent menu by 5 pt; it stays open while the pointer moves diagonally
// towards it (triangle tolerance). Choice: the item blinks (off at once, back on at
// ~74 ms) and the menu fades in ~190 ms from ~114 ms; Esc fades the same way.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../silica_ui.dart' show uiFontFamily;
import 'glass.dart';
import 'liquid_glass.dart';
import 'tip_outline.dart';
import 'window_glass.dart';
import 'appearance.dart';

/// A row of a menu.
@immutable
sealed class MenuEntry {
  const MenuEntry();
}

/// An item: label, shortcut, checkmark, icon, submenu.
class MenuAction extends MenuEntry {
  const MenuAction(
    this.label, {
    this.shortcut,
    this.icon,
    this.checked = false,
    this.enabled = true,
    this.onSelected,
    this.submenu,
  });

  final String label;

  /// Shortcut text, already with the modifier symbols (e.g. "⌘N").
  final String? shortcut;

  /// An icon of ~14 pt, drawn in the color it receives.
  final Widget Function(Color color)? icon;
  final bool checked;
  final bool enabled;
  final VoidCallback? onSelected;
  final List<MenuEntry>? submenu;

  bool get selectable => enabled && (submenu == null || submenu!.isNotEmpty);
}

/// Separator line.
class MenuDivider extends MenuEntry {
  const MenuDivider();
}

/// A row drawn by whoever opens the menu (the row of tag circles): `height` high,
/// at least `width` wide; `builder` receives the function that closes the menu. It is not chosen
/// with the keyboard and releasing the pointer over it does not close the menu: it handles its own taps.
class MenuCustom extends MenuEntry {
  const MenuCustom({
    required this.height,
    required this.builder,
    this.width = 0,
  });

  final double height;
  final double width;
  final Widget Function(BuildContext context, VoidCallback close) builder;
}

/// Gray header of a group, not selectable.
class MenuSection extends MenuEntry {
  const MenuSection(this.label);
  final String label;
}

/// The menu measurements.
abstract final class MenuMetrics {
  static const double itemHeight = 24;
  static const double dividerHeight = 11;
  static const double sectionHeight = 24;
  static const double padding = 5;
  static const double radius = 12;
  static const double textLeft = 17;
  static const double textLeftIcons = 38;
  static const double textLeftChecks = 29;
  static const double textLeftBoth = 50;
  static const double checkLeft = 12;
  static const double iconLeftChecks = 29;
  static const double iconLeft = 16;
  static const double right = 20;
  static const double highlightInset = 5;
  static const double highlightRadius = 8;
  static const double dividerInset = 16;
  static const double fontSize = 13;
  static const double sectionFontSize = 11;
  static const double shortcutGap = 32;
  static const double chevronWidth = 6;
  static const double minWidth = 120;

  /// Tip towards the object: the body edge 8 pt from the anchor; the body starts 27 pt to the
  /// left of the apex.
  static const double tipHeight = 8;

  /// The tip rectangle sent to Ossido, which draws the measured outline [TipOutline.menu]
  /// (TIP-01): 31 pt base.
  static const double tipBase = 31;

  /// The depth of the drawn tip: it reaches 2 pt past the anchor (SH-DK-17, TIP-01).
  static const double tipDepth = 10;
  static const double tipBodyLeft = 27;

  /// Submenu: overlapping by 5 pt and 5 pt above the item.
  static const double submenuOverlap = 5;

  /// Minimum distance between a menu and the edges of the area it is shown in, when it has
  /// to be moved to fit. `provisional`: the flip and the shift were not observed
  /// (menubar.md, "not observed"); the value is the 5 pt menu padding.
  static const double edgeMargin = 5;
  static const Duration submenuDelay = Duration(milliseconds: 295);
  static const Duration triangleGrace = Duration(milliseconds: 300);

  /// Blink and fade of the choice.
  static const Duration blinkOff = Duration(milliseconds: 7);
  static const Duration blinkOn = Duration(milliseconds: 74);
  static const Duration fadeStart = Duration(milliseconds: 114);
  static const Duration fade = Duration(milliseconds: 190);
}

/// The menu colors, light and dark (menubar.md, "Menu · text" and "Menu · separators").
@immutable
class MenuColors {
  const MenuColors({
    required this.text,
    required this.disabled,
    required this.shortcut,
    required this.section,
    required this.divider,
    required this.shadow,
    required this.opaqueBorder,
  });

  final Color text;
  final Color disabled;
  final Color shortcut;
  final Color section;
  final Color divider;
  final Color shadow;

  /// The hairline of a menu inside a window ([MenuPanel.opaque]).
  final Color opaqueBorder;

  /// The highlight: the same in light and dark.
  static const Color highlight = Color(0xFF007AFF);
  static const Color highlightText = Color(0xFFFFFFFF);

  /// Inside a window Flutter makes the glass ([WindowGlass]): on white `#fcfcfd`
  /// (mustache.md MU-50).
  static const MenuColors light = MenuColors(
    text: Color(0xD9000000),
    disabled: Color(0x42000000),
    shortcut: Color(0x4D000000),
    section: Color(0x42000000),
    divider: Color(0x1A000000),
    shadow: Color(0x33000000),
    opaqueBorder: Color(0x1F000000),
  );

  /// White text at 85 %, disabled at 26 %, shortcuts at 30 %, separator at 14 %;
  /// deeper shadow (−14 % against −11 % on the right). Outer hairline black ~86 %. The section header is
  /// *estimated* like the disabled one (not measured in dark).
  static const MenuColors dark = MenuColors(
    text: Color(0xD9FFFFFF),
    disabled: Color(0x42FFFFFF),
    shortcut: Color(0x4DFFFFFF),
    section: Color(0x42FFFFFF),
    divider: Color(0x24FFFFFF),
    shadow: Color(0x42000000),
    opaqueBorder: Color(0xDB000000),
  );

  /// Following the appearance in effect (the override, otherwise the system's).
  static MenuColors of(BuildContext context) =>
      SilicaAppearance.isDark(context) ? dark : light;
}

TextStyle _style(double size, Color color, {FontWeight? weight}) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1,
);

double _textWidth(String text, TextStyle style) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout()).width;

double _entryHeight(MenuEntry entry) => switch (entry) {
  MenuAction() => MenuMetrics.itemHeight,
  MenuDivider() => MenuMetrics.dividerHeight,
  MenuSection() => MenuMetrics.sectionHeight,
  MenuCustom(:final height) => height,
};

/// The text column: it depends on the checkmarks and icons in the menu.
double menuTextLeft(List<MenuEntry> entries) {
  final actions = entries.whereType<MenuAction>();
  final checks = actions.any((a) => a.checked);
  final icons = actions.any((a) => a.icon != null);
  return switch ((checks, icons)) {
    (true, true) => MenuMetrics.textLeftBoth,
    (false, true) => MenuMetrics.textLeftIcons,
    (true, false) => MenuMetrics.textLeftChecks,
    (false, false) => MenuMetrics.textLeft,
  };
}

/// The size of a menu panel.
Size menuSize(List<MenuEntry> entries) {
  final left = menuTextLeft(entries);
  var width = MenuMetrics.minWidth;
  for (final entry in entries) {
    final w = switch (entry) {
      MenuAction(:final label, :final shortcut, :final submenu) =>
        left +
            _textWidth(
              label,
              _style(MenuMetrics.fontSize, MenuColors.light.text),
            ) +
            (shortcut != null
                ? MenuMetrics.shortcutGap +
                      _textWidth(
                        shortcut,
                        _style(MenuMetrics.fontSize, MenuColors.light.shortcut),
                      )
                : submenu != null
                ? MenuMetrics.shortcutGap + MenuMetrics.chevronWidth
                : 0) +
            MenuMetrics.right,
      // The header counts as an item in the normal body size, even if it is drawn smaller
      // (silica-reference SH-DK-25: the Dock stack menu header makes the menu 220 pt wide =
      // 29 + the text at 13 pt + 20).
      MenuSection(:final label) =>
        left +
            _textWidth(
              label,
              _style(MenuMetrics.fontSize, MenuColors.light.text),
            ) +
            MenuMetrics.right,
      MenuDivider() => 0.0,
      MenuCustom(:final width) => width,
    };
    if (w > width) width = w;
  }
  final height =
      2 * MenuMetrics.padding +
      entries.fold<double>(0, (h, e) => h + _entryHeight(e));
  return Size(width.ceilToDouble(), height);
}

/// The top of each row, from the top edge of the panel.
List<double> menuRowTops(List<MenuEntry> entries) {
  final tops = <double>[];
  var y = MenuMetrics.padding;
  for (final entry in entries) {
    tops.add(y);
    y += _entryHeight(entry);
  }
  return tops;
}

/// Where a menu of `size` opens in an `area`, the way macOS places context menus
/// (`provisional`: the behaviour was not measured, only the behaviour is known).
///
/// The menu has its top-left corner at `anchor` (its bottom-left if `upwards`). If it does not
/// fit on the right it opens to the left of the anchor, its right edge at `anchor.dx`. If it
/// does not fit at the bottom it shifts up, staying [MenuMetrics.edgeMargin] from the bottom
/// edge, and never goes above `top` (the bottom of the menu bar) plus the margin. A menu
/// larger than the area starts at the top bound.
Rect placeMenu({
  required Offset anchor,
  required Size size,
  required Size area,
  bool upwards = false,
  double top = 0,
}) {
  const m = MenuMetrics.edgeMargin;
  var x = anchor.dx;
  if (x + size.width > area.width - m) x = anchor.dx - size.width;
  x = _clampLow(x, m, area.width - m - size.width);
  var y = upwards ? anchor.dy - size.height : anchor.dy;
  y = _clampLow(y, top + m, area.height - m - size.height);
  return Offset(x, y) & size;
}

/// Where a submenu of `size` opens next to its `parent` menu, whose row starts at `rowTop`:
/// to the right, or to the left of the parent if it does not fit; shifted to stay on screen
/// like [placeMenu].
Rect placeSubmenu({
  required Rect parent,
  required double rowTop,
  required Size size,
  required Size area,
  double top = 0,
}) {
  const m = MenuMetrics.edgeMargin;
  var x = parent.right - MenuMetrics.submenuOverlap;
  if (x + size.width > area.width - m) {
    x = parent.left + MenuMetrics.submenuOverlap - size.width;
  }
  x = _clampLow(x, m, area.width - m - size.width);
  final y = _clampLow(
    rowTop - MenuMetrics.padding,
    top + m,
    area.height - m - size.height,
  );
  return Offset(x, y) & size;
}

/// `v` limited to [low, high]; if the range is empty (the menu is larger than the area), `low`.
double _clampLow(double v, double low, double high) =>
    high < low ? low : v.clamp(low, high).toDouble();

/// An open menu: the items, the rectangle and the highlighted item.
class _Level {
  _Level(this.entries, this.rect, [this.parentRow]);
  final List<MenuEntry> entries;
  Rect rect;

  /// The row of the parent menu that opened this submenu (null for the main menu).
  final int? parentRow;
  int? highlighted;
  late final List<double> tops = menuRowTops(entries);

  int? rowAt(Offset p) {
    if (!rect.contains(p)) return null;
    final y = p.dy - rect.top;
    for (var i = 0; i < entries.length; i++) {
      if (y >= tops[i] && y < tops[i] + _entryHeight(entries[i])) return i;
    }
    return null;
  }
}

/// A menu with its submenus, drawn in an area that contains it (a full-screen layer, the
/// stretched bar surface). The main menu has its top-left corner at `anchor`, or its bottom
/// edge there if `upwards`. It stays inside the area ([placeMenu], [placeSubmenu]): it opens
/// to the left of the anchor if it does not fit on the right, shifts up if it does not fit
/// below, and submenus flip to the left of their parent.
class MenuHost extends StatefulWidget {
  const MenuHost({
    super.key,
    required this.entries,
    required this.anchor,
    this.upwards = false,
    this.tip,
    this.tipUp = false,
    this.onDismissed,
    this.onNext,
    this.onPrevious,
    this.autofocus = true,
    this.handlesPointer = true,
    this.onRectsChanged,
    this.opaque = false,
    this.top = 0,
  });

  /// The top of the usable part of the area (the bottom of the menu bar): menus shifted to
  /// stay on screen do not go above it.
  final double top;

  final List<MenuEntry> entries;
  final Offset anchor;
  final bool upwards;

  /// The tip of a menu pointing at an object below it (a Dock icon): the apex in
  /// area coordinates. The menu sits above, with the body starting 27 pt to the left of the
  /// tip and the bottom 8 pt above the apex; `anchor` and `upwards` do not count.
  final Offset? tip;

  /// The tip on top: the menu sits **below** the apex (a popover pointing at the button it
  /// opens from), with the body starting 27 pt to the left of the tip and the top 8 pt below
  /// the apex.
  final bool tipUp;

  /// The menu is gone (choice, Esc or click outside), once the fade has finished.
  final VoidCallback? onDismissed;

  /// → and ← without a submenu: the next menu (in the menu bar).
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool autofocus;

  /// False: the pointer is passed by whoever hosts the menu (`pointerMoved`, `pointerDown`,
  /// `pointerUp`), for example a bar where you press on an item and release in the menu.
  final bool handlesPointer;

  /// The rectangles of the open menus have changed (a submenu opens or closes): whoever hosts
  /// the menu widens the input region. Called after the frame.
  final ValueChanged<List<Rect>>? onRectsChanged;

  /// A menu inside a window: Flutter makes the glass ([MenuPanel.opaque]).
  final bool opaque;

  @override
  State<MenuHost> createState() => MenuHostState();
}

class MenuHostState extends State<MenuHost>
    with SingleTickerProviderStateMixin {
  final List<_Level> _levels = [];
  final FocusNode _focus = FocusNode();
  Timer? _submenuTimer;
  Timer? _graceTimer;
  Offset? _lastPointer;
  bool _blinkHidden = false;
  bool _closing = false;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: MenuMetrics.fade,
    value: 1,
  )..addListener(() => setState(() {}));

  /// The rectangles of the open menus (for the input region).
  List<Rect> get rects => [for (final l in _levels) l.rect];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(MenuHost old) {
    super.didUpdateWidget(old);
    if (old.entries != widget.entries ||
        (old.tip == null) != (widget.tip == null)) {
      _reset();
    }
    // A moved anchor or tip (the Dock stretching) is applied by the next `_fit`, which keeps
    // the open submenu.
  }

  /// The size of the area, known after the first layout.
  Size? _area;

  Rect _rootRect() {
    final size = menuSize(widget.entries);
    final tip = widget.tip;
    final area = _area;
    if (tip != null) {
      // Below or above the tip, which stays where it is; only the sides are kept on screen.
      var x = tip.dx - MenuMetrics.tipBodyLeft;
      if (area != null) {
        x = _clampLow(
          x,
          MenuMetrics.edgeMargin,
          area.width - MenuMetrics.edgeMargin - size.width,
        );
      }
      final y = widget.tipUp
          ? tip.dy + MenuMetrics.tipHeight
          : tip.dy - MenuMetrics.tipHeight - size.height;
      return Offset(x, y) & size;
    }
    if (area == null) {
      return (widget.upwards
              ? widget.anchor - Offset(0, size.height)
              : widget.anchor) &
          size;
    }
    return placeMenu(
      anchor: widget.anchor,
      size: size,
      area: area,
      upwards: widget.upwards,
      top: widget.top,
    );
  }

  Rect _submenuRect(_Level parent, int row, Size size) {
    final area = _area;
    final rowTop = parent.rect.top + parent.tops[row];
    if (area == null) {
      return Offset(
            parent.rect.right - MenuMetrics.submenuOverlap,
            rowTop - MenuMetrics.padding,
          ) &
          size;
    }
    return placeSubmenu(
      parent: parent.rect,
      rowTop: rowTop,
      size: size,
      area: area,
      top: widget.top,
    );
  }

  /// Places the open menus again in an area of this size (first layout, resized area, moved
  /// anchor).
  void _fit(Size area) {
    _area = area;
    _levels.first.rect = _rootRect();
    for (var i = 1; i < _levels.length; i++) {
      final level = _levels[i];
      level.rect = _submenuRect(
        _levels[i - 1],
        level.parentRow!,
        menuSize(level.entries),
      );
    }
  }

  void _reset() {
    _levels.clear();
    _levels.add(_Level(widget.entries, _rootRect()));
    _closing = false;
    _blinkHidden = false;
    _fade.value = 1;
  }

  @override
  void dispose() {
    _submenuTimer?.cancel();
    _graceTimer?.cancel();
    _fade.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSubmenu(int level, int row) {
    final parent = _levels[level];
    final entry = parent.entries[row];
    if (entry is! MenuAction || entry.submenu == null || !entry.enabled) return;
    final size = menuSize(entry.submenu!);
    final rect = _submenuRect(parent, row, size);
    setState(() {
      _levels.removeRange(level + 1, _levels.length);
      _levels.add(_Level(entry.submenu!, rect, row));
    });
  }

  /// The pointer is heading to the open submenu: inside the triangle between the previous
  /// position and the left side of the submenu.
  bool _towardSubmenu(int level, Offset p) {
    final from = _lastPointer;
    if (from == null || level + 1 >= _levels.length) return false;
    final sub = _levels[level + 1].rect;
    if (p.dx <= from.dx) return false;
    double cross(Offset a, Offset b, Offset c) =>
        (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    final a = from, b = sub.topLeft, c = sub.bottomLeft;
    final d1 = cross(a, b, p), d2 = cross(b, c, p), d3 = cross(c, a, p);
    final negative = d1 < 0 || d2 < 0 || d3 < 0;
    final positive = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negative && positive);
  }

  /// The pointer moves (menu area coordinates).
  void pointerMoved(Offset p) => _hover(p);

  /// Press: an item, a submenu, or outside (closes).
  void pointerDown(Offset p) => _press(p);

  /// Release: chooses the highlighted item under the pointer.
  void pointerUp(Offset p) => _release(p);

  /// The point is over one of the open menus.
  bool contains(Offset p) => _levels.any((l) => l.rect.contains(p));

  void _release(Offset p) {
    for (var level = _levels.length - 1; level >= 0; level--) {
      final row = _levels[level].rowAt(p);
      if (row != null && _levels[level].highlighted == row) {
        final entry = _levels[level].entries[row];
        if (entry is MenuAction && entry.selectable && entry.submenu == null) {
          _choose(level, row);
        }
        return;
      }
    }
  }

  void _hover(Offset p) {
    if (_closing) return;
    for (var level = _levels.length - 1; level >= 0; level--) {
      final row = _levels[level].rowAt(p);
      if (row == null && !_levels[level].rect.contains(p)) continue;
      // Towards the submenu: the parent item stays highlighted a little longer.
      if (level + 1 < _levels.length && _towardSubmenu(level, p)) {
        _graceTimer ??= Timer(MenuMetrics.triangleGrace, () {
          _graceTimer = null;
          if (_lastPointer case final last?) _hover(last);
        });
        _lastPointer = p;
        return;
      }
      _graceTimer?.cancel();
      _graceTimer = null;
      final current = _levels[level];
      final entry = row == null ? null : current.entries[row];
      final selectable = entry is MenuAction && entry.selectable;
      setState(() {
        current.highlighted = selectable ? row : null;
        // On another item the previous submenu closes.
        if (level + 1 < _levels.length) {
          _levels.removeRange(level + 1, _levels.length);
        }
      });
      _submenuTimer?.cancel();
      if (selectable && entry.submenu != null && row != null) {
        _submenuTimer = Timer(
          MenuMetrics.submenuDelay,
          () => _openSubmenu(level, row),
        );
      }
      _lastPointer = p;
      return;
    }
    _lastPointer = p;
  }

  void _press(Offset p) {
    for (var level = _levels.length - 1; level >= 0; level--) {
      final row = _levels[level].rowAt(p);
      if (row == null) {
        if (_levels[level].rect.contains(p)) return;
        continue;
      }
      final entry = _levels[level].entries[row];
      if (entry is! MenuAction || !entry.selectable) return;
      if (entry.submenu != null) {
        _submenuTimer?.cancel();
        _openSubmenu(level, row);
        return;
      }
      _choose(level, row);
      return;
    }
    // Outside all menus: it closes without choosing.
    close();
  }

  /// Chooses an item: blink, then the action and the fade.
  Future<void> _choose(int level, int row) async {
    if (_closing) return;
    final entry = _levels[level].entries[row];
    if (entry is! MenuAction) return;
    _closing = true;
    setState(() => _levels[level].highlighted = row);
    await Future<void>.delayed(MenuMetrics.blinkOff);
    if (!mounted) return;
    setState(() => _blinkHidden = true);
    await Future<void>.delayed(MenuMetrics.blinkOn - MenuMetrics.blinkOff);
    if (!mounted) return;
    setState(() => _blinkHidden = false);
    await Future<void>.delayed(MenuMetrics.fadeStart - MenuMetrics.blinkOn);
    if (!mounted) return;
    entry.onSelected?.call();
    await _fade.animateTo(0);
    widget.onDismissed?.call();
  }

  /// Closes with the fade (Esc, click outside).
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    _submenuTimer?.cancel();
    await _fade.animateTo(0);
    widget.onDismissed?.call();
  }

  int? _step(_Level level, int from, int delta) {
    final n = level.entries.length;
    for (var k = 1; k <= n; k++) {
      final i = (from + delta * k) % n;
      final e = level.entries[i];
      if (e is MenuAction && e.selectable) return i;
    }
    return null;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_closing || _levels.isEmpty) return KeyEventResult.handled;
    final depth = _levels.length - 1;
    final level = _levels[depth];
    final current = level.highlighted;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        close();
      case LogicalKeyboardKey.arrowDown:
        setState(() => level.highlighted = _step(level, current ?? -1, 1));
      case LogicalKeyboardKey.arrowUp:
        setState(
          () => level.highlighted = _step(
            level,
            current ?? level.entries.length,
            -1,
          ),
        );
      case LogicalKeyboardKey.arrowRight:
        final entry = current == null ? null : level.entries[current];
        if (entry is MenuAction && entry.submenu != null && current != null) {
          _openSubmenu(depth, current);
          final sub = _levels.last;
          setState(() => sub.highlighted = _step(sub, -1, 1));
        } else {
          widget.onNext?.call();
        }
      case LogicalKeyboardKey.arrowLeft:
        if (depth > 0) {
          setState(() => _levels.removeLast());
        } else {
          widget.onPrevious?.call();
        }
      case LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter ||
          LogicalKeyboardKey.space:
        if (current != null) {
          final entry = level.entries[current];
          if (entry is MenuAction && entry.submenu != null) {
            _openSubmenu(depth, current);
          } else {
            _choose(depth, current);
          }
        }
      default:
        // A letter: the first item starting with it.
        final char = event.character?.toLowerCase();
        if (char == null || char.trim().isEmpty) return KeyEventResult.ignored;
        final index = level.entries.indexWhere(
          (e) =>
              e is MenuAction &&
              e.selectable &&
              e.label.toLowerCase().startsWith(char),
        );
        if (index < 0) return KeyEventResult.ignored;
        setState(() => level.highlighted = index);
    }
    return KeyEventResult.handled;
  }

  List<Rect> _notified = const [];

  void _notifyRects() {
    final callback = widget.onRectsChanged;
    if (callback == null) return;
    final now = rects;
    if (listEquals(now, _notified)) return;
    _notified = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.hasBoundedWidth && box.hasBoundedHeight) _fit(box.biggest);
        _notifyRects();
        return _buildMenus(context);
      },
    );
  }

  Widget _buildMenus(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _key,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: widget.handlesPointer
            ? (e) => _hover(e.localPosition)
            : null,
        onPointerMove: widget.handlesPointer
            ? (e) => _hover(e.localPosition)
            : null,
        onPointerUp: widget.handlesPointer
            ? (e) => _release(e.localPosition)
            : null,
        onPointerDown: widget.handlesPointer
            ? (e) => _press(e.localPosition)
            : null,
        child: Opacity(
          opacity: _fade.value,
          child: Stack(
            children: [
              for (final level in _levels)
                Positioned.fromRect(
                  rect: level.rect,
                  child: MenuPanel(
                    entries: level.entries,
                    highlighted: _blinkHidden ? null : level.highlighted,
                    tipX: identical(level, _levels.first) && widget.tip != null
                        ? widget.tip!.dx - level.rect.left
                        : null,
                    tipUp: widget.tipUp,
                    group: _levels.indexOf(level),
                    opaque: widget.opaque,
                    onClose: close,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A menu panel: glass, shadow, rows. The size is decided by whoever places it
/// (`menuSize`).
class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    required this.entries,
    this.highlighted,
    this.tipX,
    this.tipUp = false,
    this.group = 0,
    this.opaque = false,
    this.onClose,
  });

  final List<MenuEntry> entries;
  final int? highlighted;

  /// Closes the menu (for [MenuCustom] rows).
  final VoidCallback? onClose;

  /// The glass group ([Glass.group]): a submenu has its own, and does not merge with the
  /// parent menu it is drawn on.
  final int group;

  /// A menu drawn inside a window, where the compositor's glass would sit under the
  /// content: Flutter makes the glass ([WindowGlass]) with the same material (on white
  /// `#fcfcfd`, mustache.md MU-50).
  final bool opaque;

  /// Center of the tip under the panel, from its left edge (null: no tip).
  final double? tipX;

  /// The tip on the top edge, pointing up.
  final bool tipUp;

  @override
  Widget build(BuildContext context) {
    final left = menuTextLeft(entries);
    final checks = entries.whereType<MenuAction>().any((a) => a.checked);
    final tops = menuRowTops(entries);
    final tipX = this.tipX;
    final colors = MenuColors.of(context);
    return CustomPaint(
      painter: _MenuShadow(tipX, colors.shadow, up: tipUp),
      child: opaque
          ? WindowGlass(
              key: const ValueKey('in-window menu'),
              radius: MenuMetrics.radius,
              border: colors.opaqueBorder,
              child: _rows(colors, left, checks, tops),
            )
          : LiquidGlass(
              radius: MenuMetrics.radius,
              material: GlassMaterial.thick,
              profile: GlassProfile.menu,
              interactive: false,
              group: group,
              // The tip is part of the glass (a single shape with the body, the edge continuous).
              tip: tipX == null
                  ? null
                  : GlassTip(
                      x: tipX,
                      // The rectangle of the measured Dock-menu tip, 31 × 10 pt (TIP-01):
                      // Ossido draws the outline [TipOutline.menu].
                      width: MenuMetrics.tipBase,
                      height: MenuMetrics.tipDepth,
                      edge: tipUp ? TipEdge.top : TipEdge.bottom,
                    ),
              child: _rows(colors, left, checks, tops),
            ),
    );
  }

  Widget _rows(
    MenuColors colors,
    double left,
    bool checks,
    List<double> tops,
  ) => Stack(
    children: [
      for (var i = 0; i < entries.length; i++)
        Positioned(
          left: 0,
          right: 0,
          top: tops[i],
          height: _entryHeight(entries[i]),
          child: _row(colors, entries[i], i == highlighted, left, checks),
        ),
    ],
  );

  Widget _row(
    MenuColors colors,
    MenuEntry entry,
    bool lit,
    double textLeft,
    bool checks,
  ) {
    switch (entry) {
      case MenuCustom(:final builder):
        return Builder(
          builder: (context) => builder(context, onClose ?? () {}),
        );
      case MenuDivider():
        return Center(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: MenuMetrics.dividerInset,
            ),
            color: colors.divider,
          ),
        );
      // Aligned with the item text (with checkmarks at 29, silica-reference SH-DK-25).
      case MenuSection(:final label):
        return Padding(
          padding: EdgeInsets.only(left: textLeft),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: _style(
                MenuMetrics.sectionFontSize,
                colors.section,
                weight: FontWeight.w600,
              ),
            ),
          ),
        );
      case MenuAction(
        :final label,
        :final shortcut,
        :final icon,
        :final checked,
        :final submenu,
      ):
        final color = lit
            ? MenuColors.highlightText
            : entry.enabled
            ? colors.text
            : colors.disabled;
        final minor = lit ? MenuColors.highlightText : colors.shortcut;
        return Stack(
          children: [
            if (lit)
              Positioned.fill(
                left: MenuMetrics.highlightInset,
                right: MenuMetrics.highlightInset,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: MenuColors.highlight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(MenuMetrics.highlightRadius),
                    ),
                  ),
                ),
              ),
            if (checked)
              Positioned(
                left: MenuMetrics.checkLeft,
                top: 7,
                width: 9,
                height: 10,
                child: CustomPaint(painter: _CheckPainter(color)),
              ),
            if (icon != null)
              Positioned(
                left: checks
                    ? MenuMetrics.iconLeftChecks
                    : MenuMetrics.iconLeft,
                top: 5,
                width: 14,
                height: 14,
                child: icon(color),
              ),
            Positioned(
              left: textLeft,
              right: MenuMetrics.right,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(MenuMetrics.fontSize, color),
                ),
              ),
            ),
            if (shortcut != null)
              Positioned(
                right: MenuMetrics.right,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    shortcut,
                    style: _style(
                      MenuMetrics.fontSize,
                      entry.enabled ? minor : colors.disabled,
                    ),
                  ),
                ),
              ),
            if (submenu != null)
              Positioned(
                right: MenuMetrics.right,
                top: 7.5,
                width: MenuMetrics.chevronWidth,
                height: 9,
                child: CustomPaint(painter: _ChevronPainter(color)),
              ),
          ],
        );
    }
  }
}

/// Shadow outside the panel: longer below (~20 pt) than on the sides (~16 pt). It does not fall
/// on the glass, tip included.
class _MenuShadow extends CustomPainter {
  const _MenuShadow(this.tipX, this.color, {this.up = false});
  final double? tipX;
  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(MenuMetrics.radius),
    );
    var glass = Path()..addRRect(body);
    final x = tipX;
    if (x != null) {
      // The tip as the compositor draws it: the measured outline (TIP-01).
      final tip = TipOutline.menu
          .path(overlap: 1)
          .shift(Offset(x, size.height));
      glass = Path.combine(PathOperation.union, glass, tip);
      // On top: the same shape mirrored (the body is symmetric).
      if (up) {
        glass = glass.transform(
          (Matrix4.identity()
                ..translateByDouble(0, size.height, 0, 1)
                ..scaleByDouble(1, -1, 1, 1))
              .storage,
        );
      }
    }
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect((Offset.zero & size).inflate(60)),
          glass,
        ),
      )
      ..drawRRect(
        body.shift(const Offset(0, 4)),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            Shadow.convertRadiusToSigma(16),
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MenuShadow old) =>
      old.tipX != tipX || old.up != up || old.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.8, size.height * 0.55)
        ..lineTo(size.width * 0.38, size.height - 1)
        ..lineTo(size.width - 0.5, 1),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.8, 0.8)
        ..lineTo(size.width - 0.8, size.height / 2)
        ..lineTo(0.8, size.height - 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
