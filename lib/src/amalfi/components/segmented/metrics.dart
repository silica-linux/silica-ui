// The measures of the segmented controls, per size, from the kit masters `Segments/*`
// (silica-design 747ea80). Every size is a control height of the one Amalfi scale
// ([AmalfiControlSize]: 20 / 24 / 28 / 32), with its glyph size (12 / 14 / 16 / 16, user
// decision 2026-10-16). The lens of a pressed control follows the lens rule ([AmalfiLens]).

import 'package:flutter/widgets.dart';

import '../../token_types.dart';
import '../../tokens.g.dart';

/// The measures shared by every size.
abstract final class AmalfiSegmentMetrics {
  /// Between the track of a segmented control and its items, on every side
  /// (`Segments/Control/*`: the items sit 4 inside the track).
  static const double trackPadding = 4;

  /// The space on each side of the widest label of a text item, before the item is wider than
  /// the kit's ([AmalfiSegmentSizeMetrics.textItemWidth]).
  static const double textItemPadding = 8;

  /// The width of a separator between two action segments.
  static const double separatorWidth = 1;

  /// The horizontal inset of the highlight of a text action segment, in every state.
  static const double textHighlightInset = 4;
}

/// The measures of one size of the segmented controls.
@immutable
final class AmalfiSegmentSizeMetrics {
  const AmalfiSegmentSizeMetrics._({
    required this.size,
    required this.height,
    required this.textSegmentWidth,
    required this.separatorHeight,
    required this.hoverInset,
    required this.textItemWidth,
  });

  /// The size these measures are for.
  final AmalfiControlSize size;

  /// The control height: an action capsule, or the track of a segmented control. In a toolbar
  /// ([toolbarLarge]) it is 36 (`controlHeights.toolbar`), not the 32 of a Large control.
  final double height;

  // Action segments (`Segments/Action/*`, `Segments/Align/*`).

  /// The height of an action capsule: the control height, 36 on Large (a toolbar item,
  /// `controlHeights.toolbar`).
  double get actionHeight =>
      size == AmalfiControlSize.large ? AmalfiControlHeights.toolbar : height;

  /// Whether the separators between icon action segments take a point of their own (the
  /// toolbar's Large).
  bool get separatorTakesSpace => height == AmalfiControlHeights.toolbar;

  /// The width of an icon action segment: a square.
  double get iconSegmentWidth => height;

  /// The least width of a text action segment (`Segments/Action/Text *`): wider only when its
  /// label needs it.
  final double textSegmentWidth;

  /// The glyph of an action segment: the size's icon size (14 / 16 / 20 / 20).
  double get glyph => size.iconSize;

  /// The height of a separator between two action segments, centred.
  final double separatorHeight;

  /// How far the hover highlight of an action segment is inset from the segment, vertically
  /// (and on every side for an icon segment): 0 on Mini and Small, 4 from Regular up. A
  /// pressed segment is never inset vertically.
  final double hoverInset;

  /// The label style of a text action segment: Callout on Mini and Small, Body from Regular.
  TextStyle labelStyle({Color? color}) => switch (size) {
    AmalfiControlSize.mini ||
    AmalfiControlSize.small => AmalfiType.callout(color: color),
    _ => AmalfiType.body(color: color),
  };

  /// The text token of [labelStyle].
  AmalfiTextToken get labelToken => switch (size) {
    AmalfiControlSize.mini ||
    AmalfiControlSize.small => AmalfiType.calloutToken,
    _ => AmalfiType.bodyToken,
  };

  // Segmented controls (`Segments/Control/*`, `Segments/Text Item/*`, `Segments/Icon Item/*`).

  /// The height of an item inside the track.
  double get itemHeight => height - 2 * AmalfiSegmentMetrics.trackPadding;

  /// The width of an icon item.
  double get iconItemWidth => height;

  /// The least width of a text item: wider only when the widest label needs it.
  final double textItemWidth;

  /// The glyph of an icon item: the size's icon size (14 / 16 / 20 / 20).
  double get itemGlyph => size.iconSize;

  /// The label style of a text item: Caption on Mini, Label on Small, Body from Regular.
  TextStyle itemLabelStyle({Color? color}) =>
      itemLabelToken.style(color: color);

  /// The text token of [itemLabelStyle].
  AmalfiTextToken get itemLabelToken => switch (size) {
    AmalfiControlSize.mini => AmalfiType.captionToken,
    AmalfiControlSize.small => AmalfiType.labelToken,
    _ => AmalfiType.bodyToken,
  };

  /// The measures of [size]; with [toolbar], Large is the toolbar's 36 pt item (action
  /// segments are always one, a segmented control only in a toolbar).
  static AmalfiSegmentSizeMetrics of(
    AmalfiControlSize size, {
    bool toolbar = false,
  }) => switch (size) {
    AmalfiControlSize.mini => mini,
    AmalfiControlSize.small => small,
    AmalfiControlSize.regular => regular,
    AmalfiControlSize.large => toolbar ? toolbarLarge : large,
  };

  static const AmalfiSegmentSizeMetrics mini = AmalfiSegmentSizeMetrics._(
    size: AmalfiControlSize.mini,
    height: 20,
    textSegmentWidth: 40,
    separatorHeight: 12,
    hoverInset: 0,
    textItemWidth: 44,
  );

  static const AmalfiSegmentSizeMetrics small = AmalfiSegmentSizeMetrics._(
    size: AmalfiControlSize.small,
    height: 24,
    textSegmentWidth: 44,
    separatorHeight: 12,
    hoverInset: 0,
    textItemWidth: 56,
  );

  static const AmalfiSegmentSizeMetrics regular = AmalfiSegmentSizeMetrics._(
    size: AmalfiControlSize.regular,
    height: 28,
    textSegmentWidth: 52,
    separatorHeight: 16,
    hoverInset: 4,
    textItemWidth: 72,
  );

  /// Large in a toolbar: 36 high (`Titlebars/Piece/Segmented`, `Segments/Action/*/Large`).
  static const AmalfiSegmentSizeMetrics toolbarLarge =
      AmalfiSegmentSizeMetrics._(
        size: AmalfiControlSize.large,
        height: AmalfiControlHeights.toolbar,
        textSegmentWidth: 56,
        separatorHeight: 16,
        hoverInset: 4,
        textItemWidth: 88,
      );

  static const AmalfiSegmentSizeMetrics large = AmalfiSegmentSizeMetrics._(
    size: AmalfiControlSize.large,
    height: 32,
    textSegmentWidth: 56,
    separatorHeight: 16,
    hoverInset: 4,
    textItemWidth: 88,
  );
}
