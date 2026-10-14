# Changelog

## 0.23.0 · 2026-10-14

The controls of milestone M6 (UI components 1:1). Values not measured yet are marked
provisional in the code and will change once measured.

- **Glass toolbar over scrolling content** (silica-ui#2): `ScrollUnderToolbar(toolbar, body:
  (context, padding) => …, header, active)` lets the body scroll under the 52 pt toolbar band
  behind the measured veil (`ToolbarVeil.light` / `.dark`, two blurs), with the 1 pt line once
  the content has scrolled (always in an inactive window); toolbar capsules over content get a
  blurred rim (provisional, no refraction yet).
- **Buttons and toggles**: `SilicaButton` (normal, primary, destructive; push, bevel,
  borderless, circle bezels; mini to large), `HelpButton`, `ToggleButton`, `ImageButton`,
  `DisclosureTriangle`, `DisclosureButton`, `SilicaCheckbox` (with the mixed state),
  `SilicaRadio` and `SilicaRadioGroup`, `SilicaSwitch`, `SegmentedControl` (select one, any,
  momentary), `PopUpButton`, `PullDownButton`, `ComboBox`.
- **Inputs and indicators**: `SilicaTextField` (secure, with the caps lock sign),
  `SilicaSearchField` (recents, tokens, clear), `SilicaTokenField`, `SilicaStepper`,
  `SilicaSlider` (ticks, labels) and `SilicaCircularSlider`, `SilicaDateField`,
  `SilicaCalendar`, `SilicaClockFace`, `SilicaColorWell` and `SilicaColorPicker`,
  `SilicaLevelIndicator` (continuous, discrete, rating), `SilicaProgressBar` (determinate and
  indeterminate), `SilicaSpinner`, `SilicaProgressRing`.
- **Containers and navigation**: `SourceList` (sections, nesting, badges), `TableView` (sorting,
  resizable columns, striping, outline mode), `CollectionView`, `SilicaScrollbar` and
  `SilicaScrollBehavior` (overlay and legacy scrollers), `SplitView` (sidebar behaviour,
  dividers, collapse), `WindowTabBar` and `SilicaTabView`, `PathControl`, popovers on all four
  edges (`PopoverAnchor`, `PopoverPanel`), `showWindowSheet`, `FloatingPanel` (utility, HUD),
  `SilicaTooltip`, `ToolbarCustomizeSheet`.
- **Shared base**: `ControlPalette` (accent, focus ring colors, the inactive-window gray),
  `WindowActiveScope` (with `.follow` for the app lifecycle; it falls back to `ToolbarScope`),
  `FocusRing`, `ControlAccent`, `ChevronPainter`. Every control works light and dark, in active
  and inactive windows, with the keyboard and with semantics; visible texts are parameters.
- The example is now the catalog app: every group next to each other, light/dark and window
  state switches, plus the Liquid Glass lab.

## 0.22.0 · 2026-10-14

- **API change**: `GlassTip.up` becomes `GlassTip.edge` (`TipEdge.bottom`, `top`, `left`,
  `right`); `up` stays as a getter. Side tips need Ossido with silica-glass-v1 version 6
  (`add_side_tip`): a popover beside its control.
- The menu tip is the measured drop: 24 pt base, 10 pt deep (glass widths per row 24 20 18 16
  14 12 10 8 6 2, drawn by Ossido); the menu position is unchanged (body 8 pt above the anchor).
  The shadow cut-out follows the same drop.

## 0.21.0 · 2026-10-14

- `SilicaWindow.setSize`, `setSizeLimits`, `setFixedSize`: the app chooses its window size and
  the resize limits (min = max: a fixed-size window, the zoom button disabled by Ossido). They
  need the silica-desktop embedder with the `setSize` / `setSizeLimits` window calls.

## 0.20.0 · 2026-10-14

- The calendar icon writes the month in the language of the window (`Localizations`, or the
  platform locale): English by default, Italian when the system is Italian. Before it was
  always Italian.

## 0.19.3 · 2026-10-14

- Everything in English: comments, tests, changelog. Internal widget keys renamed:
  `'pillola'` → `'pill'`, `'menu nella finestra'` → `'in-window menu'`, `'avviso pieno'` →
  `'solid alert'`, `'avviso <label>'` → `'alert <label>'` (tests that look them up must follow).

## 0.19.2 · 2026-10-14

- `SilicaIcon`: files, folders, volumes and Trash have a ground shadow under the shape of the
  drawing (icons.md IC-01: at 128 opacity 0.28, σ 2.7, 1.2 pt down; `IconShadow`).
  silica-icons draws them flat and leaves the shadow to whoever shows them.

## 0.19.1 · 2026-10-14

- `ToolbarSegment` keeps tap and drag to itself: a click or a drag starting on a control does
  not move the window (`WindowDragArea`), as before 0.19.0 (MU-08).

## 0.19.0 · 2026-10-14

- Toolbar control states (mustache.md M6 › MU-07): a 28 pt high pill (the segment width − 3;
  for buttons with their own capsule, the capsule − 2) on hover, darker on press with the
  capsule +1 pt per side; chosen segment at rest, hovered and pressed; disabled ones without
  a pill (in dark a faint pill on press); separators hidden next to the segment under the
  pointer. The click acts on release, inside the segment.
- `ToolbarSegment.onLongPress` (after `toolbarLongPress`, 295 ms: the release does not act) and
  `onPress` (on press, for buttons with a menu).
- `ToolbarScope(active:, hovered:)`: inactive window (capsule and glyph dimmed, hovering lights
  them up again) and pointer in the bar (in dark the capsules +7 levels).
- **API change** in `ToolbarColors`: `fill`, `fillBarHover`, `fillInactive`, `hover`,
  `pressed`, `chosen*`, `icon*` instead of `fillTop`/`fillBottom`/`chosenTop`/`chosenBottom`.

## 0.18.0 · 2026-10-14

- `WindowGlass` and `WindowGlassMaterial`: glass inside a window, made by Flutter (blur σ 9 and
  the thick material matrix, light and dark, the same as Ossido's) over the app content, where
  the compositor glass does not reach.
- `MenuPanel.opaque` / `MenuHost.opaque`: the in-window menu is now glass (`WindowGlass`)
  instead of a solid fill. **API change**: `MenuColors.opaqueFill` removed.

## 0.17.0 · 2026-10-14

- **Drawing change** for the icons of files, folders, volumes and Trash (silica-icons 0.2,
  icon-format.md › "Principle"): `side` is the whole canvas, no longer the app body.
  The `min_size` bands of labels, folder symbols and badges are compared with the canvas
  side; badges stay in the box between the app body (100…924) and the golden line.
- `SilicaIcon.besideApps`: a place next to the apps (Dock) keeps `side` as its body and the
  app canvas around it. `canvasExtent` gives the canvas side.

## 0.16.0 · 2026-10-14

- `SilicaDrag` (the embedder's `silica/drag` channel): Ossido's drag and drop between apps.
  `start(paths, icon:)` carries a list of files (`text/uri-list`) out of the window with the
  image on the pointer; `events` gives enter, motion, leave and drop (`SilicaDrop` with the
  URIs and the paths) of files dragged from other apps, and the end (`SilicaDragFinished`:
  `copy`, `move`, `none`) of those that left from here.

## 0.15.1 · 2026-10-14

- `SilicaIcon`: without `dark` the icon is always the light one. The dark variant belongs to
  the icon style (a separate setting), not to the system appearance: in dark appearance the
  icons of apps and files stay the same (icons.md IC-01, mu20-list-dark).

## 0.15.0 · 2026-10-14

- Dark appearance from the system (`MediaQuery.platformBrightness`, which the embedder
  receives from the settings portal).
- **API change**: `ToolbarColors` and `MenuColors` are no longer static constants but `light`
  / `dark` instances, with `of(context)` following the system appearance
  (`ToolbarColors.title` → `ToolbarColors.of(context).title`). `MenuColors.highlight` and
  `highlightText` stay static: they are the same in both appearances.
- Dark toolbar: fill `#4c4c4c` → `#535454`, pill `#595959`, icons and title `#e9e9e9`
  (mustache-spec 1.2).
