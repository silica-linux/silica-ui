// The Amalfi menu (kit `Menus/Menu/Simple|Full|Context|Submenu|Cascade`): Glass/Thick,
// radius 12, 4 pt padding around rows of 24 (items, headers) and 8 (separators).
//
// Behaviour (`docs/spec/menubar.md`, M-01): the item under the pointer is highlighted; ↑ ↓
// move the highlight, Home and End jump to the ends, a letter jumps to the first item that
// starts with it, Return or Space choose; resting ~295 ms on an item with a submenu opens it
// (→ opens it at once with the keyboard, ← closes it); the submenu stays open while the
// pointer heads towards it across other items; choosing blinks the highlight (off at once,
// back at +74 ms) and closes the menu at +114 ms; Esc closes every level.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'menu_item.dart';

/// A row of an Amalfi menu: [AmalfiMenuAction], [AmalfiMenuSection] or [AmalfiMenuDivider].
@immutable
sealed class AmalfiMenuEntry {
  const AmalfiMenuEntry();
}

/// An item that does something, or opens a [submenu].
class AmalfiMenuAction extends AmalfiMenuEntry {
  const AmalfiMenuAction(
    this.label, {
    this.shortcut,
    this.icon,
    this.checked = false,
    this.enabled = true,
    this.destructive = false,
    this.onSelected,
    this.submenu,
  });

  /// The text.
  final String label;

  /// The shortcut, with its modifier glyphs (`⌘N`); null: none.
  final String? shortcut;

  /// A 16 pt icon before the label, coloured through [IconTheme]; null: none.
  final Widget? icon;

  /// Whether the checkmark shows.
  final bool checked;

  /// Whether the item can be chosen (an empty [submenu] cannot).
  final bool enabled;

  /// Whether the action destroys something (a `Palette/Terracotta` highlight).
  final bool destructive;

  /// Called when the item is chosen, as the menu starts closing.
  final VoidCallback? onSelected;

  /// The entries of the submenu this item opens; null: none.
  final List<AmalfiMenuEntry>? submenu;

  /// Whether the pointer or the keyboard can highlight and choose it.
  bool get selectable => enabled && (submenu?.isNotEmpty ?? true);
}

/// A section header.
class AmalfiMenuSection extends AmalfiMenuEntry {
  const AmalfiMenuSection(this.label);

  final String label;
}

/// A separator line between groups.
class AmalfiMenuDivider extends AmalfiMenuEntry {
  const AmalfiMenuDivider();
}

/// A menu: [entries] on Glass/Thick with radius 12 and 4 pt of padding.
///
/// Without a [width] it is as wide as its widest row, at least [minWidth], rounded up to the
/// 4 pt grid. Given a taller box than its rows need, the surface fills it and the rows stay at
/// the top; given a shorter one, the rows scroll.
///
/// It handles the pointer and, with [autofocus] or once focused, the keyboard (see
/// [AmalfiMenuList]). To show one above the app, use [showAmalfiMenu].
class AmalfiMenu extends StatelessWidget {
  const AmalfiMenu({
    super.key,
    required this.entries,
    this.width,
    this.minWidth = AmalfiMenuMetrics.minWidth,
    this.onDismiss,
    this.onBack,
    this.autofocus = false,
    this.highlightFirst = false,
    this.initialHighlight,
    this.focusNode,
    this.opaque = false,
    this.minHeight = 0,
  });

  /// The rows, top to bottom.
  final List<AmalfiMenuEntry> entries;

  /// The width, padding included; null: as wide as the widest row.
  final double? width;

  /// The narrowest the menu gets when it sizes itself.
  final double minWidth;

  /// Called when the menu should close: after an item is chosen (at +114 ms) or on Esc.
  final VoidCallback? onDismiss;

  /// Called on ← (→ in right-to-left text): a submenu goes back to its parent.
  final VoidCallback? onBack;

  /// Whether the menu takes the keyboard focus when it appears.
  final bool autofocus;

  /// Whether the first item is highlighted when the menu appears (opened by the keyboard).
  final bool highlightFirst;

