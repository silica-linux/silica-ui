// Content that scrolls under the unified toolbar (silica-ui#2; mustache-spec R1.9, mustache.md
// MU-99). The body fills the window from the top and its first rows start below the band; what
// scrolls under the band stays visible, blurred and covered by a uniform veil from the top to the
// bottom of the band, the same in active and inactive windows:
//
//   out = offset + scale · (L + s · (in − L)),  L = Rec. 709 luminance of the content
//
// light 135.3 / 0.486 / 1.24 (white at ~51 % with saturation ×1.24), dark 31.1 / 0.400 / 1.25
// (`#333333` at ~60 %). The blur is two Gaussians of about equal weight: light σ 4.2 (0.46) and
// σ 36.1 (0.54), dark σ 3.2 (0.52) and σ 33.7 (0.48). A 1 pt line under the band appears as soon
// as the content scrolls (light ×0.9, dark +7 % white); in an inactive window it is always there
// (windows.md, Conflicts 18: to verify whether the inactive line shows with the content at the
// top). The capsules of the bar show the content refracted at their edges ([ToolbarCapsule]).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../window.dart';
import 'common.dart';

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
  });

  /// The formula `offset + scale · (L + saturation · (in − L))`, on 0–255 sRGB values.
  final double offset;
  final double scale;
  final double saturation;

  /// The two Gaussians (pt) and the weight of the wide one.
  final double sharpSigma;
  final double wideSigma;
  final double wideWeight;

  /// The 1 pt line under the band, drawn over the content.
  final Color line;

  static const ToolbarVeil light = ToolbarVeil(
    offset: 135.3,
    scale: 0.486,
    saturation: 1.24,
    sharpSigma: 4.2,
    wideSigma: 36.1,
    wideWeight: 0.54,
    // ×0.9: white → `#e5e5e5`.
    line: Color(0x1A000000),
  );

  static const ToolbarVeil dark = ToolbarVeil(
    offset: 31.1,
    scale: 0.400,
    saturation: 1.25,
    sharpSigma: 3.2,
    wideSigma: 33.7,
    wideWeight: 0.48,
    // +7 % white: black → `#121212`.
    line: Color(0x12FFFFFF),
  );

  static ToolbarVeil of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;

  static const List<double> _luma = [0.2126, 0.7152, 0.0722];

  /// The 5 × 4 color matrix of the formula (offsets in 0–255).
  List<double> get matrix => [
    for (var row = 0; row < 3; row++) ...[
      for (var col = 0; col < 3; col++)
        scale * ((1 - saturation) * _luma[col] + (row == col ? saturation : 0)),
      0,
      offset,
    ],
    0, 0, 0, 1, 0, //
  ];

  /// A uniform color seen through the veil (without the blur).
  Color apply(Color content) {
    final rgb = [content.r * 255, content.g * 255, content.b * 255];
    final l = rgb[0] * _luma[0] + rgb[1] * _luma[1] + rgb[2] * _luma[2];
    int channel(int c) => (offset + scale * (l + saturation * (rgb[c] - l)))
        .round()
        .clamp(0, 255);
    return Color.fromARGB(255, channel(0), channel(1), channel(2));
  }

  /// The wide Gaussian applied after the sharp one: together they make σ [wideSigma].
  double get wideAfterSharp =>
      math.sqrt(wideSigma * wideSigma - sharpSigma * sharpSigma);
}

/// The veil itself: blurs and tints what is painted behind it, as large as its parent.
class ToolbarVeilLayer extends StatelessWidget {
  const ToolbarVeilLayer({super.key, this.veil});

  /// Null: following the system appearance.
  final ToolbarVeil? veil;

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
        key: const ValueKey('toolbar veil'),
        children: [
          // The sharp Gaussian replaces the content…
          pass(
            ui.ImageFilter.blur(
              sigmaX: veil.sharpSigma,
              sigmaY: veil.sharpSigma,
              tileMode: TileMode.clamp,
            ),
          ),
          // …the wide one goes over it with its weight (alpha scaled by the filter)…
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
  });

  /// The toolbar row (capsules, title), laid out in the top [bandHeight].
  final Widget toolbar;

  /// Between the toolbar and the content, inside the veil (transparent background).
  final Widget? header;
  final double headerHeight;
  final double bandHeight;

  /// The content: it gets the padding of the band.
  final Widget Function(BuildContext context, EdgeInsets padding) body;

  /// Active window (null: [WindowActiveScope.of]). The veil does not change; an inactive window
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
    final line =
        widget.showLine &&
        (_scrolled || !containerActive(context, widget.active));
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
