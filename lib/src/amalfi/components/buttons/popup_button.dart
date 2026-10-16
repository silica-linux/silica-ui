// Pop-up and pull-down buttons (kit `Buttons/<Pop-up|Pull-down>/<size>/<state>` and
// `…/Open`): the opaque control look, a label on the left and a chevron on the right; pressed,
// they open a menu 4 below.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_menu.dart';
import 'button_surface.dart';
import 'glyph.dart';

/// The measures of pop-up and pull-down buttons per size, from the kit masters.
abstract final class AmalfiPopUpButtonMetrics {
  /// The default width: 92 / 108 / 124 / 148.
  static double width(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini => 92,
    AmalfiControlSize.small => 108,
    AmalfiControlSize.regular => 124,
    AmalfiControlSize.large => 148,
  };

  /// Before the label.
  static double leading(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini || AmalfiControlSize.small => 8,
    _ => 12,
  };

  /// After the chevron.
  static double trailing(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini || AmalfiControlSize.small => 4,
    _ => 8,
  };

  /// Between the label and the chevron.
  static const double gap = 4;

  /// The chevron's size: 12 for Mini and Small, 16 for Regular and Large.
  static double chevron(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini || AmalfiControlSize.small => 12,
    _ => 16,
  };

  /// The label style: Caption, Label, Body, Body.
  static TextStyle labelStyle(AmalfiControlSize size, Color color) =>
      switch (size) {
        AmalfiControlSize.mini => AmalfiType.caption(color: color),
        AmalfiControlSize.small => AmalfiType.label(color: color),
        _ => AmalfiType.body(color: color),
      };
}

/// A choice of an [AmalfiPopUpButton].
@immutable
class AmalfiPopUpItem<T> {
  const AmalfiPopUpItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

/// A command of an [AmalfiPullDownButton].
@immutable
class AmalfiPullDownItem {
  const AmalfiPullDownItem({required this.label, this.onSelected});

  final String label;

  /// Called when the item is chosen; null disables the item.
  final VoidCallback? onSelected;
}

/// A pop-up button: shows the label of the [items] entry whose value is [value] and, pressed,
/// a menu of every item with a checkmark on the current one and the highlight on it;
/// choosing one calls [onChanged].
///
/// [width] null takes the kit's width for [size]; longer labels end with an ellipsis.
/// [onChanged] null (or no items) disables it. Space or Return opens the menu from the
/// keyboard; the arrows, Return and Escape work in it.
class AmalfiPopUpButton<T> extends StatelessWidget {
  const AmalfiPopUpButton({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.size = AmalfiControlSize.regular,
    this.width,
    this.placeholder = '',
    this.semanticLabel,
    this.focusNode,
  });

  final List<AmalfiPopUpItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final AmalfiControlSize size;
  final double? width;

  /// Shown when no item has [value].
  final String placeholder;

  /// What screen readers announce before the value; null: the value alone.
  final String? semanticLabel;

  final FocusNode? focusNode;

  int get _selected => items.indexWhere((i) => i.value == value);

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final onChanged = this.onChanged;
    return _MenuButton(
      label: selected < 0 ? placeholder : items[selected].label,
      chevron: AmalfiGlyphShape.chevronUpDown,
      size: size,
      width: width,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      entries: [
        for (final item in items)
          AmalfiButtonMenuEntry(
            label: item.label,
            checked: item.value == value,
            enabled: item.enabled,
          ),
      ],
      highlighted: selected,
      onSelected: onChanged == null || items.isEmpty
          ? null
          : (i) {
              if (i >= 0 && i < items.length) onChanged(items[i].value);
            },
    );
  }
}

/// A pull-down button: [label] and a chevron; pressed, a menu of [items] (commands) opens
/// below it. [items] all disabled (or none) disables it.
class AmalfiPullDownButton extends StatelessWidget {
  const AmalfiPullDownButton({
    super.key,
    required this.label,
    required this.items,
    this.size = AmalfiControlSize.regular,
    this.width,
    this.semanticLabel,
    this.focusNode,
  });

  final String label;
  final List<AmalfiPullDownItem> items;
  final AmalfiControlSize size;
  final double? width;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => _MenuButton(
    label: label,
    chevron: AmalfiGlyphShape.chevronDown,
    size: size,
    width: width,
    semanticLabel: semanticLabel,
    focusNode: focusNode,
    entries: [
      for (final item in items)
        AmalfiButtonMenuEntry(
          label: item.label,
          enabled: item.onSelected != null,
        ),
    ],
    highlighted: -1,
    onSelected: items.any((i) => i.onSelected != null)
        ? (i) {
            if (i >= 0 && i < items.length) items[i].onSelected?.call();
          }
        : null,
  );
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({
    required this.label,
    required this.chevron,
    required this.size,
    required this.width,
    required this.semanticLabel,
    required this.focusNode,
    required this.entries,
    required this.highlighted,
    required this.onSelected,
  });

