# Kit issues

Defects and inconsistencies found in the Amalfi UI kit (silica-design) while reproducing it. The
code follows the design docs (`materials.md`, `components.md`, `tokens.json`) where they and the
kit disagree; each test lists the deviation with its reason (`expectKitGeometry(deviations:)`).
Keep one section per family, add yours at the end (with the silica-design commit).

## Fixed in silica-design `7db1d1c`

Reported while reproducing the kit, fixed in the kit; the tests no longer list them as deviations:

- Titlebars/Bar/Unified masters shared names (11 each, id-suffixed files): renamed to
  `Titlebars/Bar/Full Inset 8|16/<Active|Inactive>/<Light|Dark>`, duplicates deleted; the
  harness no longer handles id suffixes.
- Text weight 3 (Light, w300): Inter Light is no longer used.
- Text layers without a shared style, and without family, size, weight or line height
  (`Apps/Settings/Row/Nav/*` "Value"): every text layer has a shared style.
- Shapes with corner style 0 instead of 1 (smooth): 38 corners are smooth now.
- Glass/Thick and Glass/Regular carried `distortion 0.5` and `specular: true`: Regular/Thick
  have no refraction or specular now (Glass/Clear keeps the lens).
- Tooltips: Dark/Glass/Thick shadow is level 3; `Shortcut` is 104 x 24 on one line;
  `Two Lines` is 224 x 40 with two lines; `Placement/Above` leaves 8 (as the other sides).

## Still open (silica-design `7db1d1c`)

- 180 shapes have different radii per corner (`AmalfiSmoothBorder` has one radius).
- Text frames are drawn wider than the text, to whole points or to the 4 pt grid inconsistently
  ("Add to favourites" 97.03 -> 100; "Fri 16 Oct 09:41" 99.18 -> 104): each family decides how its
  label boxes round (`AmalfiWholePoints`), from its masters.
- The rendered bounds of ~190 PNGs differ from frame + shadows because text or paths overflow
  their frames (pointers, popovers, some forms and dialogs); `expectKitPixels(origin:)` handles
  those.
- The placement masters centre the tooltip across the target only to the 4 pt grid (x 0, not 2):
  the code floors the centred position to the grid (an assumption: no master tells floor from
  round).
