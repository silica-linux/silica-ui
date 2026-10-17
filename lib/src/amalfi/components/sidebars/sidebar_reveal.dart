// Showing and hiding a sidebar (`components.md` Sidebar show/hide, measured on the reference):
// the sidebar slides out to / in from the leading edge while the content widens or narrows in
// step; the toolbar items right of the sidebar move with the content edge and the sidebar
// toggle stays in place. Hide 240 ms, show 230 ms starting ~40 ms after the trigger, the
// S curve cubic-bezier(0.42, 0, 0.58, 1).

import 'package:flutter/widgets.dart';

/// The timing of the sidebar show/hide (measured: `mustache.md` MU-10).
abstract final class AmalfiSidebarMotion {
  /// Hiding the sidebar.
  static const Duration close = Duration(milliseconds: 240);

  /// Showing the sidebar, after [openDelay].
  static const Duration open = Duration(milliseconds: 230);

  /// The pause between the trigger (key or click) and the start of showing the sidebar.
  static const Duration openDelay = Duration(milliseconds: 40);

  /// The S curve, `cubic-bezier(0.42, 0, 0.58, 1)`.
  static const Curve curve = Curves.easeInOut;
}

/// Drives the show/hide of a sidebar: [builder] gets the progress, 0 hidden to 1 shown, on
/// the measured timing ([AmalfiSidebarMotion]), for layouts that need more than
/// [AmalfiSidebarReveal] (a toolbar whose items follow the content edge, a grid that reflows
/// during the slide). The progress is already curved: use it linearly.
class AmalfiSidebarRevealBuilder extends StatefulWidget {
  const AmalfiSidebarRevealBuilder({
    super.key,
    required this.visible,
    required this.builder,
  });

  /// Whether the sidebar is shown; a change starts the animation.
  final bool visible;

  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<AmalfiSidebarRevealBuilder> createState() =>
      _AmalfiSidebarRevealBuilderState();
}

class _AmalfiSidebarRevealBuilderState extends State<AmalfiSidebarRevealBuilder>
    with SingleTickerProviderStateMixin {
  static const _openTotal = Duration(milliseconds: 270);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _openTotal,
    reverseDuration: AmalfiSidebarMotion.close,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      AmalfiSidebarMotion.openDelay.inMicroseconds / _openTotal.inMicroseconds,
      1,
      curve: AmalfiSidebarMotion.curve,
    ),
    reverseCurve: AmalfiSidebarMotion.curve,
  );

  @override
  void didUpdateWidget(AmalfiSidebarRevealBuilder old) {
    super.didUpdateWidget(old);
    if (old.visible == widget.visible) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) => widget.builder(context, _progress.value),
  );
}

/// A sidebar and its content, side by side, that slide on [visible] (kit `Windows/Sidebar
/// Collapsed` and the open window): the [sidebar] (a [sidebarWidth] wide column) slides from
/// the leading edge, the [content] fills the rest and so follows the content edge, its
/// toolbar included. Put the sidebar toggle outside, or in the sidebar's own title-bar area,
/// so that it stays in place.
class AmalfiSidebarReveal extends StatelessWidget {
  const AmalfiSidebarReveal({
    super.key,
    required this.visible,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 240,
  });

  final bool visible;
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;

  @override
  Widget build(BuildContext context) => AmalfiSidebarRevealBuilder(
    visible: visible,
    builder: (context, progress) {
      final shown = sidebarWidth * progress;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(left: shown, top: 0, right: 0, bottom: 0, child: content),
          if (progress > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: shown,
              child: ClipRect(
                child: OverflowBox(
                  alignment: AlignmentDirectional.centerEnd,
                  minWidth: sidebarWidth,
                  maxWidth: sidebarWidth,
                  child: sidebar,
                ),
              ),
            ),
        ],
      );
    },
  );
}
