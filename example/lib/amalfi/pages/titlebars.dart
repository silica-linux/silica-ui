// Gallery page: title bars and toolbars (kit `Titlebars/*`): window controls in every state,
// the modular pieces, the bars and split toolbar sections, title bars and tabs, active and
// inactive. The toolbar controls are the buttons, segmented and fields families' widgets.

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

List<AmalfiSegment> _icons(List<AmalfiTitlebarGlyphData> glyphs) => [
  for (final g in glyphs)
    AmalfiSegment.icon(AmalfiTitlebarGlyph(g), semanticLabel: g.name),
];

/// An action group (segmented family).
Widget _actions(List<AmalfiTitlebarGlyphData> glyphs) =>
    AmalfiActionSegments(segments: _icons(glyphs), onPressed: (_) {});

/// A select-one control of icons or labels (segmented family), live.
class _Switcher extends StatefulWidget {
  const _Switcher({this.glyphs = const [], this.labels = const []});

  final List<AmalfiTitlebarGlyphData> glyphs;
  final List<String> labels;

  @override
  State<_Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<_Switcher> {
  Set<int> _selected = const {0};

  @override
  Widget build(BuildContext context) => AmalfiSegmentedControl(
    segments: widget.labels.isEmpty
        ? _icons(widget.glyphs)
        : [for (final l in widget.labels) AmalfiSegment.text(l)],
    selected: _selected,
    onChanged: (s) => setState(() => _selected = s),
    size: AmalfiControlSize.large,
  );
}

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

final _nav = _actions([
  AmalfiTitlebarGlyphs.chevronLeft,
  AmalfiTitlebarGlyphs.chevronRight,
]);

final _view = _Switcher(
  glyphs: [AmalfiTitlebarGlyphs.listBullet, AmalfiTitlebarGlyphs.squareGrid2x2],
);

List<Widget> _unified() => [
  AmalfiControlsPiece(onClose: () {}, onMinimise: () {}, onZoom: () {}),
  AmalfiToolbarPiece(
    child: AmalfiToolbarButton(
      icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.sidebar),
      onPressed: () {},
      semanticLabel: 'sidebar',
    ),
  ),
  AmalfiToolbarPiece(child: _nav),
  AmalfiTitlePiece(title: 'Lemon cake'),
  AmalfiSpacerPiece(),
  AmalfiToolbarPiece(child: _view),
  AmalfiToolbarPiece(
    child: AmalfiSearchField(size: AmalfiFieldSize.large, width: 200),
  ),
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
              AmalfiToolbarPiece(
                child: AmalfiToolbarButton(
                  icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.sidebar),
                  onPressed: () {},
                  semanticLabel: 'sidebar',
                ),
              ),
            ),
            ('Nav', AmalfiToolbarPiece(child: _nav)),
            for (final n in [2, 3, 4])
              (
                'Item Group $n',
                AmalfiToolbarPiece(
                  child: _actions([
                    for (var i = 0; i < n; i++) AmalfiTitlebarGlyphs.plus,
                  ]),
                ),
              ),
            ('Segmented', AmalfiToolbarPiece(child: _view)),
            (
              'Segmented 4',
              AmalfiToolbarPiece(
                child: _Switcher(
                  glyphs: [
                    AmalfiTitlebarGlyphs.listBullet,
                    AmalfiTitlebarGlyphs.squareGrid2x2,
                    AmalfiTitlebarGlyphs.photo,
                    AmalfiTitlebarGlyphs.clock,
                  ],
                ),
              ),
            ),
            (
              'Segmented Text',
              AmalfiToolbarPiece(
                child: _Switcher(labels: ['All', 'Mine', 'Shared', 'Recent']),
              ),
            ),
            (
              'Search',
              AmalfiToolbarPiece(
                child: AmalfiSearchField(
                  size: AmalfiFieldSize.large,
                  width: 200,
                ),
              ),
            ),
            (
              'Search Token',
              AmalfiToolbarPiece(
                child: AmalfiSearchField(width: 240, tokens: ['Recipes']),
              ),
            ),
            (
              'Share',
              AmalfiToolbarPiece(
                child: AmalfiToolbarButton(
                  icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.share),
                  onPressed: () {},
                  semanticLabel: 'share',
                ),
              ),
            ),
            (
              'More',
              AmalfiToolbarPiece(
                child: AmalfiToolbarButton(
                  icon: AmalfiTitlebarGlyph(
                    AmalfiTitlebarGlyphs.ellipsisCircle,
                  ),
                  onPressed: () {},
                  semanticLabel: 'ellipsisCircle',
                ),
              ),
            ),
            (
              'Add',
              AmalfiToolbarPiece.add(
                child: AmalfiToolbarButton(
                  icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.plus),
                  onPressed: () {},
                  semanticLabel: 'plus',
                ),
              ),
            ),
            (
              'Mail Send',
              AmalfiToolbarPiece(
                trailing: 16,
                child: AmalfiIconButton(
                  icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.plus),
                  onPressed: () {},
                  semanticLabel: 'plus',
                ),
              ),
            ),
            ('Spacer', AmalfiSpacerPiece()),
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
                  child: _actions([
                    for (var i = 0; i < n; i++) AmalfiTitlebarGlyphs.plus,
                  ]),
                ),
              ),
            for (final (name, glyph) in [
              ('Doc Info', AmalfiTitlebarGlyphs.doc),
              ('Doc Share', AmalfiTitlebarGlyphs.share),
              ('Mail Compose', AmalfiTitlebarGlyphs.compose),
              ('Notes New', AmalfiTitlebarGlyphs.compose),
              ('Preview Inspector', AmalfiTitlebarGlyphs.sidebar),
              ('Preview Markup', AmalfiTitlebarGlyphs.compose),
              ('Preview Rotate', AmalfiTitlebarGlyphs.plus),
            ])
              (
                name,
                AmalfiToolbarPiece(
                  child: AmalfiToolbarButton(
                    icon: AmalfiTitlebarGlyph(glyph),
                    onPressed: () {},
                    semanticLabel: 'glyph',
                  ),
                ),
              ),
            ('Notes View', AmalfiToolbarPiece(child: _view)),
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
                    AmalfiToolbarPiece(child: _nav),
                    AmalfiTitlePiece(title: 'Lemon cake'),
                    AmalfiSpacerPiece(),
                    AmalfiToolbarPiece(
                      child: AmalfiToolbarButton(
                        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.share),
                        onPressed: () {},
                        semanticLabel: 'share',
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
                child: WindowActiveScope(
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
                            AmalfiSpacerPiece(),
                            AmalfiToolbarPiece(
                              child: AmalfiToolbarButton(
                                icon: AmalfiTitlebarGlyph(
                                  AmalfiTitlebarGlyphs.sidebar,
                                ),
                                onPressed: () {},
                                semanticLabel: 'sidebar',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AmalfiToolbar.section(
                          children: [
                            AmalfiToolbarPiece(child: _nav),
                            AmalfiTitlePiece(title: 'Lemon cake'),
                            AmalfiSpacerPiece(),
                            AmalfiToolbarPiece(child: _view),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: AmalfiToolbar.section(
                          surface: AmalfiToolbarSurface.sidebar,
                          children: [
                            AmalfiSpacerPiece(),
                            AmalfiToolbarPiece(
                              child: _actions([
                                AmalfiTitlebarGlyphs.plus,
                                AmalfiTitlebarGlyphs.tag,
                                AmalfiTitlebarGlyphs.star,
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
          Specimen(label: 'Tab Bar', child: _LiveTabBar()),
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
