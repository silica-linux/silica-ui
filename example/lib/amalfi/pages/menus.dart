// Gallery page: menus (kit `Menus/*`). Every item variant in every state, the header and the
// separator, the kit's menus (live: hover them, or focus one and use the keyboard), and a
// button that opens a menu.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The menus page.
final AmalfiGalleryPage menusPage = AmalfiGalleryPage(
  family: 'menus',
  title: 'Menus',
  build: (context) => const _MenusPage(),
);

const List<AmalfiMenuEntry> _submenu = [
  AmalfiMenuAction('Lemon Cake'),
  AmalfiMenuAction('Fig Jam'),
  AmalfiMenuAction('Olive Oil'),
  AmalfiMenuDivider(),
  AmalfiMenuAction('Clear Menu'),
];

const List<AmalfiMenuEntry> _full = [
  AmalfiMenuAction('New Window', shortcut: '⌘N'),
  AmalfiMenuAction('Open Recent', submenu: _submenu),
  AmalfiMenuDivider(),
  AmalfiMenuSection('Share'),
  AmalfiMenuAction('Send a Link', icon: AmalfiGlyph(AmalfiGlyphs.share)),
  AmalfiMenuAction('Autosave', checked: true),
  AmalfiMenuAction('Duplicate', shortcut: '⌘D'),
  AmalfiMenuAction('Export…', shortcut: '⇧⌘E', enabled: false),
  AmalfiMenuDivider(),
  AmalfiMenuAction('Move to Trash', destructive: true),
];

const List<AmalfiMenuEntry> _simple = [
  AmalfiMenuAction('Orange'),
  AmalfiMenuAction('Lemon', checked: true),
  AmalfiMenuAction('Olive'),
  AmalfiMenuAction('Fig'),
];

const List<AmalfiMenuEntry> _context = [
  AmalfiMenuAction('Cut', shortcut: '⌘X'),
  AmalfiMenuAction('Copy', shortcut: '⌘C'),
  AmalfiMenuAction('Paste', shortcut: '⌘V'),
  AmalfiMenuDivider(),
  AmalfiMenuAction('Look Up', icon: AmalfiGlyph(AmalfiGlyphs.search)),
  AmalfiMenuAction(
    'Services',
    submenu: [AmalfiMenuAction('Make a Note'), AmalfiMenuAction('Share')],
  ),
  AmalfiMenuDivider(),
  AmalfiMenuAction('Delete', destructive: true),
];

class _MenusPage extends StatelessWidget {
  const _MenusPage();

  static Widget _item(AmalfiMenuItem item) => SizedBox(width: 188, child: item);

  @override
  Widget build(BuildContext context) {
    const states = ['Rest', 'Highlighted', 'Disabled'];
    AmalfiMenuItem item(
      String state, {
      String? shortcut,
      Widget? icon,
      bool checked = false,
      bool submenu = false,
      bool destructive = false,
    }) => AmalfiMenuItem(
      label: 'Menu item',
      shortcut: shortcut,
      icon: icon,
      checked: checked,
      submenu: submenu,
      destructive: destructive,
      highlighted: state == 'Highlighted',
      enabled: state != 'Disabled',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (variant, build)
            in <(String, AmalfiMenuItem Function(String))>[
              ('Plain', (s) => item(s)),
              ('Checkmark', (s) => item(s, checked: true)),
              ('Shortcut', (s) => item(s, shortcut: '⌘N')),
              ('Submenu', (s) => item(s, submenu: true)),
              (
                'Icon',
                (s) => item(s, icon: const AmalfiGlyph(AmalfiGlyphs.share)),
              ),
              ('Destructive', (s) => item(s, destructive: true)),
            ])
          SpecimenSection(
            title: 'Item · $variant',
            children: [
              for (final s in states)
                Specimen(label: s, child: _item(build(s))),
            ],
          ),
        SpecimenSection(
          title: 'Header and separator',
          children: [
            const Specimen(
              label: 'Header',
              child: SizedBox(
                width: 188,
                child: AmalfiMenuHeader(label: 'Section'),
              ),
            ),
            const Specimen(
              label: 'Separator',
              child: SizedBox(width: 188, child: AmalfiMenuSeparator()),
            ),
          ],
        ),
        const SpecimenSection(
          title: 'Menu',
          note:
              'Live: hover the rows; rest on "Open Recent" or "Services" for the submenu; '
              'click a menu, then use ↑ ↓ → ← Return Esc and letters.',
          children: [
            Specimen(
              label: 'Simple',
              child: AmalfiMenu(entries: _simple, width: 200),
            ),
            Specimen(
              label: 'Full · Cascade',
              child: AmalfiMenu(entries: _full, width: 232),
            ),
            Specimen(
              label: 'Context',
              child: AmalfiMenu(entries: _context, width: 208),
            ),
            Specimen(
              label: 'Submenu',
              child: AmalfiMenu(entries: _submenu, width: 188),
            ),
          ],
        ),
        SpecimenSection(
          title: 'Shown above the app',
          children: [
            Specimen(
              label: 'showAmalfiMenu',
              child: Builder(
                builder: (context) => AmalfiPushButton(
                  label: 'Open menu',
                  onPressed: () {
                    final box = context.findRenderObject();
                    if (box is! RenderBox) return;
                    showAmalfiMenu(
                      context: context,
                      position: box.localToGlobal(
                        Offset(0, box.size.height + 4),
                      ),
                      entries: _full,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
