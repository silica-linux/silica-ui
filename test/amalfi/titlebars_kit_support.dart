// Shared helpers of the title bar, window and sidebar kit tests.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// Kit decision overridden by the user: the window controls keep the measured 14 pt disc.
const String measuredDisc =
    'measured window controls: 14 pt disc in the 16 pt cell (kit: 16 pt disc)';

/// Kit decision overridden by the user: the window controls keep the measured 23 pt pitch.
const String measuredPitch =
    'measured window controls: pitch 23, group 62 wide (kit: pitch 24, 64 wide)';

/// The window controls at their measured place (x by bar height), not the kit's.
const String measuredPlace =
    'measured window controls: first cell at x 18 / 16 / 12 / 8 for a 52 / 48 / 40 / 32 bar '
    '(kit: 20 or 16)';

/// The 14 pt disc against the kit's 16 pt one: the rim ring moves by 1 pt, so single pixels
/// differ completely along it; the fill, gradient and symbol agree.
const KitPixelTolerance dotTolerance = KitPixelTolerance(mean: 45, max: 255);

/// The group: the discs 14 pt and 23 apart against 16 and 24.
const KitPixelTolerance controlsTolerance = KitPixelTolerance(
  mean: 40,
  max: 255,
);

/// Text against the kit with the text included: CoreText (kit) and Skia rasterise Inter
/// differently, and on the small, mostly transparent canvases of bars, pieces and tabs the
/// text is a large share of the pixels (light text on transparent in dark: mean up to ~4.5).
const KitPixelTolerance chromeText = KitPixelTolerance(mean: 5, max: 255);

bool _registered = false;

/// Teaches [RenderedStyle] the window control disc (gradient, light rim, dark edges as inner
/// shadows, radius 7 of the 14 pt disc).
void registerChromeStyles() {
  if (_registered) return;
  _registered = true;
  RenderedStyle.register((widget, context) {
    if (widget is! AmalfiWindowDot) return null;
    final s = AmalfiWindowDotStyle.of(
      widget.kind,
      widget.state,
      AmalfiTheme.of(context).brightness,
    );
    final rim = s.rim;
    return RenderedStyle(
      gradients: [s.gradient],
      borders: [
        if (rim != null)
          RenderedBorder(rim, s.rimWidth, BorderSide.strokeAlignInside),
      ],
      innerShadows: [
        if (s.edgeTop case final c?)
          BoxShadow(color: c, offset: const Offset(0, 1)),
        if (s.edgeBottom case final c?)
          BoxShadow(color: c, offset: const Offset(0, -1)),
      ],
      radii: List.filled(4, AmalfiWindowControlsMetrics.disc / 2),
      smoothing: AmalfiRadii.smoothing,
      source: 'AmalfiWindowDot',
    );
  });
}

String dotName(AmalfiWindowControlKind kind) => switch (kind) {
  AmalfiWindowControlKind.close => 'Close',
  AmalfiWindowControlKind.minimise => 'Minimise',
  AmalfiWindowControlKind.zoom => 'Zoom',
};

String stateName(AmalfiWindowControlState state) => switch (state) {
  AmalfiWindowControlState.rest => 'Rest',
  AmalfiWindowControlState.hover => 'Hover',
  AmalfiWindowControlState.pressed => 'Pressed',
  AmalfiWindowControlState.inactive => 'Inactive',
};

/// The disc of [kind] (one window control group on screen).
Finder dotOf(AmalfiWindowControlKind kind) =>
    find.byWidgetPredicate((w) => w is AmalfiWindowDot && w.kind == kind);

TestGesture? _mouse;

/// A mouse pointer kept for the rest of the test (removed at tear-down).
Future<TestGesture> mouse(WidgetTester tester) async {
  final existing = _mouse;
  if (existing != null) return existing;
  final m = _mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(() async {
    await _mouse?.removePointer();
    _mouse = null;
  });
  await m.addPointer(location: const Offset(1500, 1100));
  return m;
}

