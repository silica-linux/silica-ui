# Segmented controls

IDs: CT-SEG-01…05.

## Standard segmented control (CT-SEG-05)

- The gallery offered five styles (automatic, rounded, separated, textured, capsule): in macOS 27
  **all five render the same**. silica_ui therefore has a single style.
- 142 × 24 for three short segments: a gray capsule track, the selected segment an accent
  capsule with white text.
- Pressed segment: `#c5c5c5` light, `#585859` dark. No hover.
- Inactive window: the selected segment turns gray. Disabled: reduced contrast.
- Regular height 24; mini 18 and the 2 pt pill inset are *provisional* in silica_ui. The track is
  drawn in the push button gray (`#ececec` / `#373738`, *provisional*: the exact track gray was
  not sampled).
- The keyboard focus ring surrounds only the focused segment (CT-TF-09).


## Toolbar segmented group (CT-SEG-01)

The back/forward pair and the view switcher in a window toolbar: glass capsules with a hover
pill and a selected pill. See [toolbar.md](toolbar.md).

## Section switch in a toolbar (CT-SEG-02)

Measured on a dark-only app with four sections:

| Measure | Value |
| --- | --- |
| Track | 378 × 36, full capsule, fill `#3d3d3d` |
| Segments | 95, 94, 95, 94 pt wide |
| Rim | top `#727274`, bottom `#626262`, outer line `#0b0b0b` |
| Selected pill | ~79 × 28 pt, centred on its segment (4 pt from the top and bottom), `#525252`–`#555555` |
| Labels | white, semibold, ~13 pt |

- The pill starts moving 25–52 ms after the press and settles in about 300–350 ms, with a
  decaying motion. The content swaps in a single frame, about 30–60 ms after the release, with no
  cross-fade.
- Hovering a segment shows a highlight (colour not measured).
- The control is centred on the window, or on the area beside a sidebar when there is one.
- At the minimum window width it **collapses into a pop-up button** showing the current section.

- The segments share the whole track (95 + 94 + 95 + 94 = 378); the pill and the lens are centred
  on their segment, the first and last too (the pill sits 8 pt from the round end there, the lens
  lines up with it).

### The lens

While the section switch is pressed, the selection swells into a clear capsule lens, 91 × 48 pt,
centred on its segment and 6 pt past the track at the top and bottom (on narrow segments it also
passes the control's ends); dragging moves it with the pointer, clamped between the first and last
segment centres, and releasing inside the control chooses the segment under it. Timings and the
look are measured (LENS, silica-reference #92): see `GlassLensMetrics`.

silica_ui draws the lens from the window's own pixels. With Impeller it is a backdrop filter
clipped to the capsule running `shaders/glass_lens.frag`: the track, the rim, the pill and the
labels under it (and the toolbar where it overhangs) are magnified 1.11 ×, bent outward near the
rim (the track's edge lines show ~3 pt inside the lens), slightly blurred at the rim, split into
red and blue on the curved ends, with a dark outer edge and a 1 pt light line at the top and
bottom. The lens paints in the nearest overlay so neighbouring widgets and clips do not cut it.
Without shader filters (Skia, tests) it shows a magnified copy of the labels instead. It declares
no glass region to Ossido: the compositor's glass shows what is behind the window, which the lens
does not show.

The window control's pill fills its segment and is inset by 2 pt on every side whatever its
position.

## Small segmented controls in content (CT-SEG-03, partial)

- A base selector in a calculator (dark): selected segment in the app tint (sRGB `#ff960e`),
  others `#373738`; in an inactive window the selected one turns `#505051`.
- Previous / next arrows in a find bar: seen, not measured.

## Scope pills (CT-SEG-04, partial)

Two radio pills 22 pt tall in a 32 pt bar under a search toolbar; the chosen one has a gray
background. Group 224 × 32. Colours and pressed state not measured.
