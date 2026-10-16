// Stand-ins for the controls of other families that the form masters nest
// (`Buttons/Pop-up/Regular`, `Buttons/Push/Primary|Secondary/Regular`,
// `Toggles/Checkbox/With Label`, `Toggles/Switch/With Label`), drawn from those masters'
// rest states so that the forms can be shown and tested before the buttons and toggles
// families land. They work (they toggle, open, press) but have no hover, focus or disabled
// looks. NOT exported: forms take any widget as a control; replace these with the real
// widgets once they exist, then delete this file.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../../foundation/foundation.dart';

BoxShadow _lift(AmalfiColors colors) => BoxShadow(
  color: colors.shadowSoft,
  offset: const Offset(0, 1),
  blurRadius: 2,
);

/// `Buttons/Pop-up/Regular`: a 28 pt capsule showing [value], with the up-down chevron;
/// a click cycles through [options] (the real pop-up opens a menu).
class StandInPopUpButton extends StatelessWidget {
  const StandInPopUpButton({
    super.key,
    required this.value,
    this.options = const [],
    this.onChanged,
    this.width = 124,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return GestureDetector(
      onTap: options.isEmpty
          ? null
          : () => onChanged?.call(
              options[(options.indexOf(value) + 1) % options.length],
            ),
      child: SizedBox(
        width: width,
        height: 28,
        child: DecoratedBox(
          decoration: AmalfiShapeDecoration(
            color: colors.surfaceControl,
            shape: AmalfiSmoothBorder(
              radius: 14,
              side: BorderSide(
                color: colors.lineBorder,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            shadows: [_lift(colors)],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: AmalfiType.body(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                AmalfiGlyph(
                  AmalfiGlyphs.chevronUpDown,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Buttons/Push/Primary|Secondary/Regular`: a 28 pt capsule with a Body Emphasis label.
class StandInPushButton extends StatelessWidget {
  const StandInPushButton({
    super.key,
    required this.label,
    this.primary = false,
    this.onPressed,
    this.width = 72,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: 28,
        child: DecoratedBox(
          decoration: AmalfiShapeDecoration(
            color: primary ? colors.accentAmalfi : colors.surfaceControl,
            shape: AmalfiSmoothBorder(
              radius: 14,
              side: primary
                  ? BorderSide.none
                  : BorderSide(
                      color: colors.lineBorder,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
            ),
            shadows: primary ? null : [_lift(colors)],
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AmalfiType.bodyEmphasis(
                color: primary ? colors.textOnAccent : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `Toggles/Checkbox/With Label/On|Off`: a 16 pt box and [label], 20 tall, 4 padding.
class StandInCheckbox extends StatelessWidget {
  const StandInCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged?.call(!value),
      child: SizedBox(
        height: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: value ? colors.accentAmalfi : colors.surfaceRaised,
                    shape: AmalfiSmoothBorder(
                      radius: 5,
                      side: value
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.lineBorder,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                    ),
                    shadows: value ? null : [_lift(colors)],
                  ),
                  child: value
                      ? Center(
                          child: AmalfiGlyph(
                            AmalfiGlyphs.checkmark,
                            size: 12,
                            color: colors.textOnAccent,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SizedBox(
                  height: 18,
                  child: AmalfiWholePoints(
                    step: AmalfiGrid.base,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AmalfiType.body(color: colors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Toggles/Switch/With Label/On|Off`: [label], then a 40 × 24 switch at the trailing end,
/// in a [width] × 32 row with 12 / 4 padding.
class StandInSwitch extends StatelessWidget {
  const StandInSwitch({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.width = 240,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged?.call(!value),
      child: SizedBox(
        width: width,
        height: 32,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AmalfiType.body(color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                height: 24,
                child: DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: value ? colors.accentAmalfi : colors.surfaceSunken,
                    shape: AmalfiSmoothBorder(
                      radius: 12,
                      side: value
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.lineBorder,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                    ),
                  ),
                  child: Align(
                    // The kit's On thumb touches the trailing end, the Off one is 4 in.
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: value ? 0 : 4),
                      child: SizedBox.square(
                        dimension: 20,
                        child: DecoratedBox(
                          decoration: AmalfiShapeDecoration(
                            color: colors.textOnAccent,
                            shape: const CircleBorder(),
                            shadows: [_lift(colors)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
