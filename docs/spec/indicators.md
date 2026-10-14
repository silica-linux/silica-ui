# Level indicators, progress bars, spinners

IDs: CT-LV-01, CT-PR-01…04.

## Level indicator (CT-LV-01)

| Style | Frame (visible height) | Look |
| --- | --- | --- |
| Continuous capacity | 160 × 18 (16) | a green bar (`#59c660`) on a track |
| Discrete capacity | 160 × 18 (12) | separate cells |
| Relevance | 160 × 18 (11) | gray hatching |
| Rating | 160 × 18 | stars |

silica_ui draws the continuous bar 16 pt tall in `#59c660`, the discrete cells 12 pt tall and the
stars 11 pt. The warning and critical colours, the cell spacing and the star gap were not
measured; silica_ui's values for them are *provisional*.

## Progress bar, determinate (CT-PR-01)

| Instance | Frame | Visible bar |
| --- | --- | --- |
| Gallery | 200 × 20 | 8 pt |
| Now Playing module | 154 × 12 | — |
| Copy window (whole panel) | 404 × 88 | — |

- Fill accent (display `#296ffb`); track `#f0f0f0` light, `#383839` dark; rounded ends.
- In an inactive window the fill turns gray (silica_ui: `#c5c5c5` / `#585859`, the slider fill's
  gray).
- silica_ui draws the regular bar 8 pt thick in the plain accent on the measured track.

## Progress bar, indeterminate (CT-PR-02, partial)

The same track with a lighter gradient moving along it. The timing was not measured; silica_ui
sweeps a third of the bar every 1.2 s (*provisional*).

## Spinner (CT-PR-03)

- Regular 32 × 32, small 16 × 16.
- **Eight** gray spokes. silica_ui draws eight; its speed (one turn per second) is *provisional*.

## Circular progress ring (CT-PR-04, partial)

A timer ring in a dark app: an orange stroke (sRGB about `#ff9230`) on a `#3b3b3d` track, emptying
from the top as time passes. Stroke width and ends are *provisional* in silica_ui (stroke 6).