  /// The index in [entries] of the item highlighted when the menu appears (a pop-up
  /// button's current value); null, or an item that cannot be chosen: see [highlightFirst].
  final int? initialHighlight;

  /// The focus node of the rows (to focus the menu from outside); null: its own.
  final FocusNode? focusNode;

  /// Whether the glass is drawn without blur (see [AmalfiGlass.opaque]).
  final bool opaque;

  /// The least height of the surface; the rows stay at the top.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    Widget menu = AmalfiGlass(
      material: AmalfiMaterials.thick,
      radius: AmalfiMenuMetrics.radius,
      opaque: opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.all(AmalfiMenuMetrics.padding),
          child: AmalfiMenuList(
            entries: entries,
            onDismiss: onDismiss,
            onBack: onBack,
            autofocus: autofocus,
            highlightFirst: highlightFirst,
            initialHighlight: initialHighlight,
            focusNode: focusNode,
            opaque: opaque,
          ),
        ),
      ),
    );
    final width = this.width;
    menu = width != null
        ? SizedBox(width: width, child: menu)
        : ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: IntrinsicWidth(stepWidth: AmalfiGrid.base, child: menu),
          );
    return Semantics(container: true, explicitChildNodes: true, child: menu);
  }
}

/// The rows of a menu without its surface: [AmalfiMenu] puts it on glass; a popover list
/// (`Popovers/Content/List`) shows it as is.
///
/// Pointer: the item under the pointer is highlighted; a press and release on an item
/// chooses it; resting on an item with a submenu opens the submenu after
/// [AmalfiMenuMetrics.submenuDelay], to the trailing side (or the leading side when there is
/// no room), overlapping by [AmalfiMenuMetrics.submenuOverlap]. Keyboard (when focused): ↑ ↓
/// Home End, a letter, Return and Space, → to open a submenu, ← to leave one, Esc.
class AmalfiMenuList extends StatefulWidget {
  const AmalfiMenuList({
    super.key,
    required this.entries,
    this.onDismiss,
    this.onBack,
    this.autofocus = false,
    this.highlightFirst = false,
    this.initialHighlight,
    this.focusNode,
    this.opaque = false,
  });

  final List<AmalfiMenuEntry> entries;

  /// Called after an item is chosen (at +114 ms) and on Esc, at every level.
  final VoidCallback? onDismiss;

  /// Called on ← (→ in right-to-left text).
  final VoidCallback? onBack;

  final bool autofocus;

  /// Whether the first item starts highlighted.
  final bool highlightFirst;

  /// The index of the item that starts highlighted; null (or an item that cannot be
  /// chosen): see [highlightFirst].
  final int? initialHighlight;

  /// The focus node of the list; null: its own.
  final FocusNode? focusNode;

  /// Passed to the submenus' glass.
  final bool opaque;

  @override
  State<AmalfiMenuList> createState() => _AmalfiMenuListState();
}

