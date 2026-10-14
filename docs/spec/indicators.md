# Level indicators, progress bars, spinners

IDs: CT-LV-01, CT-PR-01…04.

## Level indicator (CT-LV-01)

| Style | Frame (visible height) | Look |
| --- | --- | --- |
| Continuous capacity | 160 × 18 (16) | a green bar (`#59c660`) on a track |
| Discrete capacity | 160 × 18 (12) | separate cells |
| Relevance | 160 × 18 (11) | gray hatching |
| Rating | 160 × 18 | stars |

Warning and critical colours, cell spacing and star size were not measured; silica_ui's values for
them are *provisional*.

## Progress bar, determinate (CT-PR-01)

| Instance | Frame | Visible bar |
| --- | --- | --- |
| Gallery | 200 × 20 | 8 pt |
| Now Playing module | 154 × 12 | — |
| Copy window (whole panel) | 404 × 88 | — |

- Fill accent (display `#296ffb`); track `#f0f0f0` light, `#383839` dark; rounded ends.
- In an inactive window the fill turns gray.

## Progress bar, indeterminate (CT-PR-02, partial)

The same track with a lighter gradient moving along it. The timing was not measured; silica_ui
sweeps a third of the bar every 1.2 s (*provisional*).

## Spinner (CT-PR-03)

- Regular 32 × 32, small 16 × 16.
- **Eight** gray spokes. silica_ui currently draws twelve spokes turning once per second: the spoke
  count must be brought to eight, the speed is *provisional*.

## Circular progress ring (CT-PR-04, partial)

A timer ring in a dark app: an orange stroke (sRGB about `#ff9230`) on a `#3b3b3d` track, emptying
from the top as time passes. Stroke width and ends are *provisional* in silica_ui (stroke 6).
