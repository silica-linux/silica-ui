// Gallery page: title bars and toolbars (kit `Titlebars/*`): window controls in every state,
// the modular pieces, the bars and split toolbar sections, title bars and tabs, active and
// inactive. Toolbar controls are stand-ins (AmalfiToolbarPlaceholder) until the buttons,
// segmented and fields families land.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The title bars and toolbars page.
final AmalfiGalleryPage titlebarsPage = AmalfiGalleryPage(
  family: 'titlebars',
  title: 'Title bars and toolbars',
  build: (context) => const _TitlebarsPage(),
);

String _kind(AmalfiWindowControlKind k) => switch (k) {
  AmalfiWindowControlKind.close => 'Close',
  AmalfiWindowControlKind.minimise => 'Minimise',
  AmalfiWindowControlKind.zoom => 'Zoom',
};

String _state(AmalfiWindowControlState s) => switch (s) {
  AmalfiWindowControlState.rest => 'Rest',
  AmalfiWindowControlState.hover => 'Hover',
  AmalfiWindowControlState.pressed => 'Pressed',
  AmalfiWindowControlState.inactive => 'Inactive',
};

/// A piece in a 52 pt slot on the window surface.
class _Slot extends StatelessWidget {
  const _Slot(this.piece);

  final Widget piece;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AmalfiTheme.of(context).colors.surfaceWindow,
    child: SizedBox(
      height: AmalfiToolbarMetrics.toolbarHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [piece],
      ),
    ),
  );
}

const _nav = AmalfiToolbarPlaceholder.group([
  AmalfiChromeGlyphs.chevronLeft,
  AmalfiChromeGlyphs.chevronRight,
]);

const _view = AmalfiToolbarPlaceholder.segmented([
  AmalfiChromeGlyphs.listBullet,
  AmalfiChromeGlyphs.squareGrid2x2,
]);

List<Widget> _unified() => [
  AmalfiControlsPiece(onClose: () {}, onMinimise: () {}, onZoom: () {}),
  const AmalfiToolbarPiece(
    child: AmalfiToolbarPlaceholder.icon(AmalfiChromeGlyphs.sidebar),
  ),
  const AmalfiToolbarPiece(child: _nav),
  const AmalfiTitlePiece(title: 'Lemon cake'),
  const AmalfiSpacerPiece(),
  const AmalfiToolbarPiece(child: _view),
  const AmalfiToolbarPiece(child: AmalfiToolbarPlaceholder.search()),
];

