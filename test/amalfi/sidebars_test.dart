// Sidebars against the kit (`Sidebars/*`). Checklist: docs/amalfi-checklist/sidebars.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'titlebars_kit_support.dart';

/// components.md (binding): rows on a 32 pt pitch (4 between rows); the kit's Group and
/// Panel stack them with no gap (pitch 28), while `Windows/Sidebar Body` uses 4.
const String rowPitch =
    'components.md row pitch 32 (gap 4); the kit stacks this master with gap 0';

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
    icon: AmalfiTitlebarGlyphs.clock,
    selected: true,
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Documents'),
    label: 'Documents',
    icon: AmalfiTitlebarGlyphs.doc,
    badge: '12',
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Downloads'),
    label: 'Downloads',
    icon: AmalfiTitlebarGlyphs.download,
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
    icon: AmalfiTitlebarGlyphs.photo,
    onTap: () {},
  ),
  AmalfiSidebarRow(
    key: const ValueKey('Music'),
    label: 'Music',
    icon: AmalfiTitlebarGlyphs.musicNote,
    onTap: () {},
  ),
];

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
                icon: AmalfiTitlebarGlyphs.folder,
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
                'Icon': glyphOf(AmalfiTitlebarGlyphs.folder),
                if (variant == 'Badge')
                  'Badge': find.byType(AmalfiSidebarBadge),
              },
            );
            await expectKitPixels(
              tester,
              master,
              row,
              tolerance: chromeText,
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
              if (expanded != null)
                'Disclosure': find.byType(AmalfiTitlebarGlyph),
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
                  icon: AmalfiTitlebarGlyphs.doc,
                  onTap: () {},
                ),
                AmalfiSidebarRow(
                  key: const ValueKey('Downloads'),
                  label: 'Downloads',
                  icon: AmalfiTitlebarGlyphs.download,
                  badge: '12',
                  onTap: () {},
                ),
                AmalfiSidebarRow(
                  key: const ValueKey('Pictures'),
                  label: 'Pictures',
                  icon: AmalfiTitlebarGlyphs.photo,
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
            deviations: {
              if (open) ...{
                '#frame': rowPitch,
                'Documents': rowPitch,
                'Downloads': rowPitch,
                'Pictures': rowPitch,
              },
            },
          );
          if (!open) {
            await expectKitPixels(tester, master, group, tolerance: chromeText);
          }
        });
      }

      testWidgets('Footer', (tester) async {
        final master = KitMaster.load('Sidebars/Footer/Rest/$appearance');
        const footer = SizedBox(
          width: 216,
          child: AmalfiSidebarFooter(
            children: [
              AmalfiToolbarPlaceholder.square(
                AmalfiTitlebarGlyphs.plus,
                key: ValueKey('Add'),
              ),
              AmalfiToolbarPlaceholder.square(
                AmalfiTitlebarGlyphs.gear,
                key: ValueKey('Settings'),
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
          maskLayers: const ['Add', 'Settings'],
        );
      });

      testWidgets('Panel', (tester) async {
        final master = KitMaster.load('Sidebars/Panel/Active/$appearance');
        final panel = SizedBox(
          height: 460,
          child: AmalfiSidebarPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            footer: const AmalfiSidebarFooter(
              key: ValueKey('Footer'),
              children: [
                AmalfiToolbarPlaceholder.square(AmalfiTitlebarGlyphs.plus),
                AmalfiToolbarPlaceholder.square(AmalfiTitlebarGlyphs.gear),
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
          deviations: {for (final n in below) n: rowPitch},
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
      final text = tester.widget<Text>(find.text('Documents'));
      expect(text.style?.color, AmalfiColors.light.textTertiary);
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
              children: const [AmalfiSidebarRow(label: 'Documents')],
            ),
          ),
        ),
      );
      expect(find.text('Documents'), findsOneWidget);
      await tester.tap(find.text('Places'));
      await tester.pump();
      expect(find.text('Documents'), findsNothing);
      expect(glyphOf(AmalfiTitlebarGlyphs.chevronRight), findsOneWidget);
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
