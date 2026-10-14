// The sidebar source list (CT-SB-01; mustache-spec 2, MU-10, MU-11): rows at a 32 pt pitch,
// 18 pt icon at x 20, text 13.75 pt at x 47; selection a radius 8 rectangle as tall as the row,
// 10 pt from the edges, text in semibold, the icon keeps its color; no background on hover. The
// first row is centered 68 pt from the top of the window (below the window buttons); a heading
// sits 24 pt above the center of its first row and 40 pt below the center of the last row before
// it. On hover a heading shows a 10 × 6 chevron that collapses the section (~190 ms, ease out,
// after ~70 ms; expanding after ~120 ms): the rows drop their text at once and slide up under the
// heading. Nested items have a disclosure triangle and a 15 pt indent (provisional: the sidebar
// nesting is not measured, the list view's is).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'common.dart';

abstract final class SourceListMetrics {
  static const double row = 32;
  static const double textLeft = 47;
  static const double iconLeft = 20;
  static const double iconSize = 18;
  static const double headingLeft = 17;
  static const double selectionInset = 10;
  static const double selectionRadius = 8;
  static const double firstRowCenter = 68;
  static const double headingToRow = 24;
  static const double rowToHeading = 40;
  static const double textSize = 13.75;
  static const double headingSize = 11.5;
  static const Size chevron = Size(10, 6);
  static const double chevronRight = 31;

  /// Nesting: 15 pt per level (the list view's, MU-20; provisional for the sidebar).
  static const double indent = 15;

  /// The badge (unread count): right-aligned, 12 pt from the selection edge (provisional).
  static const double badgeRight = 12;
  static const double badgeSize = 12;

  static const Duration collapse = Duration(milliseconds: 255);
  static const Duration expand = Duration(milliseconds: 308);
  static const double collapseDelay = 70 / 255;
  static const double expandDelay = 120 / 308;
}

/// Sidebar colors by appearance and window state (mustache-spec 2.1, 2.2).
@immutable
class SourceListColors {
  const SourceListColors({
    required this.fill,
    required this.selection,
    required this.text,
    required this.selectedText,
    required this.heading,
    required this.accentIcon,
    required this.plainIcon,
    required this.plainIconSelected,
    required this.badge,
    required this.dropTarget,
  });

  final Color fill;
  final Color selection;
  final Color text;
  final Color selectedText;
  final Color heading;
  final Color accentIcon;
  final Color plainIcon;
  final Color plainIconSelected;

  /// Count badges: the secondary text color (provisional).
  final Color badge;

  /// A row under a drag: accent fill and white text.
  final Color dropTarget;

  static SourceListColors of({required bool dark, required bool active}) =>
      switch ((dark, active)) {
        (false, true) => const SourceListColors(
          fill: Color(0xFFECECED),
          selection: Color(0xFFD7D7D7),
          text: Color(0xFF000000),
          selectedText: Color(0xFF000000),
          heading: Color(0xFF808182),
          accentIcon: Color(0xFF0070EB),
          plainIcon: Color(0xFF7C7C82),
          plainIconSelected: Color(0xFF6E6E74),
          badge: Color(0xFF808182),
          dropTarget: Color(0xFF0064E1),
        ),
        (false, false) => const SourceListColors(
          fill: Color(0xFFF2F2F2),
          selection: Color(0xFFE7E7E7),
          text: Color(0xFF727272),
          selectedText: Color(0xFF676767),
          heading: Color(0xFFA6A6A6),
          accentIcon: Color(0xFF7F7F7F),
          plainIcon: Color(0xFF7F7F7F),
          plainIconSelected: Color(0xFF7F7F7F),
          badge: Color(0xFFA6A6A6),
          dropTarget: Color(0xFF0064E1),
        ),
        (true, true) => const SourceListColors(
          fill: Color(0xFF2A2A2C),
          selection: Color(0xFF464647),
          text: Color(0xFFFFFFFF),
          selectedText: Color(0xFFFFFFFF),
          heading: Color(0xFF7C7D7E),
          accentIcon: Color(0xFF00ABFF),
          plainIcon: Color(0xFFB6B7BD),
          plainIconSelected: Color(0xFFC7C7CD),
          badge: Color(0xFF7C7D7E),
          dropTarget: Color(0xFF0059D1),
        ),
        (true, false) => const SourceListColors(
          fill: Color(0xFF29292A),
          selection: Color(0xFF373738),
          text: Color(0xFF969696),
          selectedText: Color(0xFF9B9B9C),
          heading: Color(0xFF5C5C5D),
          accentIcon: Color(0xFF929293),
          plainIcon: Color(0xFF929293),
          plainIconSelected: Color(0xFF929293),
          badge: Color(0xFF5C5C5D),
          dropTarget: Color(0xFF0059D1),
        ),
      };
}

/// A sidebar row.
@immutable
class SourceListItem {
  const SourceListItem({
    required this.id,
    required this.label,
    this.icon,
    this.accent = true,
    this.badge,
    this.children = const [],
  });

