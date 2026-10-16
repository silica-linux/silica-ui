// The window controls (kit `Titlebars/Dot/*`, `Titlebars/Controls/*`): close, minimise and
// zoom discs.
//
// User decision (README of the design folder): the window controls keep the measured values of
// `docs/spec/windows.md`, not the kit's 16 pt discs on a 24 pt pitch: 14 pt discs in a 16 pt
// cell, 23 pt pitch, vertically centred on the bar, with the first disc edge 9 pt from the
// window edge on a 32 pt bar and 19 pt on a 52 pt bar (a linear blend between, rounded to a
// whole point). The colours at rest and on hover, light and dark (dark hover keeps the rest gradient), and
// the inactive greys are
// the kit's (they equal the measured ones; light rest is `tokens.windowControls`); the pressed
// colours, the "symbols on all three while the pointer is over the group" rule and the symbol
// timing come from `docs/spec/windows.md`.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../../controls/control_base.dart' show WindowActiveScope;

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'window_scope.dart';

/// Which window control.
enum AmalfiWindowControlKind {
  /// Closes the window (red).
  close,

  /// Minimises the window (yellow).
  minimise,

  /// Zooms the window (green).
  zoom,
}

/// The look of one window control disc.
enum AmalfiWindowControlState {
  /// Active window, pointer away from the group.
  rest,

  /// Pointer over the group: the disc shows its symbol.
  hover,

  /// Pressed with the pointer still on it: lighter disc and symbol.
  pressed,

  /// Inactive window (or a disabled control): a grey disc without a symbol.
  inactive,
}

/// The measures of the window controls.
abstract final class AmalfiWindowControlsMetrics {
  /// The cell of one control (the hit area), in points.
  static const double cell = AmalfiWindowControls.dot;

  /// The disc drawn inside the cell (measured: 14 pt).
  static const double disc = 14;

  /// The distance between the centres of two controls.
  static const double pitch = AmalfiWindowControls.pitch;

  /// The width of the group of three: 16 + 2 × 23 = 62.
  static const double groupWidth = cell + 2 * pitch;

  /// The symbol inside a disc (kit: a 12 pt glyph at 2, 2 of the cell).
  static const double glyph = 12;

  /// The stroke of the symbol (Semibold at 12 pt).
  static const double glyphStroke = 1.076;

  /// The x of the group's first cell in a bar of [barHeight]: the disc edge is 9 pt from the
  /// window edge up to 32 pt, 19 pt from 52 pt, a linear blend rounded to a whole point
  /// between (52 → 18, centre x 26; 48 → 16; 40 → 12; 32 → 8).
  static double leadingFor(double barHeight) {
    final t = ((barHeight - 32) / 20).clamp(0.0, 1.0);
    final edge = (lerpDouble(9, 19, t) ?? 9).roundToDouble();
    return edge - (cell - disc) / 2;
  }

  /// The y of the group's top in a bar of [barHeight] (centred).
  static double topFor(double barHeight) => (barHeight - cell) / 2;
}

/// The colours of one disc.
@immutable
class AmalfiWindowDotStyle {
  const AmalfiWindowDotStyle({
    required this.top,
    required this.bottom,
    this.rim,
    this.rimWidth = 0.5,
    this.edgeTop,
    this.edgeBottom,
    this.glyph,
  });

  /// The vertical gradient, top and bottom (equal for a flat disc).
  final Color top, bottom;

  /// The side outline, inside the disc; null: none.
  final Color? rim;

  /// The width of [rim].
  final double rimWidth;

  /// The 1 pt bright edges at the top and bottom (dark appearance); null: none.
  final Color? edgeTop, edgeBottom;

  /// The symbol colour; null: no symbol.
  final Color? glyph;

