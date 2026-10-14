# Accent, focus ring and state rules

Rules shared by every control. IDs: CT-CL-01…03, CT-TF-09, MU-10, MU-32, plus the state strips
of the control gallery (CT-BTN-*, CT-CB-02, CT-RB-01).

## Accent colour (CT-CL-01)

The system offers nine accents. Each accent has three colours per appearance (sRGB):

- **plain**: the exact system colour. It is used by the default button and the progress fill.
- **fill**: used by toggles that are on, selected segments, switches, checkboxes, radios and
  slider fills. It is about 2 % darker than plain in light, and slightly lighter in dark.
- **ring**: the keyboard focus ring. It is the accent at about 50 % opacity over the window
  background.

Light:

| Accent | plain | fill | ring |
| --- | --- | --- | --- |
| Multicolour | `#007aff` | `#0077f9` | `#8fb4fb` |
| Blue | `#007aff` | `#0077f9` | `#8fb4fb` |
| Purple | `#953d96` | `#913b92` | `#c393c3` |
| Pink | `#f74f9f` | `#f04e9a` | `#f9a0c6` |
| Red | `#e0393e` | `#db373d` | `#ec9894` |
| Orange | `#f7821b` | `#f17e1b` | `#f8b88a` |
| Yellow | `#ffc727` | `#f9c225` | `#f9dc92` |
| Green | `#62ba46` | `#5fb644` | `#a9d59a` |
| Graphite | `#989898` | `#949494` | `#9a9a9e` |

Dark:

| Accent | plain | fill | ring |
| --- | --- | --- | --- |
| Multicolour | `#007aff` | `#0d7dff` | `#296692` |
| Blue | `#007aff` | `#0d7dff` | `#296692` |
| Purple | `#a650a7` | `#a755a9` | `#825084` |
| Pink | `#f74f9f` | `#f854a1` | `#93507e` |
| Red | `#ff5257` | `#ff565b` | `#945154` |
| Orange | `#f7821b` | `#f78622` | `#936e33` |
| Yellow | `#ffc601` | `#ffc811` | `#93912a` |
| Green | `#62ba46` | `#66bc4a` | `#5b8f4a` |
| Graphite | `#8c8c8c` | `#8f8f8f` | `#737374` |

- **Multicolour** looks blue in standard controls. The setting only changes the accent of apps
  that define their own.
- **Switch on** with the default accent is `#0176f7` in light and `#0b7cfc` in dark. With the other
  accents it is within one level of the fill.
- **Text selection** follows the accent as a light tint, and so does the date picker's "today". A
  colour well keeps its own colour.
- **A change of accent** reaches running apps within about one second.

In silica_ui:

- `SilicaAccent` names the nine accents and `AccentColors.of(accent, dark:)` holds the table.
- `ControlAccent.palette(accent: …)` applies one of the nine accents to the controls below it.
- `ControlAccent(color: …)` sets an app's own colour instead. Clock uses its orange this way.

## Focus ring (CT-TF-09, MU-10, MU-32)

| Ring | Width | Placement | Light | Dark |
| --- | --- | --- | --- | --- |
| Keyboard focus (controls and text fields, default accent) | 3 pt | outside the control's frame | `#8fb4fb` | `#296692` |
| Text field inner border | 1 pt | on the field edge | `#649efa` | `#3586c5` |
| Toolbar control (keyboard navigation on) | 4 pt | 1 pt inside the control's box, following the segment shape | `#89aff7` | `#3d7aa6` |

- **Width and colour:** the ring is 3–4 pt wide with a soft outer edge. It takes the ring colour
  of the accent in effect.
- **Shape:** the ring follows the control's shape:
  - push buttons, pop-ups and the default button get a rounded rectangle;
  - a checkbox gets a rounded square, and only around the box, not the label;
  - a radio button gets a circle;
  - a switch gets a capsule around its track;
  - in a segmented control, only the focused segment gets the ring;
  - disclosure chevrons get a tight ring.
- **Motion:** moving with Tab moves the ring in one frame, with no animation. The ring of a text
  field fades in over about 200 ms when the field takes focus (search field, MU-70).
- **Selected text** inside a focused field: `#b3d7ff` light, `#40638b` dark.
- **The sidebar** never takes keyboard focus. Its selection keeps the same colours whether the
  focus is in the content or the toolbar.

## State rules (control gallery)

These rules hold for every native control observed in a window: push, bevel, help, disclosure,
image, toggle, pop-up, combo box, segmented, switch, checkbox and radio.

- **No hover state.** The pointer over a control changes nothing. Toolbar capsules are the
  exception: they show a hover pill, see [toolbar.md](toolbar.md).
- **Pressed** keeps the geometry and moves the fill one step: 10 % towards black in light,
  towards white in dark. The same step applies to the accent.

  | Fill | Rest → pressed, light | Rest → pressed, dark |
  | --- | --- | --- |
  | Gray button | `#ececec` → `#d5d5d5` | `#373738` → `#4b4b4c` |
  | Accent button | display `#296ffb` → `#2564e2` | display `#296ffb` → `#3e7dfb` |
  | Checkbox / radio | `#e6e6e6` → `#cfcfcf` | `#3c3c3d` → `#4f4f50` |
  | Segment | → `#c5c5c5` | → `#585859` |
  | Image button glyph | `#808080` → `#262626` | `#9e9e9e` → `#dfdfdf` |

- **Menus open on press.** Pop-up and pull-down buttons open their menu on press, not on release.
- **Inactive window.** Every accent fill turns neutral gray. This covers the default button, a
  toggle that is on, the selected segment, a switch or checkbox or radio that is on, and the
  slider fill. Geometry does not change.

  | Fill | Light | Dark |
  | --- | --- | --- |
  | Buttons, toggles, segments, switches, checkboxes, radios | `#cfcfcf` | `#505051` |
  | Slider fill | `#c5c5c5` | `#585859` |

- **Disabled.** Same shapes at reduced contrast: text at about 25 % alpha, lighter fills. A
  disabled switch keeps its accent at reduced opacity.

## Accessibility variants (CT-CL-03, partial)

Increase Contrast and Reduce Transparency were measured only in two places: on the file manager
window (see the file manager spec) and on the toolbar capsules ([toolbar.md](toolbar.md)).

With "Show borders", only the switch changes, and only when it is on: it gains a darker accent
outline.

Other controls under these settings are not measured.
