# Amalfi kit harness

Tests that a component reproduces the masters of the Silica 1.0 "Amalfi" UI kit
([silica-design](https://github.com/silica-os/silica-design)). Geometry is compared **exactly**
(frames on whole points, radii, colours through the tokens, borders, shadows, text styles);
pixels are compared with a **tolerance** (Sketch rasterises text with CoreText).

## Workflow for a family

1. Copy its masters into the fixtures (and commit them; tests never read silica-design):

   ```sh
   dart run tool/sync_kit.dart --design ~/silica/silica-design Buttons/Push
   ```

   The prefix is recorded in `kit/_prefixes/`; masters nested as instances come along. Re-run
   without prefixes to refresh everything after a kit update (`kit/SOURCE.md` records the
   commit).
2. Implement the widgets under `lib/src/amalfi/components/<family>/`, export them from
   `lib/src/amalfi/components/<family>.dart`. Build them on the shared foundation
   (`lib/src/amalfi/foundation/`, below) instead of family copies.
3. Test them in `test/amalfi/<family>_test.dart` (below), with `setUpAll(loadAmalfiFonts)`.
4. Show every variant × size × state in `example/lib/amalfi/pages/<family>.dart`.
5. Tick the masters in `docs/amalfi-checklist/<family>.md`, run
   `dart run tool/gen_checklist.dart --summary`; note kit defects in
   `docs/amalfi-checklist/kit-issues.md`.

## Shared foundation (`lib/src/amalfi/foundation/`)

What every family draws with, exported from `silica_ui.dart`:

- `AmalfiShapeDecoration`: a `ShapeDecoration` whose shadows have the kit's (CSS) blur,
  σ = blur / 2, and are drawn outside the shape only; `paintAmalfiShadows`,
  `paintAmalfiInsideBorder` for custom painters; `amalfiControlShadows(colors)`, the control
  shadow (`Shadow/Soft`, 0, 1, blur 2); the tokens' levels are `AmalfiShadows.level1`–`3`.
  `AmalfiGlass(shape: …)` takes any outline (a popover's arrow).
- `AmalfiFocusHalo`: the keyboard focus ring outside the control's shape (`radius` or
  `shape`), `Line/Focus` by default, fading with `fade.quick`, keyed `AmalfiLayerKeys.focusHalo`.
- `AmalfiInteraction`: hover, press (pointer still inside), keyboard focus (halo only with
  keyboard navigation), activation on release or with `activators` (Space for toggles,
  Space and Return for buttons), drags; a control nested in another takes the press.
- `AmalfiGlyph(AmalfiGlyphs.chevronDown, size: 12)`: the control glyphs (Icon Kit Regular,
  from silica-icons), stroke scaled with the size (24 → 1.5, 12 → 0.75).
  `AmalfiSymbol('trash')` draws any Icon Kit symbol an app chooses from the installed
  silica-icons at runtime (`SILICA_ICONS_DIR`, then `silica/icons` in the XDG data folders),
  or a fallback when it is missing; tests set `AmalfiSymbols.debugEnvironment` to a folder of
  their own.
- `AmalfiLens`: the lens rule (8 beyond the control on each side, 12 above and below, radius
  half the height minus 1; the switch's thumb + 12), for the segmented, slider and switch lenses.
- `AmalfiLayerKeys`: the kit's layer names (`Box`, `State`, `Focus Halo`, …) as keys.

## API (`support/harness.dart`)

- `KitMaster.load('Tooltips/Tooltip/One Line/Rest/Light')`: the master as a typed tree.
  `layer('Surface')` (paths join child names with `/`), `rectInMaster`, `style` (fills with
  `swatch`, borders, shadows, inner shadows, blurs, corners), `font` (`fontWeight` maps Sketch
  5/6/8/9 → w400/500/600/700), `textStyle` (`Light/Callout/Primary` → `AmalfiType.calloutToken`
  + `Text/Primary`), `icon` (an Icon Kit glyph: `symbols/<weight>/<name>.svg` in silica-icons),
  `KitMaster.nested(layer)` (a nested kit master), `brightness`, `renderBounds`, `textRects`.
- `pumpKitScene(tester, widget, master: m)`: pumps the widget at the top left, dpr 1, in the
  master's appearance, with fonts, inside a `WidgetsApp` (its shortcuts and actions: Enter and
  Space reach the focused control as in an app; its tap region surface: a click beside the
  widget is a click outside), with `Directionality`, `MediaQuery` and an `Overlay` (menus,
  popovers); returns the root finder. Pumping again in the same test replaces the widget as
  `pumpWidget` does (the same widget type keeps its state), so one test can check several
  scenes.
- `expectKitGeometry(tester, m, root: root, layers: {path: finder}, deviations: {...})`: frames
  relative to the root, exactly and on whole points; the style painted at or below each finder
  (`RenderedStyle.of`: `AmalfiGlass` with any outline, `DecoratedBox` with
  `ShapeDecoration`/`AmalfiShapeDecoration`/`BoxDecoration`, `ColoredBox`; add your own with
  `RenderedStyle.register`): fills, borders (with the dash pattern when the fixture has the
  kit's), shadows, blurs and the radius of each corner (`AmalfiSmoothBorder.radii`); text
  content, family, size, weight, line height, colour and the token of the shared style, from
  a `RichText` or an `EditableText` (a field's value; obscured text as its bullets). `deviations` keys are
  `<path>#<aspect>` (`Surface#shadows`; a bare path is its frame; `#frame` the root) with the
  reason; a deviation that no longer differs fails the test.
- `expectKitPixels(tester, m, widget, maskText: true, maskLayers: [...], prepare: ...)`: renders
  at dpr 2 on the PNG's canvas and compares premultiplied RGBA with
  `KitPixelTolerance.shapes` (mean ≤ 1, max ≤ 48, for masked text) or
  `KitPixelTolerance.withText` (mean ≤ 2.5). On failure: `build/amalfi-diff/<key>.png`
  (kit | rendered | difference).

## Example

```dart
void main() {
  setUpAll(loadAmalfiFonts);

  testWidgets('One Line', (tester) async {
    final master = KitMaster.load('Tooltips/Tooltip/One Line/Rest/Light');
    const tooltip = AmalfiTooltip(message: 'Add to favourites');
    final root = await pumpKitScene(tester, tooltip, master: master);
    expectKitGeometry(tester, master, root: root, layers: {
      'Surface': find.byType(AmalfiGlass),
      'Label': find.ancestor(
        of: find.text('Add to favourites'),
        matching: find.byType(AmalfiWholePoints),
      ),
    });
    await expectKitPixels(tester, master, tooltip, maskText: true);
    await expectKitPixels(tester, master, tooltip,
        tolerance: KitPixelTolerance.withText);
  });
}
```

`tooltips_test.dart` is the complete worked example: variants, placement (hovering a region
with `prepare:`), deviations for kit defects, and behaviour tests.

## Notes

- Text measures with Inter from `fonts/` (`loadAmalfiFonts`); the kit's text frames are often
  wider than the text (rounded to the 4 pt grid): round label boxes with `AmalfiWholePoints`
  (`AmalfiWholePoints(step: AmalfiGrid.base, heightStep: 1)` keeps the line height while the
  width lands on the grid, as button labels).
- Keyboard focus: the halo shows only in the traditional highlight mode; set
  `FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional` before
  pumping (and reset it in a tear-down).
- The test rasteriser under-covers the antialiased bottom row of smooth corners on short
  shapes (8 pt tall or less: progress bars, slider tracks, thin capsules): those pixels come
  out up to ~128 levels lighter than Sketch's while the shape is right (the geometry check is
  exact). Families with such shapes keep a wider `max` for them, with the reason next to the
  tolerance; it is not a licence for larger shapes.
- The kit export (silica-design) does not carry Sketch's border options yet: a dashed border
  is checked for colour, width and position, and its dashes only when a fixture has a
  `dashPattern` (`sync_kit` copies it once the export has it).
- Inside `testWidgets`, font loading needs the real clock: the helpers use
  `ensureAmalfiFonts(tester)`; prefer `setUpAll(loadAmalfiFonts)`.
- A master that nests other masters needs their fixtures too (`sync_kit` copies them); Icon
  Kit glyphs are references to silica-icons, not fixtures.
