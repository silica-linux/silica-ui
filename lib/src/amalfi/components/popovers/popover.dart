// The Amalfi popover (kit `Popovers/Popover/Form|List|Text/<Edge> <Start|Center|End>` and
// `…/Detached`), its kit contents (`Popovers/Content/Form|List|Text`) and how it is shown.
//
// Motion (`motion.md`): it opens with a fade and a scale from 0.96 to 1 about the arrow on
// `spring.panel`, the opacity reaching 1 within the first third; it closes with
// `fade.instant` (an assumption: the spec measures no close). Esc and a press outside close
// it.

import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../menus/menu.dart';
import 'popover_surface.dart';

/// A popover: [child] on Glass/Thick with radius 16, [padding] around it, and an arrow on
/// [arrowEdge] (none when null: a detached popover).
///
/// The arrow adds [AmalfiPopoverMetrics.arrowDepth] on its side; it sits at
/// [arrowAlignment] along the edge, or [arrowOffset] from the edge's start. To show one next
/// to a control, use [showAmalfiPopover].
class AmalfiPopover extends StatelessWidget {
  const AmalfiPopover({
    super.key,
    this.arrowEdge,
    this.arrowAlignment = AmalfiPopoverArrowAlignment.center,
    this.arrowOffset,
    this.padding = AmalfiPopoverMetrics.padding,
    this.opaque = false,
    required this.child,
  });

  /// The edge with the arrow; null: detached.
  final AmalfiPopoverArrowEdge? arrowEdge;

  /// Where the arrow sits along [arrowEdge].
  final AmalfiPopoverArrowAlignment arrowAlignment;

  /// The arrow centre's distance from the start of its edge, overriding [arrowAlignment].
  final double? arrowOffset;

  /// The space between the body's edge and [child]: [AmalfiPopoverMetrics.padding], or
  /// [AmalfiPopoverMetrics.listPadding] around a list.
  final EdgeInsets padding;

  /// Whether the glass is drawn without blur (see [AmalfiPopoverSurface.opaque]).
  final bool opaque;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = AmalfiPopoverShape(
      edge: arrowEdge,
      alignment: arrowAlignment,
      arrowOffset: arrowOffset,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AmalfiPopoverSurface(
        shape: shape,
        opaque: opaque,
        child: Padding(padding: padding + shape.arrowInsets, child: child),
      ),
    );
  }
}

/// The text content of a popover (kit `Popovers/Content/Text`): a [title] in Headline
/// `Text/Primary`, the [body] in Callout `Text/Secondary` and an optional [action] (a link
/// button) under it, 4 apart, [width] wide.
class AmalfiPopoverText extends StatelessWidget {
  const AmalfiPopoverText({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.width = 232,
  });

  final String title;
  final String body;

  /// A control under the text (a link button); null: none.
  final Widget? action;

  /// The width of the content.
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final action = this.action;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmalfiWholePoints(
              child: Text(
                title,
                style: AmalfiType.headline(color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: width,
              child: Text(
                body,
                style: AmalfiType.callout(color: colors.textSecondary),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 4), action],
          ],
        ),
      ),
    );
  }
}

/// The form content of a popover (kit `Popovers/Content/Form`): a [title] in Headline
/// `Text/Primary`, a [field] and the [actions] (push buttons, the default one last) at the
/// trailing end, 8 apart, [width] wide.
class AmalfiPopoverForm extends StatelessWidget {
  const AmalfiPopoverForm({
    super.key,
    required this.title,
    required this.field,
    this.actions = const [],
    this.width = 228,
  });

  final String title;

  /// The field (a text field).
  final Widget field;

  /// The buttons, leading to trailing.
  final List<Widget> actions;

  /// The width of the content.
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AmalfiType.headline(
              color: AmalfiTheme.of(context).colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          field,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Wraps onto a second line rather than overflow when the buttons are wide.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    ),
  );
}

/// The list content of a popover (kit `Popovers/Content/List`): menu rows (a header, items
/// with icons), [width] wide, interactive as in a menu. Show it with
/// [AmalfiPopoverMetrics.listPadding].
class AmalfiPopoverList extends StatelessWidget {
  const AmalfiPopoverList({
    super.key,
    required this.entries,
    this.width = 188,
    this.onDismiss,
    this.autofocus = false,
  });

  final List<AmalfiMenuEntry> entries;
  final double width;

