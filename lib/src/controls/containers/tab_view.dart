// Tabs.
//
// Window tabs (CT-TV-01; mustache-spec 1.3, MU-01): a capsule rail 28 tall (1 pt border, radius
// 14) under the toolbar, the active tab a pill 24 tall inset by 2 pt, 1 × 16 separators between
// inactive tabs (hidden next to the active tab and the one under the pointer), the × on the left
// on hover, "+" in a 30 pt circle 3 pt after the rail; equal widths, at least 120 pt (beyond, the
// rail scrolls). Left of the first tab the bar moves the window.
//
// In-window tab view (CT-TV-02, Terminal Settings): only the structure is measured. A row of
// segments centered over the top edge of a rounded box holding the page. *Provisional geometry
// and colors.*

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../window.dart';
import 'common.dart';

abstract final class TabMetrics {
  static const double railHeight = 28;
  static const double pillHeight = 24;
  static const double minWidth = 120;
  static const double plusSide = 30;
  static const double titleSize = 11;
}

/// Window tab colors (MU-01), light and dark.
@immutable
class WindowTabColors {
  const WindowTabColors({
    required this.rail,
    required this.railBorder,
    required this.active,
    required this.hovered,
    required this.separator,
    required this.plus,
    required this.plusGlyph,
    required this.title,
    required this.titleInactive,
    required this.close,
  });

  final Color rail;
  final Color railBorder;
  final Color active;
  final Color hovered;
  final Color separator;
  final Color plus;
  final Color plusGlyph;
  final Color title;
  final Color titleInactive;
  final Color close;

  static const WindowTabColors light = WindowTabColors(
    rail: Color(0xFFE8E8E8),
    railBorder: Color(0xFFDCDCDC),
    active: Color(0xFFFEFDFE),
    hovered: Color(0xFFDCDCDC),
    separator: Color(0xFFCCCCCC),
    plus: Color(0xFFF8F8F8),
    plusGlyph: Color(0xFF282828),
    title: Color(0xFF4C4B4C),
    titleInactive: Color(0xFF828282),
    close: Color(0xFF7B7B7B),
  );

  static const WindowTabColors dark = WindowTabColors(
    rail: Color(0xFF404041),
    railBorder: Color(0xFF4F4F50),
    active: Color(0xFF464648),
    hovered: Color(0xFF4B4B4B),
    separator: Color(0xFF575758),
    plus: Color(0xFF474748),
    plusGlyph: Color(0xFFDADADA),
    title: Color(0xFFECECEC),
    titleInactive: Color(0xFF8B8B8C),
    close: Color(0xFF909091),
  );

  static WindowTabColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// The window tab bar. ⌃⇥ and ⌃⇧⇥ (with focus inside) move between tabs.
class WindowTabBar extends StatefulWidget {
  const WindowTabBar({
    super.key,
    required this.titles,
    required this.active,
    required this.onSelect,
    this.onClose,
    this.onNew,
    this.closeLabel = 'Close tab',
    this.newLabel = 'New tab',
  });

  final List<String> titles;
  final int active;
  final ValueChanged<int> onSelect;
  final ValueChanged<int>? onClose;
  final VoidCallback? onNew;

  /// Accessibility labels, localized by the app.
  final String closeLabel;
  final String newLabel;

  /// The bar with its 4 pt margins above and below.
  static const double height = TabMetrics.railHeight + 8;

