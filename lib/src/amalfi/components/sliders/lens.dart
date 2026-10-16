// The lens over a dragged slider thumb (kit `Sliders/Thumb/Lens/Dragging`, `materials.md`,
// "Lens rule"): a Glass/Clear capsule around the thumb's core, magnifying what is under it.
// Its size and radius follow the lens rule ([AmalfiLens]): 8 beyond the thumb along the track,
// 12 beyond the track across it (36 × 28), radius half its height minus 1.
//
// The lens refracts the slider's own pixels: the slider hands it what lies under it (the
// track, the fill, the ticks) as [AmalfiSliderLens.under], drawn here magnified about the
// lens centre with the material's brightness, then the clear glass (2 pt blur, rim, rim
// light) and the thumb's core on top. Distortion, chromatic aberration and the specular
// highlight of the kit's lens are not drawn (`AmalfiGlass` draws Clear without refraction).

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../glass.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'thumb.dart';

/// A Glass/Clear lens with the core of a dragged thumb in its centre, as large as its
/// constraints allow (`AmalfiSliderMetrics.lens` in a slider), with the lens rule's radius
/// ([AmalfiLens.radiusOf]).
///
/// [under] is what lies under the lens, laid out at the lens's size; it is drawn magnified by
/// [magnification] about the centre and clipped to the capsule.
class AmalfiSliderLens extends StatelessWidget {
  const AmalfiSliderLens({
    super.key,
    this.under,
    this.magnification = defaultMagnification,
  });

  /// The magnification of the lens (`materials.md`: ≈ 1.1×).
  static const double defaultMagnification = 1.1;

  /// What lies under the lens; null: nothing (the glass alone).
  final Widget? under;

  /// How much larger [under] is drawn.
  final double magnification;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
      final radius = AmalfiLens.radiusOf(size);
      final brightness = AmalfiTheme.of(context).brightness;
      final material = AmalfiMaterials.clear;
      final gain = brightness == Brightness.dark
          ? material.brightnessDark
          : material.brightnessLight;
      final under = this.under;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (under != null)
            Positioned.fill(
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: AmalfiSmoothBorder(radius: radius),
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(<double>[
                    gain, 0, 0, 0, 0, //
                    0, gain, 0, 0, 0, //
                    0, 0, gain, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: Transform.scale(scale: magnification, child: under),
                ),
              ),
            ),
          Positioned.fill(
            child: AmalfiGlass(
              material: material,
              radius: radius,
              kind: AmalfiGlassKind.control,
            ),
          ),
          const Center(child: AmalfiSliderThumb(states: {WidgetState.dragged})),
        ],
      );
    },
  );
}