/// Moves the mouse onto the window controls and lets the symbols fade in.
Future<void> hoverControls(WidgetTester tester) async {
  final m = await mouse(tester);
  await m.moveTo(const Offset(1500, 1100));
  await tester.pump();
  await m.moveTo(tester.getCenter(dotOf(AmalfiWindowControlKind.minimise)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Moves the mouse onto [finder] and settles the hover look.
Future<void> hover(WidgetTester tester, Finder finder) async {
  final m = await mouse(tester);
  await m.moveTo(const Offset(1500, 1100));
  await tester.pump();
  await m.moveTo(tester.getCenter(finder));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The whole-points box around [text] (the frame the kit gives a text layer).
Finder textBox(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(AmalfiTitlebarTextBox))
    .first;

/// [piece] in a 52 pt bar slot (pieces take the bar's height).
Widget bar52(Widget piece) => SizedBox(
  height: AmalfiToolbarMetrics.toolbarHeight,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [piece],
  ),
);

/// The chrome glyph [glyph] (one on screen).
Finder glyphOf(AmalfiTitlebarGlyphData glyph) =>
    find.byWidgetPredicate((w) => w is AmalfiTitlebarGlyph && w.glyph == glyph);

/// The states (`Active`, `Inactive`) the kit has for [prefix] in [appearance].
List<String> availableStates(String prefix, String appearance) => [
  for (final s in ['Active', 'Inactive'])
    if (File('$kitFixturesPath/$prefix/$s/$appearance.json').existsSync()) s,
];

/// The item pieces: kit piece name, the layer of its control, the piece with its control.
final List<(String, String, Widget)> itemPieces = [
  (
    'Sidebar Toggle',
    'Toolbar button',
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.sidebar),
        onPressed: () {},
        semanticLabel: 'sidebar',
      ),
    ),
  ),
  ('Nav', 'Back and forward', navPiece()),
  for (final n in [2, 3, 4])
    (
      'Item Group $n',
      'Item group',
      AmalfiToolbarPiece(
        child: toolbarActions([
          for (var i = 0; i < n; i++) AmalfiTitlebarGlyphs.plus,
        ]),
      ),
    ),
  (
    'Segmented',
    'View switcher',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiTitlebarGlyphs.listBullet,
        AmalfiTitlebarGlyphs.squareGrid2x2,
      ]),
    ),
  ),
  (
    'Segmented 4',
    'View switcher',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiTitlebarGlyphs.listBullet,
        AmalfiTitlebarGlyphs.squareGrid2x2,
        AmalfiTitlebarGlyphs.photo,
        AmalfiTitlebarGlyphs.clock,
      ]),
    ),
  ),
  (
    'Segmented Text',
    'Section switcher',
    AmalfiToolbarPiece(
      child: textSwitcher(['All', 'Mine', 'Shared', 'Recent']),
    ),
  ),
  ('Search', 'Search', AmalfiToolbarPiece(child: toolbarSearch())),
  ('Search Token', 'Search', AmalfiToolbarPiece(child: searchToken())),
  for (final (name, glyph) in [
    ('Share', AmalfiTitlebarGlyphs.share),
    ('More', AmalfiTitlebarGlyphs.ellipsisCircle),
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
      'Toolbar button',
      AmalfiToolbarPiece(
        child: AmalfiToolbarButton(
          icon: AmalfiTitlebarGlyph(glyph),
          onPressed: () {},
          semanticLabel: 'glyph',
        ),
      ),
    ),
  (
    'Add',
    'Toolbar button',
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
    'Send',
    AmalfiToolbarPiece(
      trailing: 16,
      child: AmalfiIconButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.plus),
        onPressed: () {},
        semanticLabel: 'plus',
      ),
    ),
  ),
  for (final (name, layer, n) in [
    ('Mail Filter', 'Filter group', 2),
    ('Mail Reply', 'Reply group', 3),
    ('Mail Triage', 'Triage group', 3),
    ('Notes Format', 'Format', 3),
    ('Notes Insert', 'Insert', 3),
    ('Notes Lists', 'Lists', 3),
    ('Notes Share', 'Lock and share', 2),
    ('Preview Highlight', 'Highlight', 2),
    ('Preview Highlight Off', 'Highlight', 2),
    ('Preview View', 'View menu', 2),
    ('Preview Zoom', 'Zoom', 3),
  ])
    (
      name,
      layer,
      AmalfiToolbarPiece(
        child: toolbarActions([
          for (var i = 0; i < n; i++) AmalfiTitlebarGlyphs.plus,
        ]),
      ),
    ),
  (
    'Notes View',
    'List or gallery',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiTitlebarGlyphs.listBullet,
        AmalfiTitlebarGlyphs.squareGrid2x2,
      ]),
    ),
  ),
];

/// Icon segments of [glyphs] (the segmented family takes any widget as icon).
List<AmalfiSegment> iconSegments(List<AmalfiTitlebarGlyphData> glyphs) => [
  for (final g in glyphs)
    AmalfiSegment.icon(AmalfiTitlebarGlyph(g), semanticLabel: g.name),
];

