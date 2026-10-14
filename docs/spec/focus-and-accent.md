# Accent, focus ring and state rules

Rules shared by every control. IDs: CT-CL-01…03, CT-TF-09, MU-10, MU-32, plus the state strips
of the control gallery (CT-BTN-*, CT-CB-02, CT-RB-01).

## Accent colour (CT-CL-01, partial)

Only the default ("multicolour") accent was observed. Other accent choices are not measured.

| Use | sRGB | Notes |
| --- | --- | --- |
| Accent (default button, menu highlight, selected segment) | `#007aff` | display `#296ffb`; same in light and dark |
| Slider and switch fill, light | display `#286df5` | treated as the accent |
| Slider and switch fill, dark | display `#2e73fb` | treated as the accent |
| Control Center switch (on) | `#0074f8` | slightly darker than the accent |
| Default button pressed | display `#2564e2` (light), `#3e7dfb` (dark) | |
| List selection (file manager) | `#0064e1` / `#0059d1` | darker than the accent, see [lists.md](lists.md) |

silica_ui keeps one accent, `ControlPalette.accent` = `#007aff`. An accent setting does not exist
yet (CT-CL-01 is missing).

## Focus ring (CT-TF-09, MU-10, MU-32)

Two rings were measured:

| Ring | Width | Placement | Light | Dark |
| --- | --- | --- | --- | --- |
| Text field (rename field, search field) | 3 pt | outside the field | `#8fb4fb` | `#296692` |
| Text field inner border | 1 pt | on the field edge | `#649efa` | `#3586c5` |
| Toolbar control (keyboard navigation on) | 4 pt | 1 pt inside the control's box, following the segment shape | `#89aff7` | `#3d7aa6` |

- The ring of a text field appears when the field takes focus and fades in over about 200 ms
  (search field, MU-70).
- Selected text inside a focused field: `#b3d7ff` light, `#40638b` dark.
- The keyboard focus ring of push buttons, checkboxes and radios was **not captured** (it needs
  full keyboard navigation). silica_ui draws a 3 pt ring outside the control in the toolbar ring
  colours (*provisional*).
- The sidebar never takes keyboard focus; its selection keeps the same colours whether the
  focus is in the content or the toolbar.

## State rules (control gallery)

These rules hold for every native control observed in a window (push, bevel, help, disclosure,
image, toggle, pop-up, combo box, segmented, switch, checkbox, radio):

- **No hover state.** The pointer over a control changes nothing. (Toolbar capsules are the
  exception: they show a hover pill, see [toolbar.md](toolbar.md).)
- **Pressed** keeps the geometry and moves the fill one step: darker in light, lighter in dark.

  | Fill | Rest → pressed, light | Rest → pressed, dark |
  | --- | --- | --- |
  | Gray button | `#ececec` → `#d5d5d5` | `#373738` → `#4b4b4c` |
  | Accent button | display `#296ffb` → `#2564e2` | display `#296ffb` → `#3e7dfb` |
  | Checkbox / radio | `#e6e6e6` → `#cfcfcf` | `#3c3c3d` → `#4f4f50` |
  | Segment | → `#c5c5c5` | → `#585859` |
  | Image button glyph | `#808080` → `#262626` | `#9e9e9e` → `#dfdfdf` |

- Pop-up and pull-down buttons open their menu **on press**, not on release.
- **Inactive window.** Every accent fill turns neutral gray: default button, toggle on, selected
  segment, switch on, checkbox on, radio on, slider fill. Geometry does not change. The gray was
  measured in dark only (`#545555`, from the calculator keys); light uses `#b4b4b6`
  (*provisional*).
- **Disabled.** Same shapes at reduced contrast: text at about 25 % alpha, lighter fills. A
  disabled switch keeps its accent at reduced opacity.

## Accessibility variants (CT-CL-03, partial)

Increase Contrast and Reduce Transparency were measured only on the file manager window (see the
file manager spec) and on the toolbar capsules ([toolbar.md](toolbar.md)). With "Show borders"
only the switch in the on state changes, gaining a darker accent outline. Other controls under
these settings are not measured.
