// The text frames of the chrome: as wide as the text rounded up to the 4 pt grid (the kit's
// text frames of titles and labels), as tall as the line height of the text style (18 for
// Headline, not rounded up to 20).

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import '../../whole_points.dart';

/// Sizes [child] (a single-line text) as it wants, then rounds its width up to a multiple of
/// [step] points and its height up to a whole point; the child sits at the top left.
class AmalfiTitlebarTextBox extends SingleChildRenderObjectWidget {
  const AmalfiTitlebarTextBox({
    super.key,
    this.step = AmalfiGrid.base,
    super.child,
  }) : assert(step > 0);

  /// The rounding step of the width, in points.
  final double step;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTextBox(step);

  @override
  void updateRenderObject(BuildContext context, _RenderTextBox renderObject) {
    renderObject.step = step;
  }
}

class _RenderTextBox extends RenderProxyBox {
  _RenderTextBox(this._step);

  double _step;
  set step(double value) {
    if (value == _step) return;
    _step = value;
    markNeedsLayout();
  }

  Size _round(Size size, BoxConstraints constraints) => constraints.constrain(
    Size(ceilToWholePoints(size.width, _step), ceilToWholePoints(size.height)),
  );

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = _round(child.size, constraints);
    // Lay the child out again as wide as the box, so that its text alignment applies.
    if (size.width != child.size.width) {
      child.layout(
        BoxConstraints.tightFor(width: size.width),
        parentUsesSize: true,
      );
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _round(child.getDryLayout(constraints.loosen()), constraints);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      ceilToWholePoints(super.computeMinIntrinsicWidth(height), _step);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      ceilToWholePoints(super.computeMaxIntrinsicWidth(height), _step);
}
