// Title bars and toolbars against the kit (`Titlebars/*`). Checklist:
// docs/amalfi-checklist/titlebars.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'titlebars_kit_support.dart';

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerChromeStyles();
  });

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final kind in AmalfiWindowControlKind.values) {
        for (final state in [
          AmalfiWindowControlState.rest,
          AmalfiWindowControlState.hover,
          AmalfiWindowControlState.inactive,
        ]) {
          final name =
              'Titlebars/Dot/${dotName(kind)}/${stateName(state)}/$appearance';
          testWidgets(name, (tester) async {
            final master = KitMaster.load(name);
            final dot = AmalfiWindowDot(kind: kind, state: state);
            final root = await pumpKitScene(tester, dot, master: master);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Dot': find.byType(AmalfiWindowDot),
                if (state == AmalfiWindowControlState.hover)
                  'Glyph': find.byType(AmalfiGlyph),
              },
              deviations: const {'Dot#corners': measuredDisc},
            );
            await expectKitPixels(tester, master, dot, tolerance: dotTolerance);
          });
        }
      }

      for (final state in ['Rest', 'Hover', 'Inactive']) {
        final name = 'Titlebars/Controls/$state/$appearance';
        testWidgets(name, (tester) async {
          final master = KitMaster.load(name);
          final group = AmalfiWindowControlGroup(
            onClose: () {},
            onMinimise: () {},
            onZoom: () {},
            active: state != 'Inactive',
          );
          final root = await pumpKitScene(tester, group, master: master);
          if (state == 'Hover') await hoverControls(tester);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Close': dotOf(AmalfiWindowControlKind.close),
              'Minimise': dotOf(AmalfiWindowControlKind.minimise),
              'Zoom': dotOf(AmalfiWindowControlKind.zoom),
            },
            deviations: const {
              '#frame': measuredPitch,
              'Minimise': measuredPitch,
              'Zoom': measuredPitch,
            },
          );
          await expectKitPixels(
            tester,
            master,
            group,
            tolerance: controlsTolerance,
            prepare: state == 'Hover' ? hoverControls : null,
          );
        });
      }

      for (final state in ['Active', 'Inactive']) {
        final active = state == 'Active';

        testWidgets('Piece/Controls/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Piece/Controls/$state/$appearance',
          );
          final piece = bar52(
            AmalfiControlsPiece(
              onClose: () {},
              onMinimise: () {},
              onZoom: () {},
              active: active,
            ),
          );
          final root = await pumpKitScene(tester, piece, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Window controls': find.byType(AmalfiWindowControlGroup)},
            deviations: const {'Window controls': measuredPlace},
          );
          await expectKitPixels(
            tester,
            master,
            piece,
            tolerance: controlsTolerance,
          );
        });

        testWidgets('Piece/Title/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Piece/Title/$state/$appearance',
          );
          final piece = bar52(
            AmalfiTitlePiece(title: 'Lemon cake', active: active),
          );
          final root = await pumpKitScene(tester, piece, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Title': textBox('Lemon cake')},
          );
          await expectKitPixels(tester, master, piece, tolerance: chromeText);
        });

        testWidgets('Piece/Title + Subtitle/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Piece/Title + Subtitle/$state/$appearance',
          );
          final piece = bar52(
            AmalfiTitlePiece(
              title: 'Lemon cake',
              subtitle: 'Edited today',
              active: active,
            ),
          );
          final root = await pumpKitScene(tester, piece, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Text block': find.byType(AmalfiTitleBlock),
              'Text block/Title': textBox('Lemon cake'),
              'Text block/Subtitle': textBox('Edited today'),
            },
            deviations: const {'Text block/Subtitle': subtitleWholePoints},
          );
          // The subtitle's frame is 2 pt narrower in the kit (deviation above): its pixels move.
          await expectKitPixels(
            tester,
            master,
            piece,
            maskLayers: ['Text block/Subtitle'],
            tolerance: chromeText,
          );
        });

        testWidgets('Piece/Title + Document Icon/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Piece/Title + Document Icon/$state/$appearance',
          );
          final piece = bar52(
            AmalfiTitlePiece(
              title: 'Lemon cake.recipe',
              document: true,
              active: active,
            ),
          );
          final root = await pumpKitScene(tester, piece, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Document': glyphOf(AmalfiGlyphs.doc),
              'Title': textBox('Lemon cake.recipe'),
              'Chevron': glyphOf(AmalfiGlyphs.chevronDown),
            },
          );
          await expectKitPixels(tester, master, piece, tolerance: chromeText);
        });

        testWidgets('Piece/Spacer/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Piece/Spacer/$state/$appearance',
          );
          final piece = bar52(AmalfiSpacerPiece());
          final root = await pumpKitScene(tester, piece, master: master);
          expectKitGeometry(tester, master, root: root);
          await expectKitPixels(tester, master, piece);
        });
      }

      // Item pieces: the slot around a control of another family (the merged segmented and
      // fields and buttons widgets). The pixel tests mask the
      // control: its glyphs are the app's choice and the control has its own kit tests.
      for (final (piece, child, widget) in itemPieces) {
        for (final state in availableStates(
          'Titlebars/Piece/$piece',
          appearance,
        )) {
          testWidgets('Piece/$piece/$state (slot)', (tester) async {
            final master = KitMaster.load(
              'Titlebars/Piece/$piece/$state/$appearance',
            );
            final scene = WindowActiveScope(
              active: state == 'Active',
              child: bar52(widget),
            );
            final root = await pumpKitScene(tester, scene, master: master);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {child: pieceControl()},
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              maskLayers: [child],
              // The kit's Send is a flat accent circle, ours the toolbar button's glass: its
              // shadow reaches beyond the mask.
              maskMargin: child == 'Send' ? 8 : 1,
            );
          });
        }
      }

      for (final state in ['Active', 'Inactive']) {
        final active = state == 'Active';
        testWidgets('Bar/Unified/Full Inset 16/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Bar/Unified/Full Inset 16/$state/$appearance',
          );
          final bar = SizedBox(width: 760, child: unifiedBar(active: active));
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Surface': barSurface(), ...keyed(unifiedNames)},
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: unifiedMasked,
            tolerance: chromeText,
          );
        });

        testWidgets('Section/Sidebar/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Section/Sidebar/$state/$appearance',
          );
          final bar = SizedBox(
            width: 240,
            child: AmalfiToolbar.sidebarSection(
              active: active,
              children: sidebarSectionPieces(),
            ),
          );
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Surface': barSurface(), ...keyed(sidebarSectionNames)},
            deviations: const {
              'Surface#fills': blurStrip,
              'Surface#blurs': blurStrip,
            },
          );
          // The kit's section is a blur strip over the sidebar with the divider drawn on
          // top: the pixels of the opaque section differ everywhere.
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['Controls', 'Sidebar Toggle'],
            tolerance: const KitPixelTolerance(mean: 40, max: 255),
          );
        });

        testWidgets('Section/Content/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Section/Content/$state/$appearance',
          );
          final bar = SizedBox(
            width: 760,
            child: AmalfiToolbar.section(
              active: active,
              children: contentSectionPieces(),
            ),
          );
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Surface': barSurface(), ...keyed(contentSectionNames)},
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['Nav', 'Item Group 2', 'Segmented', 'Search'],
            tolerance: chromeText,
          );
        });

        testWidgets('Section/List/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Section/List/$state/$appearance',
          );
          final bar = SizedBox(
            width: 320,
            child: AmalfiToolbar.section(
              active: active,
              children: listSectionPieces(),
            ),
          );
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Surface': barSurface(), ...keyed(listSectionNames)},
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['Item Group 2'],
            tolerance: chromeText,
          );
        });

        testWidgets('Section/Inspector/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Section/Inspector/$state/$appearance',
          );
          final bar = SizedBox(
            width: 260,
            child: AmalfiToolbar.section(
              active: active,
              surface: AmalfiToolbarSurface.sidebar,
              children: inspectorSectionPieces(),
            ),
          );
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {'Surface': barSurface(), ...keyed(inspectorSectionNames)},
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['Item Group 3'],
          );
        });

        testWidgets('Bar/Title Only/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Bar/Title Only/$state/$appearance',
          );
          final bar = SizedBox(
            width: 520,
            child: AmalfiTitleBar(
              title: 'Lemon cake',
              style: AmalfiTitleBarStyle.titleOnly,
              active: active,
              onClose: () {},
              onMinimise: () {},
              onZoom: () {},
            ),
          );
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Surface': barSurface(),
              'Title': find.text('Lemon cake'),
              'Window controls': find.byType(AmalfiWindowControlGroup),
            },
            deviations: const {'Window controls': measuredPlace},
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['Window controls'],
            tolerance: chromeText,
          );
        });

        testWidgets('Bar/Compact/$state', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Bar/Compact/$state/$appearance',
          );
          final bar = SizedBox(width: 520, child: compactBar(active: active));
          final root = await pumpKitScene(tester, bar, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Surface': barSurface(),
              'Window controls': find.byType(AmalfiWindowControlGroup),
              'Title': textBox('Lemon cake'),
            },
            deviations: const {'Window controls': compactControlsSize},
          );
          // The four toolbar buttons share one layer name in the kit: check them by x.
          final buttons = find.byType(AmalfiToolbarButton);
          expect(buttons, findsNWidgets(4));
          final origin = tester.getTopLeft(root);
          expect(
            [
              for (var i = 0; i < 4; i++)
                tester.getRect(buttons.at(i)).shift(-origin),
            ],
            [
              for (final x in [92.0, 124.0, 448.0, 480.0])
                Rect.fromLTWH(x, 8, 24, 24),
            ],
          );
        });

        for (final variant in ['Plain', 'Subtitle', 'Document']) {
          testWidgets('Title Bar/$variant/$state', (tester) async {
            final master = KitMaster.load(
              'Titlebars/Title Bar/$variant/$state/$appearance',
            );
            final bar = SizedBox(
              width: 520,
              child: AmalfiTitleBar(
                title: variant == 'Document'
                    ? 'Lemon cake.recipe'
                    : 'Lemon cake',
                subtitle: variant == 'Subtitle'
                    ? 'Edited today at 09:41'
                    : null,
                document: variant == 'Document',
                active: active,
                onClose: () {},
                onMinimise: () {},
                onZoom: () {},
              ),
            );
            final root = await pumpKitScene(tester, bar, master: master);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Edge': titleBarEdge(),
                'Title block': find.byType(AmalfiTitleBlock),
                'Window controls': find.byType(AmalfiWindowControlGroup),
                ...switch (variant) {
                  'Subtitle' => {
                    'Title block/Title': textBox('Lemon cake'),
                    'Title block/Subtitle': textBox('Edited today at 09:41'),
                  },
                  'Document' => {
                    'Title block/Document proxy': glyphOf(AmalfiGlyphs.doc),
                    'Title block/Title': textBox('Lemon cake.recipe'),
                    'Title block/Chevron': glyphOf(AmalfiGlyphs.chevronDown),
                  },
                  _ => {'Title block/Title': textBox('Lemon cake')},
                },
              },
              deviations: {'Window controls': measuredPitch},
            );
            await expectKitPixels(
              tester,
              master,
              bar,
              maskLayers: ['Window controls'],
              tolerance: chromeText,
            );
          });
        }
      }

      for (final state in ['Rest', 'Hover', 'Selected']) {
        testWidgets('Tab/$state', (tester) async {
          final master = KitMaster.load('Titlebars/Tab/$state/$appearance');
          final tab = AmalfiTab(
            label: 'Lemon cake',
            selected: state == 'Selected',
            onSelect: () {},
            onClose: () {},
          );
          Future<void> prepare(WidgetTester t) async {
            if (state == 'Hover') await hover(t, find.byType(AmalfiTab));
          }

          final root = await pumpKitScene(tester, tab, master: master);
          await prepare(tester);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              if (state != 'Rest') 'Surface': tabSurface(),
              'Label': find.text('Lemon cake'),
              if (state != 'Rest') 'Close': glyphOf(AmalfiGlyphs.xmark),
            },
          );
          await expectKitPixels(
            tester,
            master,
            tab,
            tolerance: chromeText,
            prepare: prepare,
          );
        });
      }

      for (final variant in ['Three Tabs', 'Hover']) {
        testWidgets('Tab Bar/$variant', (tester) async {
          final master = KitMaster.load(
            'Titlebars/Tab Bar/$variant/Rest/$appearance',
          );
          final bar = SizedBox(
            width: 560,
            child: AmalfiTabBar(
              tabs: [
                AmalfiTabData('Lemon cake'),
                AmalfiTabData('Fig jam'),
                AmalfiTabData('Olive oil'),
              ],
              onSelect: (_) {},
              onClose: (_) {},
              onNewTab: () {},
            ),
          );
          Future<void> prepare(WidgetTester t) async {
            if (variant == 'Hover') {
              await hover(t, find.widgetWithText(AmalfiTab, 'Fig jam'));
            }
          }

          final root = await pumpKitScene(tester, bar, master: master);
          await prepare(tester);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Track': tabTrack(),
              'Tab 1': find.widgetWithText(AmalfiTab, 'Lemon cake'),
              'Tab 2': find.widgetWithText(AmalfiTab, 'Fig jam'),
              'Tab 3': find.widgetWithText(AmalfiTab, 'Olive oil'),
              'New tab': newTabButton(),
            },
          );
          await expectKitPixels(
            tester,
            master,
            bar,
            maskLayers: ['New tab'],
            tolerance: chromeText,
            prepare: prepare,
          );
        });
      }
    });
  }

  group('window controls', () {
    AmalfiWindowControlState stateOf(
      WidgetTester tester,
      AmalfiWindowControlKind kind,
    ) => tester.widget<AmalfiWindowDot>(dotOf(kind)).state;

    double symbolOf(WidgetTester tester, AmalfiWindowControlKind kind) =>
        tester.widget<AmalfiWindowDot>(dotOf(kind)).symbolOpacity;

    testWidgets('the measured place in each bar height', (tester) async {
      expect(AmalfiWindowControlsMetrics.leadingFor(52), 18);
      expect(AmalfiWindowControlsMetrics.leadingFor(48), 16);
      expect(AmalfiWindowControlsMetrics.leadingFor(40), 12);
      expect(AmalfiWindowControlsMetrics.leadingFor(32), 8);
      expect(AmalfiWindowControlsMetrics.leadingFor(24), 8);
      expect(AmalfiWindowControlsMetrics.leadingFor(80), 18);
      await pumpKitScene(tester, bar52(const AmalfiControlsPiece()));
      // First disc centre x 26, pitch 23, centred on the 52 pt bar.
      expect(
        tester.getCenter(dotOf(AmalfiWindowControlKind.close)),
        const Offset(26, 26),
      );
      expect(
        tester.getCenter(dotOf(AmalfiWindowControlKind.zoom)),
        const Offset(26 + 2 * 23, 26),
      );
    });

    testWidgets('hovering the group shows every symbol; leaving hides them', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        AmalfiWindowControlGroup(
          onClose: () {},
          onMinimise: () {},
          onZoom: () {},
          active: false,
        ),
      );
      expect(
        stateOf(tester, AmalfiWindowControlKind.close),
        AmalfiWindowControlState.inactive,
      );
      final m = await mouse(tester);
      await m.moveTo(tester.getCenter(dotOf(AmalfiWindowControlKind.close)));
      await tester.pump();
      // Visible in the first frame, complete within ~100 ms.
      await tester.pump(const Duration(milliseconds: 110));
      for (final kind in AmalfiWindowControlKind.values) {
        expect(stateOf(tester, kind), AmalfiWindowControlState.hover);
        expect(symbolOf(tester, kind), 1);
      }
      await m.moveTo(const Offset(500, 500));
      await tester.pump(const Duration(milliseconds: 50));
      expect(symbolOf(tester, AmalfiWindowControlKind.zoom), 1);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 80));
      expect(symbolOf(tester, AmalfiWindowControlKind.zoom), 0);
      expect(
        stateOf(tester, AmalfiWindowControlKind.zoom),
        AmalfiWindowControlState.inactive,
      );
    });

    testWidgets('a press lightens one control and acts on release over it', (
      tester,
    ) async {
      final calls = <String>[];
      await pumpKitScene(
        tester,
        AmalfiWindowControlGroup(
          onClose: () => calls.add('close'),
          onMinimise: () => calls.add('minimise'),
          onZoom: () => calls.add('zoom'),
        ),
      );
      final m = await mouse(tester);
      final close = tester.getCenter(dotOf(AmalfiWindowControlKind.close));
      await m.moveTo(close);
      await tester.pump(const Duration(milliseconds: 200));
      await m.down(close);
      await tester.pump();
      expect(
        stateOf(tester, AmalfiWindowControlKind.close),
        AmalfiWindowControlState.pressed,
      );
      expect(
        stateOf(tester, AmalfiWindowControlKind.minimise),
        AmalfiWindowControlState.hover,
      );
      await m.up();
      await tester.pump();
      expect(calls, ['close']);

      // Moving off before releasing cancels.
      final zoom = tester.getCenter(dotOf(AmalfiWindowControlKind.zoom));
      await m.down(zoom);
      await tester.pump();
      await m.moveTo(zoom + const Offset(0, 40));
      await tester.pump();
      expect(
        stateOf(tester, AmalfiWindowControlKind.zoom),
        isNot(AmalfiWindowControlState.pressed),
      );
      await m.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, ['close']);
    });

    testWidgets('a control without a callback is a grey disc without symbol', (
      tester,
    ) async {
      var closed = 0;
      await pumpKitScene(
        tester,
        AmalfiWindowControlGroup(onClose: () => closed++),
      );
      await hoverControls(tester);
      expect(
        stateOf(tester, AmalfiWindowControlKind.zoom),
        AmalfiWindowControlState.inactive,
      );
      expect(
        stateOf(tester, AmalfiWindowControlKind.close),
        AmalfiWindowControlState.hover,
      );
      await tester.tap(dotOf(AmalfiWindowControlKind.zoom));
      await tester.tap(dotOf(AmalfiWindowControlKind.close));
      expect(closed, 1);
    });

    testWidgets('semantics: three labelled buttons', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        AmalfiWindowControlGroup(onClose: () {}, onZoom: () {}),
      );
      expect(
        tester.getSemantics(dotOf(AmalfiWindowControlKind.close)),
        matchesSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(dotOf(AmalfiWindowControlKind.minimise)),
        matchesSemantics(
          label: 'Minimise',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('bars', () {
    testWidgets('spacers share the free width; pieces keep theirs', (
      tester,
    ) async {
      await pumpKitScene(tester, SizedBox(width: 760, child: unifiedBar()));
      expect(tester.getSize(find.byKey(const ValueKey('Spacer'))).width, 135);
      // A wider bar gives the spacer the extra width.
      await pumpKitScene(tester, SizedBox(width: 960, child: unifiedBar()));
      expect(tester.getSize(find.byKey(const ValueKey('Spacer'))).width, 335);
      // Trailing padding 16 (components.md, user decision 2026-10-16).
      expect(tester.getTopRight(find.byKey(const ValueKey('Search'))).dx, 944);
    });

    testWidgets('an unbounded bar does not throw', (tester) async {
      await pumpKitScene(tester, UnconstrainedBox(child: unifiedBar()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('inactive: titles turn Text/Tertiary', (tester) async {
      await pumpKitScene(
        tester,
        const WindowActiveScope(
          active: false,
          child: AmalfiTitlePiece(title: 'Lemon cake'),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Lemon cake')).style?.color,
        AmalfiColors.light.textTertiary,
      );
    });

    testWidgets('a document title opens its menu', (tester) async {
      var opened = 0;
      await pumpKitScene(
        tester,
        bar52(
          AmalfiTitlePiece(
            title: 'Lemon cake.recipe',
            document: true,
            onDocumentMenu: () => opened++,
          ),
        ),
      );
      await tester.tap(find.text('Lemon cake.recipe'));
      expect(opened, 1);
    });
  });

  group('tabs', () {
    testWidgets('select, close, new tab; close only on hover or selected', (
      tester,
    ) async {
      final log = <String>[];
      await pumpKitScene(
        tester,
        SizedBox(
          width: 560,
          child: AmalfiTabBar(
            tabs: [AmalfiTabData('A'), AmalfiTabData('B')],
            onSelect: (i) => log.add('select $i'),
            onClose: (i) => log.add('close $i'),
            onNewTab: () => log.add('new'),
          ),
        ),
      );
      expect(glyphOf(AmalfiGlyphs.xmark), findsOneWidget);
      await tester.tap(find.text('B'));
      await hover(tester, find.text('B'));
      expect(glyphOf(AmalfiGlyphs.xmark), findsNWidgets(2));
      await tester.tap(glyphOf(AmalfiGlyphs.xmark).last);
      await tester.tap(newTabButton());
      expect(log, ['select 1', 'close 1', 'new']);
      // Equal widths: (560 − 8 − 24 − 2 × 4) / 2.
      expect(tester.getSize(find.byType(AmalfiTab).first).width, 260);
    });

    testWidgets('Enter selects a focused tab', (tester) async {
      var selected = 0;
      await pumpKitScene(
        tester,
        AmalfiTab(label: 'A', onSelect: () => selected++),
      );
      Focus.of(tester.element(find.text('A'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selected, 1);
    });
  });
}
