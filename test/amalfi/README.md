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
   `lib/src/amalfi/components/<family>.dart`.
3. Test them in `test/amalfi/<family>_test.dart` (below), with `setUpAll(loadAmalfiFonts)`.
4. Show every variant × size × state in `example/lib/amalfi/pages/<family>.dart`.
5. Tick the masters in `docs/amalfi-checklist/<family>.md`, run
   `dart run tool/gen_checklist.dart --summary`; note kit defects in
   `docs/amalfi-checklist/kit-issues.md`.

## API (`support/harness.dart`)

- `KitMaster.load('Tooltips/Tooltip/One Line/Rest/Light')`: the master as a typed tree.
  `layer('Surface')` (paths join child names with `/`), `rectInMaster`, `style` (fills with
  `swatch`, borders, shadows, inner shadows, blurs, corners), `font` (`fontWeight` maps Sketch
  5/6/8/9 → w400/500/600/700), `textStyle` (`Light/Callout/Primary` → `AmalfiType.calloutToken`
  + `Text/Primary`), `icon` (an Icon Kit glyph: `symbols/<weight>/<name>.svg` in silica-icons),
  `KitMaster.nested(layer)` (a nested kit master), `brightness`, `renderBounds`, `textRects`.
- `pumpKitScene(tester, widget, master: m)`: pumps the widget at the top left, dpr 1, in the
  master's appearance, with fonts, `Directionality`, `MediaQuery` and `Overlay`; returns the
  root finder.
- `expectKitGeometry(tester, m, root: root, layers: {path: finder}, deviations: {...})`: frames
  relative to the root, exactly and on whole points; the style painted at or below each finder
  (`RenderedStyle.of`: `AmalfiGlass`, `DecoratedBox` with `ShapeDecoration`/`BoxDecoration`,
  `ColoredBox`; add your own with `RenderedStyle.register`); text content, family, size,
  weight, line height, colour and the token of the shared style. `deviations` keys are
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
  wider than the text (rounded to the 4 pt grid): round label boxes with `AmalfiWholePoints`.
- Inside `testWidgets`, font loading needs the real clock: the helpers use
  `ensureAmalfiFonts(tester)`; prefer `setUpAll(loadAmalfiFonts)`.
- A master that nests other masters needs their fixtures too (`sync_kit` copies them); Icon
  Kit glyphs are references to silica-icons, not fixtures.
