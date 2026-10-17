// Title bars and toolbars (kit `Titlebars/Bar/*`, `Titlebars/Section/*`,
// `Titlebars/Title Bar/*`): flat bars on the window surface built from pieces.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../controls/control_base.dart' show WindowActiveScope;

import '../../theme.dart';
import '../../tokens.g.dart';
import 'pieces.dart';
import 'text_box.dart';
import 'window_controls.dart';
import 'window_scope.dart';

/// The surface a bar is drawn on.
enum AmalfiToolbarSurface {
  /// `Surface/Window`: the unified toolbar and the content and list sections.
  window,

  /// `Surface/Sidebar`: the sidebar and inspector sections of a split toolbar.
  sidebar,

  /// The blur strip `Blur/Sidebar Title Bar` (background blur 10, `Surface/Sidebar` at 80 %,
  /// no glass, rim, shadow or line under it): the sidebar section of a split title bar, over a
  /// sidebar that scrolls under it (`AmalfiSidebarPanel.topInset`).
  blur,

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
/// glass. [active] null follows the [WindowActiveScope]; a non-null value also sets it for the
/// pieces below.
class AmalfiToolbar extends StatelessWidget {
  /// The unified toolbar: 52 tall, ending with [AmalfiToolbarMetrics.unifiedPadding].
  const AmalfiToolbar({
    super.key,
    required this.children,
    this.height = AmalfiToolbarMetrics.toolbarHeight,
    this.padding = AmalfiToolbarMetrics.unifiedPadding,
    this.surface = AmalfiToolbarSurface.window,
    this.separator = false,
    this.active,
  }) : spacing = 0;

  /// The compact toolbar: 40 tall, its children 8 apart between paddings of 20 and 16. Its
  /// children are bare controls: `AmalfiControlsPiece(width: AmalfiToolbarMetrics
  /// .compactControlsWidth, leading: 0)`, buttons, and an `Expanded` `AmalfiTitlePiece(fill:
  /// true)`.
  const AmalfiToolbar.compact({
    super.key,
    required this.children,
    this.surface = AmalfiToolbarSurface.window,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.compactHeight,
       padding = AmalfiToolbarMetrics.compactPadding,
       spacing = AmalfiToolbarMetrics.compactGap;

  /// A section of a split toolbar (kit `Titlebars/Section/Content|List|Inspector`): 52 tall,
  /// 12 before the first piece and 8 after the last.
  const AmalfiToolbar.section({
    super.key,
    required this.children,
    this.padding = AmalfiToolbarMetrics.sectionPadding,
    this.surface = AmalfiToolbarSurface.window,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.toolbarHeight,
       spacing = 0;

  /// The sidebar section of a split toolbar (kit `Titlebars/Section/Sidebar`): on
  /// `Surface/Sidebar`, starting with the controls piece, 8 after the last piece.
  ///
  /// With [AmalfiToolbarSurface.blur] the section is a blur strip over the sidebar, which scrolls
  /// under it. No divider runs along its trailing edge (`components.md`, user decision
  /// 2026-10-17).
  const AmalfiToolbar.sidebarSection({
    super.key,
    required this.children,
    this.padding = AmalfiToolbarMetrics.sidebarSectionPadding,
    this.surface = AmalfiToolbarSurface.sidebar,
    this.separator = false,
    this.active,
  }) : height = AmalfiToolbarMetrics.toolbarHeight,
       spacing = 0;

  final List<Widget> children;

  /// The bar height (52, or 40 compact).
  final double height;

  /// The padding before the first and after the last piece.
  final EdgeInsets padding;

  /// The gap between the children (the compact bar's 8; pieces carry their own padding).
  final double spacing;

  final AmalfiToolbarSurface surface;

  /// Whether to draw a 1 pt `Line/Separator` along the bottom, inside the bar.
  final bool separator;

  /// Whether the window is active; null: from [WindowActiveScope].
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
          spacing: spacing,
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
    final content = SizedBox(
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
    );
    bar = surface == AmalfiToolbarSurface.blur
        ? ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: AmalfiBlurs.sidebarTitleBar.backgroundBlur,
                sigmaY: AmalfiBlurs.sidebarTitleBar.backgroundBlur,
                tileMode: TileMode.clamp,
              ),
              child: ColoredBox(
                color: AmalfiBlurs.sidebarTitleBar.tint(
                  AmalfiTheme.of(context).brightness,
                ),
                child: content,
              ),
            ),
          )
        : ColoredBox(
            color: switch (surface) {
              AmalfiToolbarSurface.window => colors.surfaceWindow,
              AmalfiToolbarSurface.sidebar => colors.surfaceSidebar,
              _ => const Color(0x00000000),
            },
            child: content,
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: active == null
          ? bar
          : WindowActiveScope(active: active, child: bar),
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

  /// Whether the window is active; null: from [WindowActiveScope].
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
    final active = amalfiTitlebarResolveActive(context, this.active);
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
            child: AmalfiTitlebarTextBox(
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
    return WindowActiveScope(
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
