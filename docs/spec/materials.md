# Glass materials

The materials silica_ui asks Ossido to draw (through `silica-glass-v1`) or draws itself. Measured on
generated test wallpapers (solid gray `#7a7b80`, black and white stripes, colour ramps,
displacement maps). The full compositor-side model lives in silica-desktop's spec; this page
keeps the values the controls depend on.

## Models

- **Blur:** `out = a · (w · in + (1 − w) · G_σ(in)) + b` per channel, σ in pt, `w` the share of
  sharp image left.
- **Colour:** a free affine map `out = M · in + b` on encoded sRGB values (0–255), and a
  constrained form `out = g · ((1 − s) · L + s · I) · in + c` with `L` the Rec. 709 luminance
  weights (saturation `s`, gain `g`, offset `c`). Fits in linear light are much worse: the
  materials act on encoded values.

## Summary

| Surface | σ (pt) | Sharp w | Saturation s (light / dark) | Over `#7a7b80` (light / dark) | Changes with appearance |
| --- | --- | --- | --- | --- | --- |
| Dock background | 2.5–3.25 | 0.26–0.28 | 1.65 / 1.79 | `#818289` / `#68696e` | yes |
| Control Center module | 4.5 | 0.04 | 1.74 / 1.77 | `#6a6b70` / `#6a6b70` | no |
| Volume HUD | — | — | — | `#6f7076` / same | no |
| Menus (bar menus, context menus) | ~9 (±1) | — | high, more in dark | `#c7c8cd` / `#6f7075` | yes |
| Launcher panel | 8–9 (non-Gaussian) | ≤ 0.04 | as the search panel | `#c8c9ce` / `#717276` | yes |
| Search panel | 8–14 (non-Gaussian) | ≤ 0.12 | ~1.7 / ~1.8 | `#c8c9ce` / `#717276` | yes |
| Banners and notifications | 10–11 | 0.02–0.04 | 1.7–2.5 | `#c0c1c6` / `#75767b` | yes |

Two families: a **thin, clear glass** (Dock, Control Center modules, HUD: small blur, close to the
gray behind it) and a **thick glass** (menus, panels, notifications: 8–14 pt blur, almost white in
light and dark gray in dark). Every measured glass raises saturation and compresses contrast around
a mid gray.

## Dock glass

| | σ | w | Gain on gray | Offset |
| --- | --- | --- | --- | --- |
| Light | 2.5 (horizontal) – 3.0 (vertical) | 0.26–0.28 | 0.75 | 38 |
| Dark | 2.5 – 3.25 | 0.28 | 0.67 | 16 |

Free colour map (rows = output R, G, B):

| | M | b |
| --- | --- | --- |
| Light | `[[1.100, -0.314, -0.033], [-0.146, 0.805, 0.087], [-0.158, -0.328, 1.242]]` | `[37.3, 39.3, 36.8]` |
| Dark | `[[1.058, -0.307, -0.083], [-0.199, 0.729, 0.141], [-0.164, -0.327, 1.159]]` | `[16.2, 15.7, 16.3]` |

- **Edge light:** the top and bottom rows are 1 pt lighter, with a ~7 pt inner gradient. It adds
  more over dark content (+13 levels) than over light (+7).
- **Refraction:** within ~16–24 pt of the left and right edges the glass samples the background
  further inward, up to ~5 pt at 6 pt from the edge (it magnifies like a lens). Top edge ≤ 1 pt,
  bottom ~3 pt.

## Control Center module glass

- Blur σ 4.5 pt, almost no sharp component (w 0.04), the same in light and dark.
- Free colour map, light: `[[0.946, -0.285, -0.037], [-0.126, 0.651, 0.094], [-0.140, -0.297, 1.064]]`,
  b `[30.6, 32.0, 30.3]`; dark: `[[0.942, -0.289, -0.041], [-0.130, 0.646, 0.090], [-0.144, -0.304, 1.061]]`,
  b `[31.2, 32.5, 30.8]`.
- **Refraction, two bands:** between ~6 and ~24 pt from the edge the glass magnifies (samples the
  background up to ~4 pt further inward); in the outermost ~6 pt it shows background that lies
  up to ~25 pt *outside* the module, squeezed into a few points. No displacement beyond 24–30 pt.

## Menu glass

- Blur σ ≈ 9 pt (±1). Within ~25 pt of an edge the blur looks weaker (or the lens stronger).
- The colour transfer on gray is an S curve, not a line:

  | Input | 16 | 32 | 48 | 64 | 80 | 96 | 112 | 128 | 144 | 160 | 176 | 192 | 208 | 224 | 240 |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | Light | 150 | 154 | 162 | 170 | 179 | 187 | 195 | 203 | 211 | 218 | 225 | 231 | 237 | 241 | 244 |
  | Dark | 57 | 62 | 71 | 80 | 91 | 101 | 109 | 115 | 121 | 125 | 127 | 128 | 128 | 126 | 125 |

- Indicative affine fit (rmse 4–10 because of the curve): light s 1.76, g 0.47, c 141; dark
  s 2.36, g 0.44, c 44. Saturation rises a lot, more in dark.
- No measurable refraction on the sides (≤ 1–2 pt).
- Edge: see [menus.md](menus.md) (outer hairline, inner edge light, shadow).

## Toolbar veil

The veil over content scrolling under a window toolbar is not a glass panel but a band with its
own formula: see [toolbar.md](toolbar.md).