class _AmalfiMenuListState extends State<AmalfiMenuList> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'AmalfiMenuList'));
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _submenuKey = GlobalKey();
  List<GlobalKey> _keys = const [];

  int? _highlight;
  bool _blinkOff = false;
  bool _choosing = false;

  /// The item whose submenu is open, and whether the keyboard opened it.
  int? _submenu;
  bool _submenuByKeyboard = false;

  Timer? _submenuTimer, _deferTimer, _blinkTimer, _closeTimer;
  Offset? _lastPointer;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    final initial = widget.initialHighlight;
    if (initial != null && _selectable(initial)) {
      _highlight = initial;
    } else if (widget.highlightFirst) {
      _highlight = _step(null, 1);
    }
    if (widget.autofocus) {
      // Autofocus does nothing while another node (the parent menu) has the focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(AmalfiMenuList old) {
    super.didUpdateWidget(old);
    if (old.entries != widget.entries) {
      _syncKeys();
      final h = _highlight;
      if (h != null && !_selectable(h)) _highlight = null;
      final s = _submenu;
      if (s != null && !_selectable(s)) _closeSubmenu();
    }
  }

  @override
  void dispose() {
    for (final t in [_submenuTimer, _deferTimer, _blinkTimer, _closeTimer]) {
      t?.cancel();
    }
    _ownFocus?.dispose();
    super.dispose();
  }

  void _syncKeys() {
    _keys = [for (final _ in widget.entries) GlobalKey()];
  }

  AmalfiMenuAction? _action(int i) => i >= 0 && i < widget.entries.length
      ? switch (widget.entries[i]) {
          final AmalfiMenuAction a => a,
          _ => null,
        }
      : null;

  bool _selectable(int i) => _action(i)?.selectable ?? false;

  /// The next selectable item after [from] in [direction] (no wrapping); null: none.
  int? _step(int? from, int direction) {
    final n = widget.entries.length;
    var i = from ?? (direction > 0 ? -1 : n);
    while (true) {
      i += direction;
      if (i < 0 || i >= n) return null;
      if (_selectable(i)) return i;
    }
  }

  /// The item under the global [position]; null: none (or a header, separator, gap).
  int? _indexAt(Offset position) {
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final local = box.globalToLocal(position);
      if ((Offset.zero & box.size).contains(local)) return i;
    }
    return null;
  }

  Rect? _globalRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  // Pointer.

  void _track(Offset position) {
    if (_choosing) return;
    final previous = _lastPointer;
    _lastPointer = position;
    final i = _indexAt(position);
    final open = _submenu;
    if (open != null && i != open && _headingToSubmenu(previous, position)) {
      // Moving diagonally towards the open submenu: keep it, look again when the pointer
      // rests (an assumption: the spec measures no delay for this).
      _deferTimer?.cancel();
      _deferTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted && _lastPointer == position) _apply(i);
      });
      return;
    }
    _deferTimer?.cancel();
    _apply(i);
  }

  void _apply(int? i) {
    final target = i != null && _selectable(i) ? i : null;
    if (target != _submenu && _submenu != null) _closeSubmenu();
    if (target != _highlight) {
      _submenuTimer?.cancel();
      setState(() => _highlight = target);
      if (target != null && _action(target)?.submenu != null) {
        _submenuTimer = Timer(AmalfiMenuMetrics.submenuDelay, () {
          if (mounted && _highlight == target) _openSubmenu(target);
        });
      }
    }
  }

  void _exit() {
    if (_choosing) return;
    _deferTimer?.cancel();
    _submenuTimer?.cancel();
    _lastPointer = null;
    if (_submenu == null && _highlight != null) {
      setState(() => _highlight = null);
    }
  }

  bool _headingToSubmenu(Offset? from, Offset to) {
    final rect = _globalRect(_submenuKey);
    if (from == null || rect == null) return false;
    final towardsRight = rect.left >= from.dx;
    final x = towardsRight ? rect.left : rect.right;
    return _inTriangle(to, from, Offset(x, rect.top), Offset(x, rect.bottom));
  }

  static bool _inTriangle(Offset p, Offset a, Offset b, Offset c) {
    double side(Offset p1, Offset p2, Offset p3) =>
        (p1.dx - p3.dx) * (p2.dy - p3.dy) - (p2.dx - p3.dx) * (p1.dy - p3.dy);
    final d1 = side(p, a, b), d2 = side(p, b, c), d3 = side(p, c, a);
    final negative = d1 < 0 || d2 < 0 || d3 < 0;
    final positive = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negative && positive);
  }

  void _release(Offset position) {
    final i = _indexAt(position);
    if (i != null) _activate(i);
  }

  // Submenus.

  void _openSubmenu(int i, {bool byKeyboard = false}) {
    if (_action(i)?.submenu == null || !_selectable(i)) return;
    _submenuTimer?.cancel();
    setState(() {
      _highlight = i;
      _submenu = i;
      _submenuByKeyboard = byKeyboard;
    });
    _portal.show();
  }

  void _closeSubmenu() {
    if (_portal.isShowing) _portal.hide();
    if (_submenu != null && mounted) setState(() => _submenu = null);
  }

  void _backFromSubmenu() {
    _closeSubmenu();
    _focus.requestFocus();
  }

  // Choosing.

  void _activate(int i) {
    final action = _action(i);
    if (action == null || !action.selectable || _choosing) return;
    if (action.submenu != null) {
      _openSubmenu(i);
      return;
    }
    _choosing = true;
    _submenuTimer?.cancel();
    setState(() {
      _highlight = i;
      _blinkOff = true;
    });
    _blinkTimer = Timer(AmalfiMenuMetrics.blinkOn, () {
      if (mounted) setState(() => _blinkOff = false);
    });
    _closeTimer = Timer(AmalfiMenuMetrics.chooseClose, () {
      action.onSelected?.call();
      widget.onDismiss?.call();
      if (mounted) _choosing = false;
    });
  }

  // Keyboard.

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_choosing) return KeyEventResult.handled;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backward = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    void highlight(int? i) {
      if (i == null) return;
      if (_submenu != null && _submenu != i) _closeSubmenu();
      _submenuTimer?.cancel();
      setState(() => _highlight = i);
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      highlight(_step(_highlight, 1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      highlight(_step(_highlight, -1));
    } else if (key == LogicalKeyboardKey.home) {
      highlight(_step(null, 1));
    } else if (key == LogicalKeyboardKey.end) {
      highlight(_step(null, -1));
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final h = _highlight;
      if (h == null) return KeyEventResult.handled;
      if (_action(h)?.submenu != null) {
        _openSubmenu(h, byKeyboard: true);
      } else {
        _activate(h);
      }
    } else if (key == forward) {
      final h = _highlight;
      if (h != null && _action(h)?.submenu != null) {
        _openSubmenu(h, byKeyboard: true);
      }
    } else if (key == backward) {
      final back = widget.onBack;
      if (back == null) return KeyEventResult.ignored;
      back();
    } else if (key == LogicalKeyboardKey.escape) {
      widget.onDismiss?.call();
    } else {
      final char = event.character;
      if (char == null || char.trim().isEmpty) return KeyEventResult.ignored;
      final lower = char.toLowerCase();
      for (var i = 0; i < widget.entries.length; i++) {
        final a = _action(i);
        if (a != null &&
            a.selectable &&
            a.label.toLowerCase().startsWith(lower)) {
          highlight(i);
          break;
        }
      }
    }
    return KeyEventResult.handled;
  }

  // Building.

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (var i = 0; i < widget.entries.length; i++)
        KeyedSubtree(key: _keys[i], child: _row(i, widget.entries[i])),
    ];
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _key,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _submenuOverlay,
        child: MouseRegion(
          onHover: (e) => _track(e.position),
          onExit: (_) => _exit(),
          child: Listener(
            onPointerMove: (e) => _track(e.position),
            onPointerUp: (e) => _release(e.position),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int i, AmalfiMenuEntry entry) => switch (entry) {
    AmalfiMenuDivider() => const AmalfiMenuSeparator(),
    AmalfiMenuSection(:final label) => Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(child: AmalfiMenuHeader(label: label)),
    ),
    final AmalfiMenuAction a => Semantics(
      button: true,
      enabled: a.selectable,
      checked: a.checked ? true : null,
      selected: _highlight == i,
      label: a.label,
      value: a.shortcut,
      onTap: a.selectable ? () => _activate(i) : null,
      child: ExcludeSemantics(
        child: AmalfiMenuItem(
          label: a.label,
          shortcut: a.shortcut,
          icon: a.icon,
          checked: a.checked,
          submenu: a.submenu != null,
          destructive: a.destructive,
          enabled: a.selectable,
          highlighted: _highlight == i && !_blinkOff,
        ),
      ),
    ),
  };

  Widget _submenuOverlay(BuildContext overlayContext) {
    final i = _submenu;
    final entries = i == null ? null : _action(i)?.submenu;
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    final list = context.findRenderObject();
    final item = i == null ? null : _keys[i].currentContext?.findRenderObject();
    if (entries == null ||
        overlay is! RenderBox ||
        list is! RenderBox ||
        item is! RenderBox ||
        !list.hasSize ||
        !item.hasSize) {
      return const SizedBox.shrink();
    }
    Rect rectOf(RenderBox box) => MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
    return AmalfiTheme(
      brightness: AmalfiTheme.of(context).brightness,
      child: CustomSingleChildLayout(
        delegate: _SubmenuLayout(
          list: rectOf(list),
          item: rectOf(item),
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        ),
        child: KeyedSubtree(
          key: _submenuKey,
          child: AmalfiMenu(
            entries: entries,
            onDismiss: widget.onDismiss,
            onBack: _backFromSubmenu,
            autofocus: _submenuByKeyboard,
            highlightFirst: _submenuByKeyboard,
            opaque: widget.opaque,
          ),
        ),
      ),
    );
  }
}

