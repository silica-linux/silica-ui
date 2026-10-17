// The measures of the Amalfi fields, from the kit masters `Fields/*` (components.md: fields
// 200 × 24 / 28 / 32, text areas 240 × 88).

import 'package:flutter/widgets.dart';

import '../../token_types.dart';
import '../../tokens.g.dart';

/// The sizes of a field (`Fields/Text Field/Small|Regular|Large`, and the toolbar's).
enum AmalfiFieldSize {
  /// 24 pt, Callout text, 16 pt glyphs (`AmalfiControlSize.small.iconSize`).
  small(
    height: 24,
    radius: AmalfiRadii.smallControl,
    padding: 8,
    glyph: 16,
    comboButton: 20,
    comboGlyph: AmalfiControlIcons.accessory,
  ),

  /// 28 pt, Body text, 20 pt glyphs (the default).
  regular(
    height: 28,
    radius: AmalfiRadii.field,
    padding: 8,
    glyph: 20,
    comboButton: 20,
    comboGlyph: AmalfiControlIcons.accessory,
  ),

  /// 32 pt, Body text, 20 pt glyphs. The kit's corner is 10 (no token between `field` 9 and
  /// `menu` 12).
  large(
    height: 32,
    radius: 10,
    padding: 12,
    glyph: 20,
    comboButton: 24,
    comboGlyph: AmalfiControlIcons.accessory,
  ),

  /// 36 pt, Body text, 20 pt glyphs: the search field of a toolbar (`Titlebars/Piece/Search`,
  /// a toolbar item: `controlHeights.toolbar`). Glyph at x 12, the placeholder at x 40.
  toolbar(
    height: AmalfiControlHeights.toolbar,
    radius: 12,
    padding: 12,
    glyph: 20,
    comboButton: 24,
    comboGlyph: AmalfiControlIcons.accessory,
  );

  const AmalfiFieldSize({
    required this.height,
    required this.radius,
    required this.padding,
    required this.glyph,
    required this.comboButton,
    required this.comboGlyph,
  });

  /// The field height.
  final double height;

  /// The corner radius of a rectangular field (search fields are capsules).
  final double radius;

  /// The space before the first and after the last item, horizontally.
  final double padding;

  /// The side of a glyph inside the field (search magnifier, error mark, lock): the icon
  /// size of the control of the same height ([AmalfiControlSize.iconSize]).
  final double glyph;

  /// The side of the combo button disc.
  final double comboButton;

  /// The side of the chevron in the combo button: 16 at every size (an accessory glyph,
  /// `controlIcons.accessory`).
  final double comboGlyph;

  /// The text style token of the value and placeholder.
  AmalfiTextToken get textToken =>
      this == small ? AmalfiType.calloutToken : AmalfiType.bodyToken;

  /// The text style in [color].
  TextStyle textStyle(Color color) => textToken.style(color: color);
}

/// Measures shared by every field.
abstract final class AmalfiFieldMetrics {
  /// The default width of a one-line field.
  static const double width = 200;

  /// Between the items of a field (glyph, text, buttons, tokens).
  static const double gap = 4;

  /// The border at rest and when disabled.
  static const double border = 1;

  /// The border of a focused field or one with an error.
  static const double strongBorder = 1.5;

  /// The caret width.
  static const double caretWidth = 1.5;

  /// The caret height (the kit draws 16 on 16 and 18 pt lines).
  static const double caretHeight = 16;

  /// The opacity of the error halo (`Palette/Terracotta` at 30 %).
  static const double errorHaloOpacity = 0.3;

  /// The side of the clear button.
  static const double clearButton = 20;

  /// The side of the clear button's cross.
  static const double clearGlyph = AmalfiControlIcons.accessory;

  /// The radius of the clear button disc (a circle).
  static const double clearRadius = clearButton / 2;
}

/// Measures of the text area (`Fields/Text Area/Regular`).
abstract final class AmalfiTextAreaMetrics {
  /// The default size.
  static const Size size = Size(240, 88);

  /// The space around the text; 4 more on the trailing side keep the text off the overlay
  /// scroller (the kit's text frame is 220 wide in a 240 area with 8 padding).
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 8, 12, 8);
}

/// Measures of the token field and the tokens (`Fields/Token Field`, `Fields/Token`).
abstract final class AmalfiTokenMetrics {
  /// The default width of a token field.
  static const double fieldWidth = 260;

  /// The token field's padding before the first token and after the text.
  static const EdgeInsets fieldPadding = EdgeInsets.only(left: 4, right: 8);

  /// The narrowest the text of a token field gets before the tokens scroll.
  static const double minTextWidth = 48;

  /// The token height.
  static const double height = 20;

  /// The token's padding: 8 before the label, 4 after the remove cross.
  static const EdgeInsets padding = EdgeInsets.only(left: 8, right: 4);

  /// Between the label and the remove cross: none, the 16 pt cross has 2 of air on its own
  /// sides (the kit keeps the token 64 wide for "Travel" with the 16 pt cross).
  static const double labelGap = 0;

  /// The side of the remove cross.
  static const double removeGlyph = AmalfiControlIcons.accessory;
}
