// Path control (CT-PA-01; mustache-spec 1.4, MU-03), generalized from Mustache's path bar: 28 pt
// tall with a 1 pt line above, one segment per level from x 13: 16 pt icon, text 5 pt after it,
// 5 × 7 chevron. When space runs out, the middle segments shrink equally down to 29 pt, then the
// first, then the second to last; the last stays whole; cut text fades out on the right.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'common.dart';

abstract final class PathControlMetrics {
  static const double height = 28;
  static const double left = 13;
  static const double icon = 16;
  static const double textGap = 5;
  static const double segmentExtra = 36;
  static const double segmentMin = 29;
  static const double textSize = 13;
}

@immutable
class PathControlColors {
  const PathControlColors(this.fill, this.line, this.text, this.hover);
  final Color fill;
  final Color line;
  final Color text;

  /// A segment under the pointer. *Provisional.*
  final Color hover;

  static const PathControlColors light = PathControlColors(
    Color(0xFFFFFFFF),
    Color(0xFFDCDDDD),
    Color(0xFF7F7F7F),
    Color(0xFF4D4D4D),
  );
  static const PathControlColors dark = PathControlColors(
    Color(0xFF2F2F2F),
    Color(0xFF3F3F40),
    Color(0xFFA1A1A1),
    Color(0xFFE0E0E0),
  );

  static PathControlColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// A level of the path.
@immutable
class PathItem {
  const PathItem(this.label, {this.icon});
  final String label;
  final Widget? icon;
}

/// The widths of segments with `natural` widths in `available` pt.
List<double> pathControlWidths(List<double> natural, double available) {
  final widths = [...natural];
  double total() => widths.fold(0.0, (a, b) => a + b);
  if (natural.length < 2 || total() <= available) return widths;
  final last = widths.length - 1;
  const min = PathControlMetrics.segmentMin;

  void shrink(List<int> idx) {
    final excess = total() - available;
    if (excess <= 0.5 || idx.isEmpty) return;
    double cut(double t) => idx
        .map((i) => widths[i] - math.max(min, math.min(widths[i], t)))
        .fold(0.0, (a, b) => a + b);
    var lo = min;
    var hi = idx.map((i) => widths[i]).fold(min, math.max);
    if (cut(lo) <= excess) {
      for (final i in idx) {
        widths[i] = math.min(widths[i], min);
      }
      return;
    }
    for (var step = 0; step < 40; step++) {
      final mid = (lo + hi) / 2;
      if (cut(mid) > excess) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    for (final i in idx) {
      widths[i] = math.max(min, math.min(widths[i], hi));
    }
  }

  shrink([for (var i = 1; i < last - 1; i++) i]);
  shrink([0]);
  if (last >= 2) shrink([last - 1]);
  return widths;
}

/// The path bar. A click on a segment reports its index.
class PathControl extends StatefulWidget {
  const PathControl({super.key, required this.items, this.onSelect});

  final List<PathItem> items;
  final ValueChanged<int>? onSelect;

  @override
  State<PathControl> createState() => _PathControlState();
}

class _PathControlState extends State<PathControl> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final colors = PathControlColors.of(context);
    final style = containerText(PathControlMetrics.textSize, colors.text);
    final items = widget.items;
    final natural = [
      for (var i = 0; i < items.length; i++)
        containerTextWidth(items[i].label, style) +
            (i == items.length - 1
                ? PathControlMetrics.icon + PathControlMetrics.textGap + 4
                : PathControlMetrics.segmentExtra),
    ];
    return SizedBox(
      key: const ValueKey('path control'),
      height: PathControlMetrics.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.fill,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final widths = pathControlWidths(
              natural,
              box.maxWidth - PathControlMetrics.left - 8,
            );
            return Padding(
              padding: const EdgeInsets.only(
                left: PathControlMetrics.left,
                top: 1,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    SizedBox(
                      key: ValueKey('path segment $i'),
                      width: widths[i],
                      child: _segment(
                        i,
                        truncated: widths[i] < natural[i] - 0.5,
                        style: _hovered == i
                            ? style.copyWith(color: colors.hover)
                            : style,
                        colors: colors,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _segment(
    int i, {
    required bool truncated,
    required TextStyle style,
    required PathControlColors colors,
  }) {
    final item = widget.items[i];
    final last = i == widget.items.length - 1;
    Widget text = Text(
      item.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      style: style,
    );
    if (truncated) {
      text = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          stops: [0.6, 1],
        ).createShader(rect),
        child: text,
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = i),
      onExit: (_) => setState(() {
        if (_hovered == i) _hovered = null;
      }),
      child: Semantics(
        button: true,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect == null ? null : () => widget.onSelect!(i),
          child: Row(
            children: [
              SizedBox.square(
                dimension: PathControlMetrics.icon,
                child: item.icon,
              ),
              const SizedBox(width: PathControlMetrics.textGap),
              Expanded(child: text),
              if (!last) ...[
                const SizedBox(width: 5),
                SizedBox(
                  width: 5,
                  height: 7,
                  child: CustomPaint(
                    painter: ChevronPainter(
                      ChevronDirection.right,
                      colors.text,
                      stroke: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
