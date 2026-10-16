// Gallery page: tooltips (kit `Tooltips/*`). The bubbles of every variant, then live targets
// with a tooltip on each side: rest the pointer on one.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The tooltips page.
final AmalfiGalleryPage tooltipsPage = AmalfiGalleryPage(
  family: 'tooltips',
  title: 'Tooltips',
  build: (context) => const _TooltipsPage(),
);

class _TooltipsPage extends StatelessWidget {
  const _TooltipsPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SpecimenSection(
        title: 'Tooltip',
        children: [
          Specimen(
            label: 'One Line',
            child: AmalfiTooltip(message: 'Add to favourites'),
          ),
          Specimen(
            label: 'Two Lines',
            child: AmalfiTooltip(
              message:
                  'Shows the recipe in a new window so you can keep this one open.',
            ),
          ),
          Specimen(
            label: 'Shortcut',
            child: AmalfiTooltip(message: 'Duplicate', shortcut: '⌘D'),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Placement',
        note:
            'Rest the pointer on a target: 700 ms the first time, at once while moving.',
        children: [
          for (final placement in AmalfiTooltipPlacement.values)
            Specimen(label: _name(placement), child: _Target(placement)),
        ],
      ),
    ],
  );

  static String _name(AmalfiTooltipPlacement p) => switch (p) {
    AmalfiTooltipPlacement.below => 'Below',
    AmalfiTooltipPlacement.above => 'Above',
    AmalfiTooltipPlacement.leading => 'Leading',
    AmalfiTooltipPlacement.trailing => 'Trailing',
  };
}

/// A 28 pt round target (a stand-in until the buttons family exists) with a tooltip.
class _Target extends StatelessWidget {
  const _Target(this.placement);

  final AmalfiTooltipPlacement placement;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Padding(
      // Room for the tooltip on every side inside the gallery.
      padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 36),
      child: AmalfiTooltipRegion(
        message: 'Add to favourites',
        placement: placement,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surfaceControl,
            shape: StadiumBorder(side: BorderSide(color: colors.lineBorder)),
            shadows: AmalfiShadows.of(
              AmalfiTheme.of(context).brightness,
            ).level1,
          ),
          child: SizedBox.square(
            dimension: AmalfiControlSize.regular.height,
            child: Center(
              child: Text(
                '+',
                style: AmalfiType.body(color: colors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
