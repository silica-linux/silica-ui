# Split views, tab views and the window tab bar

IDs: CT-SP-01, CT-TV-01, CT-TV-02, MU-01, MU-11.

## Split view (CT-SP-01)

- **Sidebar split** (the file manager): minimum 135 pt, snap to 200 when released between 191 and
  209, the sidebar hides when dragged within ~65 pt of the window edge; the content keeps at least
  316 pt. The pointer shows a horizontal double arrow on the edge, also at the minimum. A new
  window takes the last width set. There is no visible divider line: only the change of tone.
- **Pane split** (terminal split pane, gallery split view): observed; divider colours and the
  thick divider's handle were not measured. silica_ui's divider colours are *provisional*.

## Window tab bar (CT-TV-01)

Shown when a window has two or more tabs, under the toolbar and only above the content area.

| Measure | Value |
| --- | --- |
| Bar | 28 pt group; the content moves down by 36 pt |
| Track | capsule 28 tall, 1 pt border, radius 14, from 8 pt inside the content area to 3 pt before "+" |
| Active tab | pill 24 tall, inset 2 pt, full capsule |
| Separators between inactive tabs | 1 × 16, hidden next to the active tab and the hovered one |
| "+" button | 30 pt circle, 3 pt after the track, 7 pt from the window edge; glyph 11 pt |
| Close button | on the **left** of the tab while hovered (18 × 18 hit box, ~8 pt cross); on the active tab only the cross appears |
| Title | ~11 pt, centred, truncated at the end |
| Minimum tab width | 120 pt; beyond that the leftmost tabs compress to 4–5 pt, stacked |

| Colour | Light | Dark |
| --- | --- | --- |
| Track / border | `#e8e8e8` / `#dcdcdc` | `#404041` / `#4f4f50` |
| Active tab | `#fefdfe` | `#464648` |
| Inactive tab on hover | `#dcdcdc` | `#4b4b4b` |
| Separator | `#cccccc` | `#575758` |
| "+" background | `#fbfbfb` → `#f6f6f6`, hover `#f3f3f3` → `#ececec` | `#474748` |
| "+" glyph | `#282828` | `#dadada` |
| Title, active / inactive | `#4c4b4c` / `#828282` | `#ececec` / `#8b8b8c` |

**Animations**

- Opening a tab: it enters from the right edge while the others narrow; the motion is an
  exponential approach with τ ≈ 75 ms (the remaining distance halves every ~53 ms), visible for
  about 375 ms.
- Closing: the active pill moves to the neighbour and the closed tab shrinks, same shape.
- Reordering: the others slide out of the way when the pointer passes the middle of a neighbour;
  widths stay attached to positions; on release the pill fits in ~250 ms.
- A tab dragged out of the window becomes a small window thumbnail and opens as a new window where
  it is dropped.
- Tab widths with few tabs were unequal in the reference without a rule found; silica_ui uses
  equal widths (*provisional*).

## Tab view (CT-TV-02)

- In-window tabs (terminal settings, gallery tab view): a segmented-style bar centred on the top
  edge of a gray rounded box.
- The box colours and radius were not measured; silica_ui's tab view geometry is *provisional*.
