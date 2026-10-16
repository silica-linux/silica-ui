// The sidebar (kit `Sidebars/*`): rows, section headers, collapsible groups, count badges, the
// footer and the panel that stacks them.
//
// Layout (`components.md`, binding): width 240, horizontal padding 12, rows 28 tall on a 32 pt
// pitch (4 between rows), the selection capsule the full row width with radius 8, the row
// icon 16 at x 12 and the label at x 36; a section header is 28 tall with its title 8 below
// its top; 8 more between the last row of a section and the next header.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../titlebars/text_box.dart';

/// The measures of the sidebar.
abstract final class AmalfiSidebarMetrics {
  /// The sidebar width (min [minWidth]).
  static const double width = 240, minWidth = 200;

  /// The horizontal padding of the panel.
  static const double padding = 12;

  /// The row and header height.
  static const double rowHeight = 28;

  /// Between two rows (pitch 32).
  static const double rowGap = 4;

  /// Added before a header that follows a row (8 between sections).
  static const double sectionGap = 8;

  /// The selection and hover capsule radius.
  static const double radius = 8;

  /// The padding inside a row, the row icon and the gap after it.
  static const double rowPadding = 12, icon = 16, iconGap = 8;

  /// The space above a header's title inside the header.
  static const double headerTop = 8;

  /// The disclosure chevron of a header.
  static const double chevron = 12;

  /// The footer height and its buttons (kit `Buttons/Icon/Square/Small`).
  static const double footerHeight = 36, footerButton = 24;

  /// The badge: 16 tall, 8 on each side of the count.
  static const double badgeHeight = 16, badgePadding = 8;

  /// The narrowest badge (twice its height: a one- or two-digit count is a 32 pt pill).
  static const double badgeMinWidth = 32;
}

/// A count in a pill (kit `Sidebars/Badge`): Caption `Text/Secondary` on `Surface/Raised` with
/// a `Line/Border` rim, 16 tall, 8 on each side of the count and at least 32 wide.
class AmalfiSidebarBadge extends StatelessWidget {
  const AmalfiSidebarBadge(this.label, {super.key});

