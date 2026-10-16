// Whole points: Amalfi puts every frame, text frames included, on whole points (most on the
// 4 pt grid). Text measures fractional widths; this rounds its box up so that what follows it
// lands on the grid.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Sizes [child] as it wants, then rounds its width up to a multiple of [step] points and its
/// height up to a multiple of [heightStep] (by default [step] too), within the constraints.
/// The child is laid out at its own size, placed by [alignment] (top left by default; a
/// centred label is `Alignment.topCenter`, as the kit centres button labels in their frames).
///
/// Use it around text whose box decides the layout: `AmalfiWholePoints(child: Text(…))`.
/// With `step: AmalfiGrid.base` the box lands on the 4 pt grid, as the kit draws the text
/// frames of controls whose size follows their label (the tooltip "Add to favourites": text
/// 97.03 wide, frame 100). `AmalfiWholePoints(step: AmalfiGrid.base, heightStep: 1)` keeps
/// the line height while the width lands on the grid, as the kit draws button labels ("Button"
/// in Body Emphasis: 45.4 wide, frame 48 × 20).
class AmalfiWholePoints extends SingleChildRenderObjectWidget {
  const AmalfiWholePoints({
    super.key,
    this.step = 1,
    this.heightStep,
    this.alignment = Alignment.topLeft,
    super.child,
  }) : assert(step > 0),
       assert(heightStep == null || heightStep > 0);

  /// The rounding step of the width (and of the height without [heightStep]), in points.
  final double step;

  /// The rounding step of the height, in points; null: [step].
  final double? heightStep;

  /// Where the child sits in the rounded box.
  final Alignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholePoints(step, heightStep ?? step, alignment);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderWholePoints renderObject,
  ) {
    renderObject
      ..step = step
      ..heightStep = heightStep ?? step
      ..alignment = alignment;
  }
}

/// [x] rounded up to a multiple of [step] points, ignoring float noise below 1/1000 pt.
double ceilToWholePoints(double x, [double step = 1]) => x.isFinite
    ? ((x - 1e-3) / step).ceilToDouble().clamp(0, double.infinity) * step
    : x;

class _RenderWholePoints extends RenderShiftedBox {
  _RenderWholePoints(this._step, this._heightStep, this._alignment)
    : super(null);

  Alignment _alignment;
  set alignment(Alignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  double _step;
  set step(double value) {
    if (value == _step) return;
    _step = value;
    markNeedsLayout();
  }

  double _heightStep;
  set heightStep(double value) {
    if (value == _heightStep) return;
    _heightStep = value;
    markNeedsLayout();
  }

  double _ceil(double x) => ceilToWholePoints(x, _step);

  double _ceilHeight(double x) => ceilToWholePoints(x, _heightStep);

  Size _round(Size s) => Size(_ceil(s.width), _ceilHeight(s.height));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(_round(child.size));
    (child.parentData! as BoxParentData).offset = _alignment.alongOffset(
      size - child.size as Offset,
    );
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
      _ceilHeight(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _ceilHeight(super.computeMaxIntrinsicHeight(width));
}
