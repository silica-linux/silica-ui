// The modular pieces of title bars and toolbars (kit `Titlebars/Piece/*`): each piece is a
// full-height slot of a bar with its own horizontal padding, its content centred vertically.
//
// - Controls: the window controls, 96 wide.
// - Title, Title + Subtitle, Title + Document Icon: 8 on each side.
// - Item (Sidebar Toggle, Nav, Item Group 2/3/4, Segmented, Segmented 4, Segmented Text,
//   Search, Search Token, Share, More, Add and the app pieces): a control with 4 on each side,
//   so two controls are 8 apart (`components.md`). Add and Mail Send end with 8 and 16.
// - Spacer: takes the free width (at least 8).

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'text_box.dart';
import 'glyphs.dart';
import 'window_controls.dart';
import 'window_scope.dart';

/// The measures of the pieces.
abstract final class AmalfiToolbarPieceMetrics {
  /// The width of the controls piece.
  static const double controlsWidth = 96;

  /// The padding of an item piece on each side (8 between two controls).
  static const double itemPadding = 4;

  /// The padding of a title piece on each side.
  static const double titlePadding = 8;

  /// Between the document icon, the title and the chevron.
  static const double titleGap = 4;

  /// The narrowest a spacer gets.
  static const double spacerMinWidth = 8;

  /// The document icon and the chevron of a document title.
  static const double documentIcon = 16, chevron = 12;
}

/// A piece of a bar: [child] centred vertically in the bar's height, with [padding] before and
/// after it (kit `Titlebars/Piece/*`).
///
/// Bars give their pieces the bar's height; outside a bar the piece is as tall as its child.
class AmalfiToolbarPiece extends StatelessWidget {
  const AmalfiToolbarPiece({
    super.key,
    this.leading = AmalfiToolbarPieceMetrics.itemPadding,
    this.trailing = AmalfiToolbarPieceMetrics.itemPadding,
    required this.child,
  });

  /// An item piece that ends with 8 (kit `Piece/Add`).
  const AmalfiToolbarPiece.add({super.key, required this.child})
    : leading = AmalfiToolbarPieceMetrics.itemPadding,
      trailing = 8;

  /// The padding before and after [child].
  final double leading, trailing;

  /// The control (a toolbar button, an action group, a segmented control, a search field).
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: leading, right: trailing),
    child: Center(widthFactor: 1, child: child),
  );
}

/// The window controls as a piece (kit `Titlebars/Piece/Controls`): 96 wide, the controls
/// placed by the measured rule for the bar's height ([AmalfiWindowControlsMetrics.leadingFor]:
/// x 18, y 18 in a 52 pt bar).
class AmalfiControlsPiece extends StatelessWidget {
  const AmalfiControlsPiece({
    super.key,
    this.onClose,
    this.onMinimise,
    this.onZoom,
    this.active,
    this.width = AmalfiToolbarPieceMetrics.controlsWidth,
  });

  final VoidCallback? onClose, onMinimise, onZoom;

  /// Whether the window is active; null: from [AmalfiWindowScope].
  final bool? active;

  /// The width of the piece.
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : AmalfiToolbarMetrics.toolbarHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: AmalfiWindowControlsMetrics.leadingFor(height),
              top: AmalfiWindowControlsMetrics.topFor(height),
              child: AmalfiWindowControlGroup(
                onClose: onClose,
                onMinimise: onMinimise,
                onZoom: onZoom,
                active: active,
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// The window title as a piece (kit `Titlebars/Piece/Title`, `Title + Subtitle`,
/// `Title + Document Icon`).
///
/// [title] in Headline, `Text/Primary` (`Text/Tertiary` in an inactive window); [subtitle]
/// below it in Caption `Text/Tertiary`, the two centred on each other; with [document] a
/// 16 pt document icon before the title and a chevron after it, and [onDocumentMenu] runs
/// when the title is clicked (the document menu). Text boxes are rounded up to the 4 pt grid.
class AmalfiTitlePiece extends StatelessWidget {
  const AmalfiTitlePiece({
    super.key,
    required this.title,
    this.subtitle,
    this.document = false,
    this.onDocumentMenu,
    this.active,
  });

  final String title;

  /// A second line (the edit date); null: none.
  final String? subtitle;

  /// Whether to show the document icon and the chevron.
  final bool document;

  /// Runs when a document title is clicked; null: not clickable.
  final VoidCallback? onDocumentMenu;

  /// Whether the window is active; null: from [AmalfiWindowScope].
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final active = amalfiResolveActive(context, this.active);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AmalfiToolbarPieceMetrics.titlePadding,
      ),
      child: Center(
        widthFactor: 1,
        child: AmalfiTitleBlock(
          title: title,
          subtitle: subtitle,
          document: document,
          onDocumentMenu: onDocumentMenu,
          active: active,
        ),
      ),
    );
  }
}

