// Windows (kit `Windows/*`): the window frame and the layouts of its regions.
//
// `materials.md`: windows are flat and opaque, split into regions (toolbar, sidebar, list,
// content, inspector) by 1 pt `Line/Separator` lines; only the window as a whole has a shadow
// (`shadows.3`). Corner 18 (`components.md`), 14 for utility windows (kit
// `Windows/Window/Utility`).

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../../controls/control_base.dart' show WindowActiveScope;

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../titlebars/pieces.dart';

/// The kind of window frame.
enum AmalfiWindowKind {
  /// A document or app window: corner 18.
  regular,

  /// A utility window (a floating find panel, an inspector): corner 14.
  utility,
}

/// The measures of the window frame and layouts.
abstract final class AmalfiWindowMetrics {
  /// The corner of a regular window.
  static const double radius = AmalfiRadii.window;

  /// The corner of a utility window (kit `Windows/Window/Utility`).
  static const double utilityRadius = 14;

  /// The sidebar width (`components.md`).
  static const double sidebarWidth = 240;

  /// The inspector width (`components.md`).
  static const double inspectorWidth = 260;

  /// The list column of a three-column window (kit `Split Toolbar Three Columns`).
  static const double listWidth = 320;

  /// The separator width.
  static const double separator = 1;
}

/// A window frame: `Surface/Window` with smooth corners, the window shadow (`shadows.3`) and a
/// 1 pt `Line/Border` rim inside the edge, [child] clipped to the corners.
///
/// It also tells the chrome below whether the window is [active] ([WindowActiveScope]).
/// [shadow] false leaves the shadow to the compositor (a real toplevel window); the gallery and
/// tests draw it. Ossido also draws the 1 pt `Line/Border` rim of every toplevel window, so a
/// window without [shadow] draws no rim of its own ([rim] defaults to [shadow]): two rims on top
/// of each other double the edge's alpha (silica-desktop#212).
class AmalfiWindow extends StatelessWidget {
  const AmalfiWindow({
    super.key,
    required this.child,
    this.active = true,
    this.kind = AmalfiWindowKind.regular,
    this.shadow = true,
    bool? rim,
  }) : rim = rim ?? shadow;

  final Widget child;
  final bool active;
  final AmalfiWindowKind kind;
  final bool shadow;

  /// Whether to draw the 1 pt rim inside the edge.
  final bool rim;

  /// The corner radius of [kind].
  static double radiusOf(AmalfiWindowKind kind) => switch (kind) {
    AmalfiWindowKind.regular => AmalfiWindowMetrics.radius,
    AmalfiWindowKind.utility => AmalfiWindowMetrics.utilityRadius,
  };

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final radius = radiusOf(kind);
    final shape = AmalfiSmoothBorder(radius: radius);
    return WindowActiveScope(
      active: active,
      child: DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: colors.surfaceWindow,
          shape: shape,
          shadows: shadow ? theme.shadows.level3 : null,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: ColoredBox(color: colors.surfaceWindow, child: child),
            ),
            if (rim)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: AmalfiShapeDecoration(
                      shape: AmalfiSmoothBorder(
                        radius: radius,
                        side: BorderSide(
                          color: colors.lineBorder,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 1 pt `Line/Separator` line, as wide or tall as it is placed.
class AmalfiWindowSeparator extends StatelessWidget {
  const AmalfiWindowSeparator({super.key});

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AmalfiTheme.of(context).colors.lineSeparator);
}

/// The regions of a window under one bar (kit `Windows/Unified Toolbar`, `Unified Toolbar
/// Sidebar`, `Sidebar Collapsed`, `Compact Toolbar`, `Title Only`, `Window/Document`,
/// `Window/Sidebar Inspector`): [bar] across the top, [barHeight] tall, then the [sidebar],
/// the [content] and the [inspector] side by side.
///
/// Separators are drawn over the regions at their edges: under the bar ([barSeparator])
/// and along the leading edge of the inspector. The sidebar draws its own trailing edge (an
/// `AmalfiSidebarPanel` with `edge`, the kit's single sidebar edge, inside its width). With
/// [sidesUnderBar] the sidebar and the inspector run up to the top of the window, behind a
/// transparent bar (the bar must then use `AmalfiToolbarSurface.none`), the line under the
/// bar only spans the content, and the sidebar's edge continues up beside the bar.
class AmalfiWindowLayout extends StatelessWidget {
  const AmalfiWindowLayout({
    super.key,
    this.bar,
    this.barHeight = AmalfiToolbarMetrics.toolbarHeight,
    this.barSeparator = false,
    this.sidebar,
    this.sidebarWidth = AmalfiWindowMetrics.sidebarWidth,
    this.inspector,
    this.inspectorWidth = AmalfiWindowMetrics.inspectorWidth,
    this.sidesUnderBar = false,
    required this.content,
  });

  final Widget? bar;
  final double barHeight;
  final bool barSeparator;
  final Widget? sidebar;
  final double sidebarWidth;
  final Widget? inspector;
  final double inspectorWidth;
  final bool sidesUnderBar;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final bar = this.bar;
    final sidebar = this.sidebar;
    final inspector = this.inspector;
    final top = bar == null ? 0.0 : barHeight;
    final sideTop = sidesUnderBar ? 0.0 : top;
    final left = sidebar == null ? 0.0 : sidebarWidth;
    final right = inspector == null ? 0.0 : inspectorWidth;
    const line = AmalfiWindowMetrics.separator;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (sidebar != null)
          Positioned(
            left: 0,
            top: sideTop,
            bottom: 0,
            width: sidebarWidth,
            child: ColoredBox(color: colors.surfaceSidebar, child: sidebar),
          ),
        if (inspector != null)
          Positioned(
            right: 0,
            top: sideTop,
            bottom: 0,
            width: inspectorWidth,
            child: ColoredBox(color: colors.surfaceSidebar, child: inspector),
          ),
        Positioned(
          left: left,
          right: right,
          top: top,
          bottom: 0,
          child: content,
        ),
        if (bar != null)
          Positioned(left: 0, right: 0, top: 0, height: barHeight, child: bar),
        if (bar != null && barSeparator)
          Positioned(
            left: sidesUnderBar ? left : 0,
            right: sidesUnderBar ? right : 0,
            top: top,
            height: line,
            child: const AmalfiWindowSeparator(),
          ),
        if (sidebar != null && sidesUnderBar && bar != null)
          Positioned(
            left: sidebarWidth - line,
            top: 0,
            height: top,
            width: line,
            child: const AmalfiWindowSeparator(),
          ),
        if (inspector != null)
          Positioned(
            right: inspectorWidth - line,
            top: sidesUnderBar ? 0 : top,
            bottom: 0,
            width: line,
            child: const AmalfiWindowSeparator(),
          ),
      ],
    );
  }
}

