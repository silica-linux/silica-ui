// The full-height sidebar of a window with a unified toolbar (mustache#13, mail#7;
// titlebar.md, windows.md › Sidebar, mail.md › Viewer window). The sidebar runs from the top to
// the bottom of the window; its top [toolbarHeight] is a bar of its own, beside the content's
// toolbar and as tall: Ossido puts the window buttons on it, dragging it moves the window, and an
// app may put items in it (Mail's sidebar button). The first row is at +52 pt, so at rest nothing
// lies under the bar.
//
// SIDEBAR-GLASS (silica-reference #100, titlebar.md §4): when the list scrolls, the bar has NO
// glass, no tint and no line. The rows are hidden by a progressive fade, with a light blur:
//
//   y from the sidebar top   +62 and below  +60   +56   +52   +48   +44   +40   +36   +32  +0…+30
//   visibility of the rows    1.00          0.97  0.86  0.74  0.63  0.48  0.36  0.25  0.17  0.14
//   blur σ (pt)               0             0     0     0     1     1     1     1     2     2
//
// The window buttons and the bar's items sit over the faded rows.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../toolbar.dart' show ToolbarCapsule;
import '../../window.dart';
import 'scroll_under_toolbar.dart' show ToolbarVeil;

/// The measured fade of the rows that scroll under the top of a sidebar.
abstract final class SidebarFade {
  /// Distances from the sidebar top (pt) and the visibility of the rows there (0–1), light and
  /// dark alike (light within ±0.02).
  static const List<double> offsets = [
    0,
    30,
    32,
    36,
    40,
    44,
    48,
    52,
    56,
    60,
    62,
  ];
  static const List<double> visibility = [
    0.14, 0.14, 0.17, 0.25, 0.36, 0.48, 0.63, 0.74, 0.86, 0.97, 1.0, //
  ];

  /// Above this distance the rows are fully visible.
  static const double clearAt = 62;

  /// The visibility of a row at [y] pt from the sidebar top (linear between the samples).
  static double visibilityAt(double y) {
    if (y <= offsets.first) return visibility.first;
    if (y >= offsets.last) return 1;
    for (var i = 1; i < offsets.length; i++) {
      if (y <= offsets[i]) {
        final t = (y - offsets[i - 1]) / (offsets[i] - offsets[i - 1]);
        return visibility[i - 1] + t * (visibility[i] - visibility[i - 1]);
      }
    }
    return 1;
  }

  /// The blur σ (pt) at [y]: 2 up to +33, 1 up to +50, none from there.
  static double blurAt(double y) => y <= 33 ? 2 : (y < 50 ? 1 : 0);
}

/// A full-height sidebar with its own top bar: [bar] (optional items; keep the first
/// [windowButtonsRight] pt free for the window buttons) in the top [barHeight], and the list
/// returned by [body] filling the whole sidebar, with the padding that puts its first row below
/// the bar. The rows that scroll under the bar fade out ([SidebarFade]).
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

  /// The sidebar colour: painted under the list; the bar has no colour of its own.
  final Color background;

  /// The list: it gets the padding of the bar.
  final Widget Function(BuildContext context, EdgeInsets padding) body;

  /// Items in the bar ([ToolbarCapsule]s show the rows refracted at their edges). The bar
  /// moves the window wherever the items leave it empty.
  final Widget? bar;
  final double barHeight;

  /// No effect since 0.30.0, kept so that apps compile: the sidebar has no veil.
  final ToolbarVeil? veil;

  static ui.Shader _fade(Rect bounds) {
    final stops = [
      for (final y in SidebarFade.offsets) y / SidebarFade.clearAt,
    ];
    return ui.Gradient.linear(
      bounds.topLeft,
      bounds.topLeft + const Offset(0, SidebarFade.clearAt),
      [
        for (final v in SidebarFade.visibility)
          Color.fromARGB((v * 255).round(), 0, 0, 0),
      ],
      stops,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          Positioned.fill(
            child: ShaderMask(
              key: const ValueKey('sidebar fade'),
              blendMode: BlendMode.dstIn,
              shaderCallback: _fade,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: body(context, EdgeInsets.only(top: barHeight)),
                  ),
                  // Light blur of what lies in the top band: σ 2 up to +33, σ 1 up to +50.
                  for (final (top, height, sigma) in const [
                    (0.0, 33.0, 2.0),
                    (33.0, 17.0, 1.0),
                  ])
                    Positioned(
                      left: 0,
                      right: 0,
                      top: top,
                      height: height,
                      child: IgnorePointer(
                        child: ClipRect(
                          child: BackdropFilter(
                            key: ValueKey('sidebar blur $sigma'),
                            filter: ui.ImageFilter.blur(
                              sigmaX: sigma,
                              sigmaY: sigma,
                              tileMode: TileMode.clamp,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
