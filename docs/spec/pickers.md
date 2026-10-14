# Date, time and colour pickers

IDs: CT-DP-01…05.

## Date picker (CT-DP-02)

| Style | Frame |
| --- | --- |
| Text with stepper | 142 × 24 (text part plus a stepper at the right) |
| Text only | 142 × 21 |
| Graphical (calendar) | 139 × 148 |

- **Text styles:** the date and time are shown as numeric parts in the order of the user's locale
  (day / month / year, then hours and minutes in the observed locale). Each part is edited on its
  own; the arrow keys or the stepper change the focused part.
- **Calendar:** a header with the abbreviated month and year and three controls (previous, today,
  next); the grid starts on Monday in the observed locale. Today's number is drawn in the accent
  colour; the selected day sits on a gray square.
- silica_ui's calendar cell (22) and selection mark (20) are *provisional*. The measured selected
  day is a gray **square**; silica_ui draws a circle today, to be changed.

## Time field with parts (CT-DP-01, partial)

Seen in an alarm editor: hours and minutes as separate parts with large digits (~29 pt cap
height); the focused part is filled with the tint (orange in that app, sRGB about `#c87524`
captured). silica_ui fills the focused part with the accent.

## Colour well (CT-DP-03)

| Style | Frame |
| --- | --- |
| Default | 44 × 28 |
| Minimal | 44 × 28 |
| Expanded | 64 × 28 |

- A capsule filled with the colour; the default style has a light ring around the swatch; the
  expanded style adds a button that opens the colour panel.
- silica_ui's well (44 × 23, radius 5, swatch inset 3) is *provisional* against these frames.

## Colour panel (CT-DP-04, partial)

A floating panel of about 264 × 450 with: a toolbar of five mode buttons, a colour wheel, a
brightness slider, an opacity slider with a percentage field, a grid of swatches and an eyedropper.
Only the wheel mode was opened.

## Unit picker popover (CT-DP-05, partial)

A 356 × 486 popover listing units in a calculator's conversion mode; not measured in detail and
not in silica_ui.
