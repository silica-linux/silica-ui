// The surface of an Amalfi popover: Glass/Thick (`materials.md`: popovers on every edge and
// detached are Thick, radius 16; kit `Popovers/Popover/*`), with an arrow on one edge.
//
// The arrow is 8 deep and 20 wide at the base (flanks at atan(8 / 10) ≈ 38.7°: the kit's
// tangent lines through (30, 0), (20, 8) and (40, 8) on a top edge), its base corners rounded 4 and its
// tip 3 (the kit's radii); its centre is 30 from the start or the end of its edge, or in the
// middle (`Popovers/Popover/*/<Edge> Start|Center|End`). The body edge is 8 from the frame on
// the arrow's side, as in the kit.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../smooth_border.dart';
import '../../tokens.g.dart';

/// The edge of a popover that carries the arrow (the side facing what it points at).
enum AmalfiPopoverArrowEdge {
  /// The top edge: the popover is below its anchor.
  top,

  /// The bottom edge: the popover is above its anchor.
  bottom,

  /// The leading edge (left in left-to-right text): the popover is after its anchor.
  leading,

  /// The trailing edge: the popover is before its anchor.
  trailing,
}

/// Where the arrow sits along its edge.
enum AmalfiPopoverArrowAlignment {
  /// [AmalfiPopoverMetrics.arrowInset] from the start of the edge (the leading end of a top
  /// or bottom edge, the top end of a side edge).
  start,

  /// In the middle of the edge.
  center,

  /// [AmalfiPopoverMetrics.arrowInset] from the end of the edge.
  end,
}

/// The measures of popovers, from the kit masters `Popovers/*`.
abstract final class AmalfiPopoverMetrics {
  /// The corner radius (`materials.md`: Glass/Thick, radius 16).
  static const double radius = AmalfiRadii.popover;

  /// How far the arrow sticks out of the body.
  static const double arrowDepth = 8;

  /// Half the width of the arrow's base.
  static const double arrowHalfBase = 10;

  /// The radius of the corners where the arrow meets the body.
  static const double arrowBaseRadius = 4;

  /// The radius of the arrow's tip.
  static const double arrowTipRadius = 3;

  /// The distance of the arrow's centre from the start or end of its edge.
  static const double arrowInset = 30;

  /// The space between the body's edge and the content (`Popovers/Popover/Form|Text`).
  static const EdgeInsets padding = EdgeInsets.all(16);

  /// The space around a list (`Popovers/Popover/List`: 8 on every side).
  static const EdgeInsets listPadding = EdgeInsets.all(8);
}

/// The outline of a popover: a body with smooth corners and, unless [edge] is null
/// (detached), an arrow on [edge].
@immutable
class AmalfiPopoverShape {
  const AmalfiPopoverShape({
    this.edge,
    this.alignment = AmalfiPopoverArrowAlignment.center,
    this.arrowOffset,
    this.textDirection = TextDirection.ltr,
  });

  /// The edge with the arrow; null: none (a detached popover).
  final AmalfiPopoverArrowEdge? edge;

  /// Where the arrow sits along its edge when [arrowOffset] is null.
  final AmalfiPopoverArrowAlignment alignment;

  /// The distance of the arrow's centre from the start of its edge (as in [alignment]),
  /// overriding [alignment]; it is kept where the arrow fits between the corners.
  final double? arrowOffset;

  /// Decides which side is leading, and where a top or bottom edge starts.
  final TextDirection textDirection;

  /// The side of the frame the arrow is on, after the reading direction.
  AxisDirection? get side => switch (edge) {
    null => null,
    AmalfiPopoverArrowEdge.top => AxisDirection.up,
    AmalfiPopoverArrowEdge.bottom => AxisDirection.down,
    AmalfiPopoverArrowEdge.leading =>
      textDirection == TextDirection.rtl
          ? AxisDirection.right
          : AxisDirection.left,
    AmalfiPopoverArrowEdge.trailing =>
      textDirection == TextDirection.rtl
          ? AxisDirection.left
          : AxisDirection.right,
  };

  /// The corner radii in the kit's order (clockwise from the top-left corner, the arrow's
  /// base, tip and base where it is).
  List<double> get cornerRadii {
    const r = AmalfiPopoverMetrics.radius;
    const a = [
      AmalfiPopoverMetrics.arrowBaseRadius,
      AmalfiPopoverMetrics.arrowTipRadius,
      AmalfiPopoverMetrics.arrowBaseRadius,
    ];
    return switch (side) {
      null => const [r, r, r, r],
      AxisDirection.up => const [r, ...a, r, r, r],
      AxisDirection.right => const [r, r, ...a, r, r],
      AxisDirection.down => const [r, r, r, ...a, r],
      AxisDirection.left => const [r, r, r, r, ...a],
    };
  }

  /// The padding the arrow adds on its side.
  EdgeInsets get arrowInsets => switch (side) {
    null => EdgeInsets.zero,
    AxisDirection.up => const EdgeInsets.only(
      top: AmalfiPopoverMetrics.arrowDepth,
    ),
    AxisDirection.down => const EdgeInsets.only(
      bottom: AmalfiPopoverMetrics.arrowDepth,
    ),
    AxisDirection.left => const EdgeInsets.only(
      left: AmalfiPopoverMetrics.arrowDepth,
    ),
    AxisDirection.right => const EdgeInsets.only(
      right: AmalfiPopoverMetrics.arrowDepth,
    ),
  };

  /// The body's rectangle in [rect].
  Rect body(Rect rect) => arrowInsets.deflateRect(rect);