  /// The gradient of the disc.
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
    stops: const [0, 1],
  );

  /// The style of [kind] in [state] and [brightness].
  static AmalfiWindowDotStyle of(
    AmalfiWindowControlKind kind,
    AmalfiWindowControlState state,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    if (state == AmalfiWindowControlState.inactive) {
      return dark ? _inactiveDark : _inactiveLight;
    }
    final p = switch (kind) {
      AmalfiWindowControlKind.close => _close,
      AmalfiWindowControlKind.minimise => _minimise,
      AmalfiWindowControlKind.zoom => _zoom,
    };
    final (rest, hover, hoverGlyph, pressed, pressedGlyph) = dark
        ? (
            p.darkRest,
            p.darkHover,
            p.darkHoverGlyph,
            p.darkPressed,
            p.darkPressedGlyph,
          )
        : (
            p.lightRest,
            p.lightHover,
            p.lightHoverGlyph,
            p.lightPressed,
            p.lightPressedGlyph,
          );
    final (top, bottom, glyph) = switch (state) {
      AmalfiWindowControlState.rest => (rest.$1, rest.$2, null),
      AmalfiWindowControlState.hover => (hover, hover, hoverGlyph),
      _ => (pressed, pressed, pressedGlyph),
    };
    return dark
        ? AmalfiWindowDotStyle(
            top: state == AmalfiWindowControlState.hover ? p.darkRest.$1 : top,
            bottom: state == AmalfiWindowControlState.hover
                ? p.darkRest.$2
                : bottom,
            rim: p.darkRim,
            edgeTop: p.darkEdges.$1,
            edgeBottom: p.darkEdges.$2,
            glyph: glyph,
          )
        : AmalfiWindowDotStyle(
            top: top,
            bottom: bottom,
            rim: p.lightRim,
            glyph: glyph,
          );
  }

  static const _inactiveLight = AmalfiWindowDotStyle(
    top: Color(0xFFF4F4F7),
    bottom: Color(0xFFEAEBEC),
    rim: Color(0xFFC3C3C7),
  );
  static const _inactiveDark = AmalfiWindowDotStyle(
    top: Color(0xFF4D4D4D),
    bottom: Color(0xFF555555),
    rim: Color(0xB3999999),
    edgeTop: Color(0xFF999999),
    edgeBottom: Color(0xCC909091),
  );

  static final _close = _Palette(
    lightRest: (
      AmalfiWindowControls.close.top,
      AmalfiWindowControls.close.bottom,
    ),
    lightRim: AmalfiWindowControls.close.rim,
    lightHover: const Color(0xFFF97C72),
    lightHoverGlyph: const Color(0xFFA30000),
    lightPressed: const Color(0xFFFF9F8E),
    lightPressedGlyph: const Color(0xFFDA0000),
    darkRest: (const Color(0xFFF8635A), const Color(0xFFEE6660)),
    darkRim: const Color(0xFFEE5549),
    darkEdges: (const Color(0xFFFAB1A7), const Color(0xCCFBADA5)),
    darkHover: const Color(0xFFF1564D),
    darkHoverGlyph: const Color(0xFF8C0000),
    darkPressed: const Color(0xFFFF7560),
    darkPressedGlyph: const Color(0xFFBB0000),
  );
  static final _minimise = _Palette(
    lightRest: (
      AmalfiWindowControls.minimise.top,
      AmalfiWindowControls.minimise.bottom,
    ),
    lightRim: AmalfiWindowControls.minimise.rim,
    lightHover: const Color(0xFFFFCF41),
    lightHoverGlyph: const Color(0xFFC14400),
    lightPressed: const Color(0xFFFFFC5D),
    lightPressedGlyph: const Color(0xFFFF5A00),
    darkRest: (const Color(0xFFFAB500), const Color(0xFFFDCD29)),
    darkRim: const Color(0xFFF8B904),
    darkEdges: (const Color(0xFFFBEE5A), const Color(0xCCFBF869)),
    darkHover: const Color(0xFFFDC905),
    darkHoverGlyph: const Color(0xFFA53A00),
    darkPressed: const Color(0xFFFFFB17),
    darkPressedGlyph: const Color(0xFFDD4C00),
  );
  static final _zoom = _Palette(
    lightRest: (
      AmalfiWindowControls.zoom.top,
      AmalfiWindowControls.zoom.bottom,
    ),
    lightRim: AmalfiWindowControls.zoom.rim,
    lightHover: const Color(0xFF8DD969),
    lightHoverGlyph: const Color(0xFF368800),
    lightPressed: const Color(0xFF8EDF60),
    lightPressedGlyph: const Color(0xFF3B9600),
    darkRest: (const Color(0xFF01BC00), const Color(0xFF4BC133)),
    darkRim: const Color(0xFF09B901),
    darkEdges: (const Color(0xFF96FB78), const Color(0xCC8BFB76)),
    darkHover: const Color(0xFF36C002),
    darkHoverGlyph: const Color(0xFF2D7201),
    darkPressed: const Color(0xFF3AC80C),
    darkPressedGlyph: const Color(0xFF337E00),
  );
}

class _Palette {
  const _Palette({
    required this.lightRest,
    required this.lightRim,
    required this.lightHover,
    required this.lightHoverGlyph,
    required this.lightPressed,
    required this.lightPressedGlyph,
    required this.darkRest,
    required this.darkRim,
    required this.darkEdges,
    required this.darkHover,
    required this.darkHoverGlyph,
    required this.darkPressed,
    required this.darkPressedGlyph,
  });

  final (Color, Color) lightRest, darkRest, darkEdges;
  final Color darkRim, lightRim, lightHover, lightHoverGlyph, lightPressed;
  final Color lightPressedGlyph, darkHover, darkHoverGlyph, darkPressed;
  final Color darkPressedGlyph;
}