  /// Unique among all the items of the list.
  final String id;
  final String label;

  /// The 18 pt icon, drawn in the color it receives.
  final Widget Function(Color color)? icon;

  /// The icon in the accent color (most places) or gray (home, Trash).
  final bool accent;

  /// A count or short text at the right edge.
  final String? badge;

  /// Nested rows, shown with a disclosure triangle.
  final List<SourceListItem> children;
}

/// A section: a heading (empty: none) and its rows.
@immutable
class SourceListSection {
  const SourceListSection(this.title, this.items, {this.collapsible = true});
  final String title;
  final List<SourceListItem> items;
  final bool collapsible;
}

/// The sidebar source list. Up and down arrows move the selection, left and right collapse and
/// expand nested rows.
class SourceList extends StatefulWidget {
  const SourceList({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelect,
    this.active,
    this.topInset = SourceListMetrics.firstRowCenter,
    this.dropTarget,
    this.rowBuilder,
    this.focusNode,
  });

  final List<SourceListSection> sections;

  /// The id of the selected row.
  final String? selected;
  final ValueChanged<SourceListItem> onSelect;

  /// Null: from [ToolbarScope], otherwise active.
  final bool? active;

  /// The center of the first row from the top (68 under the window buttons).
  final double topInset;

  /// The id of the row under a drag (accent fill).
  final String? dropTarget;

  /// Wraps each row, for drag sources, drop targets and context menus (reordering hooks).
  final Widget Function(BuildContext context, SourceListItem item, Widget row)?
  rowBuilder;

  final FocusNode? focusNode;

  @override
  State<SourceList> createState() => _SourceListState();
}

class _SourceListState extends State<SourceList> with TickerProviderStateMixin {
  final Map<String, AnimationController> _sections = {};
  final Set<String> _open = {};
  String? _hovered;
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  AnimationController _controller(String title) => _sections.putIfAbsent(
    title,
    () => AnimationController(
      vsync: this,
      duration: SourceListMetrics.expand,
      reverseDuration: SourceListMetrics.collapse,
      value: 1,
    )..addListener(() => setState(() {})),
  );

