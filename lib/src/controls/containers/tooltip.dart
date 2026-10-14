// Tooltips (CT-TT-01): the help text of a control, shown after the pointer rests on it for
// ~1 s (calculator.md, 2nd key). Placed under the pointer, kept inside the window. *Provisional:
// the look, the fade, the position and the delay before hiding are not measured (C-01).*

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'common.dart';

abstract final class TooltipMetrics {
  static const Duration delay = Duration(milliseconds: 1000);

  /// *Provisional.*
  static const Duration fade = Duration(milliseconds: 100);
  static const double below = 20;
  static const double maxWidth = 300;
  static const double textSize = 11;
  static const double radius = 5;
}

@immutable
class TooltipColors {
  const TooltipColors(this.background, this.border, this.text);
  final Color background;
  final Color border;
  final Color text;

  static const TooltipColors light = TooltipColors(
    Color(0xFFF0F0F0),
    Color(0x26000000),
    Color(0xFF262626),
  );
  static const TooltipColors dark = TooltipColors(
    Color(0xFF323233),
    Color(0x33FFFFFF),
    Color(0xFFE6E6E6),
  );

  static TooltipColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// The help text `message` over `child`: shown after [TooltipMetrics.delay] at rest, hidden when
/// the pointer leaves or presses. Also read by screen readers as the control's hint.
class SilicaTooltip extends StatefulWidget {
  const SilicaTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<SilicaTooltip> createState() => _SilicaTooltipState();
}

class _SilicaTooltipState extends State<SilicaTooltip>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: TooltipMetrics.fade,
  );
  Timer? _timer;
  Offset _pointer = Offset.zero;

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  void _rest(Offset global) {
    _pointer = global;
    if (_portal.isShowing) return;
    _timer?.cancel();
    _timer = Timer(TooltipMetrics.delay, () {
      if (!mounted) return;
      _portal.show();
      _fade.forward(from: 0);
    });
  }

  void _leave() {
    _timer?.cancel();
    if (_portal.isShowing) {
      _fade.reverse().whenComplete(() {
        if (mounted && _fade.value == 0) _portal.hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: _overlay,
    child: MouseRegion(
      onHover: (e) => _rest(e.position),
      onExit: (_) => _leave(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _leave(),
        child: Semantics(tooltip: widget.message, child: widget.child),
      ),
    ),
  );

  Widget _overlay(BuildContext context) {
    final colors = TooltipColors.of(context);
    final overlay =
        Overlay.of(this.context).context.findRenderObject() as RenderBox?;
    final at = overlay == null ? _pointer : overlay.globalToLocal(_pointer);
    final size = overlay?.size ?? Size.infinite;
    final style = containerText(
      TooltipMetrics.textSize,
      colors.text,
    ).copyWith(height: 1.25);
    final width = math.min(
      TooltipMetrics.maxWidth,
      containerTextWidth(widget.message, style) + 13,
    );
    return Positioned(
      left: math.max(4, math.min(at.dx, size.width - width - 4)),
      top: at.dy + TooltipMetrics.below,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            key: const ValueKey('tooltip'),
            constraints: const BoxConstraints(
              maxWidth: TooltipMetrics.maxWidth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(TooltipMetrics.radius),
              border: Border.all(color: colors.border, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(widget.message, style: style),
          ),
        ),
      ),
    );
  }
}
