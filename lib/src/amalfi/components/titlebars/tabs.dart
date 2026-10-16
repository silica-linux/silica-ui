// Window tabs (kit `Titlebars/Tab/*`, `Titlebars/Tab Bar/*`): a tab bar on a sunken track,
// the selected tab raised, the one under the pointer on `Accent/Amalfi Soft`.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'glyphs.dart';
import '../buttons/icon_button.dart';
import 'window_scope.dart';

/// The measures of the tabs.
abstract final class AmalfiTabMetrics {
  /// The tab height.
  static const double height = 28;

  /// The tab corner radius (concentric with the 12 pt track, 4 inside... the kit draws 9).
  static const double radius = 9;

  /// The padding inside a tab, on each side.
  static const double padding = 8;

  /// The icon and close slots.
  static const double slot = 12;

  /// Between the slots and the label.
  static const double gap = 4;

  /// The width of a tab outside a bar.
  static const double width = 160;

  /// The tab bar: 36 tall, padding 4, gap 4, track radius 12.
  static const double barHeight = 36,
      barPadding = 4,
      barGap = 4,
      barRadius = 12;

  /// The new-tab button at the end of the bar (kit `Buttons/Icon/Square/Small`: 24).
  static const double newTabButton = 24;
}

/// One tab (kit `Titlebars/Tab/Rest|Hover|Selected`).
///
/// [label] in Body, `Text/Secondary` (`Text/Primary` when [selected]); an optional 12 pt
/// [icon] before it; the close button (an `xmark`) after it, shown on the selected tab and on
/// the tab under the pointer. Clicking (or Enter / Space when focused) runs [onSelect];
/// the close button runs [onClose] (null: no close button).
class AmalfiTab extends StatefulWidget {
  const AmalfiTab({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onSelect,
    this.onClose,
    this.closeLabel = 'Close tab',
    this.width = AmalfiTabMetrics.width,
  });

  final String label;

  /// A 12 pt glyph before the label; null: an empty slot.
  final Widget? icon;

  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onClose;

  /// The screen reader label of the close button (pass a localised string).
  final String closeLabel;

  /// The width; null: as wide as the constraints (a tab bar shares its width).
  final double? width;

  @override
  State<AmalfiTab> createState() => _AmalfiTabState();
}

class _AmalfiTabState extends State<AmalfiTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final selected = widget.selected;
    final showClose = widget.onClose != null && (selected || _hovered);
    final ShapeDecoration? decoration = selected
        ? ShapeDecoration(
            color: colors.surfaceRaised,
            shape: AmalfiSmoothBorder(
              radius: AmalfiTabMetrics.radius,
              side: BorderSide(
                color: colors.lineBorder,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            shadows: theme.shadows.level1,
          )
        : _hovered
        ? ShapeDecoration(
            color: colors.accentAmalfiSoft,
            shape: const AmalfiSmoothBorder(radius: AmalfiTabMetrics.radius),
          )
        : null;
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AmalfiTabMetrics.padding),
      child: Row(
        children: [
          SizedBox.square(dimension: AmalfiTabMetrics.slot, child: widget.icon),
          const SizedBox(width: AmalfiTabMetrics.gap),
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.body(
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AmalfiTabMetrics.gap),
          SizedBox.square(
            dimension: AmalfiTabMetrics.slot,
            child: showClose
                ? Semantics(
                    button: true,
                    label: widget.closeLabel,
                    onTap: widget.onClose,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onClose,
                      child: AmalfiTitlebarGlyph(
                        AmalfiTitlebarGlyphs.xmark,
                        size: AmalfiTabMetrics.slot,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
    if (decoration != null) {
      content = DecoratedBox(decoration: decoration, child: content);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      onTap: widget.onSelect,
      child: FocusableActionDetector(
        shortcuts: amalfiTitlebarActivateShortcuts,
        enabled: widget.onSelect != null,
        mouseCursor: SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onSelect?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSelect,
            child: SizedBox(
              width: widget.width,
              height: AmalfiTabMetrics.height,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab of an [AmalfiTabBar].
@immutable
class AmalfiTabData {
  const AmalfiTabData(this.label, {this.icon});

  final String label;

  /// A 12 pt glyph before the label; null: none.
  final Widget? icon;
}

/// A tab bar (kit `Titlebars/Tab Bar/*`): [tabs] sharing the width on a `Surface/Sunken`
/// track, the [selected] one raised, and a new-tab button at the end.
///
/// [onSelect] and [onClose] get the tab index; [onNewTab] null hides the new-tab button.
class AmalfiTabBar extends StatelessWidget {
  const AmalfiTabBar({
    super.key,
    required this.tabs,
    this.selected = 0,
    this.onSelect,
    this.onClose,
    this.onNewTab,
    this.newTabLabel = 'New tab',
    this.closeLabel = 'Close tab',
  });

  final List<AmalfiTabData> tabs;
  final int selected;
  final ValueChanged<int>? onSelect;
  final ValueChanged<int>? onClose;
  final VoidCallback? onNewTab;

  /// The screen reader labels (pass localised strings).
  final String newTabLabel, closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final onNewTab = this.onNewTab;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surfaceSunken,
        shape: const AmalfiSmoothBorder(radius: AmalfiTabMetrics.barRadius),
      ),
      child: SizedBox(
        height: AmalfiTabMetrics.barHeight,
        child: Padding(
          padding: const EdgeInsets.all(AmalfiTabMetrics.barPadding),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: AmalfiTabMetrics.barGap),
                Expanded(
                  child: AmalfiTab(
                    label: tabs[i].label,
                    icon: tabs[i].icon,
                    selected: i == selected,
                    width: null,
                    closeLabel: closeLabel,
                    onSelect: onSelect == null ? null : () => onSelect!(i),
                    onClose: onClose == null ? null : () => onClose!(i),
                  ),
                ),
              ],
              if (onNewTab != null) ...[
                const SizedBox(width: AmalfiTabMetrics.barGap),
                // Kit `Buttons/Icon/Square/Small`.
                AmalfiIconButton(
                  icon: const AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.plus),
                  onPressed: onNewTab,
                  semanticLabel: newTabLabel,
                  shape: AmalfiIconButtonShape.square,
                  size: AmalfiControlSize.small,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
