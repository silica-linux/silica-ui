// Popovers against the kit (`Popovers/*`). Checklist: docs/amalfi-checklist/popovers.md.
//
// Kit defect: every popover master lost its glass (`Surface/Raised`, a `Line/Separator`
// border and a 0/8/24 shadow); `materials.md` gives Glass/Thick, radius 16. The geometry
// tests list that deviation; the pixel tests compare the opaque fallback of the glass (the
// tint over `Surface/Window`, white in the light appearance) with the kit's raised surface,
// with a tolerance for the different shadow.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'menus_support.dart';
import 'support/harness.dart';

/// A stand-in for a control of another family (push button, text field, link button): a box
/// of its size, masked out of the pixel tests.
class _StandIn extends StatelessWidget {
  const _StandIn(this.name, this.width, this.height);

  final String name;
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

Finder _standIn(String name) =>
    find.byWidgetPredicate((w) => w is _StandIn && w.name == name);

const _body =
    'Olive oil keeps the crust tender and adds a peppery note. Use a mild, fruity one for sweet bakes.';

const _form = AmalfiPopoverForm(
  title: 'New collection',
  field: _StandIn('Name field', 228, 28),
  actions: [_StandIn('Cancel', 56, 24), _StandIn('Create', 56, 24)],
);

const _text = AmalfiPopoverText(
  title: 'About this ingredient',
  body: _body,
  action: _StandIn('Link', 80, 24),
);

class _Glyph extends StatelessWidget {
  const _Glyph();