/// The title text of a bar: [title], optionally with [subtitle] below or with the document
/// icon and chevron around it. Used by [AmalfiTitlePiece] and `AmalfiTitleBar`.
class AmalfiTitleBlock extends StatelessWidget {
  const AmalfiTitleBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.document = false,
    this.onDocumentMenu,
    this.active,
    this.maxLines = 1,
  });

  final String title;
  final String? subtitle;
  final bool document;
  final VoidCallback? onDocumentMenu;

  /// Whether the window is active; null: from [AmalfiWindowScope].
  final bool? active;

  /// The lines of the title (1: ellipsis).
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final active = amalfiResolveActive(context, this.active);
    final titleText = AmalfiChromeTextBox(
      child: Text(
        title,
        maxLines: maxLines,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AmalfiType.headline(
          color: active ? colors.textPrimary : colors.textTertiary,
        ),
      ),
    );
    final subtitle = this.subtitle;
    Widget block;
    if (subtitle != null) {
      block = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleText,
          AmalfiChromeTextBox(
            child: Text(
              subtitle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.caption(color: colors.textTertiary),
            ),
          ),
        ],
      );
    } else if (document) {
      block = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmalfiChromeGlyph(
            AmalfiChromeGlyphs.doc,
            size: AmalfiToolbarPieceMetrics.documentIcon,
            color: active ? colors.textSecondary : colors.textTertiary,
          ),
          const SizedBox(width: AmalfiToolbarPieceMetrics.titleGap),
          Flexible(child: titleText),
          const SizedBox(width: AmalfiToolbarPieceMetrics.titleGap),
          AmalfiChromeGlyph(
            AmalfiChromeGlyphs.chevronDown,
            size: AmalfiToolbarPieceMetrics.chevron,
            color: colors.textTertiary,
          ),
        ],
      );
    } else {
      block = titleText;
    }
    final menu = onDocumentMenu;
    return Semantics(
      header: true,
      button: menu != null,
      onTap: menu,
      child: menu == null
          ? block
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: menu,
              child: MouseRegion(child: block),
            ),
    );
  }
}

/// A flexible gap between pieces (kit `Titlebars/Piece/Spacer`): it takes the free width of
/// the bar ([flex] shares), and is at least 8 wide.
class AmalfiSpacerPiece extends StatelessWidget {
  const AmalfiSpacerPiece({super.key, this.flex = 1});

  final int flex;

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: AmalfiToolbarPieceMetrics.spacerMinWidth);
}

/// The measures of the bars (`components.md`: toolbar 52, title-only 32, compact 40).
abstract final class AmalfiToolbarMetrics {
  /// The unified toolbar and the split toolbar sections.
  static const double toolbarHeight = 52;

  /// The compact toolbar.
  static const double compactHeight = 40;

  /// The title-only bar.
  static const double titleOnlyHeight = 32;

  /// The title bar of a document or panel window, with its separator.
  static const double titleBarHeight = 48;

  /// The padding of the unified toolbar after its last piece (kit `Bar/Unified/Full Inset
  /// 8`, the bar of the window layouts: the last control ends 12 from the edge).
  static const EdgeInsets unifiedPadding = EdgeInsets.only(right: 8);

  /// The wider end padding (kit `Bar/Unified/Full Inset 16`: the last control ends 20 from
  /// the edge).
  static const EdgeInsets unifiedPaddingWide = EdgeInsets.only(right: 16);

  /// The padding of a content, list or inspector section of a split toolbar.
  static const EdgeInsets sectionPadding = EdgeInsets.only(left: 12, right: 8);

  /// The padding of the sidebar section (it starts with the controls piece).
  static const EdgeInsets sidebarSectionPadding = EdgeInsets.only(right: 8);
}
