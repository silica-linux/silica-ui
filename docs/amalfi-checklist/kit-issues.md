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

## Fixed in silica-design `747ea80`

The second round of kit fixes, after the user decisions of 2026-10-16:

- `AmalfiSmoothBorder` draws per-corner radii and the kit's smooth capsules (the "180 shapes have
  different radii per corner" item of `7db1d1c` is handled in code).
- Menus, Popovers, Alerts: menu surfaces are rows + 8; popovers are all Glass/Thick (list padding 8, arrow 8 deep); alert blocks are 16 apart and no longer shorter than their content; Dark/Glass/Thick has the level 3 shadow.
- Titlebars, Windows: fixed-width title frames fit their text; the plain title sits at y 15; the selected tab has the level 1 shadow and windows the level 3 one; a single sidebar edge; the inspector is 260; the `Bar/Unified/Full Inset 8` masters and the old `Titlebars/Toolbar/*` composites are gone (toolbar trailing padding 16, user decision 2026-10-16).
- Every disabled master: the whole control at 35 % with the rest look (user decision 2026-10-16, 372 masters).
- Buttons: the toolbar focus halo is outside and follows the control radius; `Buttons/*/Open` menus are 104 tall (4 + 4 × 24 + 4); every raised control's shadow is level 1 (`Shadow/1`).
- Toggles, Disclosure, Group Boxes: switch thumb inset 2 and pressed stretch; Small checkbox glyph stroke; round radio dots; checkbox group row widths; group box rows overflowing.
- Fields' 12 pt glyphs use the 0.75 stroke; the Large text field caret is 16 tall, centred; the Search Field Token Focused caret is after the token (x 104); the "Coast" token fits its label; Combo Box/Open nests a 104 pt Menus/Menu/Simple with the text's option checked.
- Steppers' halves are equal (divider at height / 2), the pressed overlay is clipped at the divider, the chevrons are centred in their halves.
- Progress/Spinner/Small spokes are 2 × 4 at x 7 (radius 1), centred; Progress/Circular/Determinate/Small's ring is inset by half its stroke.
- The disabled masters of Progress, Steppers, Fields, Wells and Scrollbars/Legacy are the whole control at 35 % with the rest colours.
- Forms rows sit on a 328 grid (text fields and labelled switches fill the 204 value column), sections are 352; Wells/Color Panel/Swatch Grid is 176 tall.
- Segmented and Sliders: disabled select-one controls keep their selection and dim the whole control to 35 %; Mini labels are centred; Small glyphs are 14; only select-one controls use the lens.
- Segmented and Sliders: slider ticks are 2 × 8 on the stops; the dial's value arc is concentric; the fill reaches the value while dragging and on the vertical slider; disabled at 35 % with the rest look; level 1 thumb shadow.

## Fixed in silica-design `5f5f187`

- `Menus/Menu/Cascade`: the submenu is 188 x 112 (the Submenu master) at x 224 / y 24, overlapping the parent by 4 (its padding), its first item level with the parent's; the master is 412 x 216.
- `Titlebars/Bar/Compact/*`: stack gap 8, controls at x 20, buttons at 92 / 132 and 432 / 472, title at 172, trailing padding 16.
- `Sidebars/Panel` and `Group/Open`: rows 28 at a 32 pitch, Group Open 216 x 124, Panel sections 16 apart.
- The export carries `style.borderOptions` (dash pattern, line end, join, arrowheads) on every layer; the harness checks the dashes, line end and join of a dashed border.
- Design decisions (silica-desktop `09c50a0`): glyphs inside small discs or accessory buttons stay 12 at every control size (`controlIcons.accessory`); the switch lens is thumb + 8 at Mini and Small, + 12 at Regular (`switch.lens`).

## Still open (silica-design `5f5f187`)

- `Windows/Window/Sheet Attached`: the `Sheet` instance of `Alerts/Alert/Two Buttons` is 266 tall, its master 268 (it was 268 in `747ea80`); the code builds the alert as its master.
- `Fields/Combo Button/Large` and `Combo Box/Large` draw the chevron at 16; the accessory rule makes it 12 (the Large masters are not updated).

