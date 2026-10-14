# Scroll bars

IDs: CT-SC-01…03.

## Measured instances

| Where | Track | Thumb | Notes |
| --- | --- | --- | --- |
| Search panel results (overlay) | — | 11 pt wide, radius ~5.5, `#808080` light / `#7c7c7c` dark | 3 pt from the panel's right edge; accessibility frame 19 pt wide |
| Launcher (always shown) | 11 pt, opaque, `#f2f2f2` / `#141414`, semicircle ends (radius 5.5) | same width and ends, `#808080` / `#7c7c7c` | 3 pt from the right edge; with short content the track stays and the thumb disappears |
| File manager list (while scrolling) | 11 pt, `#f3f3f3` / `#313132` | minimum 11 × 20, `#7a7a7a` / `#a2a2a2` (dark with a `#969696` border) | |
| File manager sidebar | — | 5 pt wide near the right edge | |
| Gallery scroll view, legacy style | always visible | gray | look only |

- The thumb length is proportional: visible height / content height of the track. Scrolling 100 pt
  moved a 145 pt thumb on a 385 pt track by 31 pt, as expected from the ratio.
- No hover or drag state of the thumb was observed in the launcher.

## Not measured

- **Overlay scroller fade (CT-SC-01):** when it appears, how long it stays and how it fades.
  silica_ui shows it while scrolling, then fades it after 1 s over 300 ms, with a 7 pt thumb at
  rest that grows on hover (*provisional*).
- **Elasticity at the ends (CT-SC-03):** the rubber-band overscroll was not measured; silica_ui
  uses Flutter's bouncing physics (*provisional*).