  /// The arrow tip in [rect]; null when detached.
  Offset? tip(Rect rect) {
    final side = this.side;
    if (side == null) return null;
    final b = body(rect);
    final horizontal = side == AxisDirection.up || side == AxisDirection.down;
    final extent = horizontal ? b.width : b.height;
    const inset = AmalfiPopoverMetrics.arrowInset;
    // A top or bottom edge starts at the leading end; a side edge at the top.
    final fromStart =
        arrowOffset ??
        switch (alignment) {
          AmalfiPopoverArrowAlignment.start => inset,
          AmalfiPopoverArrowAlignment.center => extent / 2,
          AmalfiPopoverArrowAlignment.end => extent - inset,
        };
    const room =
        AmalfiPopoverMetrics.radius + AmalfiPopoverMetrics.arrowHalfBase;
    final along = extent < 2 * room
        ? extent / 2
        : fromStart.clamp(room, extent - room).toDouble();
    final rtl = textDirection == TextDirection.rtl;
    return switch (side) {
      AxisDirection.up => Offset(
        rtl ? b.right - along : b.left + along,
        rect.top,
      ),
      AxisDirection.down => Offset(
        rtl ? b.right - along : b.left + along,
        rect.bottom,
      ),
      AxisDirection.left => Offset(rect.left, b.top + along),
      AxisDirection.right => Offset(rect.right, b.top + along),
    };
  }

  /// The outline in [rect].
  Path path(Rect rect) {
    final b = body(rect);
    final bodyPath = const AmalfiSmoothBorder(
      radius: AmalfiPopoverMetrics.radius,
    ).getOuterPath(b);
    final side = this.side;
    final tip = this.tip(rect);
    if (side == null || tip == null) return bodyPath;
    // The arrow in a canonical frame (base on y = 0, pointing to +y, centred on x = 0), then
    // turned onto its side.
    final angle = switch (side) {
      AxisDirection.down => 0.0,
      AxisDirection.left => math.pi / 2,
      AxisDirection.up => math.pi,
      AxisDirection.right => -math.pi / 2,
    };
    const depth = AmalfiPopoverMetrics.arrowDepth;
    // The centre of the base, on the body's edge.
    final base =
        tip - Offset(-math.sin(angle) * depth, math.cos(angle) * depth);
    final m = Matrix4.identity()
      ..translateByDouble(base.dx, base.dy, 0, 1)
      ..rotateZ(angle);
    return Path.combine(
      PathOperation.union,
      bodyPath,
      _arrow.transform(m.storage),
    );
  }

  static final Path _arrow = () {
    const h = AmalfiPopoverMetrics.arrowHalfBase;
    const d = AmalfiPopoverMetrics.arrowDepth;
    const rb = AmalfiPopoverMetrics.arrowBaseRadius;
    const rt = AmalfiPopoverMetrics.arrowTipRadius;
    // The flanks rise at θ from the base: the base corners turn by θ, the tip by 2θ.
    final theta = math.atan2(d, h);
    final tb = rb * math.tan(theta / 2);
    final tt = rt * math.tan(theta);
    final c = math.cos(theta), s = math.sin(theta);
    return Path()
      ..moveTo(-h - tb - 2, -1)
      ..lineTo(-h - tb - 2, 0)
      ..lineTo(-h - tb, 0)
      ..arcToPoint(
        Offset(-h + tb * c, tb * s),
        radius: const Radius.circular(rb),
      )
      ..lineTo(-tt * c, d - tt * s)
      ..arcToPoint(
        Offset(tt * c, d - tt * s),
        radius: const Radius.circular(rt),
        clockwise: false,
      )
      ..lineTo(h - tb * c, tb * s)
      ..arcToPoint(Offset(h + tb, 0), radius: const Radius.circular(rb))
      ..lineTo(h + tb + 2, 0)
      ..lineTo(h + tb + 2, -1)
      ..close();
  }();

  @override
  bool operator ==(Object other) =>
      other is AmalfiPopoverShape &&
      other.edge == edge &&
      other.alignment == alignment &&
      other.arrowOffset == arrowOffset &&
      other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(edge, alignment, arrowOffset, textDirection);
}

/// The outline of an [AmalfiPopoverShape] as a [ShapeBorder], for `AmalfiGlass` and
/// decorations.
class AmalfiPopoverBorder extends ShapeBorder {
  const AmalfiPopoverBorder(this.shape);

  final AmalfiPopoverShape shape;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      shape.path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      shape.path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) =>
      other is AmalfiPopoverBorder && other.shape == shape;

  @override
  int get hashCode => shape.hashCode;
}

/// Glass/Thick in the outline of [shape], holding [child] (not clipped): an `AmalfiGlass`
/// with an [AmalfiPopoverBorder] (backdrop blur and saturation clipped to the outline, tint,
/// a 1 pt inside rim, the rim light, and the level 3 shadow outside the outline only). With
/// [opaque] the backdrop is replaced by `Surface/Window`.
class AmalfiPopoverSurface extends StatelessWidget {
  const AmalfiPopoverSurface({
    super.key,
    required this.shape,
    this.opaque = false,
    this.child,
  });

  final AmalfiPopoverShape shape;

  /// Whether to draw the opaque fallback instead of blurring the backdrop.
  final bool opaque;

  final Widget? child;

  @override
  Widget build(BuildContext context) => AmalfiGlass(
    material: AmalfiMaterials.thick,
    shape: AmalfiPopoverBorder(shape),
    opaque: opaque,
    kind: AmalfiGlassKind.popover,
    child: child,
  );
}
