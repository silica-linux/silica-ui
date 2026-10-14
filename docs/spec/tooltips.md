# Tooltips

ID: CT-TT-01. Measured on a toolbar with three items, light appearance.

| Event | Timing |
| --- | --- |
| Pointer stops on a control | the tooltip appears about **1.54 s** later, in one frame (no fade-in) |
| Pointer moves to a neighbouring control while one is shown | the new tooltip replaces the old one **230–250 ms** after the pointer arrives, in one frame |
| Pointer leaves | the fade starts about **0.3 s** later and lasts about **450 ms** |

- **Look:** a light-gray (`#e3e3e3`) rounded rectangle, radius about 5 pt, with a hairline darker
  edge and a soft shadow. It is 20–22 pt tall with 11–12 pt text and about 8 pt of side padding.
  A short word in a settings window measured 52 × 20.
- **Position:** the top edge is about 18 pt below the pointer's hotspot, and the left edge is near
  the pointer's x.
- **In silica_ui:** the timings, the light colour, the size, the padding and the offset are as
  measured. The dark look, the edge and the shadow are *provisional*.