- Dark menus: white text at 85 %, disabled at 26 %, shortcuts at 30 %, separator at 14 %;
  the solid fill `#353536` (menubar.md).

## 0.14.0 · 2026-10-14

- `GlassTip.up`: the glass tip pointing up, on the top edge (silica-glass-v1 version 5,
  `add_upward_tip`).
- `MenuHost.tipUp` / `MenuPanel.tipUp`: a menu under the tip, pointing at the button it opens
  from (the window arrangement popover).

## 0.13.1 · 2026-10-14

- Menus: a header (`MenuSection`) counts in the width as a 13 pt item and is aligned with the
  item text (at 29 with checkmarks), as in the Dock stack menu (d06-pila-menu: 220 pt).

## 0.13.0 · 2026-10-14

- `SilicaWindow` (`silica/window` channel): `setFullSizeContent(toolbar)` asks Ossido for
  full-size content (the window buttons over the app's bar), `startMove()` moves the window.
- `WindowDragArea`: the empty part of the toolbar moves the window.
- `ToolbarCapsule`, `ToolbarSegment`, `ToolbarColors`: the capsules of the unified toolbar
  (38 high, radius 19, chosen segment as a 34 × 28 pill).

## 0.12.0 · 2026-10-13

- `MenuCustom`: a menu row drawn by whoever opens the menu (`height` high, at least `width`
  wide), with the function that closes the menu: the row of tag circles.

## 0.11.1 · 2026-10-13

- silica-icons step 0b: if the type comes only from the name and `globs2` gives several types
  with the same weight (`.ts`), the extension map decides first. `MimeDatabase.isAmbiguousName`.

## 0.11.0 · 2026-10-13

- Type icons write the real extension (silica-icons `file-type-label`): box, size, light and
  dark color, `no_extension`, no label below `min_size`.
- `icons.mime` accepts `{icon, category}`: the generic file with that category (the extension
  override still comes first). Step 0: the type becomes canonical through the aliases.
- `FileIcon`: `labelBox`, `labelSize`, `labelWeight`, `labelMinSide` instead of `rules`. The
  label uses the natural line of Inter, centered in the box.

## 0.10.0 · 2026-10-13

- `MenuHost.opaque` and `MenuPanel.opaque`: solid menus (`#fcfcfd` with a hairline) instead of
  glass, for context menus drawn inside an app window (until the embedder has popups).

## 0.9.1 · 2026-10-13

- `resolveFileIcon`: an `icons.mime` entry leading to the generic file (`application/json`)
  draws it with the label and the category color, as in step 5.

## 0.9.0 · 2026-10-13

- `MimeDatabase`: the MIME type of a file from shared-mime-info (`globs2` globs with weights
  and case, `subclasses`, `aliases`) and, if the name is not enough, from the content (ELF,
  scripts with `#!`, text or binary).
- `resolveFileIcon` and `FileSource`: the icon of a file in silica-icons order (type, type with
  `*`, parents, extension, generic file with the extension written in the category color,
  sheet with the question mark); an executable without an extension takes `file-executable`.
  The map is the one in the generic file manifest (`FileLabelRules`).
- Badges (`IconBadge`, `SilicaIcon.badges`, `badgesOf`, `visibleBadges`): alias at the bottom
  left, on the right the first of unreadable, locked, cloud; from 16 to 31 pt just one, below
  16 none; dark variants.
- Volumes: `volumeIconId` (network, disk image, optical, external, internal),
  `parseMountinfo`, `blockRemovable`.

## 0.8.1 · 2026-10-13

- `SilicaAlert.opaque`: solid background (white or `#272727`, outer hairline, shadow) instead
  of glass, for an alert drawn inside a window: there the compositor glass would sit under the
  content and would not show. The normal button becomes `#e8e8e8`.

## 0.8.0 · 2026-10-13

- `SilicaAlert`: the system alert (292 pt, thick glass, 66 icon, bold title, 30 pt high buttons
  stacked full width or side by side), with the `AlertRole` roles (blue default, cancel,
  pinkish destructive); Return chooses the default, Esc the cancel one (or the only button).

## 0.7.1 · 2026-10-13

- `fileIconId(name)` and `fileIconFor(name)`: the silica-icons icon of a file from its
  extension (previously in the shell's Dock). A hidden file without an extension (`.bashrc`)
  is `file-unknown`.

## 0.7.0 · 2026-10-13

- The silica-icons icons move here from the shell, for the apps (Mustache) and the shell:
  `SilicaIcon` (formerly the shell's `ShellIcon`) with `LayeredSource`, `FolderSource`,
  `FlatSource`; the manifest (`parseManifest`, `findSilicaIcon`, `silicaIconDirs`), the generic
  folder with symbol and tint (`resolveFolderIcon`, `FolderIcon`) and the special folders
  (`xdgUserDirs`, `specialFolderKey`, `xdgDataDirs`). `iconBodyPath`: the body superellipse.
- New dependency: `flutter_svg`.

## 0.6.0 · 2026-10-13

- `Glass.group` and `LiquidGlass.group`: glass merges only with glass of the same group, and a
  higher group sits on top. Every menu level has its own: the submenu is a distinct panel over
  the parent menu, not a single shape with it.
- `Glass.tip` (`GlassTip`): a tip that is part of the glass shape, with a rounded apex and
  sides joined to the body. The Dock menu tip is no longer a triangle painted over the glass;
  the menu shadow does not fall on the tip.
- Removed `MenuColors.tipFill` and `MenuColors.tipLine` (no longer needed).
- Requires silica-glass-v1 version 4 (Ossido); with an older compositor groups are ignored and
  there is no tip.

## 0.5.1 · 2026-10-13

- `MenuHost`: when `tip` or `anchor` change (the surface hosting the menu stretches) the open
  menus move with them; before they stayed where they were.

## 0.5.0 · 2026-10-13

- `MenuHost.onRectsChanged`: the rectangles of the open menus, after the frame in which they
  change (a submenu opening or closing), so that whoever hosts the menu can widen its input
  region. Without it, on a surface with an input region the submenu did not get the pointer.

## 0.4.0 · 2026-10-13

- `MenuHost.tip` and `MenuPanel.tipX`: a menu pointing at an object below it (the Dock icons)
  has a tip 8 pt high and 22 wide at the base, with the body 27 pt to the left of the apex.

## 0.3.2 · 2026-10-13

- `MenuHost.handlesPointer`: false to pass the pointer from outside (`pointerMoved`,
  `pointerDown`, `pointerUp`, `contains`), like a bar where you press on an item and release
  on a menu item.

## 0.3.1 · 2026-10-13

- Same as 0.3.0 (tag published by mistake without the intended change).

## 0.3.0 · 2026-10-13

- Menus: `MenuHost` (a menu with its submenus in an area that contains it), `MenuPanel`, the
  `MenuAction` items (shortcut, checkmark, icon, submenu, disabled), `MenuDivider` and
  `MenuSection`; `menuSize` and `menuRowTops` to place them. 24 pt items, 11 pt separators,
  blue highlight, thick glass with the shadow outside the panel; submenus after ~295 ms with
  triangle tolerance; ↑ ↓ → ← Return Esc and letters; the choice blinks and the menu fades in
  ~190 ms.

## 0.2.0 · 2026-10-13

- Glass carries the ancestors' opacity (`Opacity`, `FadeTransition`, `AnimatedOpacity`): the
  region sent to the compositor has an `opacity` field (0–1) and Ossido composes the glass
  fading together with the panel (`silica-glass-v1` version 3). With an older compositor the
  glass stays solid.

## 0.1.0 · 2026-10-13

First version as a standalone package (previously in `silica/packages/silica_ui`).

- `uiFontFamily` and `uiText`: Inter Regular and SemiBold.
- `Glass` and `GlassMaterial` (`clear`, `thick`, `regular`, `notification`) on the
  `silica/glass` channel.
- `LiquidGlass`: press, release with bounce, highlight following the pointer.
- `GlassRegistry` checks the regions at every frame: glass under an ancestor changing
  transform or opacity follows even without repainting.
- `example/`: the glass lab.
