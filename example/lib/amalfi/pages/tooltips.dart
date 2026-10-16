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

/// A round icon button with a tooltip: it adds to (or removes from) the favourites.
class _Target extends StatefulWidget {
  const _Target(this.placement);

  final AmalfiTooltipPlacement placement;

  @override
  State<_Target> createState() => _TargetState();
}

class _TargetState extends State<_Target> {
  bool _favourite = false;

  @override
  Widget build(BuildContext context) {
    final message = _favourite ? 'Remove from favourites' : 'Add to favourites';
    return Padding(
      // Room for the tooltip on every side inside the gallery.
      padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 36),
      child: AmalfiTooltipRegion(
        message: message,
        placement: widget.placement,
        child: AmalfiIconButton(
          icon: AmalfiGlyph(
            AmalfiGlyphs.star,
            color: _favourite
                ? AmalfiTheme.of(context).colors.accentAmalfi
                : null,
          ),
          semanticLabel: message,
          onPressed: () => setState(() => _favourite = !_favourite),
        ),
      ),
    );
  }
}
