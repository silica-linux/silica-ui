// Content that scrolls under the unified toolbar (silica-ui#2; SIDEBAR-GLASS, silica-reference
// #100, titlebar.md §4). The body fills the window from the top and its first rows start below
// the band. At rest the band is invisible: it is the content background, without a tint or a
// line. As soon as content scrolls under it, it becomes a bar with a hard bottom edge:
//
//   dark   the content shows through at 23 % (out = 0.23 · blurred content + 40) with a
//          σ 4.5 pt blur, and a faint 1 pt line at the edge (+7 % white);
//   light  opaque white (the content is not visible) with a 1 pt line (×0.9, `#e5e5e5`).
//
// The bar appears at once at the first scroll step. The capsules of the bar show the content
// refracted at their edges ([ToolbarCapsule]).
//
// Not measured: an inactive window (it keeps the line, as windows.md recorded, but has no veil
// at rest), and the timing of the change.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../window.dart';
import 'common.dart';
import '../../appearance.dart';

/// The measured veil of the band under the toolbar, light or dark.
@immutable
class ToolbarVeil {
  const ToolbarVeil({
    required this.offset,
    required this.scale,
    required this.saturation,
    required this.sharpSigma,
    required this.wideSigma,
    required this.wideWeight,
    required this.line,
    this.anchor = const [0, 0, 0],
  });

  /// The formula `offset + scale · (L + saturation · (in − L))`, on 0–255 sRGB values.
  final double offset;
  final double scale;
  final double saturation;

  /// The two Gaussians (pt) and the weight of the wide one; a sigma of 0 and a weight of 0
  /// skip that pass.
  final double sharpSigma;
  final double wideSigma;
  final double wideWeight;

  /// The 1 pt line under the band, drawn over the content.
  final Color line;

  /// An extra offset per channel (R, G, B, 0–255) added to [offset]: see [anchoredTo].
  final List<double> anchor;

  /// The same veil with an [anchor] that leaves `background` unchanged: the bar over the
  /// content background shows that background, without a band (silica-ui#87).
  ToolbarVeil anchoredTo(Color background) {
    final rgb = [background.r * 255, background.g * 255, background.b * 255];
    final l = rgb[0] * _luma[0] + rgb[1] * _luma[1] + rgb[2] * _luma[2];
    return ToolbarVeil(
      offset: offset,
      scale: scale,
      saturation: saturation,
      sharpSigma: sharpSigma,
      wideSigma: wideSigma,
      wideWeight: wideWeight,
      line: line,
      anchor: [
        for (var c = 0; c < 3; c++)
          // Clamped: a background the veil already saturates (white in light) needs nothing.
          rgb[c] -
              (offset + scale * (l + saturation * (rgb[c] - l))).clamp(0, 255),
      ],
    );
  }

  /// Opaque white with a 1 pt line (×0.9: white → `#e5e5e5`).
  static const ToolbarVeil light = ToolbarVeil(
    offset: 255,
    scale: 0,
    saturation: 1,
    sharpSigma: 0,
    wideSigma: 0,
    wideWeight: 0,
    line: Color(0x1A000000),
  );

  /// The content at 23 % over a 40 lift, blurred σ 4.5 pt; line +7 % white.
  static const ToolbarVeil dark = ToolbarVeil(
    offset: 40,
    scale: 0.23,
    saturation: 1,
    sharpSigma: 4.5,
    wideSigma: 4.5,
    wideWeight: 0,
    line: Color(0x12FFFFFF),
  );

  static ToolbarVeil of(BuildContext context) =>
      SilicaAppearance.isDark(context) ? dark : light;

  static const List<double> _luma = [0.2126, 0.7152, 0.0722];

  /// The 5 × 4 color matrix of the formula (offsets in 0–255).
  List<double> get matrix => [
    for (var row = 0; row < 3; row++) ...[
      for (var col = 0; col < 3; col++)
        scale * ((1 - saturation) * _luma[col] + (row == col ? saturation : 0)),
      0,
      offset + anchor[row],
    ],
    0, 0, 0, 1, 0, //
  ];

  /// A uniform color seen through the veil (without the blur).
  Color apply(Color content) {
    final rgb = [content.r * 255, content.g * 255, content.b * 255];
    final l = rgb[0] * _luma[0] + rgb[1] * _luma[1] + rgb[2] * _luma[2];
    int channel(int c) =>
        (offset + anchor[c] + scale * (l + saturation * (rgb[c] - l)))
            .round()
            .clamp(0, 255);
    return Color.fromARGB(255, channel(0), channel(1), channel(2));
  }

  /// The wide Gaussian applied after the sharp one: together they make σ [wideSigma].
  double get wideAfterSharp =>
      math.sqrt(math.max(0, wideSigma * wideSigma - sharpSigma * sharpSigma));
}

/// The veil itself: blurs and tints what is painted behind it, as large as its parent.
class ToolbarVeilLayer extends StatelessWidget {
  const ToolbarVeilLayer({super.key, this.veil, this.name = 'toolbar veil'});

  /// Null: following the system appearance.
  final ToolbarVeil? veil;

  /// The `ValueKey` of the layer's filters, for finding it (the sidebar's: 'sidebar bar veil').
  final String name;

