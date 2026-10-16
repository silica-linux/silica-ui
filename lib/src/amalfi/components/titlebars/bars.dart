// Title bars and toolbars (kit `Titlebars/Bar/*`, `Titlebars/Section/*`,
// `Titlebars/Title Bar/*`): flat bars on the window surface built from pieces.

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'pieces.dart';
import 'text_box.dart';
import 'window_controls.dart';
import 'window_scope.dart';

/// The surface a bar is drawn on.
enum AmalfiBarSurface {
  /// `Surface/Window`: the unified toolbar and the content and list sections.
  window,

  /// `Surface/Sidebar`: the sidebar and inspector sections of a split toolbar.
  sidebar,

  /// None: the bar is drawn over the regions under it (a sidebar and an inspector that run
  /// to the top of the window, kit `Windows/Window/Sidebar Inspector`).
  none,
}

/// A toolbar built from pieces (kit `Titlebars/Bar/Unified`, `Bar/Compact`,
/// `Titlebars/Section/*`).
///
/// [children] are pieces ([AmalfiControlsPiece], [AmalfiTitlePiece], [AmalfiToolbarPiece],
/// [AmalfiSpacerPiece]) laid out in a row as tall as the bar; each [AmalfiSpacerPiece] takes
/// a share of the free width. The bar is flat (`materials.md`): only the controls in it are
/// glass. [active] null follows the [AmalfiWindowScope]; a non-null value also sets it for the
/// pieces below.
class AmalfiToolbar extends StatelessWidget {
  /// The unified toolbar: 52 tall, ending with [AmalfiToolbarMetrics.unifiedPadding].
  const AmalfiToolbar({
    super.key,
    required this.children,
    this.height = AmalfiToolbarMetrics.toolbarHeight,
    this.padding = AmalfiToolbarMetrics.unifiedPadding,
    this.surface = AmalfiBarSurface.window,
    this.separator = false,
    this.active,
  });

  /// The compact toolbar: 40 tall.
  const AmalfiToolbar.compact({
    super.key,
    required this.children,
    this.padding = AmalfiToolbarMetrics.unifiedPadding,
    this.surface = AmalfiBarSurface.window,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.compactHeight;

  /// A section of a split toolbar (kit `Titlebars/Section/Content|List|Inspector`): 52 tall,
  /// 12 before the first piece and 8 after the last.
  const AmalfiToolbar.section({
    super.key,
    required this.children,
    this.padding = AmalfiToolbarMetrics.sectionPadding,
    this.surface = AmalfiBarSurface.window,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.toolbarHeight;

  /// The sidebar section of a split toolbar (kit `Titlebars/Section/Sidebar`): on
  /// `Surface/Sidebar`, starting with the controls piece, 8 after the last piece.
  const AmalfiToolbar.sidebarSection({
    super.key,
    required this.children,
    this.padding = AmalfiToolbarMetrics.sidebarSectionPadding,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.toolbarHeight,
       surface = AmalfiBarSurface.sidebar;

  final List<Widget> children;

  /// The bar height (52, or 40 compact).
  final double height;

  /// The padding before the first and after the last piece.
  final EdgeInsets padding;

  final AmalfiBarSurface surface;

  /// Whether to draw a 1 pt `Line/Separator` along the bottom, inside the bar.
  final bool separator;

  /// Whether the window is active; null: from [AmalfiWindowScope].
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final active = this.active;
    Widget bar = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedWidth;
        return Row(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              if (child is AmalfiSpacerPiece && bounded)
                Expanded(flex: child.flex, child: child)
              else
                child,
          ],
        );
      },
    );
    bar = ColoredBox(
      color: switch (surface) {
        AmalfiBarSurface.window => colors.surfaceWindow,
        AmalfiBarSurface.sidebar => colors.surfaceSidebar,
        AmalfiBarSurface.none => const Color(0x00000000),
      },
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Padding(padding: padding, child: bar),
            if (separator)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1,
                child: ColoredBox(color: colors.lineSeparator),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: active == null
          ? bar
          : AmalfiWindowScope(active: active, child: bar),
    );
  }
}

/// The kind of [AmalfiTitleBar].
enum AmalfiTitleBarStyle {
  /// Kit `Titlebars/Bar/Title Only`: 32 tall, the title centred across the bar, no
  /// separator.
  titleOnly,

  /// Kit `Titlebars/Title Bar/*`: 48 tall, the title block centred, a separator along the
  /// bottom, drawn over the window surface (no fill of its own).
  standard,

  /// The bar of a utility window (kit `Windows/Window/Utility`): 40 tall, the title in Label
  /// `Text/Secondary` at x 100, no separator, no fill of its own.
  utility,
}

/// A title bar: the window controls and a centred title (kit `Titlebars/Bar/Title Only`,
/// `Titlebars/Title Bar/Plain|Subtitle|Document`).
///
/// [subtitle] and [document] work as in [AmalfiTitlePiece]. The controls sit by the measured
/// rule ([AmalfiWindowControlsMetrics.leadingFor]), vertically centred.
class AmalfiTitleBar extends StatelessWidget {
  const AmalfiTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.document = false,
    this.onDocumentMenu,
    this.style = AmalfiTitleBarStyle.standard,
    this.onClose,
    this.onMinimise,
    this.onZoom,
    this.active,
  });

