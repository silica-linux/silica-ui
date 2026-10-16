// Showing a tooltip when the pointer rests on a control (`motion.md`: `fade.quick` after
// `delay.tooltip`, 700 ms the first time and 0 ms while the pointer moves between items).

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'placement.dart';
import 'tooltip.dart';

/// Shows an [AmalfiTooltip] with [message] (and [shortcut]) next to [child] when the pointer
/// rests on it.
///
/// The first tooltip appears [AmalfiDelays.tooltip] after the pointer enters; while one is on
/// screen, moving to another region shows its tooltip after [AmalfiDelays.tooltipWhileMoving].
/// It fades in and out with [AmalfiFades.quick]; leaving the region or pressing hides it.
/// [message] is also the hint read by screen readers. It needs an [Overlay] above it.
class AmalfiTooltipRegion extends StatefulWidget {
  const AmalfiTooltipRegion({
    super.key,
    required this.message,
    this.shortcut,
    this.placement = AmalfiTooltipPlacement.below,
    required this.child,
  });

  /// The tooltip text.
  final String message;

  /// The shortcut shown after the text; null: none.
  final String? shortcut;

  /// Where the tooltip goes next to [child] (it flips when there is no room).
  final AmalfiTooltipPlacement placement;

  final Widget child;

  @override
  State<AmalfiTooltipRegion> createState() => _AmalfiTooltipRegionState();
}

class _AmalfiTooltipRegionState extends State<AmalfiTooltipRegion>
    with SingleTickerProviderStateMixin {
  /// The region whose tooltip is on screen, across every region.
  static _AmalfiTooltipRegionState? _shown;

  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AmalfiFades.quick.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: AmalfiFades.quick.curve,
  );
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (_shown == this) _shown = null;
    _fade.dispose();
    super.dispose();
  }

  void _enter() {
    _timer?.cancel();
    if (_shown == this && _fade.status != AnimationStatus.reverse) return;
    final moving = _shown != null && _shown != this;
    _timer = Timer(
      moving ? AmalfiDelays.tooltipWhileMoving : AmalfiDelays.tooltip,
      _show,
    );
  }

  void _show() {
    if (!mounted) return;
    final other = _shown;
    if (other != null && other != this) other._hideNow();
    _shown = this;
    _portal.show();
    _fade.forward();
  }

  void _hideNow() {
    _timer?.cancel();
    _fade.value = 0;
    if (_portal.isShowing) _portal.hide();
    if (_shown == this) _shown = null;
  }

  void _leave() {
    _timer?.cancel();
    if (!_portal.isShowing) return;
    _fade.reverse().whenComplete(() {
      if (mounted && _fade.value == 0) _hideNow();
    });
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: _overlay,
    child: MouseRegion(
      onEnter: (_) => _enter(),
      onExit: (_) => _leave(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _leave(),
        child: Semantics(tooltip: widget.message, child: widget.child),
      ),
    ),
  );

  Widget _overlay(BuildContext overlayContext) {
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
    return AmalfiTheme(
      brightness: AmalfiTheme.of(context).brightness,
      child: CustomSingleChildLayout(
        delegate: _TooltipLayout(
          target: rect,
          placement: widget.placement,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        ),
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacity,
            child: AmalfiTooltip(
              message: widget.message,
              shortcut: widget.shortcut,
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipLayout extends SingleChildLayoutDelegate {
  const _TooltipLayout({
    required this.target,
    required this.placement,
    required this.textDirection,
  });

  final Rect target;
  final AmalfiTooltipPlacement placement;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => amalfiTooltipOffset(
    target: target,
    size: childSize,
    bounds: size,
    placement: placement,
    textDirection: textDirection,
  );

  @override
  bool shouldRelayout(_TooltipLayout old) =>
      old.target != target ||
      old.placement != placement ||
      old.textDirection != textDirection;
}
