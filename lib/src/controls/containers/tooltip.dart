// Tooltips (CT-TT-01): the help text of a control.
//
// Measured (docs/spec/tooltips.md, INV-D): it appears ~1.54 s after the pointer stops on a
// control, in one frame (no fade-in); moving to a neighbouring control while one is shown
// replaces it ~240 ms after the pointer arrives, in one frame; leaving starts the fade ~0.3 s
// later, over ~450 ms; a light-gray (`#e3e3e3`) rounded label (radius ~5) with a hairline darker
// edge and a soft shadow, ~20 pt tall, 11 pt text, ~8 pt side padding, its top ~18 pt below the
// pointer and its left edge near the pointer. Kept inside the window. *Provisional:* the dark
// look, the shadow, the edge.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'common.dart';

abstract final class TooltipMetrics {
  /// From the pointer resting on a control to the tooltip (CT-TT-01).
  static const Duration delay = Duration(milliseconds: 1540);

  /// From the pointer reaching a neighbouring control while a tooltip is shown (CT-TT-01).
  static const Duration switchDelay = Duration(milliseconds: 240);

  /// From the pointer leaving to the start of the fade, and the fade (CT-TT-01).
  static const Duration hideDelay = Duration(milliseconds: 300);
  static const Duration fade = Duration(milliseconds: 450);

  /// The top edge below the pointer hotspot (CT-TT-01).
  static const double below = 18;
  static const double maxWidth = 300;
  static const double textSize = 11;
  static const double radius = 5;

  /// Side and top/bottom padding: ~8 pt sides, ~20 pt tall with one line (CT-TT-01).
  static const double padding = 8;
  static const double verticalPadding = 3;
}

@immutable
class TooltipColors {
  const TooltipColors(this.background, this.border, this.text);
  final Color background;
  final Color border;
  final Color text;

  /// Measured background; the edge and the text provisional.
  static const TooltipColors light = TooltipColors(
    Color(0xFFE3E3E3),
    Color(0x26000000),
    Color(0xFF262626),
  );

  /// *Provisional: not measured.*
  static const TooltipColors dark = TooltipColors(
    Color(0xFF323233),
    Color(0x33FFFFFF),
    Color(0xFFE6E6E6),
  );

  static TooltipColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// The help text `message` over `child`: shown after [TooltipMetrics.delay] at rest (or
/// [TooltipMetrics.switchDelay] when another tooltip is up), faded out after the pointer leaves
/// or presses. Also read by screen readers as the control's hint.
class SilicaTooltip extends StatefulWidget {
  const SilicaTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<SilicaTooltip> createState() => _SilicaTooltipState();
}

class _SilicaTooltipState extends State<SilicaTooltip>
    with SingleTickerProviderStateMixin {
  /// The tooltip on screen (shown or fading), across every [SilicaTooltip].
  static _SilicaTooltipState? _current;

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
    if (_current == this) _current = null;
    _fade.dispose();
    super.dispose();
  }

  void _rest(Offset global) {
    _pointer = global;
    if (_portal.isShowing && _fade.value == 1) return;
    _timer?.cancel();
    final other = _current;
    final switching = other != null && other != this;
    _timer = Timer(
      switching ? TooltipMetrics.switchDelay : TooltipMetrics.delay,
      _show,
    );
  }

  void _show() {
    if (!mounted) return;
    final other = _current;
    if (other != null && other != this) other._hideNow();
    _current = this;
    _fade.value = 1;
    _portal.show();
    setState(() {});
  }

  void _hideNow() {
    _timer?.cancel();
    _fade.value = 0;
    if (_portal.isShowing) _portal.hide();
    if (_current == this) _current = null;
  }

  void _leave() {
    _timer?.cancel();
    if (!_portal.isShowing) return;
    _timer = Timer(TooltipMetrics.hideDelay, () {
      if (!mounted) return;
      _fade.reverse().whenComplete(() {
        if (mounted && _fade.value == 0) _hideNow();
      });
    });
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
      containerTextWidth(widget.message, style) + 2 * TooltipMetrics.padding,
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
            padding: const EdgeInsets.symmetric(
              horizontal: TooltipMetrics.padding,
              vertical: TooltipMetrics.verticalPadding,
            ),
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