- Text frames are drawn wider than the text, to whole points or to the 4 pt grid inconsistently
  ("Add to favourites" 97.03 -> 100; "Fri 16 Oct 09:41" 99.18 -> 104): each family decides how its
  label boxes round (`AmalfiWholePoints`), from its masters.
- The rendered bounds of ~190 PNGs differ from frame + shadows because text or paths overflow
  their frames (pointers, some forms and dialogs); `expectKitPixels(origin:)` handles those.
- The placement masters centre the tooltip across the target only to the 4 pt grid (x 0, not 2):
  the code floors the centred position to the grid (an assumption: no master tells floor from
  round).
- The export writes one radius for four equal corners (`[8]` for a circle); the harness reads it
  as four.
- Instances with an overridden label keep the master's text frame ("Button", 48 wide), so text
  masks of nested labels are drawn by hand in the tests that need them.
- Buttons: Pop-up and Pull-down Small chevrons are 12 pt; control glyphs are 14 at Small (user decision 2026-10-16).
- Buttons: the pop-up `chevron-up-down` keeps the 24 pt stroke (1.5) at 12 and 16 pt.
- Buttons: `Buttons/Pull-down/Open` applies its overrides to the wrong rows: row 2 shows the nested menu's checked "Lemon" instead of "Duplicate", and the highlighted item is swapped to plain.
- `Disclosure/Button/Expanded/*`: Glyph Chevron Up has no 12 pt layer style and keeps the 1.5 stroke.
- `Toggles/Radio/*/Small/Hover|Focused`: State and Focus Halo keep radius 7 while the Small radio box is a circle (8).
- `Toggles/Radio Group/List`: rows keep a stale width of 140 (With Label row is 124).
- `Group Boxes/Box/Titled` "Show banners", "Play sound" and `Untitled` "Remember" rows keep width 168.
- Fields: Search Field/Small and Text Field/Small/Error draw their glyphs at 12; control glyphs are 14 at Small (user decision 2026-10-16).
- Steppers/Stepper/* (56 masters): "Glyph Chevron Up" keeps the 24 pt stroke (1.5) at 12 pt.
- Progress/Circular/Determinate partial arcs are hand-drawn, up to 2 pt off concentric (geometry checked, pixels masked).
- Wells: the photo glyph (Image Well 20/28/36) and the eyedropper (Color Well Expanded, 16) keep the 24 pt stroke.
- Forms/Row/Check: the checkbox instance is 168 wide, not resized to its label (148), and sits at the top of the 28 pt line.
- Segmented and Sliders: the lens radius is half its height (Segments/Control/*/Pressed 22, Sliders/Thumb/Lens/Dragging 14); the lens rule takes half the height minus 1 (21, 13).
- Sliders/Circular/Dial draws the value arc as a Bézier path a fraction of a point inside the circle near the bottom (one edge pixel off by 87).
- Alerts: `Alerts/Alert/One Button|Critical|Glass` are 230/214 tall, off the 4 pt grid; the other alerts put the 2 pt remainder in the bottom padding (22), as the code does everywhere.
- Alerts: `Alerts/Alert/Critical`: the badge disc is 24 × 23.79 at y 59.48 and its glyph 16 × 15.86, off whole points.
- Alerts: `Alerts/Alert/Three Buttons`: the `Don’t Save` label frame is 68, narrower than the text (the code's button is 96, not 92).
- Menus: `Menus/Menu/Full`: `Export…` has no shortcut override and shows the master's ⌘N.
- Titlebars: `Titlebars/Piece/Title + Subtitle`: the subtitle frame is 64 wide for 58.9 pt of text, the text at its left; the code rounds it to 60 and centres it.
- Dialogs: `Dialogs/Footer/Save`: the PNG starts 2 pt left of the frame, not frame + blur (2.7).
- 28 filled glyphs at 16 pt keep the 24 pt stroke (kit side; the code scales the stroke).
- Glass/Clear lenses are encoded as a Sketch `Glass` blur (drawn as Clear's 2 pt background blur).
