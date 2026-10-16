// Gallery page: windows (kit `Windows/*`): the frame, every layout of the regions, active and
// inactive, with sample content; the toolbar controls are the other families' widgets.

import 'package:flutter/widgets.dart';

import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The windows page.
final AmalfiGalleryPage windowsPage = AmalfiGalleryPage(
  family: 'windows',
  title: 'Windows',
  build: (context) => const _WindowsPage(),
);

const String _body =
    'Whisk the eggs with sugar until pale, fold in the flour, then the lemon zest and juice.';

List<AmalfiSegment> _icons(List<AmalfiGlyphData> glyphs) => [
  for (final g in glyphs)
    AmalfiSegment.icon(AmalfiGlyph(g), semanticLabel: g.name),
];

/// An action group (segmented family).
Widget _actions(List<AmalfiGlyphData> glyphs) =>
    AmalfiActionSegments(segments: _icons(glyphs), onPressed: (_) {});

class _Content extends StatelessWidget {
  const _Content({this.padding = 24});

  final double padding;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final active = WindowActiveScope.of(context);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lemon cake',
            style: AmalfiType.title1(
              color: active ? colors.textPrimary : colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _body,
            style: AmalfiType.body(
              color: active ? colors.textSecondary : colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  const _Sidebar({this.top = 8});

  final double top;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _selected = 'Recents';

  @override
  Widget build(BuildContext context) => AmalfiSidebarPanel(
    edge: false,
    padding: EdgeInsets.fromLTRB(12, widget.top, 12, 0),
    children: [
      const AmalfiSidebarHeader(title: 'Favourites'),
      for (final (label, icon) in [
        ('Recents', AmalfiGlyphs.clock),
        ('Documents', AmalfiGlyphs.doc),
        ('Downloads', AmalfiGlyphs.download),
      ])
        AmalfiSidebarRow(
          label: label,
          icon: icon,
          selected: _selected == label,
          onTap: () => setState(() => _selected = label),
        ),
    ],
  );
}

final _nav = AmalfiToolbarPiece(
  child: _actions([AmalfiGlyphs.chevronLeft, AmalfiGlyphs.chevronRight]),
);

final _search = AmalfiToolbarPiece(
  child: AmalfiSearchField(size: AmalfiFieldSize.large, width: 200),
);

Widget _controls() =>
    AmalfiControlsPiece(onClose: () {}, onMinimise: () {}, onZoom: () {});

Widget _unifiedBar({
  AmalfiToolbarSurface surface = AmalfiToolbarSurface.window,
}) => AmalfiToolbar(
  surface: surface,
  children: [
    _controls(),
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiGlyph(AmalfiGlyphs.sidebar),
        onPressed: () {},
        semanticLabel: 'sidebar',
      ),
    ),
    _nav,
    AmalfiTitlePiece(title: 'Lemon cake'),
    AmalfiSpacerPiece(),
    _search,
  ],
);

AmalfiWindowColumn _sidebarColumn() => AmalfiWindowColumn(
  width: AmalfiWindowMetrics.sidebarWidth,
  toolbarOverChild: true,
  toolbar: AmalfiToolbar.sidebarSection(
    children: [
      _controls(),
      AmalfiSpacerPiece(),
      AmalfiToolbarPiece(
        child: AmalfiToolbarButton(
          icon: AmalfiGlyph(AmalfiGlyphs.sidebar),
          onPressed: () {},
          semanticLabel: 'sidebar',
        ),
      ),
    ],
  ),
  child: const _Sidebar(top: 60),
);

AmalfiWindowColumn _contentColumn() => AmalfiWindowColumn(
  toolbar: AmalfiToolbar.section(
    children: [
      _nav,
      AmalfiTitlePiece(title: 'Lemon cake'),
      AmalfiSpacerPiece(),
      _search,
    ],
  ),
  child: const _Content(),
);

class _Window extends StatelessWidget {
  const _Window({
    required this.size,
    required this.child,
    this.active = true,
    this.kind = AmalfiWindowKind.regular,
  });

  final Size size;
  final Widget child;
  final bool active;
  final AmalfiWindowKind kind;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: AmalfiWindow(active: active, kind: kind, child: child),
  );
}

