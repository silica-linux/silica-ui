// What the small Amalfi controls of the toggles, disclosure and group box families share: the
// soft control shadow drawn with the kit's blur semantics, the stroked Icon Kit glyphs they
// use, the keyboard focus halo, the layer keys the kit tests look for, and the pointer and
// keyboard interaction (hover, press, focus, activation, drag).
//
// These helpers live in the toggles family for now; they are meant to move to a shared place
// when the families are merged.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart' show amalfiShadowSigma;
import '../../smooth_border.dart';
import '../../tokens.g.dart';

/// The soft shadow under raised controls at rest (checkbox and radio boxes, switch thumbs,
/// the disclosure button): `Shadow Soft`, y 1, blur 2 (the kit's blur, see
/// [AmalfiShapeDecoration]).
List<BoxShadow> amalfiControlShadow(AmalfiColors colors) => [
  BoxShadow(
    color: colors.shadowSoft,
    offset: const Offset(0, 1),
    blurRadius: 2,
  ),
];

/// A [ShapeDecoration] painted as the kit draws a shape: its [shadows] outside the shape only
/// (they never show through a translucent fill), each [BoxShadow.blurRadius] read as a CSS
/// `box-shadow` blur (σ = blur / 2); an inside border of an [OutlinedBorder] stroked on the
/// outline itself, twice as wide and clipped to the shape (as `AmalfiGlass` strokes its rim).
class AmalfiShapeDecoration extends ShapeDecoration {
  const AmalfiShapeDecoration({
    super.color,
    super.gradient,
    super.shadows,
    required super.shape,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _AmalfiShapePainter(this, onChanged);
}

class _AmalfiShapePainter extends BoxPainter {
  _AmalfiShapePainter(this._decoration, super.onChanged);

  final AmalfiShapeDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty || !size.isFinite) return;
    final rect = offset & size;
    final direction = configuration.textDirection;
    final shape = _decoration.shape;
    final outline = shape.getOuterPath(rect, textDirection: direction);

    final shadows = _decoration.shadows ?? const <BoxShadow>[];
    if (shadows.isNotEmpty) {
      var reach = 0.0;
      for (final s in shadows) {
        reach = math.max(
          reach,
          s.blurRadius * 2 + s.spreadRadius + s.offset.distance + 1,
        );
      }
      canvas
        ..save()
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect.inflate(reach)),
            outline,
          ),
        );
      for (final s in shadows) {
        final paint = Paint()
          ..color = s.color
          ..maskFilter = s.blurRadius > 0
              ? MaskFilter.blur(
                  BlurStyle.normal,
                  amalfiShadowSigma(s.blurRadius),
                )
              : null;
        canvas.drawPath(
          shape.getOuterPath(
            rect.shift(s.offset).inflate(s.spreadRadius),
            textDirection: direction,
          ),
          paint,
        );
      }
      canvas.restore();
    }

    final color = _decoration.color;
    final gradient = _decoration.gradient;
    if (color != null) canvas.drawPath(outline, Paint()..color = color);
    if (gradient != null) {
      canvas.drawPath(
        outline,
        Paint()..shader = gradient.createShader(rect, textDirection: direction),
      );
    }
    final side = shape is OutlinedBorder ? shape.side : BorderSide.none;
    if (side.style != BorderStyle.none &&
        side.width > 0 &&
        side.strokeAlign == BorderSide.strokeAlignInside) {
      canvas
        ..save()
        ..clipPath(outline)
        ..drawPath(
          outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = side.width * 2
            ..color = side.color,
        )
        ..restore();
      return;
    }
    shape.paint(canvas, rect, textDirection: direction);
  }
}

/// The keys of the layers a control draws, named as in the kit (`Box`, `State`,
/// `Focus Halo`, …), so that a test can find each one.
abstract final class AmalfiLayerKeys {
  /// The body of a box, track or button (`Box`, `Track`, `Background`, `Surface`).
  static const Key body = ValueKey('amalfi.layer.body');

  /// The hover overlay (`State`).
  static const Key state = ValueKey('amalfi.layer.state');

  /// The keyboard focus halo (`Focus Halo`).
  static const Key focusHalo = ValueKey('amalfi.layer.focusHalo');

  /// A glyph or mark (`Glyph Check`, `Glyph Dash`, `Dot`, `Glyph Chevron …`).
  static const Key mark = ValueKey('amalfi.layer.mark');