  @override
  Widget build(BuildContext context) => const SizedBox.square(dimension: 16);
}

const _list = AmalfiPopoverList(
  entries: [
    AmalfiMenuSection('Open in'),
    AmalfiMenuAction('Recents', icon: _Glyph()),
    AmalfiMenuAction('Downloads', icon: _Glyph()),
    AmalfiMenuAction('Pictures', icon: _Glyph()),
  ],
);

/// The content of each kit variant, and the layers of other families it holds.
const _contents = <String, Widget>{'Form': _form, 'List': _list, 'Text': _text};

/// Layers of a content master drawn by other families (masked) or by stand-ins.
const _foreign = <String, List<String>>{
  'Form': ['Name field', 'Buttons'],
  'List': ['Pictures', 'Downloads', 'Recents'],
  'Text': ['Link'],
};

/// Hovers "Downloads" in a list (the kit highlights it).
Future<void> _highlightDownloads(WidgetTester tester) async {
  await hover(tester, menuItem('Downloads'));
}

/// The rectangles of the icons of the list rows, in master coordinates (the glyphs are
/// silica-icons symbols, stood in for).
List<Rect> _listIcons(Offset content) => [
  for (final y in [24.0, 48.0, 72.0])
    Rect.fromLTWH(content.dx + 8, content.dy + y + 4, 16, 16),
];

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerSurfaceStyles();
  });

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      testWidgets('Content Form', (tester) async {
        final master = KitMaster.load('Popovers/Content/Form/Rest/$appearance');
        final root = await pumpKitScene(tester, _form, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Title': textBox('New collection'),
            'Name field': _standIn('Name field'),
            'Buttons': find.byType(Wrap),
            'Buttons/Cancel': _standIn('Cancel'),
            'Buttons/Create': _standIn('Create'),
          },
        );
        await expectKitPixels(
          tester,
          master,
          _form,
          maskLayers: _foreign['Form']!,
          tolerance: denseText,
        );
      });

      testWidgets('Content Text', (tester) async {
        final master = KitMaster.load('Popovers/Content/Text/Rest/$appearance');
        final root = await pumpKitScene(tester, _text, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Title': find
                .ancestor(
                  of: find.text('About this ingredient'),
                  matching: find.byType(AmalfiWholePoints),
                )
                .first,
            'Body': textBox(_body),
            'Link': _standIn('Link'),
          },
        );
        await expectKitPixels(
          tester,
          master,
          _text,
          maskLayers: _foreign['Text']!,
          tolerance: denseText,
        );
      });

      testWidgets('Content List', (tester) async {
        final master = KitMaster.load('Popovers/Content/List/Rest/$appearance');
        final root = await pumpKitScene(tester, _list, master: master);
        await _highlightDownloads(tester);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Open in': find.byType(AmalfiMenuHeader),
            for (final l in ['Recents', 'Downloads', 'Pictures'])
              l: menuItem(l),
          },
        );
        await expectKitPixels(
          tester,
          master,
          _list,
          maskText: true,
          mask: _listIcons(Offset.zero),
          tolerance: highlightCorners,
          prepare: _highlightDownloads,
        );
        await expectKitPixels(
          tester,
          master,
          _list,
          mask: _listIcons(Offset.zero),
          tolerance: KitPixelTolerance.withText,
          prepare: _highlightDownloads,
        );
      });

      for (final variant in ['Form', 'List', 'Text']) {
        for (final (edge, edgeName) in [
          (null, null),
          (AmalfiPopoverArrowEdge.top, 'Top'),
          (AmalfiPopoverArrowEdge.bottom, 'Bottom'),
          (AmalfiPopoverArrowEdge.leading, 'Leading'),
          (AmalfiPopoverArrowEdge.trailing, 'Trailing'),
        ]) {
          for (final (alignment, alignName) in [
            (AmalfiPopoverArrowAlignment.start, 'Start'),
            (AmalfiPopoverArrowAlignment.center, 'Center'),
            (AmalfiPopoverArrowAlignment.end, 'End'),
          ]) {
            if (edge == null &&
                alignment != AmalfiPopoverArrowAlignment.start) {
              continue;
            }
            final name = edge == null ? 'Detached' : '$edgeName $alignName';
            testWidgets('Popover $variant $name', (tester) async {
              final master = KitMaster.load(
                'Popovers/Popover/$variant/$name/$appearance',
              );
              final surface = edge == null ? 'Body' : 'Surface';
              Widget popover({bool opaque = false}) => AmalfiPopover(
                arrowEdge: edge,
                arrowAlignment: alignment,
                padding: variant == 'List'
                    ? AmalfiPopoverMetrics.listPadding
                    : AmalfiPopoverMetrics.padding,
                opaque: opaque,
                child: _contents[variant]!,
              );
              final root = await pumpKitScene(
                tester,
                popover(),
                master: master,
              );
              const lost = 'kit popovers lost the glass (materials.md: Thick)';
              expectKitGeometry(
                tester,
                master,
                root: root,
                layers: {
                  surface: find.byType(AmalfiPopoverSurface),
                  'Content': find.byWidget(_contents[variant]!),
                },
                deviations: {
                  for (final aspect in [
                    'fills',
                    'borders',
                    'shadows',
                    'innerShadows',
                    'blurs',
                  ])
                    '$surface#$aspect': lost,
                },
              );
              // The tip of the arrow is on the frame, at the kit's place along the edge.
              if (edge != null) {
                final shape = tester
                    .widget<AmalfiPopoverSurface>(
                      find.byType(AmalfiPopoverSurface),
                    )
                    .shape;
                final tip = shape.tip(Offset.zero & master.size);
                final svg = master.layer(surface).raw['svg']! as String;
                final kitTip = _kitTip(svg, edgeName!);
                expect((tip! - kitTip).distance, lessThan(1.5));
              }

              // Pixels: the opaque fallback against the kit's opaque surface. The arrow
              // band differs (the kit's arrow is 9.85 deep over a body cut 1.85 short), and
              // the content of other families is masked.
              final content = master.layer('Content').rectInMaster;
              final nested = KitMaster.nested(master.layer('Content'));
              final mask = <Rect>[
                for (final l in _foreign[variant]!)
                  if (variant != 'List')
                    nested.layer(l).rectInMaster.shift(content.topLeft),
                if (variant == 'List') ..._listIcons(content.topLeft),
                ..._arrowBand(master.size, edgeName),
              ];
              await expectKitPixels(
                tester,
                master,
                popover(opaque: true),
                maskText: true,
                mask: mask,
                tolerance: _lostGlass,
                origin: _origin(master, edgeName),
                prepare: variant == 'List' ? _highlightDownloads : null,
              );
            });
          }
        }
      }
    });
  }

  group('behaviour', () {
    test('layout: centred on the anchor, flipped when there is no room', () {
      const bounds = Size(800, 600);
      const size = Size(260, 128);
      var r = amalfiPopoverLayout(
        anchor: const Rect.fromLTWH(380, 100, 40, 28),
        size: size,
        bounds: bounds,
      );
      expect(r.offset, const Offset(270, 128));
      expect(r.placement, AmalfiPopoverPlacement.below);
      expect(r.arrowOffset, 130);

      r = amalfiPopoverLayout(
        anchor: const Rect.fromLTWH(380, 560, 40, 28),
        size: size,
        bounds: bounds,
      );
      expect(r.placement, AmalfiPopoverPlacement.above);
      expect(r.offset.dy, 560 - 128);

      // Near the edge: kept 8 inside, the arrow still points at the anchor.
      r = amalfiPopoverLayout(
        anchor: const Rect.fromLTWH(0, 100, 40, 28),
        size: size,
        bounds: bounds,
      );
      expect(r.offset.dx, 8);
      expect(r.arrowOffset, 12);
    });

    testWidgets(
      'showAmalfiPopover: opens below, Esc and a press outside close',
      (tester) async {
        late BuildContext context;
        await pumpKitScene(
          tester,
          Padding(
            padding: const EdgeInsets.all(200),
            child: Builder(
              builder: (c) {
                context = c;
                return const SizedBox(width: 40, height: 28);
              },
            ),
          ),
        );
        var closed = 0;
        Future<void> open() async {
          showAmalfiPopover(
            context: context,
            anchor: const Rect.fromLTWH(200, 200, 40, 28),
            builder: (_, _) => _text,
          ).then((_) => closed++);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
        }

        Future<void> settle() async {
          await tester.pump();
          await tester.pump(AmalfiFades.instant.duration * 2);
          await tester.pump();
        }

        await open();
        final popover = find.byType(AmalfiPopover);
        expect(popover, findsOneWidget);
        expect(
          tester.widget<AmalfiPopover>(popover).arrowEdge,
          AmalfiPopoverArrowEdge.top,
        );
        expect(tester.getTopLeft(popover).dy, 228);
        expect(tester.getCenter(popover).dx, closeTo(220, 0.5));

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle();
        expect(popover, findsNothing);
        expect(closed, 1);

        await open();
        await tester.tapAt(const Offset(5, 5), kind: PointerDeviceKind.mouse);
        await settle();
        expect(popover, findsNothing);
        expect(closed, 2);
      },
    );
  });
}

