// A content area that scrolls both ways with its two scroll bars (kit `Scrollbars/Area/*`):
// overlay bars float over the content, the vertical one stopping above the horizontal one;
// legacy bars sit beside it with the corner square between them.

import 'package:flutter/widgets.dart';

import 'scrollbar.dart';
import 'scrollbar_track.dart';

/// Scrolls [child] vertically and horizontally, with an Amalfi scroll bar for each axis.
///
/// [child] is laid out at its own size (unbounded both ways). [vertical] and [horizontal]
/// control the two scroll positions; [verticalStates] and [horizontalStates] hold the bars'
/// interaction states (see `AmalfiScrollbar.statesController`).
class AmalfiScrollArea extends StatelessWidget {
  const AmalfiScrollArea({
    super.key,
    required this.child,
    this.style = AmalfiScrollbarStyle.overlay,
    this.vertical,
    this.horizontal,
    this.verticalStates,
    this.horizontalStates,
  });

  final Widget child;
  final AmalfiScrollbarStyle style;
  final ScrollController? vertical;
  final ScrollController? horizontal;
  final WidgetStatesController? verticalStates;
  final WidgetStatesController? horizontalStates;

  @override
  Widget build(BuildContext context) {
    final thickness = AmalfiScrollbarMetrics.thicknessOf(style);
    final overlay = style == AmalfiScrollbarStyle.overlay;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final views = SingleChildScrollView(
      controller: vertical,
      child: SingleChildScrollView(
        controller: horizontal,
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
    final bars = AmalfiScrollbar(
      style: style,
      statesController: verticalStates,
      // The vertical bar stops above the horizontal one (and the corner).
      padding: EdgeInsets.only(bottom: thickness),
      child: AmalfiScrollbar(
        axis: Axis.horizontal,
        style: style,
        notificationDepth: 1,
        statesController: horizontalStates,
        padding: overlay
            ? EdgeInsets.only(
                left: rtl ? thickness : 0,
                right: rtl ? 0 : thickness,
              )
            : EdgeInsets.zero,
        child: views,
      ),
    );
    if (overlay) return bars;
    return Stack(
      children: [
        Positioned.fill(child: bars),
        Positioned(
          bottom: 0,
          left: rtl ? 0 : null,
          right: rtl ? null : 0,
          child: const AmalfiScrollbarCorner(),
        ),
      ],
    );
  }
}