  /// Called after an item is chosen and on Esc.
  final VoidCallback? onDismiss;

  final bool autofocus;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AmalfiMenuList(
      entries: entries,
      onDismiss: onDismiss,
      autofocus: autofocus,
    ),
  );
}

/// The side of its anchor a popover goes to.
enum AmalfiPopoverPlacement {
  /// Under the anchor (the arrow on the top edge).
  below,

  /// Over the anchor (the arrow on the bottom edge).
  above,

  /// Before the anchor in the reading direction (the arrow on the trailing edge).
  leading,

  /// After the anchor (the arrow on the leading edge).
  trailing,
}

/// The arrow edge of a popover at [placement].
AmalfiPopoverArrowEdge amalfiPopoverArrowEdge(
  AmalfiPopoverPlacement placement,
) => switch (placement) {
  AmalfiPopoverPlacement.below => AmalfiPopoverArrowEdge.top,
  AmalfiPopoverPlacement.above => AmalfiPopoverArrowEdge.bottom,
  AmalfiPopoverPlacement.leading => AmalfiPopoverArrowEdge.trailing,
  AmalfiPopoverPlacement.trailing => AmalfiPopoverArrowEdge.leading,
};

/// Where a popover of [size] goes next to [anchor] (both in the coordinates of an area of
/// [bounds]): its top-left corner, the placement used (the opposite one when [placement]
/// has no room and the other side has), and the arrow centre's distance from the start of
/// its edge, pointing at the anchor's centre.
///
/// The arrow tip touches the anchor (an assumption: the kit has no anchored master).
/// Across, the popover is centred on the anchor and kept [margin] inside the bounds.
({Offset offset, AmalfiPopoverPlacement placement, double arrowOffset})
amalfiPopoverLayout({
  required Rect anchor,
  required Size size,
  required Size bounds,
  AmalfiPopoverPlacement placement = AmalfiPopoverPlacement.below,
  TextDirection textDirection = TextDirection.ltr,
  double margin = 8,
}) {
  final rtl = textDirection == TextDirection.rtl;
  bool leftOf(AmalfiPopoverPlacement p) =>
      (p == AmalfiPopoverPlacement.leading) != rtl;
  double along(AmalfiPopoverPlacement p) => switch (p) {
    AmalfiPopoverPlacement.below => anchor.bottom,
    AmalfiPopoverPlacement.above => anchor.top - size.height,
    _ => leftOf(p) ? anchor.left - size.width : anchor.right,
  };
  bool vertical(AmalfiPopoverPlacement p) =>
      p == AmalfiPopoverPlacement.below || p == AmalfiPopoverPlacement.above;
  bool fits(AmalfiPopoverPlacement p) {
    final v = along(p);
    return vertical(p)
        ? v >= 0 && v + size.height <= bounds.height
        : v >= 0 && v + size.width <= bounds.width;
  }

  final other = switch (placement) {
    AmalfiPopoverPlacement.below => AmalfiPopoverPlacement.above,
    AmalfiPopoverPlacement.above => AmalfiPopoverPlacement.below,
    AmalfiPopoverPlacement.leading => AmalfiPopoverPlacement.trailing,
    AmalfiPopoverPlacement.trailing => AmalfiPopoverPlacement.leading,
  };
  final chosen = fits(placement) || !fits(other) ? placement : other;
  double across(double centre, double extent, double room) {
    final v = centre - extent / 2;
    final max = room - margin - extent;
    if (max < margin) return (room - extent) / 2;
    return v.clamp(margin, max).toDouble();
  }

  if (vertical(chosen)) {
    final x = across(anchor.center.dx, size.width, bounds.width);
    final fromStart = rtl
        ? x + size.width - anchor.center.dx
        : anchor.center.dx - x;
    return (
      offset: Offset(x, along(chosen)),
      placement: chosen,
      arrowOffset: fromStart,
    );
  }
  final y = across(anchor.center.dy, size.height, bounds.height);
  return (
    offset: Offset(along(chosen), y),
    placement: chosen,
    arrowOffset: anchor.center.dy - y,
  );
}

