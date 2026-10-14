import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  // The Dock-menu path of TIP-01, origin at the apex, body edge at y = −10.187: fillets from
  // ±15.289, flanks from ±7.992 (y −6.720) to ±4.105 (y −1.950).
  test('the menu outline has the measured points', () {
    const tip = TipOutline.menu;
    const d = 10.187;
    expect(tip.halfBase, closeTo(15.289, 0.01));
    expect(tip.filletEnd.dx, closeTo(-7.992, 0.01));
    expect(tip.filletEnd.dy - d, closeTo(-6.720, 0.01));
    expect(tip.apexStart.dx, closeTo(-4.105, 0.01));
    expect(tip.apexStart.dy - d, closeTo(-1.950, 0.01));
  });

  test('the popover outlines fit their tip rectangles', () {
    expect(2 * TipOutline.popover.halfBase, closeTo(32, 0.5));
    expect(TipOutline.popover.depth, closeTo(11, 0.25));
    expect(2 * TipOutline.popoverSide.halfBase, closeTo(39, 0.5));
    expect(TipOutline.popoverSide.depth, closeTo(12, 0.3));
    expect(2 * TipOutline.menu.halfBase, closeTo(MenuMetrics.tipBase, 0.6));
  });

  test('the path spans the base and reaches the apex', () {
    final path = TipOutline.menu.path(overlap: 0.5);
    // Base and overlap (getBounds would include the arcs' control points).
    expect(path.contains(const Offset(-15.2, -0.4)), isTrue);
    expect(path.contains(const Offset(15.2, -0.4)), isTrue);
    expect(path.contains(const Offset(-15.4, -0.4)), isFalse);
    expect(path.contains(const Offset(0, -0.6)), isFalse);
    // The apex at the measured depth.
    expect(path.contains(const Offset(0, 10.1)), isTrue);
    expect(path.contains(const Offset(0, 10.3)), isFalse);
    // Round apex: a point beside the apex is outside.
    expect(path.contains(const Offset(0, 10)), isTrue);
    expect(path.contains(const Offset(3, 10)), isFalse);
    // Concave fillets: the straight chord from the base corner to the flank leaves the shape.
    expect(path.contains(const Offset(-12, 1.2)), isFalse);
  });

  test('side popovers sit the side tip depth from the anchor', () {
    final p = placePopover(
      anchor: const Rect.fromLTWH(100, 200, 20, 20),
      size: const Size(200, 120),
      bounds: const Rect.fromLTWH(0, 0, 800, 600),
      preferred: TipEdge.right,
    );
    expect(p.edge, TipEdge.left);
    expect(p.rect.left, 120 + PopoverMetrics.sideTipDepth + PopoverMetrics.gap);
  });
}