  final String label;
  final AmalfiGlyphShape chevron;
  final AmalfiControlSize size;
  final double? width;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final List<AmalfiButtonMenuEntry> entries;
  final int highlighted;
  final ValueChanged<int>? onSelected;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _tapGroup = Object();
  final FocusNode _menuFocus = FocusNode(debugLabel: 'AmalfiButtonMenu');

  /// What had the focus before the menu opened; it gets it back when the menu closes.
  FocusNode? _returnFocus;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AmalfiFades.instant.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: AmalfiFades.instant.curve,
  );

  bool get _open =>
      _portal.isShowing && _fade.status != AnimationStatus.reverse;

  @override
  void didUpdateWidget(_MenuButton old) {
    super.didUpdateWidget(old);
    if (widget.onSelected == null && _portal.isShowing) _closeNow();
  }

  @override
  void dispose() {
    _fade.dispose();
    _menuFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _show();
    }
  }

  void _show() {
    if (widget.onSelected == null || widget.entries.isEmpty) return;
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(_portal.show);
    _fade.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _portal.isShowing) _menuFocus.requestFocus();
    });
  }

  void _close() {
    if (!_portal.isShowing) return;
    _restoreFocus();
    _fade.reverse().whenComplete(() {
      if (mounted && _fade.value == 0) _closeNow();
    });
    setState(() {});
  }

  void _restoreFocus() {
    final back = _returnFocus;
    _returnFocus = null;
    if (_menuFocus.hasFocus && back != null && back.context != null) {
      back.requestFocus();
    } else if (_menuFocus.hasFocus) {
      _menuFocus.unfocus();
    }
  }

  void _closeNow() {
    _restoreFocus();
    _fade.value = 0;
    if (_portal.isShowing) setState(_portal.hide);
  }

  void _select(int i) {
    _close();
    widget.onSelected?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final look = amalfiControlLook(
      colors,
      contentDisabled: colors.textTertiary,
    );
    final size = widget.size;
    final height = size.height;
    final shape = AmalfiSmoothBorder(radius: AmalfiRadii.capsule(height));
    final enabled = widget.onSelected != null && widget.entries.isNotEmpty;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _menu,
      child: TapRegion(
        groupId: _tapGroup,
        child: AmalfiButtonBehavior(
          onPressed: enabled ? _toggle : null,
          focusNode: widget.focusNode,
          pressed: _open,
          semanticLabel: widget.semanticLabel == null
              ? widget.label
              : '${widget.semanticLabel}, ${widget.label}',
          builder: (context, visual) {
            final color = look.contentFor(visual);
            final chevronColor = visual.enabled
                ? colors.textSecondary
                : colors.textTertiary;
            return AmalfiButtonSurface(
              look: look,
              shape: shape,
              visual: visual,
              child: SizedBox(
                width: widget.width ?? AmalfiPopUpButtonMetrics.width(size),
                height: height,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AmalfiPopUpButtonMetrics.leading(size),
                    right: AmalfiPopUpButtonMetrics.trailing(size),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: AmalfiPopUpButtonMetrics.labelStyle(
                            size,
                            color,
                          ),
                        ),
                      ),
                      const SizedBox(width: AmalfiPopUpButtonMetrics.gap),
                      AmalfiGlyph(
                        widget.chevron,
                        size: AmalfiPopUpButtonMetrics.chevron(size),
                        color: chevronColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _menu(BuildContext overlayContext) {
    final target = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (target == null || overlay == null || !target.hasSize) {
      return const SizedBox.shrink();
    }
    final rect = MatrixUtils.transformRect(
      target.getTransformTo(overlay),
      Offset.zero & target.size,
    );
    final width = rect.width > AmalfiButtonMenuMetrics.minWidth
        ? rect.width
        : AmalfiButtonMenuMetrics.minWidth;
    return AmalfiTheme(
      brightness: AmalfiTheme.of(context).brightness,
      child: CustomSingleChildLayout(
        delegate: _MenuLayout(rect),
        child: TapRegion(
          groupId: _tapGroup,
          onTapOutside: (_) => _close(),
          child: FadeTransition(
            opacity: _opacity,
            child: AmalfiButtonMenu(
              entries: widget.entries,
              highlighted: widget.highlighted,
              width: width,
              onSelected: _select,
              onDismiss: _close,
              focusNode: _menuFocus,
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the menu 4 below the button, its leading edge on the button's; above it when there is
/// no room below; always inside the overlay.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.target);

  final Rect target;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const d = AmalfiButtonMenuMetrics.distance;
    var y = target.bottom + d;
    if (y + child.height > size.height && target.top - d - child.height >= 0) {
      y = target.top - d - child.height;
    }
    var x = target.left;
    if (x + child.width > size.width) x = size.width - child.width;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) => old.target != target;
}
