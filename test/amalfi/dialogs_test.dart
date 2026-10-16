// Dialogs against the kit (`Dialogs/*`). Checklist: docs/amalfi-checklist/dialogs.md.
//
// The buttons, the places group and the file rows are the real controls, compared with the
// kit's nested masters in the dialog's pixels. The form rows and sections (`Forms/*`) are
// another family's composites: boxes of their size here, masked out of the pixel tests.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'menus_support.dart';
import 'support/harness.dart';

/// A box the size of a form row or section (`Forms/*`), masked out of the pixel tests.
class StandIn extends StatelessWidget {
  const StandIn(this.name, this.width, this.height, {super.key});

  final String name;
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

Finder standIn(String name) =>
    find.byWidgetPredicate((w) => w is StandIn && w.name == name);

Finder keyed(String name) => find.byKey(ValueKey(name));

AmalfiPushButton _button(String label, {bool primary = false}) =>
    AmalfiPushButton(
      key: ValueKey(label),
      label: label,
      variant: primary
          ? AmalfiPushButtonVariant.primary
          : AmalfiPushButtonVariant.secondary,
      onPressed: () {},
    );

final _openFooter = AmalfiDialogFooter(
  actions: [_button('Cancel'), _button('Open', primary: true)],
);

final _saveFooter = AmalfiDialogFooter(
  leading: [_button('New Folder')],
  actions: [_button('Cancel'), _button('Save', primary: true)],
);

const _files = ['Lemon cake.recipe', 'Focaccia.recipe', 'Limoncello notes.txt'];

final _browser = AmalfiDialogBrowser(
  places: Align(
    alignment: Alignment.topLeft,
    child: AmalfiSidebarGroup(
      key: const ValueKey('Places group'),
      title: 'Places',
      expanded: true,
      onToggle: () {},
      children: [
        AmalfiSidebarRow(
          label: 'Documents',
          icon: AmalfiGlyphs.doc,
          onTap: () {},
        ),
        AmalfiSidebarRow(
          label: 'Downloads',
          icon: AmalfiGlyphs.download,
          badge: '3',
          onTap: () {},
        ),
        AmalfiSidebarRow(
          label: 'Pictures',
          icon: AmalfiGlyphs.photo,
          onTap: () {},
        ),
      ],
    ),
  ),
  files: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final f in _files)
        AmalfiSidebarRow(
          key: ValueKey(f),
          label: f,
          icon: AmalfiGlyphs.doc,
          selected: f == _files.first,
          onTap: () {},
        ),
    ],
  ),
);

final _open = AmalfiDialog(
  title: 'Open recipe',
  children: [const StandIn('Look in', 272, 28), _browser],
  footer: _openFooter,
);

final _save = AmalfiDialog(
  title: 'Save as',
  children: [
    const StandIn('Save as', 348, 28),
    const StandIn('Where', 264, 28),
    _browser,
  ],
  footer: _saveFooter,
);

final _generic = AmalfiDialog(
  title: 'Share recipe',
  layout: AmalfiDialogLayout.generic,
  children: const [
    StandIn('Profile', 352, 156),
    StandIn('Preferences', 352, 116),
  ],
  footer: AmalfiDialogFooter(
    key: const ValueKey('Footer'),
    actions: [_button('Cancel'), _button('Save', primary: true)],
  ),
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
        final scene = SizedBox(width: 560, child: _openFooter);
        final root = await pumpKitScene(tester, scene, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {'Cancel': keyed('Cancel'), 'Open': keyed('Open')},
        );
        await expectKitPixels(tester, master, scene, maskText: true);
      });

      testWidgets('Footer Save', (tester) async {
        final master = KitMaster.load('Dialogs/Footer/Save/Rest/$appearance');
        final scene = SizedBox(width: 560, child: _saveFooter);
        final root = await pumpKitScene(tester, scene, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'New Folder': keyed('New Folder'),
            'Cancel': keyed('Cancel'),
            'Save': keyed('Save'),
          },
        );
        // The PNG starts 2 pt left of the frame (the New Folder button's shadow), not the
        // 2.7 the frame and the shadow's blur give.
        await expectKitPixels(
          tester,
          master,
          scene,
          maskText: true,
          // The masked text frames are the nested master's (`Button`, 48 wide): the rest
          // of the overridden label `New Folder`.
          mask: [const Rect.fromLTWH(12, 5, 72, 18)],
          origin: const Offset(2, 1),
        );
      });

      testWidgets('Browser Files', (tester) async {
        final master = KitMaster.load('Dialogs/Browser/Files/Rest/$appearance');
        final scene = SizedBox(width: 560, child: _browser);
        final root = await pumpKitScene(tester, scene, master: master);
        final panes = find.byType(AmalfiAlertSurface);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {
            'Places': panes.first,
            'Places/Surface': panes.first,
            'Places/Places group': keyed('Places group'),
            'File list': panes.last,
            'File list/Surface': panes.last,
            for (final f in _files) 'File list/$f': keyed(f),
          },
        );
        await expectKitPixels(
          tester,
          master,
          scene,
          maskText: true,
          // The places group's glyphs and badge: stand-ins here, as in sidebars_test.dart
          // (the kit's group now stacks its rows on the 32 pt pitch, as the code does).
          mask: [const Rect.fromLTWH(8, 8, 200, 128)],
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
            'Footer' => find.byType(AmalfiDialogFooter),
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
          );
          await expectKitPixels(
            tester,
            master,
            dialog,
            maskText: true,
            maskLayers: [
              for (final r in rows)
                if (r != 'Browser' && r != 'Footer') r,
            ],
            mask: [
              // The places group's glyphs and badge (see above), inside the browser.
              if (rows.contains('Browser'))
                master.layer('Browser').rectInMaster.topLeft.translate(8, 8) &
                    const Size(200, 128),
              // The overridden label `New Folder` past the nested master's text frame.
              if (name == 'Save Panel')
                master.layer('Footer').rectInMaster.topLeft.translate(12, 5) &
                    const Size(72, 18),
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
