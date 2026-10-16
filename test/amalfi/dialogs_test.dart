// Dialogs against the kit (`Dialogs/*`). Checklist: docs/amalfi-checklist/dialogs.md.
//
// Layout only: the rows (form rows, sidebar groups and rows, push buttons) belong to other
// families and are stood in for by boxes of their size, masked out of the pixel tests.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'alerts_test.dart' show StandIn, standIn;
import 'menus_support.dart';
import 'support/harness.dart';

const _openFooter = AmalfiDialogFooter(
  actions: [StandIn('Cancel', 72, 28), StandIn('Open', 72, 28)],
);

const _saveFooter = AmalfiDialogFooter(
  leading: [StandIn('New Folder', 96, 28)],
  actions: [StandIn('Cancel', 72, 28), StandIn('Save', 72, 28)],
);

const _browser = AmalfiDialogBrowser(
  places: Align(
    alignment: Alignment.topLeft,
    child: StandIn('Places group', 200, 112),
  ),
  files: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StandIn('Lemon cake.recipe', 216, 28),
      StandIn('Focaccia.recipe', 216, 28),
      StandIn('Limoncello notes.txt', 216, 28),
    ],
  ),
);

/// The kit's places group is 216 wide inside a 216 pane with 8 of padding; the code gives it
/// the pane's inside (200).
const _placesOverflow = 'kit places group 216 wide in a 200 pt inside';

const _open = AmalfiDialog(
  title: 'Open recipe',
  children: [StandIn('Look in', 272, 28), _browser],
  footer: _openFooter,
);

const _save = AmalfiDialog(
  title: 'Save as',
  children: [StandIn('Save as', 348, 28), StandIn('Where', 264, 28), _browser],
  footer: _saveFooter,
);

const _generic = AmalfiDialog(
  title: 'Share recipe',
  layout: AmalfiDialogLayout.generic,
  children: [StandIn('Profile', 352, 156), StandIn('Preferences', 324, 116)],
  footer: StandIn('Footer', 352, 28),
);

Finder _dialogTitle(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(IntrinsicWidth))
    .first;

Finder get _surface => find.byType(AmalfiAlertSurface).first;

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerSurfaceStyles();
  });

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      testWidgets('Footer Open', (tester) async {
        final master = KitMaster.load('Dialogs/Footer/Open/Rest/$appearance');
        const scene = SizedBox(width: 560, child: _openFooter);
        final root = await pumpKitScene(tester, scene, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {'Cancel': standIn('Cancel'), 'Open': standIn('Open')},
        );
        await expectKitPixels(
          tester,
          master,
          scene,
          maskLayers: ['Cancel', 'Open'],
        );
      });

      testWidgets('Footer Save', (tester) async {
        final master = KitMaster.load('Dialogs/Footer/Save/Rest/$appearance');
        const scene = SizedBox(width: 560, child: _saveFooter);
        final root = await pumpKitScene(tester, scene, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'New Folder': standIn('New Folder'),
            'Cancel': standIn('Cancel'),
            'Save': standIn('Save'),
          },
        );
        await expectKitPixels(
          tester,
          master,
          scene,
          maskLayers: ['New Folder', 'Cancel', 'Save'],
        );
      });

      testWidgets('Browser Files', (tester) async {
        final master = KitMaster.load('Dialogs/Browser/Files/Rest/$appearance');
        const scene = SizedBox(width: 560, child: _browser);
        final root = await pumpKitScene(tester, scene, master: master);
        final panes = find.byType(AmalfiAlertSurface);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Places': panes.first,
            'Places/Surface': panes.first,
            'Places/Places group': standIn('Places group'),
            'File list': panes.last,
            'File list/Surface': panes.last,
            for (final f in [
              'Lemon cake.recipe',
              'Focaccia.recipe',
              'Limoncello notes.txt',
            ])
              'File list/$f': standIn(f),
          },
          deviations: {'Places/Places group': _placesOverflow},
        );
        await expectKitPixels(
          tester,
          master,
          scene,
          maskLayers: [
            'Places/Places group',
            'File list/Lemon cake.recipe',
            'File list/Focaccia.recipe',
            'File list/Limoncello notes.txt',
          ],
          tolerance: largeCorners,
        );
      });

      for (final (name, dialog, rows) in [
        ('Open Panel', _open, ['Look in', 'Browser', 'Footer']),
        ('Save Panel', _save, ['Save as', 'Where', 'Browser', 'Footer']),
        ('Generic', _generic, ['Profile', 'Preferences', 'Footer']),
      ]) {
        testWidgets('Dialog $name', (tester) async {
          final master = KitMaster.load(
            'Dialogs/Dialog/$name/Rest/$appearance',
          );
          final root = await pumpKitScene(tester, dialog, master: master);
          Finder row(String r) => switch (r) {
            'Browser' => find.byType(AmalfiDialogBrowser),
            'Footer' when name != 'Generic' => find.byType(AmalfiDialogFooter),
            _ => standIn(r),
          };
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Surface': _surface,
              'Title': _dialogTitle(dialog.title),
              for (final r in rows) r: row(r),
            },
            deviations: {
              if (name == 'Generic')
                'Profile':
                    'kit Profile section 372 wide in a 352 pt content (overflows)',
            },
          );
          await expectKitPixels(
            tester,
            master,
            dialog,
            maskText: true,
            maskLayers: [
              for (final r in rows)
                if (r != 'Browser') r,
              if (rows.contains('Browser')) 'Browser',
            ],
            tolerance: largeCorners,
          );
        });
      }
    });
  }

  testWidgets('a long title wraps inside the dialog', (tester) async {
    await pumpKitScene(
      tester,
      const AmalfiDialog(
        title:
            'A very long dialog title that cannot fit on one line of the panel at all, '
            'so it wraps onto a second line',
        layout: AmalfiDialogLayout.generic,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AmalfiDialog)).width, 400);
  });
}