/// A toolbar action group (kit `Segments/Action/Icon N/Large`).
Widget toolbarActions(List<AmalfiTitlebarGlyphData> glyphs) =>
    AmalfiActionSegments(segments: iconSegments(glyphs), onPressed: (_) {});

/// A select-one control of icons (kit `Segments/Control/One N Icon/Large`).
Widget viewSwitcher(List<AmalfiTitlebarGlyphData> glyphs) =>
    AmalfiSegmentedControl(
      segments: iconSegments(glyphs),
      selected: const {0},
      onChanged: (_) {},
      size: AmalfiControlSize.large,
    );

/// A select-one control of labels (kit `Segments/Control/One 4 Text/Large`).
Widget textSwitcher(List<String> labels) => AmalfiSegmentedControl(
  segments: [for (final l in labels) AmalfiSegment.text(l)],
  selected: const {0},
  onChanged: (_) {},
  size: AmalfiControlSize.large,
);

/// The toolbar search field (kit `Fields/Search Field/Large/Empty`, 200 wide).
Widget toolbarSearch() =>
    const AmalfiSearchField(size: AmalfiFieldSize.large, width: 200);

/// The search field with a token (kit `Fields/Search Field/Regular/Token`, 240 wide).
Widget searchToken() =>
    const AmalfiSearchField(width: 240, tokens: ['Recipes']);

/// The control in an item piece: a widget of the buttons, segmented or fields family.
Finder pieceControl() => find
    .byWidgetPredicate(
      (w) =>
          w is AmalfiToolbarButton ||
          w is AmalfiIconButton ||
          w is AmalfiActionSegments ||
          w is AmalfiSegmentedControl ||
          w is AmalfiSearchField,
    )
    .first;

/// Back and forward.
Widget navPiece({Key? key}) => AmalfiToolbarPiece(
  key: key,
  child: toolbarActions([
    AmalfiTitlebarGlyphs.chevronLeft,
    AmalfiTitlebarGlyphs.chevronRight,
  ]),
);

/// The pieces found by their key (the kit layer name).
Map<String, Finder> keyed(List<String> names) => {
  for (final n in names) n: find.byKey(ValueKey(n)),
};

/// The surface of the bar on screen.
Finder barSurface() => find
    .descendant(
      of: find.byWidgetPredicate(
        (w) => w is AmalfiToolbar || w is AmalfiTitleBar,
      ),
      matching: find.byType(ColoredBox),
    )
    .first;

const List<String> unifiedNames = [
  'Controls',
  'Sidebar Toggle',
  'Nav',
  'Title',
  'Spacer',
  'Segmented',
  'Search',
];

const List<String> unifiedMasked = ['Controls', 'Sidebar Toggle'];

/// The unified bar of the kit (`Bar/Unified/Full Inset 8|16`).
Widget unifiedBar({
  bool? active,
  EdgeInsets padding = AmalfiToolbarMetrics.unifiedPadding,
  double? width,
}) => AmalfiToolbar(
  active: active,
  padding: padding,
  children: [
    AmalfiControlsPiece(
      key: const ValueKey('Controls'),
      onClose: () {},
      onMinimise: () {},
      onZoom: () {},
    ),
    AmalfiToolbarPiece(
      key: ValueKey('Sidebar Toggle'),
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.sidebar),
        onPressed: () {},
        semanticLabel: 'sidebar',
      ),
    ),
    navPiece(key: const ValueKey('Nav')),
    AmalfiTitlePiece(key: ValueKey('Title'), title: 'Lemon cake'),
    AmalfiSpacerPiece(key: ValueKey('Spacer')),
    AmalfiToolbarPiece(
      key: ValueKey('Segmented'),
      child: viewSwitcher([
        AmalfiTitlebarGlyphs.listBullet,
        AmalfiTitlebarGlyphs.squareGrid2x2,
      ]),
    ),
    AmalfiToolbarPiece(key: ValueKey('Search'), child: toolbarSearch()),
  ],
);

const List<String> sidebarSectionNames = [
  'Controls',
  'Spacer',
  'Sidebar Toggle',
];

List<Widget> sidebarSectionPieces() => [
  AmalfiControlsPiece(
    key: const ValueKey('Controls'),
    onClose: () {},
    onMinimise: () {},
    onZoom: () {},
  ),
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Sidebar Toggle'),
    child: AmalfiToolbarButton(
      icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.sidebar),
      onPressed: () {},
      semanticLabel: 'sidebar',
    ),
  ),
];

