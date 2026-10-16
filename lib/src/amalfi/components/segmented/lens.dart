// The lens of a pressed glass segmented control (`materials.md`, "Lens rule"): a Glass/Clear
// capsule that grows over the pressed item, follows the pointer while it drags and settles on
// the chosen item before it fades.
//
// Kept apart from the control on purpose: [AmalfiSegmentLens] only draws the lens in a given
// rectangle at a given presence, and [amalfiSegmentLensRect] / [amalfiSegmentLensMagnification]
// give the geometry, so the look can be replaced without touching the control's behaviour.
//
// Geometry from the kit (`Segments/Control/*/Pressed`): the lens reaches
// [AmalfiSegmentMetrics.lensOutset] (8) beyond the pressed item on each side and 8 beyond the
// track above and below: an 88 × 44 capsule over a 72 × 20 item of a 28 pt track.
// `materials.md` gives "8 pt above and below" (as the kit) but "width = segment + 8" and
// "height 1.25 × control"; the kit's 8 on every side is used (44 = 28 + 16, not 35).
//
// Look: Glass/Clear as `AmalfiGlass` draws it (a 2 pt backdrop blur, no tint, the 1 pt inside
// rim and the rim light). The refraction of `materials.md` (distortion, chromatic aberration,
// specular edge) is not drawn: the items over the lens are magnified instead
// ([amalfiSegmentLensMagnification], ×1.1 under the lens centre).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../tokens.g.dart';
import 'metrics.dart';

/// The lens over an item at [item] of a track of [trackHeight] whose top is at [trackTop],
/// at [presence] (0: the item's own capsule, 1: the full lens), centred at [centreX].
Rect amalfiSegmentLensRect({
  required Rect item,
  required double trackTop,
  required double trackHeight,
  required double centreX,
  required double presence,
}) {
  const outset = AmalfiSegmentMetrics.lensOutset;
  final p = presence.isFinite ? math.max(presence, 0.0) : 0.0;
  final full = Rect.fromLTWH(
    centreX - item.width / 2 - outset,
    trackTop - outset,
    item.width + 2 * outset,
    trackHeight + 2 * outset,
  );
  final from = Rect.fromCenter(
    center: Offset(centreX, item.center.dy),
    width: item.width,
    height: item.height,
  );
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
/// [opacity]. It ignores the pointer and semantics.
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
        radius: constraints.biggest.shortestSide / 2,
        opaque: opaque,
        child: const SizedBox.expand(),
      ),
    );
    if (opacity < 1) lens = Opacity(opacity: opacity, child: lens);
    return IgnorePointer(child: ExcludeSemantics(child: lens));
  }
}
