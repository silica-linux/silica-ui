# Kit issues

Defects and inconsistencies found in the Amalfi UI kit (silica-design) while reproducing it. The
code follows the design docs (`materials.md`, `components.md`, `tokens.json`) where they and the
kit disagree; each test lists the deviation with its reason (`expectKitGeometry(deviations:)`).
Keep one section per family, add yours at the end (with the silica-design commit).

## Export (silica-design `ec113fd`)

- Four names are shared by 11 masters each: `Titlebars/Bar/Unified/<Active|Inactive>/<Light|Dark>`.
  Their files carry the id (`Dark (7B023A23).json`); the checklist and the fixtures use that key.
- Text weight 3 (Light, w300) appears on 6 text layers; the package has no Inter Light.
- 2 text layers (`Apps/Settings/Row/Nav/*` "Value") have no family, size, weight or line height.
- 40 text layers have no shared text style; 20 shapes have radii with corner style 0 instead of 1
  (smooth); 180 shapes have different radii per corner (`AmalfiSmoothBorder` has one radius).
- Glass/Thick and Glass/Regular blurs carry `distortion 0.5` and `specular: true`, which
  `materials.md` gives only to Glass/Clear (the lens).
- Text frames are drawn wider than the text, to whole points or to the 4 pt grid inconsistently
  ("Add to favourites" 97.03 → 100; "Fri 16 Oct 09:41" 99.18 → 104): each family decides how its
  label boxes round (`AmalfiWholePoints`), from its masters.
- The rendered bounds of ~190 PNGs differ from frame + shadows because text or paths overflow
  their frames (pointers, popovers, some forms and dialogs); `expectKitPixels(origin:)` handles
  those.

## Tooltips

- Dark/Glass/Thick's shadow is `#52000000` (the level 2 colour) with the level 3 offset and blur;
  tokens and `materials.md`: level 3, `#5C000000`. Code: tokens.
- `Tooltips/Tooltip/Shortcut`: the label frame is 40 wide, so "Duplicate" breaks inside the word
  over two lines (tooltip 40 tall); the shortcut frame is 40 wide for "⌘D". Code: one line, 24
  tall, same padding, gap and width (104). Not ticked.
- `Tooltips/Tooltip/Two Lines` shows three lines.
- `Tooltips/Placement/Above` leaves 12 between tooltip and target; Below, Leading and Trailing
  leave 8. Code: 8. Not ticked.
- The placement masters centre the tooltip across the target only to the 4 pt grid (x 0, not 2):
  the code floors the centred position to the grid (an assumption: no master tells floor from
  round).
