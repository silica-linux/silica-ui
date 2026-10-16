// Gallery page: popovers (kit `Popovers/*`). The three contents, every arrow edge and
// position and the detached popover, and buttons that show a popover next to themselves.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';
import 'menus.dart' show GalleryButton, GalleryGlyph;

/// The popovers page.
final AmalfiGalleryPage popoversPage = AmalfiGalleryPage(
  family: 'popovers',
  title: 'Popovers',
  build: (context) => const _PopoversPage(),
);

/// A 228 × 28 text field standing in for the fields family until it exists.
class _FieldStandIn extends StatelessWidget {
  const _FieldStandIn();

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: ShapeDecoration(
        color: colors.surfaceRaised,
        shape: AmalfiSmoothBorder(
          radius: AmalfiRadii.field,
          side: BorderSide(color: colors.lineBorder),
        ),
      ),
      child: Text(
        'Amalfi coast',
        style: AmalfiType.body(color: colors.textPrimary),
      ),
    );
  }
}

Widget _content(String variant) => switch (variant) {
  'Form' => const AmalfiPopoverForm(
    title: 'New collection',
    field: _FieldStandIn(),
    actions: [GalleryButton('Cancel'), GalleryButton('Create', primary: true)],
  ),
  'List' => const AmalfiPopoverList(
    entries: [
      AmalfiMenuSection('Open in'),
      AmalfiMenuAction('Recents', icon: GalleryGlyph()),
      AmalfiMenuAction('Downloads', icon: GalleryGlyph()),
      AmalfiMenuAction('Pictures', icon: GalleryGlyph()),
    ],
  ),
  _ => AmalfiPopoverText(
    title: 'About this ingredient',
    body:
        'Olive oil keeps the crust tender and adds a peppery note. Use a mild, fruity one for sweet bakes.',
    action: Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Text(
          'Learn more',
          style: AmalfiType.body(
            color: AmalfiTheme.of(context).colors.accentAmalfi,
          ),
        ),
      ),
    ),
  ),
};

class _PopoversPage extends StatelessWidget {
  const _PopoversPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final variant in ['Form', 'List', 'Text'])
        SpecimenSection(
          title: 'Popover · $variant',
          children: [
            for (final edge in AmalfiPopoverArrowEdge.values)
              for (final alignment in AmalfiPopoverArrowAlignment.values)
                Specimen(
                  label: '${_name(edge.name)} ${_name(alignment.name)}',
                  child: AmalfiPopover(
                    arrowEdge: edge,
                    arrowAlignment: alignment,
                    padding: variant == 'List'
                        ? AmalfiPopoverMetrics.listPadding
                        : AmalfiPopoverMetrics.padding,
                    child: _content(variant),
                  ),
                ),
            Specimen(
              label: 'Detached',
              child: AmalfiPopover(
                padding: variant == 'List'
                    ? AmalfiPopoverMetrics.listPadding
                    : AmalfiPopoverMetrics.padding,
                child: _content(variant),
              ),
            ),
          ],
        ),
      SpecimenSection(
        title: 'Shown next to a control',
        note:
            'Click: the popover opens on that side (or flips); Esc or a click outside closes it.',
        children: [
          for (final placement in AmalfiPopoverPlacement.values)
            Specimen(
              label: _name(placement.name),
              child: Builder(
                builder: (context) => GalleryButton(
                  'Show',
                  onPressed: () {
                    final box = context.findRenderObject();
                    if (box is! RenderBox) return;
                    showAmalfiPopover(
                      context: context,
                      anchor: box.localToGlobal(Offset.zero) & box.size,
                      placement: placement,
                      builder: (_, _) => _content('Text'),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    ],
  );

  static String _name(String s) => s[0].toUpperCase() + s.substring(1);
}
