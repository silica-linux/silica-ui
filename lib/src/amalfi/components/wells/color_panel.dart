// The colour panel (kit `Wells/Color Panel/Swatch Grid`): Glass/Thick, radius 16, a
// Headline title and rows of swatches.

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import 'swatch.dart';

/// The measures of the colour panel.
abstract final class AmalfiColorPanelMetrics {
  /// The corner radius (`popover`: the panel floats like a popover).
  static const double radius = AmalfiRadii.popover;

  /// The space around the content.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(12, 14, 12, 12);
}

/// A panel of colour swatches: [title], then one [AmalfiSwatchRow] per list of [swatches]
/// (the Amalfi colours of the appearance, [amalfiSwatches], when null).
///
/// The first chip equal to [selected] has the ring; [onSelected] receives the colour of a
/// clicked chip.
class AmalfiColorPanel extends StatelessWidget {
  const AmalfiColorPanel({
    super.key,
    this.title = 'Swatches',
    this.swatches,
    this.selected,
    this.onSelected,
    this.opaque = false,
  });

  final String title;
  final List<List<Color>>? swatches;
  final Color? selected;
  final ValueChanged<Color>? onSelected;

  /// Whether the glass is drawn without blur (see [AmalfiGlass.opaque]).
  final bool opaque;

  /// The Amalfi colours as the kit's swatch grid shows them, four rows of six: the accent
  /// and the palette; lavender, the pressed accent, the text colours and the sunken surface;
  /// the surfaces, the border and the glass tint; the soft accent, the separator, the glass
  /// rim, the press overlay, the soft shadow and the text on the accent.
  static List<List<Color>> amalfiSwatches(AmalfiColors c) => [
    [
      c.accentAmalfi,
      c.paletteLimone,
      c.paletteTerracotta,
      c.paletteBouganville,
      c.paletteUlivo,
      c.paletteMare,
    ],
    [
      c.paletteLavanda,
      c.accentAmalfiPressed,
      c.textPrimary,
      c.textSecondary,
      c.textTertiary,
      c.surfaceSunken,
    ],
    [
      c.surfaceSidebar,
      c.surfaceRaised,
      c.surfaceWindow,
      c.surfaceControlPressed,
      c.lineBorder,
      c.glassTint,
    ],
    [
      c.accentAmalfiSoft,
      c.lineSeparator,
      c.glassRimDark,
      c.statePressOverlay,
      c.shadowSoft,
      c.textOnAccent,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final rows = swatches ?? amalfiSwatches(colors);
    var marked = false;
    return AmalfiGlass(
      material: AmalfiMaterials.thick,
      radius: AmalfiColorPanelMetrics.radius,
      opaque: opaque,
      child: Padding(
        padding: AmalfiColorPanelMetrics.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  AmalfiType.headlineToken.lineHeight ??
                  AmalfiType.headlineToken.size,
              child: AmalfiWholePoints(
                step: AmalfiGrid.base,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AmalfiType.headline(color: colors.textPrimary),
                ),
              ),
            ),
            for (final row in rows)
              AmalfiSwatchRow(
                colors: row,
                // Only the first chip of the panel with the colour is marked.
                selected: () {
                  final s = selected;
                  if (marked || s == null || !row.contains(s)) return null;
                  marked = true;
                  return s;
                }(),
                onSelected: onSelected,
              ),
          ],
        ),
      ),
    );
  }
}