/// Puts a submenu beside its parent: its leading edge on the parent list's trailing edge
/// (so it overlaps the parent's padding, [AmalfiMenuMetrics.submenuOverlap]), its top on the
/// item's top (`Menus/Menu/Cascade`); on the other side when it does not fit, then inside
/// the bounds.
class _SubmenuLayout extends SingleChildLayoutDelegate {
  const _SubmenuLayout({
    required this.list,
    required this.item,
    required this.textDirection,
  });

  final Rect list;
  final Rect item;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final after = list.right;
    final before = list.left - childSize.width;
    final rtl = textDirection == TextDirection.rtl;
    final fitsAfter = after + childSize.width <= size.width;
    final fitsBefore = before >= 0;
    final x = rtl
        ? (fitsBefore || !fitsAfter ? before : after)
        : (fitsAfter || !fitsBefore ? after : before);
    final y = item.top;
    double clamp(double v, double extent, double room) =>
        v + extent > room ? room - extent : v;
    return Offset(
      clamp(x, childSize.width, size.width).clamp(0, double.infinity),
      clamp(y, childSize.height, size.height).clamp(0, double.infinity),
    );
  }

  @override
  bool shouldRelayout(_SubmenuLayout old) =>
      old.list != list ||
      old.item != item ||
      old.textDirection != textDirection;
}