  /// The count (`12`).
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return DecoratedBox(
      decoration: AmalfiShapeDecoration(
        color: colors.surfaceRaised,
        shape: AmalfiSmoothBorder(
          radius: AmalfiSidebarMetrics.badgeHeight / 2,
          side: BorderSide(
            color: colors.lineBorder,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: SizedBox(
        height: AmalfiSidebarMetrics.badgeHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmalfiSidebarMetrics.badgePadding,
          ),
          child: Center(
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth:
                    AmalfiSidebarMetrics.badgeMinWidth -
                    2 * AmalfiSidebarMetrics.badgePadding,
              ),
              child: AmalfiTitlebarTextBox(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: AmalfiType.caption(color: colors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sidebar row (kit `Sidebars/Row/Plain|Badge`): a 16 pt [icon] and [label], an optional
/// [badge] at the end.
///
/// Selected: `Accent/Amalfi Soft` capsule, the label in Body Emphasis and the icon in the
/// accent. Under the pointer: a `Line/Separator` capsule. Disabled ([onTap] null and not
/// [selected]): the whole row at `AmalfiStates.disabledOpacity`. Enter or Space activates a focused row.
class AmalfiSidebarRow extends StatefulWidget {
  const AmalfiSidebarRow({
    super.key,
    required this.label,
    this.icon,
    this.badge,
    this.selected = false,
    this.onTap,
    this.enabled = true,
  });

  final String label;

  /// The Icon Kit glyph; null: an empty 16 pt slot.
  final AmalfiGlyphData? icon;

  /// The count shown in a badge; null: none.
  final String? badge;

  final bool selected;
  final VoidCallback? onTap;

  /// Whether the row can be chosen; a disabled row is dimmed and ignores the pointer.
  final bool enabled;

  @override
  State<AmalfiSidebarRow> createState() => _AmalfiSidebarRowState();
}

class _AmalfiSidebarRowState extends State<AmalfiSidebarRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = widget.enabled;
    final selected = widget.selected && enabled;
    final hovered = _hovered && enabled && !selected;
    final iconColor = selected ? colors.accentAmalfi : colors.textSecondary;
    final labelStyle = selected
        ? AmalfiType.bodyEmphasis(color: colors.textPrimary)
        : AmalfiType.body(color: colors.textPrimary);
    final icon = widget.icon;
    final badge = widget.badge;
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AmalfiSidebarMetrics.rowPadding,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: AmalfiSidebarMetrics.icon,
            child: icon == null
                ? null
                : AmalfiGlyph(
                    icon,
                    size: AmalfiSidebarMetrics.icon,
                    color: iconColor,
                  ),
          ),
          const SizedBox(width: AmalfiSidebarMetrics.iconGap),
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AmalfiSidebarMetrics.iconGap),
            AmalfiSidebarBadge(badge),
          ],
        ],
      ),
    );
    if (selected || hovered) {
      row = DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: selected ? colors.accentAmalfiSoft : colors.lineSeparator,
          shape: const AmalfiSmoothBorder(radius: AmalfiSidebarMetrics.radius),
        ),
        child: row,
      );
    }
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.label,
      value: badge,
      onTap: enabled ? widget.onTap : null,
      excludeSemantics: true,
      child: AmalfiInteraction(
        // An enabled row without an action still shows the hover.
        onActivate: enabled ? (widget.onTap ?? () {}) : null,
        activators: AmalfiInteraction.buttonActivates,
        onStateChanged: (state) => setState(() {
          _hovered = state.hovered;
          _focused = state.focused && widget.onTap != null;
        }),
        builder: (context, _) => SizedBox(
          height: AmalfiSidebarMetrics.rowHeight,
          child: !enabled
              ? Opacity(opacity: AmalfiStates.disabledOpacity, child: row)
              : _focused
              ? Stack(
                  fit: StackFit.passthrough,
                  children: [
                    row,
                    const Positioned.fill(
                      child: AmalfiFocusHalo(
                        radius: AmalfiSidebarMetrics.radius,
                      ),
                    ),
                  ],
                )
              : row,
        ),
      ),
    );
  }
}

/// A section header (kit `Sidebars/Header/Plain|Open|Closed`): [title] in Label
/// `Text/Tertiary`, 8 below the top of the 28 pt header.
///
/// With [expanded] non-null the header shows a disclosure chevron at the end (down when
/// expanded, right when collapsed) and toggles with [onToggle] when clicked (or with Enter /
/// Space when focused).
class AmalfiSidebarHeader extends StatelessWidget {
  const AmalfiSidebarHeader({
    super.key,
    required this.title,
    this.expanded,
    this.onToggle,
  });

  final String title;

  /// Whether the section is open; null: a plain header without a chevron.
  final bool? expanded;

  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final expanded = this.expanded;
    final header = SizedBox(
      height: AmalfiSidebarMetrics.rowHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmalfiSidebarMetrics.rowPadding,
          AmalfiSidebarMetrics.headerTop,
          AmalfiSidebarMetrics.rowPadding,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AmalfiType.label(color: colors.textTertiary),
              ),
            ),
            if (expanded != null) ...[
              const SizedBox(width: 4),
              AmalfiGlyph(
                expanded ? AmalfiGlyphs.chevronDown : AmalfiGlyphs.chevronRight,
                size: AmalfiSidebarMetrics.chevron,
                color: colors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
    if (expanded == null) {
      return Semantics(
        header: true,
        label: title,
        excludeSemantics: true,
        child: header,
      );
    }
    return Semantics(
      header: true,
      button: true,
      expanded: expanded,
      label: title,
      onTap: onToggle,
      excludeSemantics: true,
      child: AmalfiInteraction(
        onActivate: onToggle,
        activators: AmalfiInteraction.buttonActivates,
        builder: (context, state) => state.focused
            ? Stack(
                fit: StackFit.passthrough,
                children: [
                  header,
                  const Positioned.fill(
                    child: AmalfiFocusHalo(radius: AmalfiSidebarMetrics.radius),
                  ),
                ],
              )
            : header,
      ),
    );
  }
}

