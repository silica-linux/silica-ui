# Text and search fields

IDs: CT-TF-01…04, CT-TF-07…09, MU-32, MU-70, MU-96.

## Text field (CT-TF-01)

| Instance | Frame |
| --- | --- |
| Gallery, square bezel | 180 × 22 |
| Gallery, rounded bezel | 180 × 22 (capsule outline) |
| Save card name field | 232 × 26 |
| Alarm label field | 224 × 26 |
| "New folder" name field | 282 × 26 |
| "Go to folder" path field | 344 × 22 |

- Background white (dark `#191919`) with a thin gray border.
- Focus: a 3 pt ring outside the field in the accent at about 50 % (exact colours in
  [focus-and-accent.md](focus-and-accent.md)), plus a 1 pt accent inner border.
- When a sheet opens with a name field, the name is already selected.
- Disabled: reduced contrast; silica_ui shows the text in the placeholder colour (*provisional*).
- The square bezel's corner radius was not measured; silica_ui uses 6 pt (*provisional*).

## Secure field (CT-TF-02)

160 × 22 in the gallery; characters are shown as bullets. The caps-lock indicator was not
observed; silica_ui draws its own glyph at the right end (*provisional*).

## Inline rename field (CT-TF-08)

- A field exactly as wide as its text that **grows and shrinks while typing** (63 pt for an
  eleven-character name).
- 21 pt tall including the ring; 13 pt inside; text 4 pt from the edge.
- Ring 3 pt `#8fb4fb` light / `#296692` dark; inner border 1 pt `#649efa` / `#3586c5`;
  background white / dark background; selected text `#b3d7ff` / `#40638b`.
- The whole name is selected when the field opens (in the file manager, the name without the
  extension).

## Search field (CT-TF-04, MU-70, MU-96)

| Instance | Frame |
| --- | --- |
| Gallery | 200 × 22, capsule, magnifier and placeholder |
| Control Center editor | 205 × 28 |
| Save panel toolbar | 199 × 27 |
| Window toolbar (expanded from the search button) | 242 × 38, with focus ring |

- In a window toolbar the search is first a 38 pt round glass button; activating it turns the
  button into the 242 × 38 field about 170 ms later, in one frame (no width animation). The focus
  ring fades in over ~200 ms.
- Typing shows a suggestions menu below the field (about 650 ms after the first letter); choosing
  a suggestion turns it into a token ([tokens.md](tokens.md)).
- Esc empties the field and turns it back into the round button; the window stays in search mode.
- The clear button appears when the field has text (look not measured separately).
- The search panel's own large field (CT-TF-03) belongs to the shell spec (silica-desktop).

## Multi-line text area (CT-TF-07, partial)

A comments field in the Info window: only its structure was observed (a bordered multi-line
field). silica_ui's `maxLines` variant uses the text field's look (*provisional*).