  @override
  void dispose() {
    _ownFocus?.dispose();
    for (final controller in _sections.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSection(String title) {
    final controller = _controller(title);
    if (_collapsing(title)) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  bool _collapsing(String title) {
    final controller = _sections[title];
    return controller != null &&
        (controller.status == AnimationStatus.reverse || controller.value == 0);
  }

  double _openness(String title) {
    final controller = _sections[title];
    if (controller == null) return 1;
    final collapsing = _collapsing(title);
    final delay = collapsing
        ? SourceListMetrics.collapseDelay
        : SourceListMetrics.expandDelay;
    final elapsed = collapsing ? 1 - controller.value : controller.value;
    final moved = Curves.easeOut.transform(
      ((elapsed - delay) / (1 - delay)).clamp(0.0, 1.0),
    );
    return collapsing ? 1 - moved : moved;
  }

  /// The visible rows in order, with their depth.
  List<(SourceListItem, int)> _visible() {
    final out = <(SourceListItem, int)>[];
    void walk(List<SourceListItem> items, int depth) {
      for (final item in items) {
        out.add((item, depth));
        if (_open.contains(item.id)) walk(item.children, depth + 1);
      }
    }

    for (final section in widget.sections) {
      if (section.title.isNotEmpty && _collapsing(section.title)) continue;
      walk(section.items, 0);
    }
    return out;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rows = _visible();
    final index = rows.indexWhere((r) => r.$1.id == widget.selected);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (rows.isEmpty) return KeyEventResult.handled;
      final next = index < 0
          ? 0
          : (index + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)).clamp(
              0,
              rows.length - 1,
            );
      widget.onSelect(rows[next].$1);
      return KeyEventResult.handled;
    }
    if (index >= 0 &&
        (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.arrowLeft)) {
      final item = rows[index].$1;
      if (item.children.isEmpty) return KeyEventResult.ignored;
      setState(() {
        if (key == LogicalKeyboardKey.arrowRight) {
          _open.add(item.id);
        } else {
          _open.remove(item.id);
        }
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SourceListColors.of(
      dark: containerDark(context),
      active: containerActive(context, widget.active),
    );
    final children = <Widget>[];
    var first = true;
    for (final section in widget.sections) {
      if (section.items.isEmpty) continue;
      final title = section.title;
      if (title.isNotEmpty) {
        // The heading takes 32 pt with its text centered 24 from the top.
        if (first) {
          children.add(
            SizedBox(
              height: widget.topInset - SourceListMetrics.headingToRow - 24,
            ),
          );
        }
        children.add(_heading(section, colors));
      } else if (first) {
        children.add(
          SizedBox(height: widget.topInset - SourceListMetrics.row / 2),
        );
      }
      first = false;
      final openness = title.isEmpty ? 1.0 : _openness(title);
      final textVisible = title.isEmpty || !_collapsing(title);
      final rows = <Widget>[];
      void walk(List<SourceListItem> items, int depth) {
        for (final item in items) {
          rows.add(_row(item, depth, colors, showText: textVisible));
          if (_open.contains(item.id)) walk(item.children, depth + 1);
        }
      }

      walk(section.items, 0);
      children.add(
        ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: openness,
            child: Column(mainAxisSize: MainAxisSize.min, children: rows),
          ),
        ),
      );
    }
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: ColoredBox(
        color: colors.fill,
        child: ListView(padding: EdgeInsets.zero, children: children),
      ),
    );
  }

  Widget _heading(SourceListSection section, SourceListColors colors) {
    final title = section.title;
    final hovered = _hovered == title;
    final collapsed = _collapsing(title);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = title),
      onExit: (_) => setState(() {
        if (_hovered == title) _hovered = null;
      }),
      child: Semantics(
        header: true,
        expanded: section.collapsible ? !collapsed : null,
        child: SizedBox(
          key: ValueKey('source heading $title'),
          height: SourceListMetrics.row,
          child: Stack(
            children: [
              Positioned(
                left: SourceListMetrics.headingLeft,
                right:
                    SourceListMetrics.chevronRight +
                    SourceListMetrics.chevron.width,
                top: 24 - 8,
                height: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: containerText(
                      SourceListMetrics.headingSize,
                      colors.heading,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // The chevron appears on hover, without delay or fade (MU-11).
              if (hovered && section.collapsible)
                Positioned(
                  right: SourceListMetrics.chevronRight - 4,
                  top: 24 - 10,
                  width: SourceListMetrics.chevron.width + 8,
                  height: 20,
                  child: GestureDetector(
                    key: ValueKey('source collapse $title'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleSection(title),
                    child: Center(
                      child: SizedBox(
                        width: collapsed
                            ? SourceListMetrics.chevron.height
                            : SourceListMetrics.chevron.width,
                        height: collapsed
                            ? SourceListMetrics.chevron.width
                            : SourceListMetrics.chevron.height,
                        child: CustomPaint(
                          painter: ContainerChevron(
                            colors.heading,
                            collapsed
                                ? AxisDirection.right
                                : AxisDirection.down,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    SourceListItem item,
    int depth,
    SourceListColors colors, {
    required bool showText,
  }) {
    final selected = item.id == widget.selected;
    final drop = item.id == widget.dropTarget;
    final indent = depth * SourceListMetrics.indent;
    final open = _open.contains(item.id);
    final textColor = drop
        ? const Color(0xFFFFFFFF)
        : selected
        ? colors.selectedText
        : colors.text;
    final iconColor = drop
        ? const Color(0xFFFFFFFF)
        : item.accent
        ? colors.accentIcon
        : selected
        ? colors.plainIconSelected
        : colors.plainIcon;
    Widget row = Semantics(
      button: true,
      selected: selected,
      expanded: item.children.isEmpty ? null : open,
      label: item.label,
      child: GestureDetector(
        key: ValueKey('source ${item.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          widget.onSelect(item);
        },
        child: SizedBox(
          height: SourceListMetrics.row,
          child: Stack(
            children: [
              if (selected || drop)
                Positioned.fill(
                  left: SourceListMetrics.selectionInset,
                  right: SourceListMetrics.selectionInset,
                  child: DecoratedBox(
                    key: ValueKey(
                      drop ? 'source drop' : 'source selection ${item.id}',
                    ),
                    decoration: BoxDecoration(
                      color: drop ? colors.dropTarget : colors.selection,
                      borderRadius: BorderRadius.circular(
                        SourceListMetrics.selectionRadius,
                      ),
                    ),
                  ),
                ),
              if (item.children.isNotEmpty)
                Positioned(
                  left: indent + 8,
                  top: 0,
                  bottom: 0,
                  width: 12,
                  child: GestureDetector(
                    key: ValueKey('source disclose ${item.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      if (!_open.remove(item.id)) _open.add(item.id);
                    }),
                    child: Center(
                      child: OutlineTriangle(open: open, color: colors.heading),
                    ),
                  ),
                ),
              if (item.icon case final icon?)
                Positioned(
                  left: SourceListMetrics.iconLeft + indent,
                  top: (SourceListMetrics.row - SourceListMetrics.iconSize) / 2,
                  width: SourceListMetrics.iconSize,
                  height: SourceListMetrics.iconSize,
                  child: icon(iconColor),
                ),
              if (showText)
                Positioned(
                  left: SourceListMetrics.textLeft + indent,
                  right:
                      SourceListMetrics.selectionInset +
                      (item.badge == null ? 4 : 40),
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: containerText(
                        SourceListMetrics.textSize,
                        textColor,
                        weight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ),
              if (showText && item.badge != null)
                Positioned(
                  right:
                      SourceListMetrics.selectionInset +
                      SourceListMetrics.badgeRight,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      item.badge!,
                      key: ValueKey('source badge ${item.id}'),
                      style: containerText(
                        SourceListMetrics.badgeSize,
                        drop ? textColor : colors.badge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.rowBuilder case final builder?) {
      row = builder(context, item, row);
    }
    return row;
  }
}
