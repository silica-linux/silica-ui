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
| Selected pill | ~28 pt tall, 4 pt inset, `#525252`–`#555555` |
| Labels | white, semibold, ~13 pt |

- The pill starts moving 25–52 ms after the press and settles in about 300–350 ms, with a
  decaying motion. The content swaps in a single frame, about 30–60 ms after the release, with no
  cross-fade.
- Hovering a segment shows a highlight (colour not measured).
- The control is centred on the window, or on the area beside a sidebar when there is one.
- At the minimum window width it **collapses into a pop-up button** showing the current section.

### The lens (provisional)

While the section switch is pressed, the selection swells into a lens of glass that magnifies the
labels under it; dragging across the control moves it, segment by segment, to the enabled segment
under the pointer, and releasing inside the control chooses that segment. The lens then shrinks
back into the pill. Not measured yet (LENS request): silica_ui uses a lens 1.12 × the pill's width
and 1.4 × its height (it rises past the track), a 1.3× magnification, a swell spring with a small
overshoot, a travel spring with a ~3 % overshoot and a shrink without visible bounce; with reduced
motion it appears, jumps and disappears at once. The edge refraction is drawn by a fragment shader
where the engine supports shader image filters (Impeller), otherwise the content is only
magnified.

The chosen pill is inset by the same amount on every side of the track (4 pt for the section
switch, 2 pt for the window control) whatever its position.

## Small segmented controls in content (CT-SEG-03, partial)

- A base selector in a calculator (dark): selected segment in the app tint (sRGB `#ff960e`),
  others `#373738`; in an inactive window the selected one turns `#505051`.
- Previous / next arrows in a find bar: seen, not measured.

## Scope pills (CT-SEG-04, partial)

Two radio pills 22 pt tall in a 32 pt bar under a search toolbar; the chosen one has a gray
background. Group 224 × 32. Colours and pressed state not measured.
