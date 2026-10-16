// The keyboard focus halo (`tokens.json` `focus`): [AmalfiFocus.halo] points of `Line/Focus`
// outside the control, following its outline.

import 'package:flutter/widgets.dart';

import '../smooth_border.dart';
import '../theme.dart';
import '../tokens.g.dart';
import 'layer_keys.dart';

/// The keyboard focus halo of a control the size of this widget (place it over the control
/// with `Positioned.fill`): a [width] ring of [color] outside [shape], or outside a smooth
/// rectangle of [radius] when [shape] is null. It fades with [AmalfiFades.quick] when
/// [visible] changes and never takes pointer events.
///
/// [color] null is `Line/Focus` of the theme in effect; [opacity] dims the ring (a field's
/// error halo is `Palette/Terracotta` at 30 %). The ring is drawn by a [DecoratedBox] keyed
/// [AmalfiLayerKeys.focusHalo] (the kit's `Focus Halo` layer).
class AmalfiFocusHalo extends StatelessWidget {
  const AmalfiFocusHalo({
    super.key,
    this.shape,
    this.radius = 0,
    this.color,
    this.visible = true,
    this.opacity = 1,
    this.width = AmalfiFocus.halo,
  });

  /// The control's outline; null: an [AmalfiSmoothBorder] of [radius]. Its side is ignored.
  final OutlinedBorder? shape;

  /// The corner radius of the control when [shape] is null.
  final double radius;

  /// The ring colour; null: `Line/Focus`.
  final Color? color;

  /// Whether the ring shows.
  final bool visible;

  /// The ring's opacity when shown.
  final double opacity;

  /// The ring width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final outline = shape ?? AmalfiSmoothBorder(radius: radius);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? opacity : 0,
        duration: AmalfiFades.quick.duration,
        curve: AmalfiFades.quick.curve,
        child: DecoratedBox(
          key: AmalfiLayerKeys.focusHalo,
          decoration: ShapeDecoration(
            shape: outline.copyWith(
              side: BorderSide(
                color:
                    color ?? AmalfiFocus.color(AmalfiTheme.of(context).colors),
                width: width,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
