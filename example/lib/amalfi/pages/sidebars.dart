// Gallery page: sidebars (kit `Sidebars/*`): rows in every state, badges, headers, groups,
// the footer and a live panel.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The sidebars page.
final AmalfiGalleryPage sidebarsPage = AmalfiGalleryPage(
  family: 'sidebars',
  title: 'Sidebars',
  build: (context) => const _SidebarsPage(),
);

class _SidebarsPage extends StatelessWidget {
  const _SidebarsPage();

  @override
  Widget build(BuildContext context) {
    final surface = AmalfiTheme.of(context).colors.surfaceSidebar;
    Widget onSidebar(Widget child) => ColoredBox(
      color: surface,
      child: SizedBox(width: 216, child: child),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpecimenSection(
          title: 'Row',
          note: 'Point at a row to see Hover.',
          children: [
            for (final badge in [null, '12'])
              for (final (state, selected, enabled) in [
                ('Rest', false, true),
                ('Selected', true, true),
                ('Disabled', false, false),
              ])
                Specimen(
                  label: '${badge == null ? 'Plain' : 'Badge'} · $state',
                  child: onSidebar(
                    AmalfiSidebarRow(
                      label: 'Documents',
                      icon: AmalfiGlyphs.folder,
                      badge: badge,
                      selected: selected,
                      enabled: enabled,
                      onTap: () {},
                    ),
                  ),
                ),
          ],
        ),
        SpecimenSection(
          title: 'Badge',
          children: [
            Specimen(label: '12', child: AmalfiSidebarBadge('12')),
            Specimen(label: '128', child: AmalfiSidebarBadge('128')),
          ],
        ),
        SpecimenSection(
          title: 'Header',
          children: [
            for (final (label, expanded) in [
              ('Plain', null),
              ('Open', true),
              ('Closed', false),
            ])
              Specimen(
                label: label,
                child: onSidebar(
                  AmalfiSidebarHeader(
                    title: 'Favourites',
                    expanded: expanded,
                    onToggle: () {},
                  ),
                ),
              ),
          ],
        ),
        SpecimenSection(
          title: 'Group and footer',
          children: [
            Specimen(
              label: 'Group (click the header)',
              child: onSidebar(const _Group()),
            ),
            Specimen(
              label: 'Footer',
              child: onSidebar(
                AmalfiSidebarFooter(
                  children: [
                    AmalfiIconButton(
                      icon: AmalfiGlyph(AmalfiGlyphs.plus),
                      onPressed: () {},
                      semanticLabel: 'plus',
                      shape: AmalfiIconButtonShape.square,
                      size: AmalfiControlSize.small,
                    ),
                    AmalfiIconButton(
                      icon: AmalfiGlyph(AmalfiGlyphs.gear),
                      onPressed: () {},
                      semanticLabel: 'gear',
                      shape: AmalfiIconButtonShape.square,
                      size: AmalfiControlSize.small,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SpecimenSection(
          title: 'Panel',
          children: [
            Specimen(
              label: 'Live',
              child: SizedBox(height: 460, child: _Panel()),
            ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatefulWidget {
  const _Group();

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  bool _open = true;

  @override
  Widget build(BuildContext context) => AmalfiSidebarGroup(
    title: 'Places',
    expanded: _open,
    onToggle: () => setState(() => _open = !_open),
    children: [
      AmalfiSidebarRow(
        label: 'Documents',
        icon: AmalfiGlyphs.doc,
        onTap: () {},
      ),
      AmalfiSidebarRow(
        label: 'Downloads',
        icon: AmalfiGlyphs.download,
        badge: '12',
        onTap: () {},
      ),
      AmalfiSidebarRow(
        label: 'Pictures',
        icon: AmalfiGlyphs.photo,
        onTap: () {},
      ),
    ],
  );
}

class _Panel extends StatefulWidget {
  const _Panel();

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  static const _rows = [
    ('Recents', AmalfiGlyphs.clock, null),
    ('Documents', AmalfiGlyphs.doc, '12'),
    ('Downloads', AmalfiGlyphs.download, null),
  ];
  static const _library = [
    ('Photos', AmalfiGlyphs.photo),
    ('Music', AmalfiGlyphs.musicNote),
  ];

  String _selected = 'Recents';
  bool _favourites = true, _libraryOpen = true, _tags = false;

  AmalfiSidebarRow _row(String label, AmalfiGlyphData icon, [String? badge]) =>
      AmalfiSidebarRow(
        label: label,
        icon: icon,
        badge: badge,
        selected: _selected == label,
        onTap: () => setState(() => _selected = label),
      );

  @override
  Widget build(BuildContext context) => AmalfiSidebarPanel(
    footer: AmalfiSidebarFooter(
      children: [
        AmalfiIconButton(
          icon: AmalfiGlyph(AmalfiGlyphs.plus),
          onPressed: () {},
          semanticLabel: 'plus',
          shape: AmalfiIconButtonShape.square,
          size: AmalfiControlSize.small,
        ),
        AmalfiIconButton(
          icon: AmalfiGlyph(AmalfiGlyphs.gear),
          onPressed: () {},
          semanticLabel: 'gear',
          shape: AmalfiIconButtonShape.square,
          size: AmalfiControlSize.small,
        ),
      ],
    ),
    children: [
      AmalfiSidebarGroup(
        title: 'Favourites',
        expanded: _favourites,
        onToggle: () => setState(() => _favourites = !_favourites),
        children: [for (final (l, i, b) in _rows) _row(l, i, b)],
      ),
      AmalfiSidebarGroup(
        title: 'Library',
        expanded: _libraryOpen,
        onToggle: () => setState(() => _libraryOpen = !_libraryOpen),
        children: [for (final (l, i) in _library) _row(l, i)],
      ),
      AmalfiSidebarGroup(
        title: 'Tags',
        expanded: _tags,
        onToggle: () => setState(() => _tags = !_tags),
        children: [_row('Recipes', AmalfiGlyphs.tag)],
      ),
    ],
  );
}
