// Gallery page: dialogs (kit `Dialogs/*`): the save and open panels, the generic dialog,
// the file browser and the footers, built from the real form rows, sidebar rows and push
// buttons.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The dialogs page.
final AmalfiGalleryPage dialogsPage = AmalfiGalleryPage(
  family: 'dialogs',
  title: 'Dialogs',
  build: (context) => const _DialogsPage(),
);

/// A pop-up of folders ("Where: Recipes").
class _Folders extends StatefulWidget {
  const _Folders(this.label);

  final String label;

  @override
  State<_Folders> createState() => _FoldersState();
}

class _FoldersState extends State<_Folders> {
  String _folder = 'Recipes';

  @override
  Widget build(BuildContext context) => AmalfiFormRow(
    label: widget.label,
    control: AmalfiPopUpButton<String>(
      items: const [
        AmalfiPopUpItem(value: 'Recipes', label: 'Recipes'),
        AmalfiPopUpItem(value: 'Documents', label: 'Documents'),
        AmalfiPopUpItem(value: 'Desktop', label: 'Desktop'),
      ],
      value: _folder,
      onChanged: (v) => setState(() => _folder = v),
    ),
  );
}

AmalfiPushButton _button(String label, {bool primary = false}) =>
    AmalfiPushButton(
      label: label,
      variant: primary
          ? AmalfiPushButtonVariant.primary
          : AmalfiPushButtonVariant.secondary,
      onPressed: () {},
    );

/// The places and files of a file dialog, with a selection that follows clicks.
class _Browser extends StatefulWidget {
  const _Browser();

  @override
  State<_Browser> createState() => _BrowserState();
}

class _BrowserState extends State<_Browser> {
  bool _open = true;
  String _place = 'Documents';
  String _file = 'Lemon cake.recipe';

  @override
  Widget build(BuildContext context) => AmalfiDialogBrowser(
    places: Align(
      alignment: Alignment.topLeft,
      child: AmalfiSidebarGroup(
        title: 'Places',
        expanded: _open,
        onToggle: () => setState(() => _open = !_open),
        children: [
          for (final (place, glyph, badge) in [
            ('Documents', AmalfiGlyphs.doc, null),
            ('Downloads', AmalfiGlyphs.download, '3'),
            ('Pictures', AmalfiGlyphs.photo, null),
          ])
            AmalfiSidebarRow(
              label: place,
              icon: glyph,
              badge: badge,
              selected: place == _place,
              onTap: () => setState(() => _place = place),
            ),
        ],
      ),
    ),
    files: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in [
          'Lemon cake.recipe',
          'Focaccia.recipe',
          'Limoncello notes.txt',
        ])
          AmalfiSidebarRow(
            label: f,
            icon: AmalfiGlyphs.doc,
            selected: f == _file,
            onTap: () => setState(() => _file = f),
          ),
      ],
    ),
  );
}

final _openFooter = AmalfiDialogFooter(
  actions: [_button('Cancel'), _button('Open', primary: true)],
);

final _saveFooter = AmalfiDialogFooter(
  leading: [_button('New Folder')],
  actions: [_button('Cancel'), _button('Save', primary: true)],
);

class _DialogsPage extends StatelessWidget {
  const _DialogsPage();

  @override
  Widget build(BuildContext context) => Column(
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
                const AmalfiFormRow(
                  label: 'Save as:',
                  control: AmalfiTextField(width: 268),
                ),
                const _Folders('Where:'),
                const _Browser(),
              ],
              footer: _saveFooter,
            ),
          ),
          Specimen(
            label: 'Open Panel',
            child: AmalfiDialog(
              title: 'Open recipe',
              children: [const _Folders('Look in:'), const _Browser()],
              footer: _openFooter,
            ),
          ),
          Specimen(
            label: 'Generic',
            child: AmalfiDialog(
              title: 'Share recipe',
              layout: AmalfiDialogLayout.generic,
              children: const [
                AmalfiFormRow(
                  label: 'Name:',
                  control: AmalfiTextField(),
                  expand: true,
                ),
                AmalfiFormRow(
                  label: 'With:',
                  control: AmalfiTextField(placeholder: 'Marta'),
                  expand: true,
                ),
              ],
              footer: AmalfiDialogFooter(
                actions: [_button('Cancel'), _button('Share', primary: true)],
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
            child: SizedBox(width: 560, child: _Browser()),
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
