// Popovers against the kit (`Popovers/*`). Checklist: docs/amalfi-checklist/popovers.md.
//
// Every popover is Glass/Thick (kit 747ea80); the contents hold the real push buttons, text
// field and link button, checked against their own masters. The list rows' glyphs are
// masked (the kit overrides them with Icon Kit symbols the fixtures do not name).

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'menus_support.dart';
import 'support/harness.dart';

const _body =
    'Olive oil keeps the crust tender and adds a peppery note. Use a mild, fruity one for sweet bakes.';

void _pressed() {}

final _form = AmalfiPopoverForm(
  title: 'New collection',
  field: AmalfiTextField(
    width: 228,
    controller: TextEditingController(text: 'Amalfi coast'),
  ),
  actions: const [
    AmalfiPushButton(
      label: 'Cancel',
      size: AmalfiControlSize.small,
      onPressed: _pressed,
    ),
    AmalfiPushButton(
      label: 'Create',
      variant: AmalfiPushButtonVariant.primary,
      size: AmalfiControlSize.small,
      onPressed: _pressed,
    ),
  ],
);

const _text = AmalfiPopoverText(
  title: 'About this ingredient',
  body: _body,
  action: AmalfiLinkButton(label: 'Learn more', onPressed: _pressed),
);

// The kit's list rows override their glyphs with Icon Kit symbols the fixtures do not
// name: the rows show installed symbols, masked out of the pixels (`_listIcons`).
const _list = AmalfiPopoverList(
  entries: [
    AmalfiMenuSection('Open in'),
    AmalfiMenuAction('Recents', icon: AmalfiSymbol('clock', size: 16)),
    AmalfiMenuAction(
      'Downloads',
      icon: AmalfiSymbol('arrow-down-circle', size: 16),
    ),
    AmalfiMenuAction('Pictures', icon: AmalfiSymbol('photo', size: 16)),
  ],
);

/// The content of each kit variant.
final _contents = <String, Widget>{'Form': _form, 'List': _list, 'Text': _text};

/// The push button labelled [label].
Finder _button(String label) =>
    find.widgetWithText(AmalfiPushButton, label).first;

/// The label box of [text] inside [within].
Finder _labelOf(String text, Finder within) => find
    .ancestor(
      of: find.descendant(of: within, matching: find.text(text)),
      matching: find.byType(AmalfiWholePoints),
    )
    .first;

/// Checks the controls of the form content against their own kit masters.
void _expectFormControls(WidgetTester tester, KitMaster content) {
  for (final name in ['Cancel', 'Create']) {
    final layer = content.layer('Buttons/$name');
    final button = _button(name);
    expectKitGeometry(
      tester,
      KitMaster.nested(layer),
      root: button,
      layers: {
        'Background': find
            .descendant(
              of: button,
              matching: find.byKey(AmalfiButtonLayers.background),
            )
            .first,
        'Label': _labelOf(name, button),
      },
      // The harness reads the master, not the instance's label override.
      deviations: const {'Label#text': 'the instance overrides the label'},
    );
  }
  final field = find.byType(AmalfiTextField);
  const stretched = 'the content stretches the 200 pt master to 228';
  expectKitGeometry(
    tester,
    KitMaster.nested(content.layer('Name field')),
    root: field,
    layers: {
      'Background': find.byType(AmalfiFieldSurface),
      'Value': find.byType(AmalfiEditable),
    },
    deviations: const {
      '#frame': stretched,
      'Background': stretched,
      'Value': stretched,
    },
  );
}

/// Checks the link button of the text content against its kit master.
void _expectTextControls(WidgetTester tester, KitMaster content) {
  final link = find.byType(AmalfiLinkButton);
  expectKitGeometry(
    tester,
    KitMaster.nested(content.layer('Link')),
    root: link,
    layers: {'Label': _labelOf('Learn more', link)},
  );
}

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
            'Name field': find.byType(AmalfiTextField),
            'Buttons': find.byType(Wrap),
            'Buttons/Cancel': _button('Cancel'),
            'Buttons/Create': _button('Create'),
          },
        );
        _expectFormControls(tester, master);
        await expectKitPixels(
          tester,
          master,
          _form,
          maskText: true,
          tolerance: _fieldCorner,
        );
        await expectKitPixels(tester, master, _form, tolerance: denseText);
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
            'Link': find.byType(AmalfiLinkButton),
          },
        );
        _expectTextControls(tester, master);
        await expectKitPixels(tester, master, _text, maskText: true);
        await expectKitPixels(tester, master, _text, tolerance: _allText);
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
              Widget popover() => AmalfiPopover(
                arrowEdge: edge,
                arrowAlignment: alignment,
                padding: variant == 'List'
                    ? AmalfiPopoverMetrics.listPadding
                    : AmalfiPopoverMetrics.padding,
                child: _contents[variant]!,
              );
              final root = await pumpKitScene(
                tester,
                popover(),
                master: master,
              );
              expectKitGeometry(
                tester,
                master,
                root: root,
                layers: {
                  surface: find.byType(AmalfiPopoverSurface),
                  'Content': find.byWidget(_contents[variant]!),
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

              final content = master.layer('Content').rectInMaster;
              await expectKitPixels(
                tester,
                master,
                popover(),
                maskText: true,
                mask: [if (variant == 'List') ..._listIcons(content.topLeft)],
                tolerance: _glass,
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

/// The glass against the kit's: [largeCorners], and on the body's corners beside the
/// arrow (where Sketch smooths the 16 pt corner into the arrow's 4 pt base corner) one
/// edge pixel differs by 103 in the light appearance (alpha 111 against 8); the rest of the
/// outline agrees (mean ≤ 0.29).
const _glass = KitPixelTolerance(max: 104);

/// The text field's bottom corners: one antialiased pixel 56 apart from Sketch's (alpha 145
/// against 201) on the 8 pt smooth corner; the rest of the form agrees (mean ≤ 0.19).
const _fieldCorner = KitPixelTolerance(max: 56);

/// The text content master is text only (title, body and the link's label, no surface):
/// CoreText's rasterisation averages 5.04 apart in the dark appearance ([denseText] is 5 for
/// rows with some surface). The text is in place (masked, the shapes agree exactly).
const _allText = KitPixelTolerance(mean: 5.1, max: 255);

/// The sharp tip of the kit's arrow: its rounded tip (radius 3) moved out to where the
/// flanks meet.
Offset _kitTip(String svg, String edge) {
  final points = [
    for (final m in RegExp(r'([\d.]+),([\d.]+)').allMatches(svg))
      Offset(double.parse(m.group(1)!), double.parse(m.group(2)!)),
  ];
  const r = AmalfiPopoverMetrics.arrowTipRadius;
  final half = math.atan2(
    AmalfiPopoverMetrics.arrowHalfBase,
    AmalfiPopoverMetrics.arrowDepth,
  );
  final out = r / math.sin(half) - r;
  int byX(Offset a, Offset b) => a.dx.compareTo(b.dx);
  int byY(Offset a, Offset b) => a.dy.compareTo(b.dy);
  return switch (edge) {
    'Top' => (points..sort(byY)).first.translate(0, -out),
    'Bottom' => (points..sort(byY)).last.translate(0, out),
    'Leading' => (points..sort(byX)).first.translate(-out, 0),
    _ => (points..sort(byX)).last.translate(out, 0),
  };
}