  @override
  State<WindowTabBar> createState() => _WindowTabBarState();
}

class _WindowTabBarState extends State<WindowTabBar> {
  int? _hovered;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.tab ||
        !HardwareKeyboard.instance.isControlPressed) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? -1 : 1;
    widget.onSelect((widget.active + step) % widget.titles.length);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WindowTabColors.of(context);
    final titles = widget.titles;
    return Focus(
      onKeyEvent: _key,
      canRequestFocus: false,
      child: SizedBox(
        key: const ValueKey('window tab bar'),
        height: WindowTabBar.height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 7, 4),
          child: Row(
            children: [
              const WindowDragArea(
                child: SizedBox(width: 8, height: TabMetrics.railHeight),
              ),
              Expanded(
                child: Container(
                  height: TabMetrics.railHeight,
                  decoration: BoxDecoration(
                    color: colors.rail,
                    borderRadius: BorderRadius.circular(
                      TabMetrics.railHeight / 2,
                    ),
                    border: Border.all(color: colors.railBorder),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final width = box.maxWidth / titles.length;
                      final each = width < TabMetrics.minWidth
                          ? TabMetrics.minWidth
                          : width;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < titles.length; i++)
                              SizedBox(width: each, child: _tab(colors, i)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (widget.onNew != null) ...[
                const SizedBox(width: 3),
                Semantics(
                  button: true,
                  label: widget.newLabel,
                  child: GestureDetector(
                    key: const ValueKey('window tab new'),
                    onTap: widget.onNew,
                    child: Container(
                      width: TabMetrics.plusSide,
                      height: TabMetrics.plusSide,
                      decoration: BoxDecoration(
                        color: colors.plus,
                        shape: BoxShape.circle,
                      ),
                      child: CustomPaint(painter: _Plus(colors.plusGlyph)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(WindowTabColors colors, int i) {
    final active = i == widget.active;
    final hovered = _hovered == i;
    final next = i + 1;
    final separator =
        !active &&
        next < widget.titles.length &&
        next != widget.active &&
        !hovered &&
        _hovered != next;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = i),
      onExit: (_) => setState(() {
        if (_hovered == i) _hovered = null;
      }),
      child: Semantics(
        selected: active,
        button: true,
        label: widget.titles[i],
        child: GestureDetector(
          key: ValueKey('window tab $i'),
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(i),
          child: Stack(
            children: [
              if (active || hovered)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: active ? colors.active : colors.hovered,
                      borderRadius: BorderRadius.circular(
                        TabMetrics.pillHeight / 2,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Center(
                    child: Text(
                      widget.titles[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: containerText(
                        TabMetrics.titleSize,
                        active ? colors.title : colors.titleInactive,
                      ),
                    ),
                  ),
                ),
              ),
              if (hovered && widget.onClose != null)
                Positioned(
                  left: 4,
                  top: (TabMetrics.railHeight - 2 - 18) / 2,
                  width: 18,
                  height: 18,
                  child: Semantics(
                    button: true,
                    label: widget.closeLabel,
                    child: GestureDetector(
                      key: ValueKey('window tab close $i'),
                      onTap: () => widget.onClose!(i),
                      child: CustomPaint(painter: _Cross(colors.close)),
                    ),
                  ),
                ),
              if (separator)
                Positioned(
                  right: 0,
                  top: (TabMetrics.railHeight - 2 - 16) / 2,
                  width: 1,
                  height: 16,
                  child: ColoredBox(color: colors.separator),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plus extends CustomPainter {
  const _Plus(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c - const Offset(5.5, 0), c + const Offset(5.5, 0), paint)
      ..drawLine(c - const Offset(0, 5.5), c + const Offset(0, 5.5), paint);
  }

  @override
  bool shouldRepaint(_Plus old) => old.color != color;
}

class _Cross extends CustomPainter {
  const _Cross(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c - const Offset(3.5, 3.5), c + const Offset(3.5, 3.5), paint)
      ..drawLine(
        c + const Offset(-3.5, 3.5),
        c + const Offset(3.5, -3.5),
        paint,
      );
  }

  @override
  bool shouldRepaint(_Cross old) => old.color != color;
}

/// In-window tab view colors. *Provisional: estimated from the toolbar and table colors.*
@immutable
class TabViewColors {
  const TabViewColors({
    required this.box,
    required this.boxBorder,
    required this.segments,
    required this.segmentsBorder,
    required this.chosen,
    required this.text,
    required this.textChosen,
  });

  final Color box;
  final Color boxBorder;
  final Color segments;
  final Color segmentsBorder;
  final Color chosen;
  final Color text;
  final Color textChosen;

  static const TabViewColors light = TabViewColors(
    box: Color(0x08000000),
    boxBorder: Color(0x14000000),
    segments: Color(0xFFF8F8F8),
    segmentsBorder: Color(0xFFDCDCDC),
    chosen: Color(0xFFFFFFFF),
    text: Color(0xFF4D4D4D),
    textChosen: Color(0xFF000000),
  );

  static const TabViewColors dark = TabViewColors(
    box: Color(0x0DFFFFFF),
    boxBorder: Color(0x1AFFFFFF),
    segments: Color(0xFF434344),
    segmentsBorder: Color(0xFF555556),
    chosen: Color(0xFF6A6A6B),
    text: Color(0xFFD0D0D0),
    textChosen: Color(0xFFFFFFFF),
  );

  static TabViewColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// Tabs inside a window (settings panes, inspectors): segments over a rounded box with the page.
/// ← → move between tabs when the segments have the focus.
class SilicaTabView extends StatefulWidget {
  const SilicaTabView({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.page,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// The page of the selected tab.
  final Widget page;

  static const double segmentHeight = 24;
  static const double boxRadius = 8;

  @override
  State<SilicaTabView> createState() => _SilicaTabViewState();
}

class _SilicaTabViewState extends State<SilicaTabView> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final n = widget.labels.length;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onSelect((widget.selected + 1) % n);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onSelect((widget.selected - 1 + n) % n);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = TabViewColors.of(context);
    const half = SilicaTabView.segmentHeight / 2;
    return Stack(
      children: [
        Positioned.fill(
          top: half,
          child: Container(
            decoration: BoxDecoration(
              color: colors.box,
              border: Border.all(color: colors.boxBorder),
              borderRadius: BorderRadius.circular(SilicaTabView.boxRadius),
            ),
            padding: const EdgeInsets.fromLTRB(12, half + 12, 12, 12),
            child: widget.page,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _key,
            child: Container(
              height: SilicaTabView.segmentHeight,
              decoration: BoxDecoration(
                color: colors.segments,
                border: Border.all(color: colors.segmentsBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.labels.length; i++)
                    Semantics(
                      selected: i == widget.selected,
                      button: true,
                      label: widget.labels[i],
                      child: GestureDetector(
                        key: ValueKey('tab view $i'),
                        onTap: () {
                          _focus.requestFocus();
                          widget.onSelect(i);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == widget.selected ? colors.chosen : null,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            widget.labels[i],
                            style: containerText(
                              13,
                              i == widget.selected
                                  ? colors.textChosen
                                  : colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
