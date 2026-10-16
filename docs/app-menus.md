# App menus in the menu bar

How a Silica app publishes its menus to the global menu bar (silica-desktop#25). The bar shows
the menus of the frontmost app; the chosen item comes back to the app. Requires Ossido with
`silica-menu-v1` and the Silica embedder (`silica/menu` channel); elsewhere nothing is
published and the shortcuts still work inside the app.

## In short

1. Wrap the app's root in one `SilicaMenuBar` and declare the menus there.
2. Use the standard builders: `SilicaMenus.app`, `SilicaMenus.edit` (or `textEdit`),
   `SilicaMenus.window`, `SilicaMenus.help`. Add the app's own menus with `SilicaMenu` and
   `SilicaMenuItem`.
3. Rebuild `SilicaMenuBar` when a state changes (checkmark, enabled item): the bar is updated
   only when the menus really differ.
4. Remove the key handling the menu now does (⌘1, ⌘C…): `SilicaMenuBar` binds the shortcuts of
   its enabled items while the app has the keyboard.

```dart
SilicaMenuBar(
  menus: [
    SilicaMenus.app(l.appName, onAbout: showAbout, onSettings: openSettings),
    SilicaMenus.edit(l.menuEdit, copy: copy, paste: paste),
    SilicaMenu(
      label: l.menuView,
      menus: [
        PlatformMenuItemGroup(members: [
          for (final mode in Mode.values)
            SilicaMenuItem(
              label: l.modeName(mode),
              checked: mode == current,
              shortcut: SingleActivator(mode.key, meta: true),
              onSelected: () => setMode(mode),
            ),
        ]),
        SilicaMenu(label: l.decimalPlaces, menus: [
          for (var p = 0; p <= 15; p++)
            SilicaMenuItem(label: '$p', checked: p == places, onSelected: () => setPlaces(p)),
        ]),
        const SilicaMenuItem.system(SilicaMenuItemRole.fullScreen),
      ],
    ),
    SilicaMenus.window(l.menuWindow),
    SilicaMenus.help(l.menuHelp, onHelp: openHelp),
  ],
  child: app,
)
```

## What the bar does by itself

- **App menu**: titled with the app's name in bold (the `SilicaMenus.app` name). About and
  Settings… appear only when the app gives them an action. Services, Hide, Hide Others, Show
  All and Quit are system items: the bar runs them (Ossido's `app.hide`, `app.hide_others`,
  `app.show_all`, `app.quit`; ⌘H, ⌥⌘H and ⌘Q are Ossido's shortcuts).
- **Labels in the user's language**: an item with a standard role and an empty label (About,
  Settings…, Undo, Redo, Cut, Copy, Paste, Delete, Select All, the app's Help, the system
  items) takes the bar's label and default shortcut. The app's own labels are the app's to
  translate.
- **Window menu**: the bar puts its system items first (Minimize, Fill, Move & Resize, Full
  screen), then the app's items, then Bring All to Front and the list of the app's windows (the
  active one checked).
  Without a Window menu in the model the bar adds one before Help. `SilicaMenus.window(close:
  true)` puts Close (⌘W) first, for apps without a File menu.
- **Help menu**: the app's help item, or Silica Help when the app has none.
- **States**: `enabled: false` greys an item; an item without an action is greyed too, unless
  it is a system item. `checked` draws the checkmark. A `SilicaMenu` inside a menu is a
  submenu. `PlatformMenuItemGroup`s are separated by lines.

## Keyboard

The model only shows the shortcuts. Keys go to the app as before: `SilicaMenuBar` wraps the
child in `CallbackShortcuts` with the shortcuts of the enabled items that have an action
(`shortcuts: false` turns that off for apps that keep their own key handling). ⌘ is the Logo
key, `meta: true` in Flutter. The system shortcuts (⌘Q, ⌘H, ⌥⌘H, ⌘W, ⌘M, ⌃⌘F) are Ossido's and never
reach the app.

## Flutter's PlatformMenuBar

`SilicaMenuBar` installs `SilicaMenuDelegate` as the binding's `platformMenuDelegate`, so plain
`PlatformMenuBar`, `PlatformMenu`, `PlatformMenuItem` and `PlatformProvidedMenuItem` (about,
quit, services, hide…, minimize, toggle full screen, arrange in front) also publish to the bar.
Call `SilicaMenuDelegate.install()` before `runApp` when using `PlatformMenuBar` directly; its
shortcuts are then not bound in the app (Flutter leaves that to the platform), so prefer
`SilicaMenuBar`.

## Checklist for an app

- [ ] One `SilicaMenuBar` above the app's content (with multiple windows: the active window's
      state drives the items).
- [ ] App menu from `SilicaMenus.app`; About and Settings only if the app has them.
- [ ] Edit menu with the actions the app supports; the others stay greyed (as on the
      reference), never removed.
- [ ] Every item does something or is greyed; nothing hidden behind a dead item.
- [ ] Checkmarks and enabled states follow the app's state (rebuild on change).
- [ ] The app's own key handling for the same shortcuts removed (or `shortcuts: false`).
- [ ] Labels localized (English source, Italian translation) except the standard roles.
- [ ] Every item is also an app command (`<app>.*` in the app's `docs/spec.md`).

Protocol details: silica-desktop `docs/protocols.md`, section silica-menu-v1.