const List<String> contentSectionNames = [
  'Nav',
  'Title',
  'Spacer',
  'Item Group 2',
  'Segmented',
  'Search',
];

List<Widget> contentSectionPieces() => [
  navPiece(key: const ValueKey('Nav')),
  AmalfiTitlePiece(key: ValueKey('Title'), title: 'Lemon cake'),
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Item Group 2'),
    child: toolbarActions([
      AmalfiTitlebarGlyphs.plus,
      AmalfiTitlebarGlyphs.tag,
    ]),
  ),
  AmalfiToolbarPiece(
    key: ValueKey('Segmented'),
    child: viewSwitcher([
      AmalfiTitlebarGlyphs.listBullet,
      AmalfiTitlebarGlyphs.squareGrid2x2,
    ]),
  ),
  AmalfiToolbarPiece(key: ValueKey('Search'), child: toolbarSearch()),
];

const List<String> listSectionNames = ['Title', 'Spacer', 'Item Group 2'];

List<Widget> listSectionPieces() => [
  AmalfiTitlePiece(key: ValueKey('Title'), title: 'Lemon cake'),
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Item Group 2'),
    child: toolbarActions([
      AmalfiTitlebarGlyphs.plus,
      AmalfiTitlebarGlyphs.tag,
    ]),
  ),
];

const List<String> inspectorSectionNames = ['Spacer', 'Item Group 3'];

List<Widget> inspectorSectionPieces() => [
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Item Group 3'),
    child: toolbarActions([
      AmalfiTitlebarGlyphs.plus,
      AmalfiTitlebarGlyphs.tag,
      AmalfiTitlebarGlyphs.star,
    ]),
  ),
];

/// components.md: 8 between toolbar controls; the kit's compact bar packs them 4 apart.
const String compactPacked =
    'kit compact bar packs its controls 4 apart from x 88; components.md: 8 between '
    'controls, controls at the measured place';

/// The compact bar of the kit (`Bar/Compact`).
Widget compactBar({bool? active}) => AmalfiToolbar.compact(
  active: active,
  children: [
    AmalfiControlsPiece(onClose: () {}, onMinimise: () {}, onZoom: () {}),
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.chevronLeft),
        onPressed: () {},
        semanticLabel: 'chevronLeft',
      ),
    ),
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.chevronRight),
        onPressed: () {},
        semanticLabel: 'chevronRight',
      ),
    ),
    AmalfiTitlePiece(title: 'Lemon cake'),
    AmalfiSpacerPiece(),
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.share),
        onPressed: () {},
        semanticLabel: 'share',
      ),
    ),
    AmalfiToolbarPiece(
      child: AmalfiToolbarButton(
        icon: AmalfiTitlebarGlyph(AmalfiTitlebarGlyphs.ellipsisCircle),
        onPressed: () {},
        semanticLabel: 'ellipsisCircle',
      ),
    ),
  ],
);

/// Kit defect: text layers with a fixed width are 4 wider than their text rounded up to the
/// grid (the title "Lemon cake" is 76 in `Piece/Title`, 80 in `Piece/Title + Subtitle`), so
/// the blocks around them are 4 wider too; we size every title the same way (76).
const String fixedText =
    'kit fixed-width text frame 4 wider than the text rounded to the 4 pt grid';

/// Kit defect: the plain title bar's title block is 20 tall with the 18 pt title at its top
/// (y 14); the document title bar centres it (y 15), as we do.
const String plainTitleTop =
    'kit plain title at y 14 (top of a 20 pt block); centred at y 15 as in Document; '
    'also 4 narrower (fixed-width frame)';

/// The separator along the bottom of a title bar (translucent `Line/Separator`).
Finder titleBarEdge() => find.descendant(
  of: find.byType(AmalfiTitleBar),
  matching: find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color.a < 1 && w.color.a > 0,
  ),
);

/// The surface of the tab on screen.
Finder tabSurface() => find
    .descendant(of: find.byType(AmalfiTab), matching: find.byType(DecoratedBox))
    .first;

/// Kit defect: the selected tab's shadow is `#00000024` / `#00000052` with level 1's offset
/// and blur; the tokens' level 1 is `#1A000000` / `#33000000`.
const String tabShadow =
    'kit selected tab shadow colour is not shadows.1 (light #24 / dark #52 vs #1A / #33)';

/// The track of the tab bar.
Finder tabTrack() => find
    .descendant(
      of: find.byType(AmalfiTabBar),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// The new-tab button.
Finder newTabButton() => find.descendant(
  of: find.byType(AmalfiTabBar),
  matching: find.byType(AmalfiIconButton),
);