class _TitlebarsPage extends StatelessWidget {
  const _TitlebarsPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpecimenSection(
        title: 'Dot',
        note:
            'Measured window controls: 14 pt discs in 16 pt cells, 23 apart. '
            'Pressed is not in the kit (measured colours).',
        children: [
          for (final kind in AmalfiWindowControlKind.values)
            for (final state in AmalfiWindowControlState.values)
              Specimen(
                label: '${_kind(kind)} · ${_state(state)}',
                child: AmalfiWindowDot(kind: kind, state: state),
              ),
        ],
      ),
      SpecimenSection(
        title: 'Controls',
        note:
            'Live: point at a group to show the symbols; press and drag off to cancel.',
        children: [
          Specimen(
            label: 'Active',
            child: AmalfiWindowControlGroup(
              onClose: () {},
              onMinimise: () {},
              onZoom: () {},
            ),
          ),
          Specimen(
            label: 'Inactive',
            child: AmalfiWindowControlGroup(
              onClose: () {},
              onMinimise: () {},
              onZoom: () {},
              active: false,
            ),
          ),
          Specimen(
            label: 'Not resizable',
            child: AmalfiWindowControlGroup(onClose: () {}),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Piece',
        children: [
          for (final active in [true, false]) ...[
            Specimen(
              label: 'Controls · ${active ? 'Active' : 'Inactive'}',
              child: _Slot(
                AmalfiControlsPiece(
                  onClose: () {},
                  onMinimise: () {},
                  onZoom: () {},
                  active: active,
                ),
              ),
            ),
            Specimen(
              label: 'Title · ${active ? 'Active' : 'Inactive'}',
              child: _Slot(
                AmalfiTitlePiece(title: 'Lemon cake', active: active),
              ),
            ),
            Specimen(
              label: 'Title + Subtitle · ${active ? 'Active' : 'Inactive'}',
              child: _Slot(
                AmalfiTitlePiece(
                  title: 'Lemon cake',
                  subtitle: 'Edited today',
                  active: active,
                ),
              ),
            ),
            Specimen(
              label:
                  'Title + Document Icon · ${active ? 'Active' : 'Inactive'}',
              child: _Slot(
                AmalfiTitlePiece(
                  title: 'Lemon cake.recipe',
                  document: true,
                  onDocumentMenu: () {},
                  active: active,
                ),
              ),
            ),
          ],
          for (final (label, piece) in <(String, Widget)>[
            (
              'Sidebar Toggle',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.icon(
                  AmalfiChromeGlyphs.sidebar,
                ),
              ),
            ),
            ('Nav', const AmalfiToolbarPiece(child: _nav)),
            for (final n in [2, 3, 4])
              (
                'Item Group $n',
                AmalfiToolbarPiece(
                  child: AmalfiToolbarPlaceholder.group([
                    for (var i = 0; i < n; i++) AmalfiChromeGlyphs.plus,
                  ]),
                ),
              ),
            ('Segmented', const AmalfiToolbarPiece(child: _view)),
            (
              'Segmented 4',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.segmented([
                  AmalfiChromeGlyphs.listBullet,
                  AmalfiChromeGlyphs.squareGrid2x2,
                  AmalfiChromeGlyphs.photo,
                  AmalfiChromeGlyphs.clock,
                ]),
              ),
            ),
            (
              'Segmented Text',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.text([
                  'All',
                  'Mine',
                  'Shared',
                  'Recent',
                ]),
              ),
            ),
            (
              'Search',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.search(),
              ),
            ),
            (
              'Search Token',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.search(width: 240, height: 28),
              ),
            ),
            (
              'Share',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.icon(AmalfiChromeGlyphs.share),
              ),
            ),
            (
              'More',
              const AmalfiToolbarPiece(
                child: AmalfiToolbarPlaceholder.icon(
                  AmalfiChromeGlyphs.ellipsisCircle,
                ),
              ),
            ),
            (
              'Add',
              const AmalfiToolbarPiece.add(
                child: AmalfiToolbarPlaceholder.icon(AmalfiChromeGlyphs.plus),
              ),
            ),
            (
              'Mail Send',
              const AmalfiToolbarPiece(
                trailing: 16,
                child: AmalfiToolbarPlaceholder.round(AmalfiChromeGlyphs.plus),
              ),
            ),
            ('Spacer', const AmalfiSpacerPiece()),
            // App pieces: the same slots with each app's controls.
            for (final (name, n) in [
              ('Mail Filter', 2),
              ('Mail Reply', 3),
              ('Mail Triage', 3),
              ('Notes Format', 3),
              ('Notes Insert', 3),
              ('Notes Lists', 3),
              ('Notes Share', 2),
              ('Preview Highlight', 2),
              ('Preview Highlight Off', 2),
              ('Preview View', 2),
              ('Preview Zoom', 3),
            ])
              (
                name,
                AmalfiToolbarPiece(
                  child: AmalfiToolbarPlaceholder.group([
                    for (var i = 0; i < n; i++) AmalfiChromeGlyphs.plus,
                  ]),
                ),
              ),
            for (final (name, glyph) in [
              ('Doc Info', AmalfiChromeGlyphs.doc),
              ('Doc Share', AmalfiChromeGlyphs.share),
              ('Mail Compose', AmalfiChromeGlyphs.compose),
              ('Notes New', AmalfiChromeGlyphs.compose),
              ('Preview Inspector', AmalfiChromeGlyphs.sidebar),
              ('Preview Markup', AmalfiChromeGlyphs.compose),
              ('Preview Rotate', AmalfiChromeGlyphs.plus),
            ])
              (
                name,
                AmalfiToolbarPiece(child: AmalfiToolbarPlaceholder.icon(glyph)),
              ),
            ('Notes View', const AmalfiToolbarPiece(child: _view)),
          ])
            Specimen(label: label, child: _Slot(piece)),
        ],
      ),
      SpecimenSection(
        title: 'Bar',
        children: [
          for (final active in [true, false])
            for (final (inset, padding) in [
              (8, AmalfiToolbarMetrics.unifiedPadding),
              (16, AmalfiToolbarMetrics.unifiedPaddingWide),
            ])
              Specimen(
                label:
                    'Unified · Full Inset $inset · ${active ? 'Active' : 'Inactive'}',
                child: SizedBox(
                  width: 760,
                  child: AmalfiToolbar(
                    active: active,
                    padding: padding,
                    children: _unified(),
                  ),
                ),
              ),
          for (final active in [true, false]) ...[
            Specimen(
              label: 'Compact · ${active ? 'Active' : 'Inactive'}',
              child: SizedBox(
                width: 520,
                child: AmalfiToolbar.compact(
                  active: active,
                  children: [
                    AmalfiControlsPiece(
                      onClose: () {},
                      onMinimise: () {},
                      onZoom: () {},
                    ),
                    const AmalfiToolbarPiece(child: _nav),
                    const AmalfiTitlePiece(title: 'Lemon cake'),
                    const AmalfiSpacerPiece(),
                    const AmalfiToolbarPiece(
                      child: AmalfiToolbarPlaceholder.icon(
                        AmalfiChromeGlyphs.share,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Specimen(
              label: 'Title Only · ${active ? 'Active' : 'Inactive'}',
              child: SizedBox(
                width: 520,
                child: AmalfiTitleBar(
                  title: 'Lemon cake',
                  style: AmalfiTitleBarStyle.titleOnly,
                  active: active,
                  onClose: () {},
                  onMinimise: () {},
                  onZoom: () {},
                ),
              ),
            ),
          ],
        ],
      ),
      SpecimenSection(
        title: 'Section',
        children: [
          for (final active in [true, false])
            Specimen(
              label:
                  'Sidebar · Content · Inspector · ${active ? 'Active' : 'Inactive'}',
              child: SizedBox(
                width: 1000,
                child: AmalfiWindowScope(
                  active: active,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: AmalfiToolbar.sidebarSection(
                          children: [
                            AmalfiControlsPiece(
                              onClose: () {},
                              onMinimise: () {},
                              onZoom: () {},
                            ),
                            const AmalfiSpacerPiece(),
                            const AmalfiToolbarPiece(
                              child: AmalfiToolbarPlaceholder.icon(
                                AmalfiChromeGlyphs.sidebar,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: AmalfiToolbar.section(
                          children: [
                            AmalfiToolbarPiece(child: _nav),
                            AmalfiTitlePiece(title: 'Lemon cake'),
                            AmalfiSpacerPiece(),
                            AmalfiToolbarPiece(child: _view),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 260,
                        child: AmalfiToolbar.section(
                          surface: AmalfiBarSurface.sidebar,
                          children: [
                            AmalfiSpacerPiece(),
                            AmalfiToolbarPiece(
                              child: AmalfiToolbarPlaceholder.group([
                                AmalfiChromeGlyphs.plus,
                                AmalfiChromeGlyphs.tag,
                                AmalfiChromeGlyphs.star,
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Title Bar',
        children: [
          for (final active in [true, false])
            for (final (label, subtitle, document) in [
              ('Plain', null, false),
              ('Subtitle', 'Edited today at 09:41', false),
              ('Document', null, true),
            ])
              Specimen(
                label: '$label · ${active ? 'Active' : 'Inactive'}',
                child: SizedBox(
                  width: 520,
                  child: ColoredBox(
                    color: AmalfiTheme.of(context).colors.surfaceWindow,
                    child: AmalfiTitleBar(
                      title: document ? 'Lemon cake.recipe' : 'Lemon cake',
                      subtitle: subtitle,
                      document: document,
                      active: active,
                      onClose: () {},
                      onMinimise: () {},
                      onZoom: () {},
                    ),
                  ),
                ),
              ),
        ],
      ),
      SpecimenSection(
        title: 'Tab',
        note: 'Point at a tab to see Hover; the close button shows on hover.',
        children: [
          Specimen(
            label: 'Rest',
            child: AmalfiTab(
              label: 'Lemon cake',
              onSelect: () {},
              onClose: () {},
            ),
          ),
          Specimen(
            label: 'Selected',
            child: AmalfiTab(
              label: 'Lemon cake',
              selected: true,
              onSelect: () {},
              onClose: () {},
            ),
          ),
          const Specimen(label: 'Tab Bar', child: _LiveTabBar()),
        ],
      ),
    ],
  );
}

class _LiveTabBar extends StatefulWidget {
  const _LiveTabBar();

  @override
  State<_LiveTabBar> createState() => _LiveTabBarState();
}

class _LiveTabBarState extends State<_LiveTabBar> {
  final List<String> _tabs = ['Lemon cake', 'Fig jam', 'Olive oil'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 560,
    child: AmalfiTabBar(
      tabs: [for (final t in _tabs) AmalfiTabData(t)],
      selected: _selected,
      onSelect: (i) => setState(() => _selected = i),
      onClose: (i) => setState(() {
        if (_tabs.length == 1) return;
        _tabs.removeAt(i);
        _selected = _selected.clamp(0, _tabs.length - 1);
      }),
      onNewTab: () => setState(() {
        _tabs.add('Untitled ${_tabs.length + 1}');
        _selected = _tabs.length - 1;
      }),
    ),
  );
}
