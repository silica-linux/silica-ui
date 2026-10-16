// The face of a field-like control: the background (fill and border) and the keyboard focus
// halo outside it (`AmalfiFocus`: 3 pt of `Line/Focus`, following the control's corners).
// Shared by the fields, wells and forms.

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../smooth_border.dart';
import '../../token_types.dart';
import '../../tokens.g.dart';

/// The focus halo: a [width] ring of [color] outside a smooth rectangle of [radius], the size
/// of this widget. It fades with [AmalfiFades.quick] when [visible] changes.
///
/// [opacity] dims the ring (the error halo is `Palette/Terracotta` at 30 %).
class AmalfiFocusHalo extends StatelessWidget {
  const AmalfiFocusHalo({
    super.key,
    required this.radius,
    required this.color,
    this.visible = true,
    this.opacity = 1,
    this.width = AmalfiFocus.halo,
  });

  /// The corner radius of the control (the ring follows it outside).
  final double radius;

  /// The ring colour (`Line/Focus`, or the error colour).
  final Color color;

  /// Whether the ring shows.
  final bool visible;

  /// The ring's opacity when shown.
  final double opacity;

  /// The ring width.
  final double width;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: visible ? opacity : 0,
      duration: AmalfiFades.quick.duration,
      curve: AmalfiFades.quick.curve,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: AmalfiSmoothBorder(
            radius: radius,
            side: BorderSide(
              color: color,
              width: width,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
        ),
      ),
    ),
  );
}

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
                  child: const SizedBox.expand(),
                )
              : DecoratedBox(
                  decoration: ShapeDecoration(
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