/// A collapsible section (kit `Sidebars/Group/Open|Closed`): a header with a chevron and,
/// while [expanded], its [children] (rows) below it, 4 apart.
class AmalfiSidebarGroup extends StatelessWidget {
  const AmalfiSidebarGroup({
    super.key,
    required this.title,
    required this.expanded,
    this.onToggle,
    this.children = const [],
  });

  final String title;
  final bool expanded;
  final VoidCallback? onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AmalfiSidebarHeader(title: title, expanded: expanded, onToggle: onToggle),
      if (expanded)
        for (final child in children) ...[
          const SizedBox(height: AmalfiSidebarMetrics.rowGap),
          child,
        ],
    ],
  );
}

/// The bar at the bottom of a sidebar (kit `Sidebars/Footer`): a 1 pt separator along its top
/// and [children] (24 pt buttons) 4 apart from the start, 36 tall.
class AmalfiSidebarFooter extends StatelessWidget {
  const AmalfiSidebarFooter({super.key, this.children = const []});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return SizedBox(
      height: AmalfiSidebarMetrics.footerHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1,
            child: ColoredBox(color: colors.lineSeparator),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmalfiSidebarMetrics.rowPadding,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sidebar (kit `Sidebars/Panel`, `Windows/Sidebar Body`): `Surface/Sidebar`, [children]
/// (headers, groups and rows) stacked 4 apart with 8 more before every header or group that
/// follows something, and an optional [footer] at the bottom.
///
/// [padding] is the space around the list: 12 at the sides; at the top 8 under a toolbar, or
/// the toolbar height + 8 when the sidebar runs under a split toolbar (`Sidebar Body/Full`).
/// With [edge] a 1 pt separator runs along the trailing edge, inside the width (a window
/// layout draws its own separator instead).
class AmalfiSidebarPanel extends StatelessWidget {
  const AmalfiSidebarPanel({
    super.key,
    required this.children,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 0),
    this.edge = true,
    this.width = AmalfiSidebarMetrics.width,
    this.topInset = 0,
  });

  final List<Widget> children;
  final Widget? footer;
  final EdgeInsets padding;
  final bool edge;

  /// The width; null: as wide as the constraints.
  final double? width;

  /// The height of a glass toolbar section over the top of the panel
  /// (`AmalfiToolbar.sidebarSection` with `AmalfiToolbarSurface.glass`): the rows start below
  /// it and scroll under it. 0: the panel starts under an opaque bar.
  final double topInset;

  static bool _isHeader(Widget w) =>
      w is AmalfiSidebarHeader || w is AmalfiSidebarGroup;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final footer = this.footer;
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        list.add(const SizedBox(height: AmalfiSidebarMetrics.rowGap));
        if (_isHeader(children[i])) {
          list
            ..add(const SizedBox(height: AmalfiSidebarMetrics.sectionGap))
            ..add(const SizedBox(height: AmalfiSidebarMetrics.rowGap));
        }
      }
      list.add(children[i]);
    }
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: colors.surfaceSidebar,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Padding(
              padding: topInset > 0 ? padding.copyWith(top: 0) : padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: list,
                  );
                  if (!constraints.hasBoundedHeight) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [content, if (footer != null) footer],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRect(
                          child: SingleChildScrollView(
                            // Under a glass bar the rows scroll beneath it.
                            padding: topInset > 0
                                ? EdgeInsets.only(top: topInset + padding.top)
                                : EdgeInsets.zero,
                            child: content,
                          ),
                        ),
                      ),
                      if (footer != null) footer,
                    ],
                  );
                },
              ),
            ),
            if (edge)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 1,
                child: ColoredBox(color: colors.lineSeparator),
              ),
          ],
        ),
      ),
    );
  }
}
