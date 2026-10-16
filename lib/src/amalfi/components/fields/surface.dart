// The face of a field-like control: the background (fill and border) and the keyboard focus
// halo outside it (`AmalfiFocusHalo`).
// Shared by the fields, wells and forms.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../glass.dart';
import '../../smooth_border.dart';
import '../../token_types.dart';

/// The background of a field: a smooth rectangle of [radius] filled with [fill] and a
/// [borderWidth] border of [border] inside it, or, with [glass], that material instead
/// (search fields are Glass/Regular capsules), with an optional [halo] around it and
/// [child] on top.
class AmalfiFieldSurface extends StatelessWidget {
  const AmalfiFieldSurface({
    super.key,
    required this.radius,
    this.fill,
    this.border,
    this.borderWidth = 1,
    this.glass,
    this.halo,
    this.haloVisible = true,
    this.haloOpacity = 1,
    this.child,
  });

  final double radius;
  final Color? fill;
  final Color? border;
  final double borderWidth;

  /// Draws this glass instead of [fill] and [border].
  final AmalfiGlassMaterial? glass;

  /// The halo colour; null: no halo.
  final Color? halo;
  final bool haloVisible;
  final double haloOpacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final glass = this.glass;
    final border = this.border;
    final halo = this.halo;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: glass != null
              ? AmalfiGlass(
                  material: glass,
                  radius: radius,
                  kind: AmalfiGlassKind.control,
                  child: const SizedBox.expand(),
                )
              : DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: fill,
                    shape: AmalfiSmoothBorder(
                      radius: radius,
                      side: border == null
                          ? BorderSide.none
                          : BorderSide(
                              color: border,
                              width: borderWidth,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                    ),
                  ),
                ),
        ),
        if (halo != null)
          Positioned.fill(
            child: AmalfiFocusHalo(
              radius: radius,
              color: halo,
              visible: haloVisible,
              opacity: haloOpacity,
            ),
          ),
        ?child,
      ],
    );
  }
}
