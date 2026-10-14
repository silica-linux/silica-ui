# Sheets, cards and panels

IDs: CT-SH-01, CT-SH-02, CT-TL-02, CT-PN-01…03, MU-06, MU-95, MU-96.

## Compact card (CT-SH-02)

In macOS 27 the save dialog and small prompts are **no longer attached to the title bar**: they are
rounded cards centred on the window, horizontally and vertically, over a veiled window.

| Card | Size |
| --- | --- |
| Save, compact | 413 × 218 |
| Save, expanded | 866 × 347 (may be wider than its window), resizable, stays centred |
| New folder | 320 × 158 |
| Go to folder | 460 × 183 (path field 344 × 22, recent paths in 22 pt rows) |
| Save a search | 413 × 263 |
| Alarm editor (dark app) | 514 × 391, fill `#272727` |

| Colour | Light | Dark |
| --- | --- | --- |
| Card background | `#ffffff` | `#272727` (top line `#3d3d3d`) |
| Outer border | `#a6a6a6` | `#010101` |
| Window veil at rest | white → `#bababa` | `#262726` → `#1c1c1c` |

- Corner radius about 18–20 pt.
- **Opening** (from the key): the veil starts ~145 ms later and is complete at ~440 ms; the card
  appears at ~212 ms, **fading in while moving down about 20 pt**, at constant width (no scaling),
  and is still at ~480 ms.
- **Closing:** starts ~46 ms after the release, a fade with no movement, gone at ~270 ms; the veil
  is gone at ~310 ms.
- **Expanding** the save card: it starts ~190 ms after the click and settles at ~420 ms; the card
  widens to the left and downward while a sidebar (186 pt) slides in from the left.
- Labels sit right-aligned in a column, controls start at a common x; buttons sit at the bottom
  right (cancel 81 × 26, the default in the accent).
- The width a card was last resized to is remembered.
- A gallery sheet (an alert run as a sheet) behaves the same way: a floating rounded card centred
  on the dimmed window.

## Sheet attached to the toolbar (CT-SH-01, CT-TL-02)

The customize-toolbar sheet is the one sheet still attached to the window, hanging from the bottom
of the toolbar.

| Measure | Value |
| --- | --- |
| Sheet | 1066 × 500, top at the toolbar's bottom edge (52), centred on the window (may overflow) |
| Material | translucent, 1 pt dark border, shadow also above |
| Palette items | 100 × 68 (38 pt icon and a two-line label), 8 per row, row pitch 78; items already in the bar are dimmed |
| Default set | a 1002 × 67 strip on a rounded background |
| Bottom controls | a "Show" pop-up 129 × 26 (icons and text / icons only / text only), a "Done" button 74 × 26 in the accent |

- The sheet appears about 910 ms after the click and takes ~95 ms to come in; "Done" closes it
  in one or two frames.
- Dragging an item into the bar opens a gap in ~130 ms; dropping between two neighbours puts it
  **inside their capsule** (the groups merge). In flight the item is a circle with a shadow.
- Dragging a bar item onto the palette removes it in one frame, with no puff.
- "Icons and text" gives each item its own capsule or circle and raises the bar to 66 pt with a
  ~10 pt label under each item; the setting applies to every window.
- Every bar item can also be moved and removed without the sheet (accessibility actions).
- silica_ui's "Show" choice and the gap animation are *provisional*.

## Panels (CT-PN-01, CT-PN-03)

- **Utility panel** (Info window, copy progress window 404 × 88): a small titled window with the
  window material; measured in the file manager spec.
- **Open panel:** a separate 880 × 448 window with no visible title: a 186 pt sidebar, a toolbar
  row (back/forward, view, group, location menu, search), the file area, and at the bottom
  secondary actions on the left and cancel / open on the right (open disabled with no selection).
- **Floating small panel** (emoji picker, CT-PN-02): seen, not measured.
- Panel chrome and the HUD style in silica_ui (`FloatingPanel`) are *provisional*.
