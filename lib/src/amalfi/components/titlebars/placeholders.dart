// Stand-ins for the toolbar controls of other families (toolbar icon buttons, action groups,
// segmented controls, search fields), sized as the kit's controls so the pieces and bars can
// be laid out and shown before those families land. They draw a plain Glass/Regular capsule
// with the glyphs and do nothing when clicked.
//
// TEMPORARY: replace with the public widgets of the buttons, segmented and fields families
// once they are on main (the pieces only need a child of the right size).

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'glyphs.dart';
import 'window_scope.dart';

/// A non-interactive stand-in for a toolbar control, the size of the kit's control.
///
/// In an inactive window the content dims to [AmalfiStates.disabledOpacity] (kit: the
/// toolbar controls of an inactive bar are their Disabled masters).
class AmalfiToolbarPlaceholder extends StatelessWidget {
  /// A 32 pt round icon button (kit `Buttons/Toolbar/Icon`).
  const AmalfiToolbarPlaceholder.icon(AmalfiChromeGlyphData glyph, {Key? key})
    : this._(key: key, kind: _Kind.icon, glyph: glyph, width: 32);

  /// An action group: 32 pt segments split by 1 × 16 separators (kit `Segments/Action/Icon
  /// N/Large`: 64, 96, 128 wide).
  const AmalfiToolbarPlaceholder.group(
    List<AmalfiChromeGlyphData> glyphs, {
    Key? key,
  }) : this._(key: key, kind: _Kind.group, glyphs: glyphs);

  /// A select-one control of icon segments with the [selected] one on a thumb (kit
  /// `Segments/Control/One N Icon/Large`: 4 + N × 32 + 4).
  const AmalfiToolbarPlaceholder.segmented(
    List<AmalfiChromeGlyphData> glyphs, {
    Key? key,
    int selected = 0,
  }) : this._(
         key: key,
         kind: _Kind.segmented,
         glyphs: glyphs,
         selected: selected,
       );

  /// A select-one control of text segments, [segmentWidth] each (kit
  /// `Segments/Control/One 4 Text/Large`: 4 + 4 × 88 + 4).
  const AmalfiToolbarPlaceholder.text(
    List<String> labels, {
    Key? key,
    int selected = 0,
    double segmentWidth = 88,
  }) : this._(
         key: key,
         kind: _Kind.text,
         labels: labels,
         selected: selected,
         segmentWidth: segmentWidth,
       );

  /// A search field (kit `Fields/Search Field/Large`: 200 × 32; Regular 240 × 28).
  const AmalfiToolbarPlaceholder.search({
    Key? key,
    double width = 200,
    double height = 32,
    String prompt = 'Search',
  }) : this._(
         key: key,
         kind: _Kind.search,
         width: width,
         height: height,
         prompt: prompt,
       );

  /// A round accent button of [size] (kit `Buttons/Icon/Round/Regular`, 28).
  const AmalfiToolbarPlaceholder.round(
    AmalfiChromeGlyphData glyph, {
    Key? key,
    double size = 28,
  }) : this._(
         key: key,
         kind: _Kind.round,
         glyph: glyph,
         width: size,
         height: size,
       );

  /// A small square icon button, 24 pt (kit `Buttons/Icon/Square/Small`: the sidebar
  /// footer's buttons, the tab bar's new-tab button).
  const AmalfiToolbarPlaceholder.square(AmalfiChromeGlyphData glyph, {Key? key})
    : this._(key: key, kind: _Kind.square, glyph: glyph, width: 24, height: 24);

  const AmalfiToolbarPlaceholder._({
    super.key,
    required _Kind kind,
    AmalfiChromeGlyphData? glyph,
    this.glyphs = const [],
    this.labels = const [],
    this.selected,
    this.width,
    this.height = 32,
    double segmentWidth = 32,
    String prompt = '',
  }) : _kind = kind,
       _glyph = glyph,
       _segmentWidth = segmentWidth,
       _prompt = prompt;

  final _Kind _kind;
  final AmalfiChromeGlyphData? _glyph;

  /// The glyphs of the segments.
  final List<AmalfiChromeGlyphData> glyphs;

  /// The labels of text segments.
  final List<String> labels;

  /// The selected segment; null: none.
  final int? selected;

  /// The width (null: from the segments) and height.
  final double? width;
  final double height;

  final double _segmentWidth;
  final String _prompt;

  /// The width this stand-in takes.
  double get resolvedWidth => switch (_kind) {
    _Kind.group => 32.0 * glyphs.length,
    _Kind.segmented => 8 + 32.0 * glyphs.length,
    _Kind.text => 8 + _segmentWidth * labels.length,
    _ => width ?? height,
  };

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final active = AmalfiWindowScope.isActive(context);
    final ink = colors.textPrimary;
    Widget glyph(AmalfiChromeGlyphData g, Color color) =>
        AmalfiChromeGlyph(g, size: 16, color: color);
    final w = resolvedWidth;

    Widget content;
    switch (_kind) {
      case _Kind.icon:
        content = Center(child: glyph(_glyph ?? AmalfiChromeGlyphs.plus, ink));
      case _Kind.square:
        return SizedBox(
          width: w,
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.surfaceControl,
              shape: AmalfiSmoothBorder(
                radius: AmalfiRadii.smallControl,
                side: BorderSide(
                  color: colors.lineBorder,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              shadows: theme.shadows.level1,
            ),
            child: Center(child: glyph(_glyph ?? AmalfiChromeGlyphs.plus, ink)),
          ),
        );
      case _Kind.round:
        return SizedBox(
          width: w,
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.accentAmalfi,
              shape: const StadiumBorder(),
            ),
            child: Center(
              child: glyph(
                _glyph ?? AmalfiChromeGlyphs.plus,
                colors.textOnAccent,
              ),
            ),
          ),
        );
      case _Kind.group:
        content = Row(
          children: [
            for (var i = 0; i < glyphs.length; i++) ...[
              if (i > 0)
                SizedBox(
                  width: 0,
                  child: OverflowBox(
                    maxWidth: 1,
                    child: Container(
                      width: 1,
                      height: 16,
                      color: colors.lineSeparator,
                    ),
                  ),
                ),
              SizedBox(width: 32, child: Center(child: glyph(glyphs[i], ink))),
            ],
          ],
        );
      case _Kind.segmented || _Kind.text:
        final count = _kind == _Kind.text ? labels.length : glyphs.length;
        final segment = _kind == _Kind.text ? _segmentWidth : 32.0;
        content = Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: segment,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: i == selected ? colors.surfaceControl : null,
                      shape: const StadiumBorder(),
                    ),
                    child: Center(
                      child: _kind == _Kind.text
                          ? Text(
                              labels[i],
                              maxLines: 1,
                              style: AmalfiType.body(color: ink),
                            )
                          : glyph(glyphs[i], ink),
                    ),
                  ),
                ),
            ],
          ),
        );
      case _Kind.search:
        content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              glyph(AmalfiChromeGlyphs.search, colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmalfiType.body(color: colors.textTertiary),
                ),
              ),
            ],
          ),
        );
    }
    return SizedBox(
      width: w,
      height: height,
      child: AmalfiGlass(
        material: AmalfiMaterials.regular,
        radius: height / 2,
        child: Opacity(
          opacity: active ? 1 : AmalfiStates.disabledOpacity,
          child: content,
        ),
      ),
    );
  }
}

enum _Kind { icon, group, segmented, text, search, round, square }