/// Shows a popover built by [builder] next to [anchor] (a rectangle in global coordinates),
/// on the [placement] side (or the other one when there is no room), with its arrow pointing
/// at the anchor's centre. Completes when it closes: on Esc, on a press outside it, or when
/// the builder's `dismiss` is called.
Future<void> showAmalfiPopover({
  required BuildContext context,
  required Rect anchor,
  required Widget Function(BuildContext context, VoidCallback dismiss) builder,
  AmalfiPopoverPlacement placement = AmalfiPopoverPlacement.below,
  EdgeInsets padding = AmalfiPopoverMetrics.padding,
  bool opaque = false,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  final brightness = AmalfiTheme.of(context).brightness;
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  final overlayBox = overlay.context.findRenderObject();
  final local = overlayBox is RenderBox && overlayBox.hasSize
      ? Rect.fromPoints(
          overlayBox.globalToLocal(anchor.topLeft),
          overlayBox.globalToLocal(anchor.bottomRight),
        )
      : anchor;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Directionality(
      textDirection: direction,
      child: AmalfiTheme(
        brightness: brightness,
        child: _PopoverPresenter(
          anchor: local,
          placement: placement,
          padding: padding,
          opaque: opaque,
          builder: builder,
          onClosed: () {
            entry.remove();
            entry.dispose();
            if (!done.isCompleted) done.complete();
          },
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _PopoverPresenter extends StatefulWidget {
  const _PopoverPresenter({
    required this.anchor,
    required this.placement,
    required this.padding,
    required this.opaque,
    required this.builder,
    required this.onClosed,
  });

  final Rect anchor;
  final AmalfiPopoverPlacement placement;
  final EdgeInsets padding;
  final bool opaque;
  final Widget Function(BuildContext context, VoidCallback dismiss) builder;
  final VoidCallback onClosed;

  @override
  State<_PopoverPresenter> createState() => _PopoverPresenterState();
}

class _PopoverPresenterState extends State<_PopoverPresenter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
  );
  late AmalfiPopoverPlacement _placement = widget.placement;
  double? _arrowOffset;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _motion.animateWith(SpringSimulation(AmalfiSprings.panel, 0, 1, 0));
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    setState(() => _closing = true);
    _motion
        .animateTo(
          0,
          duration: AmalfiFades.instant.duration,
          curve: AmalfiFades.instant.curve,
        )
        .whenCompleteOrCancel(widget.onClosed);
  }

  void _placed(AmalfiPopoverPlacement placement, double arrowOffset) {
    if (placement == _placement && arrowOffset == _arrowOffset) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _placement = placement;
        _arrowOffset = arrowOffset;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final edge = amalfiPopoverArrowEdge(_placement);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final popover = AmalfiPopover(
      arrowEdge: edge,
      arrowOffset: _arrowOffset,
      padding: widget.padding,
      opaque: widget.opaque,
      child: Builder(builder: (c) => widget.builder(c, _dismiss)),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _dismiss(),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _PopoverLayout(
            anchor: widget.anchor,
            placement: widget.placement,
            textDirection: Directionality.of(context),
            onPlaced: _placed,
          ),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
            },
            child: Focus(
              autofocus: true,
              child: IgnorePointer(
                ignoring: _closing,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) {
                    final v = _motion.value;
                    final opacity = (_closing ? v : v * 3)
                        .clamp(0.0, 1.0)
                        .toDouble();
                    if (reduce) return Opacity(opacity: opacity, child: child);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * v,
                        alignment: _arrowAlignment(edge),
                        child: child,
                      ),
                    );
                  },
                  child: popover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Alignment _arrowAlignment(AmalfiPopoverArrowEdge edge) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (edge) {
      AmalfiPopoverArrowEdge.top => Alignment.topCenter,
      AmalfiPopoverArrowEdge.bottom => Alignment.bottomCenter,
      AmalfiPopoverArrowEdge.leading =>
        rtl ? Alignment.centerRight : Alignment.centerLeft,
      AmalfiPopoverArrowEdge.trailing =>
        rtl ? Alignment.centerLeft : Alignment.centerRight,
    };
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout({
    required this.anchor,
    required this.placement,
    required this.textDirection,
    required this.onPlaced,
  });

  final Rect anchor;
  final AmalfiPopoverPlacement placement;
  final TextDirection textDirection;
  final void Function(AmalfiPopoverPlacement, double) onPlaced;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final r = amalfiPopoverLayout(
      anchor: anchor,
      size: childSize,
      bounds: size,
      placement: placement,
      textDirection: textDirection,
    );
    onPlaced(r.placement, r.arrowOffset);
    return r.offset;
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      old.anchor != anchor ||
      old.placement != placement ||
      old.textDirection != textDirection;
}
