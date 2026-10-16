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
Finder glyphOf(AmalfiGlyphData glyph) =>
    find.byWidgetPredicate((w) => w is AmalfiGlyph && w.glyph == glyph);

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
        icon: AmalfiGlyph(AmalfiGlyphs.sidebar),
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
        child: toolbarActions([for (var i = 0; i < n; i++) AmalfiGlyphs.plus]),
      ),
    ),
  (
    'Segmented',
    'View switcher',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiGlyphs.listBullet,
        AmalfiGlyphs.squareGrid2x2,
      ]),
    ),
  ),
  (
    'Segmented 4',
    'View switcher',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiGlyphs.listBullet,
        AmalfiGlyphs.squareGrid2x2,
        AmalfiGlyphs.photo,
        AmalfiGlyphs.clock,
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
    ('Share', AmalfiGlyphs.share),
    ('More', AmalfiGlyphs.ellipsisCircle),
    ('Doc Info', AmalfiGlyphs.doc),
    ('Doc Share', AmalfiGlyphs.share),
    ('Mail Compose', AmalfiGlyphs.compose),
    ('Notes New', AmalfiGlyphs.compose),
    ('Preview Inspector', AmalfiGlyphs.sidebar),
    ('Preview Markup', AmalfiGlyphs.compose),
    ('Preview Rotate', AmalfiGlyphs.plus),
  ])
    (
      name,
      'Toolbar button',
      AmalfiToolbarPiece(
        child: AmalfiToolbarButton(
          icon: AmalfiGlyph(glyph),
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
        icon: AmalfiGlyph(AmalfiGlyphs.plus),
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
        icon: AmalfiGlyph(AmalfiGlyphs.plus),
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
        child: toolbarActions([for (var i = 0; i < n; i++) AmalfiGlyphs.plus]),
      ),
    ),
  (
    'Notes View',
    'List or gallery',
    AmalfiToolbarPiece(
      child: viewSwitcher([
        AmalfiGlyphs.listBullet,
        AmalfiGlyphs.squareGrid2x2,
      ]),
    ),
  ),
];

/// Icon segments of [glyphs] (the segmented family takes any widget as icon).
List<AmalfiSegment> iconSegments(List<AmalfiGlyphData> glyphs) => [
  for (final g in glyphs)
    AmalfiSegment.icon(AmalfiGlyph(g), semanticLabel: g.name),
];

/// A toolbar action group (kit `Segments/Action/Icon N/Large`).
Widget toolbarActions(List<AmalfiGlyphData> glyphs) =>
    AmalfiActionSegments(segments: iconSegments(glyphs), onPressed: (_) {});

/// A select-one control of icons (kit `Segments/Control/One N Icon/Large`).
Widget viewSwitcher(List<AmalfiGlyphData> glyphs) => AmalfiSegmentedControl(
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
  child: toolbarActions([AmalfiGlyphs.chevronLeft, AmalfiGlyphs.chevronRight]),
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

/// The unified bar of the kit (`Bar/Unified/Full Inset 16`).
Widget unifiedBar({bool? active}) => AmalfiToolbar(
  active: active,
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
        icon: AmalfiGlyph(AmalfiGlyphs.sidebar),
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
        AmalfiGlyphs.listBullet,
        AmalfiGlyphs.squareGrid2x2,
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
      icon: AmalfiGlyph(AmalfiGlyphs.sidebar),
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
    child: toolbarActions([AmalfiGlyphs.plus, AmalfiGlyphs.tag]),
  ),
  AmalfiToolbarPiece(
    key: ValueKey('Segmented'),
    child: viewSwitcher([AmalfiGlyphs.listBullet, AmalfiGlyphs.squareGrid2x2]),
  ),
  AmalfiToolbarPiece(key: ValueKey('Search'), child: toolbarSearch()),
];

const List<String> listSectionNames = ['Title', 'Spacer', 'Item Group 2'];

List<Widget> listSectionPieces() => [
  AmalfiTitlePiece(key: ValueKey('Title'), title: 'Lemon cake'),
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Item Group 2'),
    child: toolbarActions([AmalfiGlyphs.plus, AmalfiGlyphs.tag]),
  ),
];

const List<String> inspectorSectionNames = ['Spacer', 'Item Group 3'];

List<Widget> inspectorSectionPieces() => [
  AmalfiSpacerPiece(key: ValueKey('Spacer')),
  AmalfiToolbarPiece(
    key: ValueKey('Item Group 3'),
    child: toolbarActions([
      AmalfiGlyphs.plus,
      AmalfiGlyphs.tag,
      AmalfiGlyphs.star,
    ]),
  ),
];

/// The group of window controls is 62 wide (14 pt discs 7 apart, measured), the kit's 64.
const String compactControlsSize =
    'measured window controls 62 wide (14 pt discs), kit 64 (16 pt discs); the x and the '
    'gap to the next control follow the kit';

/// The compact bar of the kit (`Bar/Compact`): children 8 apart between paddings of 20 and 16.
Widget compactBar({bool? active}) => AmalfiToolbar.compact(
  active: active,
  children: [
    AmalfiControlsPiece(
      width: AmalfiToolbarMetrics.compactControlsWidth,
      leading: 0,
      onClose: () {},
      onMinimise: () {},
      onZoom: () {},
    ),
    for (final (glyph, label) in [
      (AmalfiGlyphs.chevronLeft, 'chevronLeft'),
      (AmalfiGlyphs.chevronRight, 'chevronRight'),
    ])
      AmalfiToolbarPiece(
        leading: 0,
        trailing: 0,
        child: AmalfiToolbarButton(
          icon: AmalfiGlyph(glyph),
          onPressed: () {},
          semanticLabel: label,
        ),
      ),
    Expanded(child: AmalfiTitlePiece(title: 'Lemon cake', fill: true)),
    for (final (glyph, label) in [
      (AmalfiGlyphs.share, 'share'),
      (AmalfiGlyphs.ellipsisCircle, 'ellipsisCircle'),
    ])
      AmalfiToolbarPiece(
        leading: 0,
        trailing: 0,
        child: AmalfiToolbarButton(
          icon: AmalfiGlyph(glyph),
          onPressed: () {},
          semanticLabel: label,
        ),
      ),
  ],
);

/// Kit defect: the subtitle "Edited today" of `Piece/Title + Subtitle` has a fixed-width
/// frame 64 wide for 58.9 pt of text (the grid gives 60, as the other titlebar texts), the
/// text at its left, so 2.5 pt left of the centre under the title.
const String fixedSubtitle =
    'kit fixed-width subtitle frame 64 for 58.9 pt of text, text not centred; ours rounded '
    'to the grid (60) and centred';

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
