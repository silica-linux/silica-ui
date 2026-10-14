# silica_ui specification

This folder describes how Silica's interface controls look and behave. The numbers come from
observing macOS 27 from the outside, in a clean-room process: the system is used, captured on a
calibrated display and measured. No system files, assets or texts are copied. The raw captures,
videos and measuring scripts stay in the private `silica-reference` repository. What is published
here is the result: measured values, behaviour described in our own words, and diagrams drawn
from the numbers.

## Conventions

- **IDs.** Every measured item has a stable ID: `CT-…` for controls (inventory of interface
  controls), `MU-…` / `R…` for measurements taken in the file manager, `TIP-01` for the tip
  outline, and so on. A section quotes the IDs it is based on, so a value can be traced back to
  its measurement session.
- **Units.** Sizes are in points at 1× (1 pt = 1 px on the measuring display). Positions are
  relative to the control or window named in the table.
- **Colours.** sRGB hex. Where only the display-profile value was available, the table says so
  ("display"). Translucent materials are given as the colour over the standard gray background
  `#7a7b80`, plus the formula when it was fitted.
- **Light / dark.** Tables give both appearances when measured; a dash means not measured.
- **Active / inactive.** "Inactive" is the state of a control in a window that is not the key
  window.
- **Provisional.** Values marked *provisional* were estimated (from a sibling control, an
  inference or a single sample). The code marks the same values; they change when measured.
- **Timings.** Delays are from the input event (press, release, key) to the first changed
  frame; durations until the last changed frame. Captures run at 75 Hz, so ±13 ms.

## Diagrams

`diagrams/` holds SVG drawings made from the tables: dimensioned boxes, outlines and colour
swatches. They are schematic (not renderings) and are original work of the project.

## Files

| File | Controls |
| --- | --- |
| [focus-and-accent.md](focus-and-accent.md) | accent colour, focus ring, pressed / disabled / inactive rules |
| [materials.md](materials.md) | glass materials used by the controls |
| [buttons.md](buttons.md) | push, bevel, help, disclosure, image, toggle, toolbar and round buttons |
| [toggles.md](toggles.md) | switches, checkboxes, radio buttons |
| [segmented.md](segmented.md) | segmented controls |
| [menus.md](menus.md) | menus, pop-up and pull-down buttons, combo box |
| [fields.md](fields.md) | text, secure, search and rename fields |
| [tokens.md](tokens.md) | token fields and search tokens |
| [sliders.md](sliders.md) | sliders and steppers |
| [pickers.md](pickers.md) | date, time and colour pickers |
| [indicators.md](indicators.md) | level indicators, progress bars, spinners |
| [lists.md](lists.md) | sidebar (source list), tables, outline and collection views |
| [scrollers.md](scrollers.md) | scroll bars |
| [split-and-tabs.md](split-and-tabs.md) | split views, tab views, the window tab bar |
| [popovers.md](popovers.md) | popovers and the tip outline |
| [sheets-and-panels.md](sheets-and-panels.md) | sheets, compact cards, panels, the customize-toolbar sheet |
| [tooltips.md](tooltips.md) | tooltips |
| [toolbar.md](toolbar.md) | the glass toolbar and the veil over scrolling content |
| [alerts.md](alerts.md) | alerts |
| [inventory-controls.md](inventory-controls.md) | every CT ID with its status in silica_ui |