  @override
  Widget build(BuildContext context) {
    final veil = this.veil ?? ToolbarVeil.of(context);
    Widget pass(ui.ImageFilter filter) => Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(filter: filter, child: const SizedBox.expand()),
      ),
    );
    return IgnorePointer(
      child: Stack(
        key: ValueKey(name),
        children: [
          // The sharp Gaussian replaces the content…
          if (veil.sharpSigma > 0)
            pass(
              ui.ImageFilter.blur(
                sigmaX: veil.sharpSigma,
                sigmaY: veil.sharpSigma,
                tileMode: TileMode.clamp,
              ),
            ),
          // …the wide one, if any, goes over it with its weight (alpha scaled by the filter)…
          if (veil.wideWeight > 0)
            pass(
              ui.ImageFilter.compose(
                outer: ui.ColorFilter.matrix(<double>[
                  1, 0, 0, 0, 0, //
                  0, 1, 0, 0, 0, //
                  0, 0, 1, 0, 0, //
                  0, 0, 0, veil.wideWeight, 0, //
                ]),
                inner: ui.ImageFilter.blur(
                  sigmaX: veil.wideAfterSharp,
                  sigmaY: veil.wideAfterSharp,
                  tileMode: TileMode.clamp,
                ),
              ),
            ),
          // …then the tint (affine: it commutes with the blur).
          pass(ui.ColorFilter.matrix(veil.matrix)),
        ],
      ),
    );
  }
}

/// A column of the body with its own background under the band, left to right: a list and a
/// reader side by side (Mail). [width] null takes the remaining width.
@immutable
class ToolbarVeilColumn {
  const ToolbarVeilColumn(this.background, {this.width});

  final Color background;
  final double? width;
}

/// The vertical scrollable directly in the body.
bool defaultScrollUnderPredicate(ScrollMetrics metrics, int depth) =>
    depth == 0 && metrics.axis == Axis.vertical;

/// Any vertical scrollable in the body, at any depth.
bool anyVerticalScrollUnderPredicate(ScrollMetrics metrics, int depth) =>
    metrics.axis == Axis.vertical;

/// A window body that scrolls under the glass toolbar: [toolbar] in the top [bandHeight], an
/// optional [header] right below it (a column header, a tab bar) inside the same veiled band, and
/// the [body] filling the whole area. The body receives the padding that puts its first row below
/// the band; it must be a scrollable (or contain one) that reports its scroll position.
///
/// Mustache and Mail use it the same way:
///
/// ```dart
/// ScrollUnderToolbar(
///   toolbar: myToolbarRow,
///   body: (context, padding) => ListView(padding: padding, children: rows),
/// )
/// ```
class ScrollUnderToolbar extends StatefulWidget {
  const ScrollUnderToolbar({
    super.key,
    required this.toolbar,
    required this.body,
    this.header,
    this.headerHeight = 0,
    this.bandHeight = toolbarHeight,
    this.active,
    this.veil,
    this.showLine = true,
    this.scrollPredicate = defaultScrollUnderPredicate,
    this.background,
    this.columns,
  });

  /// The toolbar row (capsules, title), laid out in the top [bandHeight].
  final Widget toolbar;

  /// Between the toolbar and the content, inside the veil (transparent background).
  final Widget? header;
  final double headerHeight;
  final double bandHeight;

  /// The content: it gets the padding of the band.
  final Widget Function(BuildContext context, EdgeInsets padding) body;

  /// Active window (null: [WindowActiveScope.of]). The bar does not change; an inactive window
  /// keeps the line under the band.
  final bool? active;

  /// Null: following the system appearance.
  final ToolbarVeil? veil;

  /// False when the content draws its own line under the band (a column header).
  final bool showLine;

  /// Which scrollables move the line: by default the vertical one at depth 0. Views with
  /// nested lists (columns, a list that also scrolls sideways) pass
  /// [anyVerticalScrollUnderPredicate].
  final bool Function(ScrollMetrics metrics, int depth) scrollPredicate;

  /// No effect since 0.30.0, kept so that apps compile: the band is invisible at rest and a
  /// bar once content scrolls under it, whatever the background (SIDEBAR-GLASS).
  final Color? background;

  /// No effect since 0.30.0 (see [background]).
  final List<ToolbarVeilColumn>? columns;

  @override
  State<ScrollUnderToolbar> createState() => _ScrollUnderToolbarState();
}

class _ScrollUnderToolbarState extends State<ScrollUnderToolbar> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) => _onMetrics(n.metrics, n.depth);

  bool _onMetrics(ScrollMetrics m, int depth) {
    if (!widget.scrollPredicate(m, depth)) return false;
    final scrolled = m.extentBefore > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final band = widget.bandHeight + widget.headerHeight;
    final veil = widget.veil ?? ToolbarVeil.of(context);
    final active = containerActive(context, widget.active);
    final line = widget.showLine && (_scrolled || !active);
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) => _onMetrics(n.metrics, n.depth),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.body(context, EdgeInsets.only(top: band)),
            ),
          ),
        ),
        // Invisible at rest; a bar as soon as content is under it.
        if (_scrolled)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: band,
            child: ToolbarVeilLayer(veil: veil),
          ),
        if (line)
          Positioned(
            left: 0,
            right: 0,
            top: band,
            height: 1,
            child: ColoredBox(
              key: const ValueKey('toolbar line'),
              color: veil.line,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: widget.bandHeight,
          child: ToolbarOverContent(child: widget.toolbar),
        ),
        if (widget.header case final header?)
          Positioned(
            left: 0,
            right: 0,
            top: widget.bandHeight,
            height: widget.headerHeight,
            child: header,
          ),
      ],
    );
  }
}