/// A column of a split window: its own toolbar section ([toolbar], 52 tall) over its [child].
@immutable
class AmalfiWindowColumn {
  const AmalfiWindowColumn({
    required this.child,
    this.toolbar,
    this.width,
    this.toolbarOverChild = false,
    this.ownEdge = false,
  });

  /// The column's region (the sidebar, a list, the content, the inspector).
  final Widget child;

  /// The toolbar section on top of it (`AmalfiToolbar.section`, `.sidebarSection`); null:
  /// none.
  final Widget? toolbar;

  /// The width; null: this column takes the free width (one column should).
  final double? width;

  /// Whether [child] runs up to the top, under the toolbar (a sidebar whose surface continues
  /// behind its section, kit `Windows/Sidebar Body/Full`).
  final bool toolbarOverChild;

  /// Whether [child] draws its own trailing edge (a sidebar: `AmalfiSidebarPanel` with
  /// `edge`), so no separator follows the column.
  final bool ownEdge;
}

/// A window split into columns, each with its own toolbar section (kit `Windows/Split
/// Toolbar`, `Split Toolbar Inspector`, `Split Toolbar Three Columns`), with a full-height
/// separator over every boundary between columns, except after a column that draws its own
/// edge ([AmalfiWindowColumn.ownEdge], the sidebar).
class AmalfiSplitWindowLayout extends StatelessWidget {
  const AmalfiSplitWindowLayout({
    super.key,
    required this.columns,
    this.toolbarHeight = AmalfiToolbarMetrics.toolbarHeight,
  });

  final List<AmalfiWindowColumn> columns;
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fixed = columns.fold<double>(0, (sum, c) => sum + (c.width ?? 0));
      final flexible = columns.where((c) => c.width == null).length;
      final total = constraints.hasBoundedWidth ? constraints.maxWidth : fixed;
      final share = flexible == 0
          ? 0.0
          : ((total - fixed) / flexible).clamp(0.0, double.infinity);
      final children = <Widget>[];
      final lines = <Widget>[];
      var x = 0.0;
      for (var i = 0; i < columns.length; i++) {
        final c = columns[i];
        final w = c.width ?? share;
        final toolbar = c.toolbar;
        final childTop = toolbar == null || c.toolbarOverChild
            ? 0.0
            : toolbarHeight;
        children.add(
          Positioned(
            left: x,
            width: w,
            top: childTop,
            bottom: 0,
            child: c.child,
          ),
        );
        if (toolbar != null) {
          children.add(
            Positioned(
              left: x,
              width: w,
              top: 0,
              height: toolbarHeight,
              child: toolbar,
            ),
          );
        }
        if (i > 0 && !columns[i - 1].ownEdge) {
          lines.add(
            Positioned(
              left: x,
              width: AmalfiWindowMetrics.separator,
              top: 0,
              bottom: 0,
              child: const AmalfiWindowSeparator(),
            ),
          );
        }
        x += w;
      }
      return Stack(fit: StackFit.expand, children: [...children, ...lines]);
    },
  );
}

/// The strip a full-screen window shows when the pointer reaches the top of the screen (kit
/// `Windows/Window/Full Screen Strip`): the menu bar (32 tall, 20 from each side), 12 below
/// it the window's toolbar (52), a separator, then [child] (the top of the window content).
class AmalfiFullScreenStrip extends StatelessWidget {
  const AmalfiFullScreenStrip({
    super.key,
    required this.menuBar,
    required this.toolbar,
    this.child,
  });

  /// The menu bar (the shell's).
  final Widget menuBar;

  /// The window's toolbar.
  final Widget toolbar;

  final Widget? child;

  /// The menu bar height, its side inset and the gap under it.
  static const double menuBarHeight = 32, menuBarInset = 20, gap = 12;

  /// Where the toolbar starts.
  static const double toolbarTop = menuBarHeight + gap;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    const separatorTop = toolbarTop + AmalfiToolbarMetrics.toolbarHeight;
    return ColoredBox(
      color: colors.surfaceWindow,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: menuBarInset,
            right: menuBarInset,
            top: 0,
            height: menuBarHeight,
            child: menuBar,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: toolbarTop,
            height: AmalfiToolbarMetrics.toolbarHeight,
            child: toolbar,
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: separatorTop,
            height: AmalfiWindowMetrics.separator,
            child: AmalfiWindowSeparator(),
          ),
          if (child case final child?)
            Positioned(
              left: 0,
              right: 0,
              top: separatorTop + AmalfiWindowMetrics.separator,
              bottom: 0,
              child: child,
            ),
        ],
      ),
    );
  }
}