class _WindowsPage extends StatelessWidget {
  const _WindowsPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpecimenSection(
        title: 'Window',
        children: [
          Specimen(
            label: 'Document',
            child: _Window(
              size: const Size(540, 360),
              child: AmalfiWindowLayout(
                bar: AmalfiTitleBar(
                  title: 'Lemon cake.recipe',
                  document: true,
                  onDocumentMenu: () {},
                  onClose: () {},
                  onMinimise: () {},
                  onZoom: () {},
                ),
                barHeight: AmalfiToolbarMetrics.titleBarHeight,
                content: const _Content(padding: 28),
              ),
            ),
          ),
          Specimen(
            label: 'Panel',
            child: _Window(
              size: const Size(300, 260),
              child: AmalfiWindowLayout(
                bar: AmalfiTitleBar(
                  title: 'Style',
                  onClose: () {},
                  onMinimise: () {},
                  onZoom: () {},
                ),
                barHeight: AmalfiToolbarMetrics.titleBarHeight,
                content: const SizedBox.expand(),
              ),
            ),
          ),
          Specimen(
            label: 'Utility',
            child: _Window(
              kind: AmalfiWindowKind.utility,
              size: const Size(260, 196),
              child: AmalfiWindowLayout(
                bar: AmalfiTitleBar(
                  title: 'Quick find',
                  style: AmalfiTitleBarStyle.utility,
                  onClose: () {},
                ),
                barHeight: AmalfiToolbarMetrics.compactHeight,
                content: const SizedBox.expand(),
              ),
            ),
          ),
          for (final active in [true, false])
            Specimen(
              label: active ? 'Sidebar Inspector' : 'Inactive',
              child: _Window(
                active: active,
                size: const Size(900, 420),
                child: AmalfiWindowLayout(
                  bar: _unifiedBar(surface: AmalfiToolbarSurface.none),
                  barSeparator: true,
                  sidesUnderBar: true,
                  sidebar: const _Sidebar(top: 60),
                  inspector: const SizedBox.expand(),
                  content: const _Content(),
                ),
              ),
            ),
          Specimen(
            label: 'Full Screen Strip',
            child: SizedBox(
              width: 900,
              height: 112,
              child: AmalfiFullScreenStrip(
                // The menu bar is the shell's (M4); an empty strip here.
                menuBar: const SizedBox.expand(),
                toolbar: _unifiedBar(),
              ),
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Layouts',
        children: [
          for (final active in [true, false])
            Specimen(
              label:
                  'Unified Toolbar Sidebar · ${active ? 'Active' : 'Inactive'}',
              child: _Window(
                active: active,
                size: const Size(860, 420),
                child: AmalfiWindowLayout(
                  bar: _unifiedBar(),
                  barSeparator: true,
                  sidebar: const _Sidebar(),
                  content: const _Content(),
                ),
              ),
            ),
          Specimen(
            label: 'Unified Toolbar · Sidebar Collapsed',
            child: _Window(
              size: const Size(720, 360),
              child: AmalfiWindowLayout(
                bar: _unifiedBar(),
                content: const _Content(),
              ),
            ),
          ),
          for (final active in [true, false])
            Specimen(
              label: 'Split Toolbar · ${active ? 'Active' : 'Inactive'}',
              child: _Window(
                active: active,
                size: const Size(860, 420),
                child: AmalfiSplitWindowLayout(
                  columns: [_sidebarColumn(), _contentColumn()],
                ),
              ),
            ),
          Specimen(
            label: 'Split Toolbar Inspector',
            child: _Window(
              size: const Size(1100, 420),
              child: AmalfiSplitWindowLayout(
                columns: [
                  _sidebarColumn(),
                  _contentColumn(),
                  AmalfiWindowColumn(
                    width: AmalfiWindowMetrics.inspectorWidth,
                    toolbarOverChild: true,
                    toolbar: AmalfiToolbar.section(
                      surface: AmalfiToolbarSurface.sidebar,
                      children: [
                        AmalfiSpacerPiece(),
                        AmalfiToolbarPiece(
                          child: _actions([
                            AmalfiGlyphs.plus,
                            AmalfiGlyphs.tag,
                            AmalfiGlyphs.star,
                          ]),
                        ),
                      ],
                    ),
                    child: ColoredBox(
                      color: AmalfiTheme.of(context).colors.surfaceSidebar,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Specimen(
            label: 'Split Toolbar Three Columns',
            child: _Window(
              size: const Size(1200, 420),
              child: AmalfiSplitWindowLayout(
                columns: [
                  _sidebarColumn(),
                  AmalfiWindowColumn(
                    width: AmalfiWindowMetrics.listWidth,
                    toolbar: AmalfiToolbar.section(
                      children: [
                        AmalfiTitlePiece(title: 'Recipes'),
                        AmalfiSpacerPiece(),
                      ],
                    ),
                    child: SizedBox.expand(),
                  ),
                  _contentColumn(),
                ],
              ),
            ),
          ),
          Specimen(
            label: 'Compact Toolbar',
            child: _Window(
              size: const Size(520, 280),
              child: AmalfiWindowLayout(
                bar: AmalfiToolbar.compact(
                  children: [
                    AmalfiControlsPiece(
                      width: AmalfiToolbarMetrics.compactControlsWidth,
                      leading: 0,
                      onClose: () {},
                      onMinimise: () {},
                      onZoom: () {},
                    ),
                    Expanded(
                      child: AmalfiTitlePiece(title: 'Lemon cake', fill: true),
                    ),
                    AmalfiToolbarPiece(
                      leading: 0,
                      trailing: 0,
                      child: AmalfiToolbarButton(
                        icon: AmalfiGlyph(AmalfiGlyphs.share),
                        onPressed: () {},
                        semanticLabel: 'share',
                      ),
                    ),
                  ],
                ),
                barHeight: AmalfiToolbarMetrics.compactHeight,
                barSeparator: true,
                content: const _Content(padding: 16),
              ),
            ),
          ),
          Specimen(
            label: 'Title Only',
            child: _Window(
              size: const Size(520, 280),
              child: AmalfiWindowLayout(
                bar: AmalfiTitleBar(
                  title: 'Lemon cake',
                  style: AmalfiTitleBarStyle.titleOnly,
                  onClose: () {},
                  onMinimise: () {},
                  onZoom: () {},
                ),
                barHeight: AmalfiToolbarMetrics.titleOnlyHeight,
                content: const _Content(),
              ),
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Sidebar Body',
        children: [
          Specimen(
            label: 'Full (under a split toolbar)',
            child: SizedBox(width: 240, height: 320, child: _Sidebar(top: 60)),
          ),
          Specimen(
            label: 'Below Bar',
            child: SizedBox(width: 240, height: 320, child: _Sidebar()),
          ),
        ],
      ),
    ],
  );
}
