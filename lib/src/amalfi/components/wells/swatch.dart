// Colour swatches (kit `Wells/Swatch Chip/Rest|Selected`, `Wells/Swatch Row/*`): a 24 pt
// disc of the colour with a 1 pt `Line/Border` inside, a 2 pt `Accent/Amalfi` ring outside
// when selected; a row of six with 8 between them and 4 around.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';

/// The measures of the swatches.
abstract final class AmalfiSwatchMetrics {
  /// The side of a chip.
  static const double chip = 24;

  /// The selection ring, outside the chip.
  static const double ring = 2;

  /// Between two chips of a row.
  static const double gap = 8;

  /// Around the chips of a row.
  static const double padding = 4;
}

/// A colour swatch: a disc of [color]. [selected] adds the accent ring.
///
/// [onPressed] runs on a click, or on Space / Enter with the keyboard focus (shown with the
/// focus halo); null: the chip only shows the colour. [semanticLabel] names the colour.
class AmalfiSwatchChip extends StatefulWidget {
  const AmalfiSwatchChip({
    super.key,
    required this.color,
    this.selected = false,
    this.onPressed,
    this.semanticLabel,
    this.focusNode,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<AmalfiSwatchChip> createState() => _AmalfiSwatchChipState();
}

class _AmalfiSwatchChipState extends State<AmalfiSwatchChip> {
  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    const radius = AmalfiSwatchMetrics.chip / 2;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: AmalfiInteraction(
        onActivate: widget.onPressed,
        activators: AmalfiInteraction.buttonActivates,
        focusNode: widget.focusNode,
        cursor: SystemMouseCursors.click,
        builder: (context, state) => SizedBox.square(
          dimension: AmalfiSwatchMetrics.chip,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.selected)
                DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    shape: AmalfiSmoothBorder(
                      radius: radius,
                      side: BorderSide(
                        color: colors.accentAmalfi,
                        width: AmalfiSwatchMetrics.ring,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: AmalfiShapeDecoration(
                  color: widget.color,
                  shape: AmalfiSmoothBorder(
                    radius: radius,
                    side: BorderSide(
                      color: colors.lineBorder,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                ),
              ),
              AmalfiFocusHalo(radius: radius, visible: state.focused),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of swatches of [colors]; the first one equal to [selected] has the ring.
/// [onSelected] receives the colour of a clicked chip.
class AmalfiSwatchRow extends StatelessWidget {
  const AmalfiSwatchRow({
    super.key,
    required this.colors,
    this.selected,
    this.onSelected,
  });

  final List<Color> colors;
  final Color? selected;
  final ValueChanged<Color>? onSelected;

  @override
  Widget build(BuildContext context) {
    final chosen = selected;
    final mark = chosen == null ? -1 : colors.indexOf(chosen);
    return Padding(
      padding: const EdgeInsets.all(AmalfiSwatchMetrics.padding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < colors.length; i++) ...[
            if (i > 0) const SizedBox(width: AmalfiSwatchMetrics.gap),
            AmalfiSwatchChip(
              color: colors[i],
              selected: i == mark,
              onPressed: onSelected == null
                  ? null
                  : () => onSelected?.call(colors[i]),
            ),
          ],
        ],
      ),
    );
  }
}
