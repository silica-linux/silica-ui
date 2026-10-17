// Sidebars against the kit (`Sidebars/*`). Checklist: docs/amalfi-checklist/sidebars.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'titlebars_kit_support.dart';

/// The sidebar of `Sidebars/Panel` (and of the window layouts, `Windows/Sidebar Body`).
List<Widget> panelRows({bool library = true}) => [
  const AmalfiSidebarHeader(
    key: ValueKey('Favourites'),
    title: 'Favourites',
    expanded: true,
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Recents'),
    label: 'Recents',
    icon: AmalfiGlyphs.clock,
    selected: true,
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Documents'),
    label: 'Documents',
    icon: AmalfiGlyphs.doc,
    badge: '12',
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Downloads'),
    label: 'Downloads',
    icon: AmalfiGlyphs.download,
    onTap: () {},
  ),
  const AmalfiSidebarHeader(
    key: ValueKey('Library'),
    title: 'Library',
    expanded: true,
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Photos'),
    label: 'Photos',
    icon: AmalfiGlyphs.photo,
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Music'),
    label: 'Music',
    icon: AmalfiGlyphs.musicNote,
    onTap: () {},
  ),
];

/// The kit's Sidebar Emphasis and Sidebar Header are Sketch weight 6 (Medium, as Body
/// Emphasis); components.md and tokens.json specify 600 (user decision 2026-10-17).
/// Rows: 14 pt text and a 20 pt symbol (the kit draws the symbol from the font, the
/// controls paint the same drawing as a vector) and 600 against the kit's 500 when selected.
const KitPixelTolerance _rowText = KitPixelTolerance(mean: 3, max: 255);

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final variant in ['Plain', 'Badge']) {
        for (final state in ['Rest', 'Hover', 'Selected', 'Disabled']) {
          testWidgets('Row/$variant/$state', (tester) async {
            final master = KitMaster.load(
              'Sidebars/Row/$variant/$state/$appearance',
            );
            final row = SizedBox(
              width: 216,
              child: AmalfiSidebarRow(
                label: 'Documents',
                icon: AmalfiGlyphs.folder,
                badge: variant == 'Badge' ? '12' : null,
                selected: state == 'Selected',
                enabled: state != 'Disabled',
                onTap: () {},
              ),
            );
            Future<void> prepare(WidgetTester t) async {
              if (state == 'Hover') {
                await hover(t, find.byType(AmalfiSidebarRow));
              }
            }

            final root = await pumpKitScene(tester, row, master: master);
            await prepare(tester);
            final surface = switch (state) {
              'Hover' => 'Hover',
              'Selected' => 'Selection',
              _ => null,
            };
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                if (surface != null)
                  surface: find
                      .descendant(
                        of: find.byType(AmalfiSidebarRow),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                'Label': find.text('Documents'),
                'Icon': glyphOf(AmalfiGlyphs.folder),
                if (variant == 'Badge')
                  'Badge': find.byType(AmalfiSidebarBadge),
              },
            );
            await expectKitPixels(
              tester,
              master,
              row,
              tolerance: _rowText,
              prepare: prepare,
            );
          });
        }
      }

      testWidgets('Badge', (tester) async {
        final master = KitMaster.load('Sidebars/Badge/Rest/$appearance');
        const badge = AmalfiSidebarBadge('12');
        final root = await pumpKitScene(tester, badge, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Pill': find.byType(DecoratedBox).first,
            'Count': textBox('12'),
          },
        );
        await expectKitPixels(tester, master, badge, tolerance: chromeText);
      });

      for (final (variant, expanded) in [
        ('Plain', null),
        ('Open', true),
        ('Closed', false),
      ]) {
        testWidgets('Header/$variant', (tester) async {
          final master = KitMaster.load(
            'Sidebars/Header/$variant/Rest/$appearance',
          );
          final header = SizedBox(
            width: 216,
            child: AmalfiSidebarHeader(
              title: 'Favourites',
              expanded: expanded,
              onToggle: () {},
            ),
          );
          final root = await pumpKitScene(tester, header, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Title': find.text('Favourites'),
              if (expanded != null) 'Disclosure': find.byType(AmalfiGlyph),
            },
          );
          await expectKitPixels(tester, master, header, tolerance: chromeText);
        });
      }

      for (final open in [true, false]) {
        testWidgets('Group/${open ? 'Open' : 'Closed'}', (tester) async {
          final master = KitMaster.load(
            'Sidebars/Group/${open ? 'Open' : 'Closed'}/Rest/$appearance',
          );
          final group = SizedBox(
            width: 216,
            child: AmalfiSidebarGroup(
              title: 'Places',
              expanded: open,
              onToggle: () {},
              children: [
                AmalfiSidebarRow(
                  key: const ValueKey('Documents'),
                  label: 'Documents',
                  icon: AmalfiGlyphs.doc,
                  onTap: () {},
                ),
                AmalfiSidebarRow(
                  key: const ValueKey('Downloads'),
                  label: 'Downloads',
                  icon: AmalfiGlyphs.download,
                  badge: '12',
                  onTap: () {},
                ),
                AmalfiSidebarRow(
                  key: const ValueKey('Pictures'),
                  label: 'Pictures',
                  icon: AmalfiGlyphs.photo,
                  onTap: () {},
                ),
              ],
            ),
          );
          final root = await pumpKitScene(tester, group, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Header': find.byType(AmalfiSidebarHeader),
              if (open) ...keyed(['Documents', 'Downloads', 'Pictures']),
            },
          );
          if (!open) {
            await expectKitPixels(tester, master, group, tolerance: chromeText);
          }
        });
      }

      testWidgets('Footer', (tester) async {
        final master = KitMaster.load('Sidebars/Footer/Rest/$appearance');
        final footer = SizedBox(
          width: 216,
          child: AmalfiSidebarFooter(
            children: [
              AmalfiIconButton(
                key: ValueKey('Add'),
                icon: AmalfiGlyph(AmalfiGlyphs.plus),
                onPressed: () {},
                semanticLabel: 'plus',
                shape: AmalfiIconButtonShape.square,
                size: AmalfiControlSize.small,
              ),
              AmalfiIconButton(
                key: ValueKey('Settings'),
                icon: AmalfiGlyph(AmalfiGlyphs.gear),
                onPressed: () {},
                semanticLabel: 'gear',
                shape: AmalfiIconButtonShape.square,
                size: AmalfiControlSize.small,
              ),
            ],
          ),
        );
        final root = await pumpKitScene(tester, footer, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Edge': find
                .descendant(
                  of: find.byType(AmalfiSidebarFooter),
                  matching: find.byType(ColoredBox),
                )
                .first,
            ...keyed(['Add', 'Settings']),
          },
        );
        await expectKitPixels(
          tester,
          master,
          footer,
          maskLayers: ['Add', 'Settings'],
        );
      });

      testWidgets('Panel', (tester) async {
        final master = KitMaster.load('Sidebars/Panel/Active/$appearance');
        final panel = SizedBox(
          height: 460,
          child: AmalfiSidebarPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            footer: AmalfiSidebarFooter(
              key: ValueKey('Footer'),
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
              ...panelRows(),
              const AmalfiSidebarHeader(
                key: ValueKey('Tags'),
                title: 'Tags',
                expanded: false,
              ),
            ],
          ),
        );
        final root = await pumpKitScene(tester, panel, master: master);
        const below = [
          'Recents',
          'Documents',
          'Downloads',
          'Library',
          'Photos',
          'Music',
          'Tags',
        ];
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Surface': find
                .descendant(
                  of: find.byType(AmalfiSidebarPanel),
                  matching: find.byType(ColoredBox),
                )
                .first,
            ...keyed(['Favourites', ...below, 'Footer']),
          },
        );
      });
    });
  }

  group('behaviour', () {
    testWidgets('a row runs onTap on click and on Enter when focused', (
      tester,
    ) async {
      var taps = 0;
      await pumpKitScene(
        tester,
        SizedBox(
          width: 216,
          child: AmalfiSidebarRow(label: 'Documents', onTap: () => taps++),
        ),
      );
      await tester.tap(find.byType(AmalfiSidebarRow));
      expect(taps, 1);
      final focus = find.descendant(
        of: find.byType(AmalfiSidebarRow),
        matching: find.byType(Focus),
      );
      Focus.of(
        tester.element(
          find
              .descendant(of: focus.last, matching: find.byType(MouseRegion))
              .first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
    });

    testWidgets('a disabled row ignores clicks and is dimmed', (tester) async {
      var taps = 0;
      await pumpKitScene(
        tester,
        SizedBox(
          width: 216,
          child: AmalfiSidebarRow(
            label: 'Documents',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(AmalfiSidebarRow));
      expect(taps, 0);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Documents'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, AmalfiStates.disabledOpacity);
    });

    testWidgets('a group header toggles and hides its rows', (tester) async {
      var open = true;
      await pumpKitScene(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 216,
            child: AmalfiSidebarGroup(
              title: 'Places',
              expanded: open,
              onToggle: () => setState(() => open = !open),
              children: [AmalfiSidebarRow(label: 'Documents')],
            ),
          ),
        ),
      );
      expect(find.text('Documents'), findsOneWidget);
      await tester.tap(find.text('Places'));
      await tester.pump();
      expect(find.text('Documents'), findsNothing);
      expect(glyphOf(AmalfiGlyphs.chevronRight), findsOneWidget);
    });

    testWidgets('semantics: selected row, expandable header', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        SizedBox(
          width: 216,
          child: Column(
            children: [
              AmalfiSidebarHeader(
                title: 'Places',
                expanded: true,
                onToggle: () {},
              ),
              AmalfiSidebarRow(label: 'Recents', selected: true, onTap: () {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AmalfiSidebarRow)),
        matchesSemantics(
          label: 'Recents',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });
}
