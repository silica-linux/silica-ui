// The lens of a pressed glass segmented control (`materials.md`, "Lens rule"): a Glass/Clear
// capsule that grows over the pressed item, follows the pointer while it drags and settles on
// the chosen item before it fades.
//
// Kept apart from the control on purpose: [AmalfiSegmentLens] only draws the lens in a given
// rectangle at a given presence, and [amalfiSegmentLensRect] / [amalfiSegmentLensMagnification]
// give the geometry, so the look can be replaced without touching the control's behaviour.
//
// Geometry: the lens rule ([AmalfiLens], user decision 2026-10-16): 8 beyond the pressed item
// on each side, 12 above and below it (an 88 × 44 lens over a 72 × 20 item of a 28 pt track,
// as `Segments/Control/*/Pressed`), radius half its height minus 1 (the kit's is half its
// height: a deviation in the tests).
//
// Look: Glass/Clear as `AmalfiGlass` draws it (a 2 pt backdrop blur, no tint, the 1 pt inside
// rim and the rim light). The refraction of `materials.md` (distortion, chromatic aberration,
// specular edge) is not drawn: the items over the lens are magnified instead
// ([amalfiSegmentLensMagnification], ×1.1 under the lens centre).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../glass.dart';
import '../../tokens.g.dart';

/// The lens over [item] slid to be centred at [centreX], at [presence] (0: the item's own
/// capsule, 1: the full lens, [AmalfiLens.around] the item; a spring may overshoot).
Rect amalfiSegmentLensRect({
  required Rect item,
  required double centreX,
  required double presence,
}) {
  final p = presence.isFinite ? math.max(presence, 0.0) : 0.0;
  final from = Rect.fromCenter(
    center: Offset(centreX, item.center.dy),
    width: item.width,
    height: item.height,
  );
  final full = AmalfiLens.around(from);
  return Rect.lerp(from, full, p) ?? full;
}

/// The scale of the content of an item centred at [itemCentreX], [itemWidth] wide, under a
/// lens centred at [lensCentreX] at [presence]: the lens's magnification at its centre,
/// falling to none one item width away.
double amalfiSegmentLensMagnification({
  required double itemCentreX,
  required double itemWidth,
  required double lensCentreX,
  required double presence,
}) {
  final magnification = AmalfiMaterials.clear.refraction?.magnification ?? 1.0;
  if (itemWidth <= 0 || !presence.isFinite) return 1;
  final cover = (1 - (itemCentreX - lensCentreX).abs() / itemWidth).clamp(
    0.0,
    1.0,
  );
  return 1 + (magnification - 1) * presence.clamp(0.0, 1.0) * cover;
}

/// The lens of a pressed glass segment: a Glass/Clear capsule filling its parent, at
/// [opacity], with the lens rule's radius ([AmalfiLens.radiusOf]). It ignores the pointer
/// and semantics.
class AmalfiSegmentLens extends StatelessWidget {
  const AmalfiSegmentLens({super.key, this.opacity = 1, this.opaque = false});

  /// The lens's opacity (it fades out once it has settled).
  final double opacity;

  /// Whether the glass is drawn without blur (see [AmalfiGlass.opaque]).
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.expand();
    Widget lens = LayoutBuilder(
      builder: (context, constraints) => AmalfiGlass(
        key: const ValueKey('amalfi-segment-lens'),
        material: AmalfiMaterials.clear,
        radius: AmalfiLens.radiusOf(constraints.biggest),
        opaque: opaque,
        child: const SizedBox.expand(),
      ),
    );
    if (opacity < 1) lens = Opacity(opacity: opacity, child: lens);
    return IgnorePointer(child: ExcludeSemantics(child: lens));
  }
}