/// The opaque fallback against the kit's raised surface: the kit's shadow is 0/8/24, the
/// glass's 0/12/32, and in the dark the fallback is the tint over `Surface/Window`
/// (#26272B) against `Surface/Raised` (#2A2B30); the edge pixels of the outline differ by up
/// to 100 where the kit's opaque surface antialiases over its own shadow and the glass over
/// a shadow drawn outside the shape only.
const _lostGlass = KitPixelTolerance(mean: 3, max: 112);

/// Where the master's origin is in its PNG. Sketch bounds the PNG by the outline's path,
/// whose rounded arrow tip is 1.16 inside the frame: on the arrow's side the shadow starts
/// 1 pt closer to the frame than the harness assumes. (Only the top and leading sides move
/// the origin.)
Offset _origin(KitMaster master, String? edge) {
  final at = -master.renderBounds.topLeft;
  return switch (edge) {
    'Top' => at.translate(0, -1),
    'Leading' => at.translate(-1, 0),
    _ => at,
  };
}

/// Where the kit's arrow and body edge differ from the code's: the band of the arrow's edge,
/// and the body's corners on that edge (moved by the 1.85 pt the kit cuts off the body).
List<Rect> _arrowBand(Size size, String? edge) {
  const band = 12.0, corner = 36.0;
  final w = size.width, h = size.height;
  return switch (edge) {
    null => const [],
    'Top' => [
      Rect.fromLTWH(0, 0, w, band),
      Rect.fromLTWH(0, 0, corner, corner),
      Rect.fromLTWH(w - corner, 0, corner, corner),
    ],
    'Bottom' => [
      Rect.fromLTWH(0, h - band, w, band),
      Rect.fromLTWH(0, h - corner, corner, corner),
      Rect.fromLTWH(w - corner, h - corner, corner, corner),
    ],
    'Leading' => [
      Rect.fromLTWH(0, 0, band, h),
      Rect.fromLTWH(0, 0, corner, corner),
      Rect.fromLTWH(0, h - corner, corner, corner),
    ],
    _ => [
      Rect.fromLTWH(w - band, 0, band, h),
      Rect.fromLTWH(w - corner, 0, corner, corner),
      Rect.fromLTWH(w - corner, h - corner, corner, corner),
    ],
  };
}

/// The sharp tip of the kit's arrow: its rounded tip moved out by 3 × (√2 − 1).
Offset _kitTip(String svg, String edge) {
  final points = [
    for (final m in RegExp(r'([\d.]+),([\d.]+)').allMatches(svg))
      Offset(double.parse(m.group(1)!), double.parse(m.group(2)!)),
  ];
  const out = 3 * 0.41421356;
  int byX(Offset a, Offset b) => a.dx.compareTo(b.dx);
  int byY(Offset a, Offset b) => a.dy.compareTo(b.dy);
  return switch (edge) {
    'Top' => (points..sort(byY)).first.translate(0, -out),
    'Bottom' => (points..sort(byY)).last.translate(0, out),
    'Leading' => (points..sort(byX)).first.translate(-out, 0),
    _ => (points..sort(byX)).last.translate(out, 0),
  };
}