  /// A switch thumb (`Thumb`).
  static const Key thumb = ValueKey('amalfi.layer.thumb');

  /// The lens over a dragged switch thumb (`Lens`).
  static const Key lens = ValueKey('amalfi.layer.lens');

  /// The label of a labelled control (`Label`, `Title`, `Heading`).
  static const Key label = ValueKey('amalfi.layer.label');

  /// The content of a group or box (`Content`).
  static const Key content = ValueKey('amalfi.layer.content');

  /// The control inside a labelled row (`Checkbox box`, `Radio box`, `Switch`, `Triangle`).
  static const Key control = ValueKey('amalfi.layer.control');
}

/// The keyboard focus halo: [AmalfiFocus.halo] points of `Line/Focus` outside a shape of
/// [radius], the size of its parent (place it with `Positioned.fill`).
class AmalfiFocusHalo extends StatelessWidget {
  const AmalfiFocusHalo({
    super.key,
    required this.radius,
    required this.colors,
  });

  /// The corner radius of the control it surrounds.
  final double radius;

  /// The colours of the appearance in effect.
  final AmalfiColors colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: AmalfiLayerKeys.focusHalo,
    decoration: AmalfiShapeDecoration(
      shape: AmalfiSmoothBorder(
        radius: radius,
        side: BorderSide(
          color: AmalfiFocus.color(colors),
          width: AmalfiFocus.halo,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
    ),
  );
}

/// The Icon Kit glyphs the controls draw, as their 24 pt outlines (`symbols/regular/*.svg` in
/// silica-icons), stroked with round caps and joins.
enum AmalfiGlyph {
  /// `checkmark`.
  checkmark([Offset(4.6, 12.6), Offset(9.4, 17.6), Offset(19.4, 6.4)]),

  /// `minus`.
  minus([Offset(4, 12), Offset(20, 12)]),

  /// `chevron-right`.
  chevronRight([Offset(9.41, 5.4), Offset(14.59, 12), Offset(9.41, 18.6)]),

  /// `chevron-down`.
  chevronDown([Offset(5.4, 9.41), Offset(12, 14.59), Offset(18.6, 9.41)]),

  /// `chevron-up`.
  chevronUp([Offset(5.4, 14.59), Offset(12, 9.41), Offset(18.6, 14.59)]);

  const AmalfiGlyph(this.points);

  /// The polyline on the 24 pt canvas.
  final List<Offset> points;

  /// The stroke width at [size] points: Regular is 1.5 at 24 and scales with the size
  /// (12 → 0.75, 16 → 1), as the Icon Kit's stroke styles.
  static double strokeWidth(double size) => 1.5 * size / 24;
}

/// Paints [glyph] in [color], filling its size (a square), optionally turned by [turns]
/// around its centre.
class AmalfiGlyphPainter extends CustomPainter {
  const AmalfiGlyphPainter({
    required this.glyph,
    required this.color,
    this.turns = 0,
  });

  final AmalfiGlyph glyph;
  final Color color;

  /// Clockwise turns (0.25 = 90°).
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0 || !side.isFinite) return;
    final scale = side / 24;
    final path = Path();
    for (final (i, p) in glyph.points.indexed) {
      i == 0
          ? path.moveTo(p.dx * scale, p.dy * scale)
          : path.lineTo(p.dx * scale, p.dy * scale);
    }
    canvas.save();
    if (turns != 0) {
      final c = Offset(side / 2, side / 2);
      canvas
        ..translate(c.dx, c.dy)
        ..rotate(turns * 2 * math.pi)
        ..translate(-c.dx, -c.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AmalfiGlyph.strokeWidth(side)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AmalfiGlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.turns != turns;
}

/// A glyph of [size] points (see [AmalfiGlyphPainter]).
class AmalfiGlyphIcon extends StatelessWidget {
  const AmalfiGlyphIcon({
    super.key,
    required this.glyph,
    required this.size,
    required this.color,
    this.turns = 0,
  });

  final AmalfiGlyph glyph;
  final double size;
  final Color color;
  final double turns;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: AmalfiGlyphPainter(glyph: glyph, color: color, turns: turns),
    ),
  );
}

/// The interaction state of a control.
@immutable
class AmalfiInteractionState {
  const AmalfiInteractionState({
    this.enabled = true,
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
  });

  /// Whether the control reacts to input.
  final bool enabled;