/// Shows a menu of [entries] above the app with its top-left corner at the global [position]
/// (moved inside the overlay when it would leave it), and completes when it closes: after a
/// choice, on Esc, or on a press outside it.
///
/// It fades in and out with [AmalfiFades.instant] (`motion.md`: no scale) and takes the
/// keyboard focus. [width], [minWidth] and [opaque] are as in [AmalfiMenu].
Future<void> showAmalfiMenu({
  required BuildContext context,
  required Offset position,
  required List<AmalfiMenuEntry> entries,
  double? width,
  double minWidth = AmalfiMenuMetrics.minWidth,
  bool opaque = false,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  final brightness = AmalfiTheme.of(context).brightness;
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Directionality(
      textDirection: direction,
      child: AmalfiTheme(
        brightness: brightness,
        child: _MenuPresenter(
          position: position,
          onClosed: () {
            entry.remove();
            entry.dispose();
            if (!done.isCompleted) done.complete();
          },
          builder: (dismiss) => AmalfiMenu(
            entries: entries,
            width: width,
            minWidth: minWidth,
            opaque: opaque,
            autofocus: true,
            onDismiss: dismiss,
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _MenuPresenter extends StatefulWidget {
  const _MenuPresenter({
    required this.position,
    required this.onClosed,
    required this.builder,
  });

  final Offset position;
  final VoidCallback onClosed;
  final Widget Function(VoidCallback dismiss) builder;

  @override
  State<_MenuPresenter> createState() => _MenuPresenterState();
}

class _MenuPresenterState extends State<_MenuPresenter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AmalfiFades.instant.duration,
  )..forward();
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: AmalfiFades.instant.curve,
  );
  bool _closing = false;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    _fade.reverse().whenCompleteOrCancel(widget.onClosed);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _dismiss(),
        ),
      ),
      CustomSingleChildLayout(
        delegate: _MenuLayout(widget.position),
        child: FadeTransition(
          opacity: _opacity,
          child: IgnorePointer(
            ignoring: _closing,
            child: widget.builder(_dismiss),
          ),
        ),
      ),
    ],
  );
}

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.position);

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = position.dx, y = position.dy;
    if (x + childSize.width > size.width) x = size.width - childSize.width;
    if (y + childSize.height > size.height) y = size.height - childSize.height;
    return Offset(x < 0 ? 0 : x, y < 0 ? 0 : y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) => old.position != position;
}