  final String title;
  final String? subtitle;
  final bool document;
  final VoidCallback? onDocumentMenu;
  final AmalfiTitleBarStyle style;
  final VoidCallback? onClose, onMinimise, onZoom;

  /// Whether the window is active; null: from [AmalfiWindowScope].
  final bool? active;

  /// The height of [style].
  static double heightOf(AmalfiTitleBarStyle style) => switch (style) {
    AmalfiTitleBarStyle.titleOnly => AmalfiToolbarMetrics.titleOnlyHeight,
    AmalfiTitleBarStyle.standard => AmalfiToolbarMetrics.titleBarHeight,
    AmalfiTitleBarStyle.utility => AmalfiToolbarMetrics.compactHeight,
  };

  /// The x of a utility bar's title (kit: after the controls, 20 apart).
  static const double utilityTitleX = 100;

  /// The room kept free on each side of a title-only bar's title: the bar padding (20) and a
  /// balance as wide as the kit's controls (64).
  static const double titleOnlyInset = 84;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final active = amalfiResolveActive(context, this.active);
    final height = heightOf(style);
    final titleOnly = style == AmalfiTitleBarStyle.titleOnly;
    final Widget title = switch (style) {
      AmalfiTitleBarStyle.titleOnly => Positioned(
        left: titleOnlyInset,
        right: titleOnlyInset,
        top: (height - (AmalfiType.headlineToken.lineHeight ?? 18)) / 2,
        child: Semantics(
          header: true,
          child: Text(
            this.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AmalfiType.headline(
              color: active ? colors.textPrimary : colors.textTertiary,
            ),
          ),
        ),
      ),
      AmalfiTitleBarStyle.utility => Positioned(
        left: utilityTitleX,
        right: AmalfiWindowControlsMetrics.leadingFor(height),
        top: (height - (AmalfiType.labelToken.lineHeight ?? 14)) / 2,
        child: Semantics(
          header: true,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AmalfiChromeTextBox(
              child: Text(
                this.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AmalfiType.label(
                  color: active ? colors.textSecondary : colors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
      AmalfiTitleBarStyle.standard => Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: titleOnlyInset + 12),
          child: Center(
            child: AmalfiTitleBlock(
              title: this.title,
              subtitle: subtitle,
              document: document,
              onDocumentMenu: onDocumentMenu,
            ),
          ),
        ),
      ),
    };
    return AmalfiWindowScope(
      active: active,
      child: ColoredBox(
        color: titleOnly ? colors.surfaceWindow : const Color(0x00000000),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              title,
              Positioned(
                left: AmalfiWindowControlsMetrics.leadingFor(height),
                top: AmalfiWindowControlsMetrics.topFor(height),
                child: AmalfiWindowControlGroup(
                  onClose: onClose,
                  onMinimise: onMinimise,
                  onZoom: onZoom,
                ),
              ),
              if (style == AmalfiTitleBarStyle.standard)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 1,
                  child: ColoredBox(color: colors.lineSeparator),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
