// Whole points: Amalfi puts every frame, text frames included, on whole points (most on the
// 4 pt grid). Text measures fractional widths; this rounds its box up so that what follows it
// lands on the grid.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Sizes [child] as it wants, then rounds its width and height up to a multiple of [step]
/// points (within the constraints). The child is laid out at its own size, at the top left.
///
/// Use it around text whose box decides the layout: `AmalfiWholePoints(child: Text(…))`.
/// With `step: AmalfiGrid.base` the box lands on the 4 pt grid, as the kit draws the text
/// frames of controls whose size follows their label (the tooltip "Add to favourites": text
/// 97.03 wide, frame 100).
class AmalfiWholePoints extends SingleChildRenderObjectWidget {
  const AmalfiWholePoints({super.key, this.step = 1, super.child})
    : assert(step > 0);

  /// The rounding step in points.
  final double step;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholePoints(step);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderWholePoints renderObject,
  ) {
    renderObject.step = step;
  }
}

/// [x] rounded up to a multiple of [step] points, ignoring float noise below 1/1000 pt.
double ceilToWholePoints(double x, [double step = 1]) => x.isFinite
    ? ((x - 1e-3) / step).ceilToDouble().clamp(0, double.infinity) * step
    : x;

class _RenderWholePoints extends RenderProxyBox {
  _RenderWholePoints(this._step);

  double _step;
  set step(double value) {
    if (value == _step) return;
    _step = value;
    markNeedsLayout();
  }

  double _ceil(double x) => ceilToWholePoints(x, _step);

  Size _round(Size s) => Size(_ceil(s.width), _ceil(s.height));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(_round(child.size));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(_round(child.getDryLayout(constraints)));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _ceil(super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _ceil(super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _ceil(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _ceil(super.computeMaxIntrinsicHeight(width));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child?.getDistanceToActualBaseline(baseline);
}
