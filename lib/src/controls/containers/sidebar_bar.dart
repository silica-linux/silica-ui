// The full-height sidebar of a window with a unified toolbar (mustache#13, mail#7;
// titlebar.md, windows.md › Sidebar, mail.md › Viewer window). The sidebar runs from the top to
// the bottom of the window; its top [toolbarHeight] is a bar of its own, beside the content's
// toolbar and as tall: Ossido puts the window buttons on it, dragging it moves the window, and an
// app may put items in it (Mail's sidebar button). The list starts below the bar (Finder: the
// first row centred at y 68; Mail: "starts under the toolbar row") and scrolls under it, behind
// the same veil as the content under its toolbar, so the bar shows the rows blurred and tinted.
//
// At rest the bar has the sidebar colour, without a band: the veil is anchored to the sidebar
// background ([ToolbarVeil.anchoredTo]), active and inactive (windows.md: the inactive sidebar is
// uniform from top to bottom).
//
// PROVISIONAL (SIDEBAR-GLASS requested): the veil of the sidebar bar is the content's (MU-99),
// not measured over the sidebar; no line under the bar when the list scrolls.

import 'package:flutter/widgets.dart';

import '../../toolbar.dart' show ToolbarCapsule;
import '../../window.dart';
import 'scroll_under_toolbar.dart';

/// A full-height sidebar with its own top bar: [bar] (optional items; keep the first
/// [windowButtonsRight] pt free for the window buttons) in the top [barHeight], and the list
/// returned by [body] filling the whole sidebar, with the padding that puts its first row below
/// the bar.
///
/// ```dart
/// SidebarScrollUnderBar(
///   background: sidebarFill,
///   body: (context, padding) => ListView(padding: padding, children: rows),
/// )
/// ```
class SidebarScrollUnderBar extends StatelessWidget {
  const SidebarScrollUnderBar({
    super.key,
    required this.background,
    required this.body,
    this.bar,
    this.barHeight = toolbarHeight,
    this.veil,
  });

  /// The sidebar colour: painted under the list and kept by the bar at rest.
  final Color background;

  /// The list: it gets the padding of the bar.
  final Widget Function(BuildContext context, EdgeInsets padding) body;

  /// Items in the bar ([ToolbarCapsule]s show the rows refracted at their edges). The bar
  /// moves the window wherever the items leave it empty.
  final Widget? bar;
  final double barHeight;

  /// Null: following the system appearance.
  final ToolbarVeil? veil;

  @override
  Widget build(BuildContext context) {
    final veil = (this.veil ?? ToolbarVeil.of(context)).anchoredTo(background);
    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          Positioned.fill(
            child: body(context, EdgeInsets.only(top: barHeight)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: barHeight,
            child: ToolbarVeilLayer(veil: veil, name: 'sidebar bar veil'),
          ),
          Positioned(
            key: const ValueKey('sidebar bar'),
            left: 0,
            right: 0,
            top: 0,
            height: barHeight,
            child: WindowDragArea(
              child: ToolbarOverContent(
                child: Stack(
                  fit: StackFit.expand,
                  children: [const SizedBox.expand(), ?bar],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A window split into a full-height sidebar and the content: the sidebar [width] wide, shown
/// by [shown] (0 hidden … 1 shown; while hiding it slides out to the left keeping its width and
/// the content widens), the content from its edge to the right of the window. The content keeps
/// its own toolbar ([ScrollUnderToolbar]); with the sidebar hidden the window buttons fall on
/// it, so its first items start after [contentLeadingInset].
class SidebarLayout extends StatelessWidget {
  const SidebarLayout({
    super.key,
    required this.sidebar,
    required this.content,
    required this.width,
    this.shown = 1,
  });

  final Widget sidebar;
  final Widget content;
  final double width;
  final double shown;

  /// The visible width of the sidebar.
  double get visibleWidth => width * shown.clamp(0.0, 1.0);

  /// How far the content's toolbar items keep from its left edge so that they clear the window
  /// buttons, for a sidebar `visible` pt wide: 0 with the sidebar shown.
  static double contentLeadingInset(double visible) =>
      (windowButtonsRight - visible).clamp(0.0, windowButtonsRight);

  @override
  Widget build(BuildContext context) {
    final visible = visibleWidth;
    return Stack(
      children: [
        if (visible > 0)
          Positioned(
            left: visible - width,
            top: 0,
            bottom: 0,
            width: width,
            child: sidebar,
          ),
        Positioned(left: visible, top: 0, right: 0, bottom: 0, child: content),
      ],
    );
  }
}
