// Gallery page: dialogs (kit `Dialogs/*`): the save and open panels, the generic dialog,
// the file browser and the footers. Layout only: the rows stand in for the forms, sidebars
// and buttons families.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';
import 'menus.dart' show GalleryButton;

/// The dialogs page.
final AmalfiGalleryPage dialogsPage = AmalfiGalleryPage(
  family: 'dialogs',
  title: 'Dialogs',
  build: (context) => const _DialogsPage(),
);

/// A labelled row standing in for a form row ("Where: Recipes").
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.width = 272});

  final String label, value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return SizedBox(
      width: width,
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: AmalfiType.body(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: ShapeDecoration(
                color: colors.surfaceRaised,
                shape: AmalfiSmoothBorder(
                  radius: AmalfiRadii.field,
                  side: BorderSide(color: colors.lineBorder),
                ),
              ),
              child: Text(
                value,
                style: AmalfiType.body(color: colors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A list row standing in for the sidebars family.
class _ListRow extends StatelessWidget {
  const _ListRow(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: selected
          ? ShapeDecoration(
              color: colors.accentAmalfiSoft,
              shape: const AmalfiSmoothBorder(radius: 8),
            )
          : null,
      child: Text(label, style: AmalfiType.body(color: colors.textPrimary)),
    );
  }
}

const _browser = AmalfiDialogBrowser(
  places: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ListRow('Recents'),
      _ListRow('Desktop'),
      _ListRow('Documents', selected: true),
      _ListRow('Downloads'),
    ],
  ),
  files: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ListRow('Lemon cake.recipe', selected: true),
      _ListRow('Focaccia.recipe'),
      _ListRow('Limoncello notes.txt'),
    ],
  ),
);

const _openFooter = AmalfiDialogFooter(
  actions: [
    GalleryButton('Cancel', width: 72),
    GalleryButton('Open', primary: true, width: 72),
  ],
);

const _saveFooter = AmalfiDialogFooter(
  leading: [GalleryButton('New Folder', width: 96)],
  actions: [
    GalleryButton('Cancel', width: 72),
    GalleryButton('Save', primary: true, width: 72),
  ],
);

class _DialogsPage extends StatelessWidget {
  const _DialogsPage();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpecimenSection(
        title: 'Dialog',
        children: [
          Specimen(
            label: 'Save Panel',
            child: AmalfiDialog(
              title: 'Save as',
              children: [
                _Row('Save as', 'Lemon cake', width: 348),
                _Row('Where', 'Recipes', width: 264),
                _browser,
              ],
              footer: _saveFooter,
            ),
          ),
          Specimen(
            label: 'Open Panel',
            child: AmalfiDialog(
              title: 'Open recipe',
              children: [_Row('Look in', 'Recipes'), _browser],
              footer: _openFooter,
            ),
          ),
          Specimen(
            label: 'Generic',
            child: AmalfiDialog(
              title: 'Share recipe',
              layout: AmalfiDialogLayout.generic,
              children: [
                _Row('Name', 'Lemon cake', width: 352),
                _Row('With', 'Marta', width: 352),
              ],
              footer: AmalfiDialogFooter(
                actions: [
                  GalleryButton('Cancel', width: 72),
                  GalleryButton('Share', primary: true, width: 72),
                ],
              ),
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Parts',
        children: [
          Specimen(
            label: 'Browser · Files',
            child: SizedBox(width: 560, child: _browser),
          ),
          Specimen(
            label: 'Footer · Open',
            child: SizedBox(width: 560, child: _openFooter),
          ),
          Specimen(
            label: 'Footer · Save',
            child: SizedBox(width: 560, child: _saveFooter),
          ),
        ],
      ),
    ],
  );
}