/// The symbol of [kind] (kit: `xmark`, `minus`, `plus`).
AmalfiGlyphData amalfiWindowControlGlyph(AmalfiWindowControlKind kind) =>
    switch (kind) {
      AmalfiWindowControlKind.close => AmalfiGlyphs.xmark,
      AmalfiWindowControlKind.minimise => AmalfiGlyphs.minus,
      AmalfiWindowControlKind.zoom => AmalfiGlyphs.plus,
    };

/// One window control disc, drawn in [state]: a 14 pt disc centred in a 16 pt cell, with its
/// symbol at [symbolOpacity] when the state has one.
///
/// This is the static look (kit `Titlebars/Dot/<kind>/<state>`); [AmalfiWindowControlGroup]
/// is the interactive group.
class AmalfiWindowDot extends StatelessWidget {
  const AmalfiWindowDot({
    super.key,
    required this.kind,
    this.state = AmalfiWindowControlState.rest,
    this.symbolOpacity = 1,
  });

  final AmalfiWindowControlKind kind;
  final AmalfiWindowControlState state;

  /// The opacity of the symbol (it fades in and out on hover).
  final double symbolOpacity;

  @override
  Widget build(BuildContext context) {
    final style = AmalfiWindowDotStyle.of(
      kind,
      state,
      AmalfiTheme.of(context).brightness,
    );
    final glyph = style.glyph;
    const inset =
        (AmalfiWindowControlsMetrics.cell - AmalfiWindowControlsMetrics.disc) /
        2;
    const glyphInset =
        (AmalfiWindowControlsMetrics.cell - AmalfiWindowControlsMetrics.glyph) /
        2;
    return SizedBox.square(
      dimension: AmalfiWindowControlsMetrics.cell,
      child: Stack(
        children: [
          Positioned(
            left: inset,
            top: inset,
            width: AmalfiWindowControlsMetrics.disc,
            height: AmalfiWindowControlsMetrics.disc,
            child: _Disc(style: style),
          ),
          if (glyph != null && symbolOpacity > 0)
            Positioned(
              left: glyphInset,
              top: glyphInset,
              child: Opacity(
                opacity: symbolOpacity.clamp(0.0, 1.0),
                child: AmalfiGlyph(
                  amalfiWindowControlGlyph(kind),
                  size: AmalfiWindowControlsMetrics.glyph,
                  color: glyph,
                  strokeWidth: AmalfiWindowControlsMetrics.glyphStroke,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.style});

  final AmalfiWindowDotStyle style;

  @override
  Widget build(BuildContext context) {
    final rim = style.rim;
    const radius = AmalfiWindowControlsMetrics.disc / 2;
    return DecoratedBox(
      decoration: AmalfiShapeDecoration(
        gradient: style.gradient,
        shape: AmalfiSmoothBorder(
          radius: radius,
          side: rim == null
              ? BorderSide.none
              : BorderSide(
                  color: rim,
                  width: style.rimWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
        ),
      ),
      child: style.edgeTop == null && style.edgeBottom == null
          ? const SizedBox.expand()
          : CustomPaint(
              painter: _EdgePainter(style.edgeTop, style.edgeBottom),
              child: const SizedBox.expand(),
            ),
    );
  }
}

/// The 1 pt bright edges of a dark disc: inner shadows (0, 1) and (0, −1) with no blur.
class _EdgePainter extends CustomPainter {
  _EdgePainter(this.top, this.bottom);

  final Color? top, bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final disc = Path()..addOval(Offset.zero & size);
    final outside = Path()..addRect((Offset.zero & size).inflate(2));
    canvas.save();
    canvas.clipPath(disc);
    for (final (color, dy) in [(top, 1.0), (bottom, -1.0)]) {
      if (color == null) continue;
      final band = Path.combine(
        PathOperation.difference,
        outside,
        disc.shift(Offset(0, dy)),
      );
      canvas.drawPath(band, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.top != top || old.bottom != bottom;
}

/// The close, minimise and zoom controls of a window (kit `Titlebars/Controls`).
///
/// A null callback disables that control: a grey disc that shows no symbol (`docs/spec`:
/// minimise and zoom of a window that cannot be resized). While the pointer is over the group
/// every enabled control shows its symbol, also in an inactive window (whose discs then take
/// their active colours); pressing one lightens only that one, and the action runs on release
/// over it (moving off before releasing cancels). [active] null follows the
/// [WindowActiveScope].
///
/// The group is [AmalfiWindowControlsMetrics.groupWidth] × 16; place it with
/// [AmalfiWindowControlsMetrics.leadingFor] and [AmalfiWindowControlsMetrics.topFor] (the
/// pieces and bars of this family do).
class AmalfiWindowControlGroup extends StatefulWidget {
  const AmalfiWindowControlGroup({
    super.key,
    this.onClose,
    this.onMinimise,
    this.onZoom,
    this.active,
    this.closeLabel = 'Close',
    this.minimiseLabel = 'Minimise',
    this.zoomLabel = 'Zoom',
  });

  final VoidCallback? onClose, onMinimise, onZoom;

  /// Whether the window is active; null: from [WindowActiveScope].
  final bool? active;

  /// The screen reader labels (pass localised strings).
  final String closeLabel, minimiseLabel, zoomLabel;

  @override
  State<AmalfiWindowControlGroup> createState() =>
      _AmalfiWindowControlGroupState();
}

class _AmalfiWindowControlGroupState extends State<AmalfiWindowControlGroup>
    with SingleTickerProviderStateMixin {
  /// The symbols' opacity: in with `fade.instant` (measured: complete in ~70–110 ms), out
  /// ~60 ms after the pointer leaves, gone ~60 ms later (measured: by ~110–130 ms).
  late final AnimationController _symbols = AnimationController(
    vsync: this,
    duration: AmalfiFades.instant.duration,
    reverseDuration: const Duration(milliseconds: 60),
  );
  static const Duration _exitDelay = Duration(milliseconds: 60);

  bool _hovered = false;
  AmalfiWindowControlKind? _pressed;
  bool _pressedInside = false;
  Timer? _exit;

  @override
  void dispose() {
    _exit?.cancel();
    _symbols.dispose();
    super.dispose();
  }

  VoidCallback? _action(AmalfiWindowControlKind kind) => switch (kind) {
    AmalfiWindowControlKind.close => widget.onClose,
    AmalfiWindowControlKind.minimise => widget.onMinimise,
    AmalfiWindowControlKind.zoom => widget.onZoom,
  };

  String _label(AmalfiWindowControlKind kind) => switch (kind) {
    AmalfiWindowControlKind.close => widget.closeLabel,
    AmalfiWindowControlKind.minimise => widget.minimiseLabel,
    AmalfiWindowControlKind.zoom => widget.zoomLabel,
  };

  void _setHovered(bool hovered) {
    _exit?.cancel();
    if (hovered) {
      setState(() => _hovered = true);
      _symbols.forward();
    } else {
      _exit = Timer(_exitDelay, () {
        if (!mounted) return;
        setState(() => _hovered = false);
        _symbols.reverse();
      });
    }
  }

  AmalfiWindowControlState _state(AmalfiWindowControlKind kind, bool active) {
    if (_action(kind) == null) return AmalfiWindowControlState.inactive;
    if (_pressed == kind && _pressedInside) {
      return AmalfiWindowControlState.pressed;
    }
    if (_hovered || _symbols.value > 0) return AmalfiWindowControlState.hover;
    return active
        ? AmalfiWindowControlState.rest
        : AmalfiWindowControlState.inactive;
  }

  Widget _control(AmalfiWindowControlKind kind, bool active) {
    final action = _action(kind);
    const cell = Size.square(AmalfiWindowControlsMetrics.cell);
    return Semantics(
      button: true,
      enabled: action != null,
      label: _label(kind),
      onTap: action,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: action == null
            ? null
            : (_) => setState(() {
                _pressed = kind;
                _pressedInside = true;
              }),
        onPointerMove: (e) {
          if (_pressed != kind) return;
          final inside = (Offset.zero & cell).contains(e.localPosition);
          if (inside != _pressedInside) {
            setState(() => _pressedInside = inside);
          }
        },
        onPointerUp: (e) {
          if (_pressed != kind) return;
          final fire =
              (Offset.zero & cell).contains(e.localPosition) && action != null;
          setState(() => _pressed = null);
          if (fire) action();
        },
        onPointerCancel: (_) => setState(() => _pressed = null),
        child: AnimatedBuilder(
          animation: _symbols,
          builder: (context, _) => AmalfiWindowDot(
            kind: kind,
            state: _state(kind, active),
            symbolOpacity: _pressed == kind && _pressedInside
                ? 1
                : _symbols.value,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = amalfiTitlebarResolveActive(context, widget.active);
    const gap =
        AmalfiWindowControlsMetrics.pitch - AmalfiWindowControlsMetrics.cell;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: SizedBox(
        width: AmalfiWindowControlsMetrics.groupWidth,
        height: AmalfiWindowControlsMetrics.cell,
        child: Row(
          children: [
            _control(AmalfiWindowControlKind.close, active),
            const SizedBox(width: gap),
            _control(AmalfiWindowControlKind.minimise, active),
            const SizedBox(width: gap),
            _control(AmalfiWindowControlKind.zoom, active),
          ],
        ),
      ),
    );
  }
}