  /// The pointer is over the control.
  final bool hovered;

  /// The primary button is down on the control and the pointer is still over it.
  final bool pressed;

  /// The control has the keyboard focus (shown with the halo).
  final bool focused;

  @override
  bool operator ==(Object other) =>
      other is AmalfiInteractionState &&
      other.enabled == enabled &&
      other.hovered == hovered &&
      other.pressed == pressed &&
      other.focused == focused;

  @override
  int get hashCode => Object.hash(enabled, hovered, pressed, focused);
}

/// Pointer and keyboard handling of a control: hover, press (with the pointer still inside),
/// keyboard focus (the halo shows only with keyboard navigation), activation on release
/// inside or with Space, and optionally a drag of the primary button.
///
/// [builder] draws the control in its [AmalfiInteractionState]. With [onActivate] null the
/// control is disabled: no hover, press, focus or activation.
class AmalfiInteraction extends StatefulWidget {
  const AmalfiInteraction({
    super.key,
    required this.builder,
    this.onActivate,
    this.onKey,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.dragSlop = 2,
    this.focusNode,
    this.autofocus = false,
    this.cursor = SystemMouseCursors.basic,
  });

  final Widget Function(BuildContext context, AmalfiInteractionState state)
  builder;

  /// A release inside the control, or Space with the keyboard focus; null: disabled.
  final VoidCallback? onActivate;

  /// Other keys with the keyboard focus.
  final KeyEventResult Function(KeyEvent event)? onKey;

  /// The pointer moved [dragSlop] points with the primary button down: a drag starts (the
  /// release then ends it instead of activating). Positions are local.
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  /// How far the pointer moves before a press becomes a drag.
  final double dragSlop;

  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor cursor;

  @override
  State<AmalfiInteraction> createState() => _AmalfiInteractionState();
}

class _AmalfiInteractionState extends State<AmalfiInteraction> {
  bool _hovered = false;
  bool _focused = false;
  bool _down = false;
  bool _inside = false;
  bool _dragging = false;
  Offset _downAt = Offset.zero;

  bool get _enabled => widget.onActivate != null;

  @override
  void didUpdateWidget(AmalfiInteraction old) {
    super.didUpdateWidget(old);
    if (!_enabled) {
      if (_dragging) widget.onDragEnd?.call();
      _down = _dragging = false;
    }
  }

  bool _contains(Offset local) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize && box.size.contains(local);
  }

  void _pointerDown(PointerDownEvent e) {
    if (!_enabled || e.buttons & kPrimaryButton == 0) return;
    setState(() {
      _down = true;
      _inside = true;
      _dragging = false;
      _downAt = e.localPosition;
    });
  }

  void _pointerMove(PointerMoveEvent e) {
    if (!_down) return;
    final drags = widget.onDragStart != null;
    if (drags &&
        !_dragging &&
        (e.localPosition - _downAt).distance >= widget.dragSlop) {
      setState(() => _dragging = true);
      widget.onDragStart?.call(_downAt);
    }
    if (_dragging) {
      widget.onDragUpdate?.call(e.localPosition);
      return;
    }
    final inside = _contains(e.localPosition);
    if (inside != _inside) setState(() => _inside = inside);
  }

  void _pointerUp(PointerUpEvent e) {
    if (!_down) return;
    final dragged = _dragging;
    final fire = !dragged && _inside && _contains(e.localPosition);
    setState(() {
      _down = false;
      _dragging = false;
      _hovered = _contains(e.localPosition);
    });
    if (dragged) {
      widget.onDragEnd?.call();
    } else if (fire && _enabled) {
      widget.onActivate?.call();
    }
  }

  void _pointerCancel() {
    if (!_down) return;
    final dragged = _dragging;
    setState(() => _down = _dragging = false);
    if (dragged) widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final state = AmalfiInteractionState(
      enabled: enabled,
      hovered: enabled && _hovered,
      pressed: enabled && _down && (_inside || _dragging),
      focused: enabled && _focused,
    );
    final onKey = widget.onKey;
    Widget child = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? widget.cursor : MouseCursor.defer,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (on) {
        if (on != _focused) setState(() => _focused = on);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: (_) => _pointerCancel(),
          child: widget.builder(context, state),
        ),
      ),
    );
    if (onKey != null) {
      child = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) =>
            enabled ? onKey(event) : KeyEventResult.ignored,
        child: child,
      );
    }
    return child;
  }
}
