// The toolbar glass controls: capsules (Back / Forward, segmented groups, view selectors), single
// round buttons, toolbar menu buttons and the search button (TITLEBAR-GLASS, #86).
//
// Measured: capsules 38 tall (radius 19) or 36–38 pt circles; a 1 pt separator between the
// segments of a button pair. Hover: a round highlight on the segment under the pointer (a 28 pt
// circle on button pairs, a pill the size of the selection on segmented groups, the whole circle
// on single buttons), +20 levels in dark and −10 in light, fading in ~170 ms; the separators next
// to it hide; none on disabled segments. Press: the whole container grows ~1 pt per side in
// 40–50 ms and stays grown while held, even with the pointer outside; in dark a soft light spot
// centred on the pointer (+20–25 levels, Gaussian falloff σ ≈ 26 pt, clipped to the container)
// follows the pointer with ~30 ms of lag, also on disabled segments, and fades with the distance
// once the pointer leaves the bounds. While held the highlight jumps to the enabled segment under
// the pointer and goes off at the edge. Release outside: spring back in ~100 ms with a small
// undershoot. Click: the pressed size is held ~100 ms after mouse-up, then back in ≤ 40 ms; the
// action fires on mouse-up. Long press on Back opens the history menu below the capsule.
//
// The colours are in [ToolbarColors] (window.dart).
//
// Narrow toolbars (layout is the app's, there is no toolbar layout widget here): items that do not
// fit collapse into a "»" overflow button, a 38 pt single-segment capsule placed before the
// search button, whose `onPress` opens a menu with the hidden items; the view selector first
// collapses into one pop-up capsule (the current view's icon and up/down chevrons, a menu on
// press). At the minimum width only the title, "»" and search remain.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'window.dart';

/// The measured timings and sizes of the toolbar glass controls (TITLEBAR-GLASS).
abstract final class ToolbarGlassMetrics {
  /// The hover highlight on a button pair (Back / Forward): a circle centred on the segment.
  static const double hoverDiameter = 28;

  /// The height of the highlight and selection pills (5 pt from the capsule top and bottom).
  static const double pillHeight = 28;

  /// A selection pill is the segment width minus this (40 → 34).
  static const double selectionInset = 6;

  /// The hover highlight fades in and out in this time.
  static const Duration hoverFade = Duration(milliseconds: 170);

  /// Pressed: the container grows by this much per side, in [pressGrow].
  static const double pressGrowth = 1;
  static const Duration pressGrow = Duration(milliseconds: 45);

  /// Click: the pressed size stays [clickHold] after mouse-up, then returns in [clickRelease].
  static const Duration clickHold = Duration(milliseconds: 100);
  static const Duration clickRelease = Duration(milliseconds: 40);

  /// Release outside: back to rest in ~100 ms with a ~10 % undershoot.
  static const SpringDescription releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 1350,
    damping: 44,
  );

  /// The pressed glow: Gaussian σ, lag behind the pointer, fade in on press and out on release.
  static const double glowSigma = 26;
  static const Duration glowLag = Duration(milliseconds: 30);
  static const Duration glowFadeIn = Duration(milliseconds: 100);
  static const Duration glowFadeOut = Duration(milliseconds: 200);

  /// With the pointer `d` pt outside the container the glow is scaled by
  /// `1 / (1 + d / glowFalloff)` (+8 levels at 15 pt, +3 at 55 pt) and spreads out.
  static const double glowFalloff = 8.5;
}

/// The long-press delay (history menu on Back and Forward, MU-07).
const Duration toolbarLongPress = Duration(milliseconds: 295);

/// The shape of the hover highlight in a [ToolbarCapsule].
enum ToolbarHighlight {
  /// A [ToolbarGlassMetrics.hoverDiameter] circle centred on the segment (Back / Forward, button
  /// groups, a button with a menu chevron).
  circle,

  /// A pill the size of the selection: the segment width minus
  /// [ToolbarGlassMetrics.selectionInset], [ToolbarGlassMetrics.pillHeight] tall (view
  /// selectors, segmented groups).
  selection,
}

/// A toolbar capsule: 38 high, radius 19, with [ToolbarSegment]s in a row. A single segment as
/// wide as it is high becomes a circle (Search, single buttons), lit as a whole on hover.
///
/// The capsule tracks the pointer for all its segments: the hover highlight, the separators that
/// hide next to it, the press growth, the pressed glow and the release timing are described in
/// [ToolbarGlassMetrics]. The action of a segment fires on mouse-up over it; while held, the
/// highlight jumps to the enabled segment under the pointer, and releasing over another enabled
/// segment acts on that one.
class ToolbarCapsule extends StatefulWidget {
  const ToolbarCapsule({
    super.key,
    required this.children,
    this.separators = false,
    this.highlight,
  });

  final List<Widget> children;

  /// A 1 × 21 line between the segments (Back / Forward).
  final bool separators;

  /// The hover highlight; by default [ToolbarHighlight.circle] with [separators] (button pairs),
  /// otherwise [ToolbarHighlight.selection] (segmented groups).
  final ToolbarHighlight? highlight;

  @override
  State<ToolbarCapsule> createState() => _ToolbarCapsuleState();
}

class _ToolbarCapsuleState extends State<ToolbarCapsule>
    with TickerProviderStateMixin {
  final Map<int, _ToolbarSegmentState> _segments = {};

  /// The enabled segment under the hovering pointer.
  int? _hovered;

  /// While held: the enabled segment under the pointer, inside the capsule.
  int? _tracked;

  /// The segment pressed at mouse-down (it may be disabled).
  int? _down;
  int? _pointer;
  bool _longFired = false;
  Timer? _long;

  late final AnimationController _grow =
      AnimationController.unbounded(vsync: this)
        ..addListener(_changed)
        ..addStatusListener((status) {
          // The release spring settles within its tolerance: rest exactly.
          if (status == AnimationStatus.completed &&
              _grow.value != 0 &&
              _grow.value.abs() < 0.01) {
            _grow.value = 0;
          }
        });
  late final AnimationController _glowAmount = AnimationController(vsync: this)
    ..addListener(_changed)
    ..addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _glowTicker.stop();
    });
  late final Ticker _glowTicker = createTicker(_followGlow);
  Duration _lastTick = Duration.zero;
  Offset? _glowTarget;
  Offset? _glowAt;

  bool get _held => _pointer != null;
  int? get _highlighted => _held ? _tracked : _hovered;

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _long?.cancel();
    _glowTicker.dispose();
    _grow.dispose();
    _glowAmount.dispose();
    super.dispose();
  }

  void _register(int index, _ToolbarSegmentState segment) =>
      _segments[index] = segment;

  void _unregister(int index, _ToolbarSegmentState segment) {
    if (_segments[index] == segment) _segments.remove(index);
  }

  Size get _size {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : Size.zero;
  }

  /// The segment under `global`, or the nearest one along the row from a separator or the
  /// outline, if `global` is inside the capsule.
  int? _segmentAt(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    if (!(Offset.zero & box.size).contains(box.globalToLocal(global))) {
      return null;
    }
    int? best;
    var bestDistance = double.infinity;
    for (final MapEntry(key: index, value: segment) in _segments.entries) {
      final r = segment.context.findRenderObject();
      if (r is! RenderBox || !r.hasSize || !r.attached) continue;
      final x = r.globalToLocal(global).dx;
      final d = x < 0 ? -x : (x > r.size.width ? x - r.size.width : 0.0);
      if (d < bestDistance) {
        bestDistance = d;
        best = index;
      }
    }
    return best;
  }

  int? _enabledAt(Offset global) {
    final i = _segmentAt(global);
    return i != null && (_segments[i]?.widget.enabled ?? false) ? i : null;
  }

  void _hover(PointerEvent e) {
    if (_held) return;
    final next = _enabledAt(e.position);
    if (next != _hovered) setState(() => _hovered = next);
  }

  void _exit(PointerExitEvent e) {
    if (_held || _hovered == null) return;
    setState(() => _hovered = null);
  }

  void _pointerDown(PointerDownEvent e) {
    if (_held || e.buttons & kPrimaryButton == 0) return;
    final reduced = _reduced;
    _pointer = e.pointer;
    _longFired = false;
    _down = _segmentAt(e.position);
    _tracked = _enabledAt(e.position);
    if (reduced) {
      _grow.value = 1;
    } else {
      _grow.animateTo(
        1,
        duration: ToolbarGlassMetrics.pressGrow,
        curve: Curves.easeOut,
      );
    }
    _glowTarget = _glowAt = e.localPosition;
    if (reduced) {
      _glowAmount.value = 1;
    } else {
      _glowAmount.animateTo(1, duration: ToolbarGlassMetrics.glowFadeIn);
    }
    if (!_glowTicker.isActive) {
      _lastTick = Duration.zero;
      _glowTicker.start();
    }
    setState(() {});
    final segment = _down == null ? null : _segments[_down];
    if (segment == null || !segment.widget.enabled) return;
    segment.widget.onPress?.call();
    if (segment.widget.onLongPress != null ||
        segment.widget.onLongPressMenu != null) {
      final index = _down!;
      _long?.cancel();
      _long = Timer(toolbarLongPress, () => _fireLong(index));
    }
  }

  void _fireLong(int index) {
    final segment = _segments[index];
    if (!_held || _tracked != index || segment == null) return;
    _longFired = true;
    segment.widget.onLongPress?.call();
    final menu = segment.widget.onLongPressMenu;
    final box = context.findRenderObject();
    final seg = segment.context.findRenderObject();
    if (menu != null && box is RenderBox && seg is RenderBox) {
      final top = box.localToGlobal(Offset.zero).dy;
      final left = seg.localToGlobal(Offset.zero).dx;
      menu(Rect.fromLTWH(left, top, seg.size.width, box.size.height));
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final next = _enabledAt(e.position);
    if (next != _down) _long?.cancel();
    _glowTarget = e.localPosition;
    if (_reduced) _glowAt = e.localPosition;
    if (!_glowTicker.isActive) {
      _lastTick = Duration.zero;
      _glowTicker.start();
    }
    if (next != _tracked) setState(() => _tracked = next);
  }

  void _pointerUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _long?.cancel();
    final inside = (Offset.zero & _size).contains(e.localPosition);
    final target = _tracked;
    final click = inside && !_longFired;
    _hovered = inside ? _enabledAt(e.position) : null;
    _release(click: click);
    if (click && target != null) _segments[target]?.widget.onTap?.call();
  }

  void _pointerCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _long?.cancel();
    _hovered = null;
    _release(click: false);
  }

  void _release({required bool click}) {
    _pointer = null;
    _tracked = null;
    _down = null;
    final reduced = _reduced;
    if (click) {
      _grow.animateWith(_ClickRelease(from: _grow.value, reduced: reduced));
    } else if (reduced) {
      _grow.value = 0;
    } else {
      _grow.animateWith(
        SpringSimulation(
          ToolbarGlassMetrics.releaseSpring,
          _grow.value,
          0,
          _grow.velocity,
          tolerance: const Tolerance(distance: 0.005, velocity: 0.05),
        ),
      );
    }
    if (reduced) {
      _glowAmount.value = 0;
    } else {
      _glowAmount.animateBack(0, duration: ToolbarGlassMetrics.glowFadeOut);
    }
    setState(() {});
  }

  /// The glow follows the pointer as a first-order lag of [ToolbarGlassMetrics.glowLag].
  void _followGlow(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final target = _glowTarget, at = _glowAt;
    if (dt <= 0) return;
    if (target == null || at == null || at == target) {
      // Caught up: no frames until the pointer moves again.
      _glowTicker.stop();
      return;
    }
    final lag = ToolbarGlassMetrics.glowLag.inMicroseconds / 1e6;
    final next = Offset.lerp(at, target, 1 - math.exp(-dt / lag))!;
    setState(() => _glowAt = (next - target).distance < 0.01 ? target : next);
  }

  ToolbarGlowPainter? _glowPainter(ToolbarColors colors) {
    final at = _glowAt;
    if (at == null || _glowAmount.value <= 0 || colors.glow.a == 0) {
      return null;
    }
    final size = _size;
    // The pointer's distance outside the container: the spot weakens and spreads.
    final center = Offset(
      at.dx.clamp(0, size.width),
      at.dy.clamp(0, size.height),
    );
    final d = (at - center).distance;
    return ToolbarGlowPainter(
      center: center,
      strength: _glowAmount.value / (1 + d / ToolbarGlassMetrics.glowFalloff),
      sigma: ToolbarGlassMetrics.glowSigma + 2 * d,
      color: colors.glow,
      radius: size.height / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ToolbarColors.of(context);
    final scope = ToolbarScope.maybeOf(context);
    final active = scope?.active ?? true;
    final fill = !active
        ? colors.fillInactive
        : (scope?.hovered ?? false)
        ? colors.fillBarHover
        : colors.fill;
    final children = widget.children;
    final overContent = ToolbarOverContent.of(context);
    final shape = children.length == 1
        ? null
        : widget.highlight ??
              (widget.separators
                  ? ToolbarHighlight.circle
                  : ToolbarHighlight.selection);
    final highlighted = _highlighted;
    final instant = _held || _reduced;
    final innerRadius = BorderRadius.circular(toolbarCapsuleHeight / 2 - 1);
    final capsule = Container(
      height: toolbarCapsuleHeight,
      // The outline: a 1 pt ring, light above and below, darker on the sides.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            for (final c in [
              colors.borderTop,
              colors.borderSide,
              colors.borderBottom,
            ])
              overContent ? c.withValues(alpha: capsuleRimOutlineAlpha) : c,
          ],
        ),
        borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2),
      ),
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: overContent ? null : fill,
          borderRadius: innerRadius,
        ),
        position: DecorationPosition.background,
        child: CustomPaint(
          painter: overContent ? _RimFillPainter(fill) : null,
          child: ClipRRect(
            borderRadius: innerRadius,
            child: CustomPaint(
              foregroundPainter: _glowPainter(colors),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (widget.separators && i > 0)
                      Container(
                        width: 1,
                        height: 21,
                        color: highlighted == i || highlighted == i - 1
                            ? null
                            : colors.separator,
                      ),
                    _CapsuleSlot(
                      capsule: this,
                      index: i,
                      shape: shape,
                      highlighted: highlighted == i,
                      pressed: _held && highlighted == i,
                      held: _held,
                      instant: instant,
                      child: children[i],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return MouseRegion(
      onEnter: _hover,
      onHover: _hover,
      onExit: _exit,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerUp,
        onPointerCancel: _pointerCancel,
        // The capsule keeps tap and drag to itself: a drag from a control does not move the
        // window (WindowDragArea), MU-08.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onPanStart: (_) {},
          child: ToolbarGrow(
            grow: _grow.value * ToolbarGlassMetrics.pressGrowth,
            child: overContent ? _RefractedRim(child: capsule) : capsule,
          ),
        ),
      ),
    );
  }
}

/// After a click: hold the pressed size for [ToolbarGlassMetrics.clickHold], then return to rest
/// in [ToolbarGlassMetrics.clickRelease] (instantly with reduced motion).
class _ClickRelease extends Simulation {
  _ClickRelease({required this.from, required this.reduced});

  final double from;
  final bool reduced;

  double get _hold => ToolbarGlassMetrics.clickHold.inMicroseconds / 1e6;
  double get _back =>
      reduced ? 0 : ToolbarGlassMetrics.clickRelease.inMicroseconds / 1e6;

  @override
  double x(double time) {
    if (time < _hold) return from;
    if (_back == 0) return 0;
    final t = ((time - _hold) / _back).clamp(0.0, 1.0);
    return from * (1 - Curves.easeIn.transform(t));
  }

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => time >= _hold + _back;
}

/// The pressed glow: a light spot of `color` scaled by `strength` at `center`, with a Gaussian
/// falloff of σ = `sigma`, clipped to the capsule of corner `radius`.
class ToolbarGlowPainter extends CustomPainter {
  const ToolbarGlowPainter({
    required this.center,
    required this.strength,
    required this.color,
    this.sigma = ToolbarGlassMetrics.glowSigma,
    this.radius = toolbarCapsuleHeight / 2,
  });

  final Offset center;
  final double strength;
  final Color color;
  final double sigma;
  final double radius;

  static const List<double> _stops = [0, 0.15, 0.3, 0.45, 0.6, 0.8, 1];

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0 || color.a == 0 || size.isEmpty) return;
    final reach = 3 * sigma;
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final colors = [
      for (final s in _stops)
        color.withValues(
          alpha: color.a * strength.clamp(0.0, 1.0) * math.exp(-4.5 * s * s),
        ),
    ];
    final circle = Rect.fromCircle(center: center, radius: reach);
    canvas
      ..drawCircle(
        center,
        reach,
        Paint()
          ..shader = RadialGradient(
            colors: colors,
            stops: _stops,
          ).createShader(circle),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(ToolbarGlowPainter old) =>
      old.center != center ||
      old.strength != strength ||
      old.color != color ||
      old.sigma != sigma ||
      old.radius != radius;
}

/// Over content, the outermost [capsuleRim] pt of a capsule show the content under it, blurred
/// by [capsuleRimSigma] and lightly covered by the fill: an approximation of the refraction seen
/// at the capsule edges (MU-21, R1.9). *Provisional values: the profile is not measured.*
const double capsuleRim = 3;
const double capsuleRimSigma = 3;
const double capsuleRimFillAlpha = 0.45;
const double capsuleRimOutlineAlpha = 0.6;

/// The content under the capsule, blurred, inside its shape.
class _RefractedRim extends StatelessWidget {
  const _RefractedRim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: capsuleRimSigma,
              sigmaY: capsuleRimSigma,
              tileMode: TileMode.clamp,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      child,
    ],
  );
}

/// The capsule fill over content: opaque inside, translucent on the rim.
class _RimFillPainter extends CustomPainter {
  const _RimFillPainter(this.fill);
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rim = capsuleRim - 1;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final inner = outer.deflate(rim);
    canvas
      ..drawDRRect(
        outer,
        inner,
        Paint()..color = fill.withValues(alpha: capsuleRimFillAlpha),
      )
      ..drawRRect(inner, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_RimFillPainter old) => old.fill != fill;
}

/// Paints its child grown by [grow] pt on each side around its centre (the pressed toolbar
/// glass). Layout and hit testing are unchanged.
class ToolbarGrow extends SingleChildRenderObjectWidget {
  const ToolbarGrow({super.key, required this.grow, super.child});

  /// Points added on each side; 0 at rest.
  final double grow;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGrow(grow);

  @override
  void updateRenderObject(BuildContext context, _RenderGrow renderObject) =>
      renderObject.grow = grow;
}

class _RenderGrow extends RenderProxyBox {
  _RenderGrow(this._grow);

  double _grow;
  double get grow => _grow;
  set grow(double value) {
    if (value == _grow) return;
    _grow = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final w = size.width, h = size.height;
    if (_grow == 0 || w <= 0 || h <= 0) return super.paint(context, offset);
    final sx = (w + 2 * _grow) / w, sy = (h + 2 * _grow) / h;
    final transform = Matrix4.identity()
      ..translateByDouble(w / 2, h / 2, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-w / 2, -h / 2, 0, 1);
    context.pushTransform(needsCompositing, offset, transform, super.paint);
  }
}

class _CapsuleSlot extends InheritedWidget {
  const _CapsuleSlot({
    required this.capsule,
    required this.index,
    required this.shape,
    required this.highlighted,
    required this.pressed,
    required this.held,
    required this.instant,
    required super.child,
  });

  final _ToolbarCapsuleState capsule;
  final int index;

  /// Null: the only segment, lit as a whole (the capsule inset by 1 pt, Search 36 × 34).
  final ToolbarHighlight? shape;

  /// Under the pointer (hovering, or held over it).
  final bool highlighted;

  /// Held over this segment.
  final bool pressed;

  /// The capsule is held (enabled icons lose a little contrast).
  final bool held;

  /// The highlight jumps instead of fading (while held, or with reduced motion).
  final bool instant;

  static _CapsuleSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CapsuleSlot>();

  @override
  bool updateShouldNotify(_CapsuleSlot old) =>
      old.capsule != capsule ||
      old.index != index ||
      old.shape != shape ||
      old.highlighted != highlighted ||
      old.pressed != pressed ||
      old.held != held ||
      old.instant != instant;
}

/// A capsule segment: `width` wide, with the icon drawn in the color it receives. It must be a
/// child of a [ToolbarCapsule], which tracks the pointer for it.
///
/// The highlight ([ToolbarHighlight]) fades in under the pointer and darkens on press; the
/// chosen segment always keeps the selection pill. Disabled: no highlight, no action (the press
/// growth and the glow still show).
/// The click acts on release; with [onLongPress] or [onLongPressMenu], held for
/// [toolbarLongPress] it opens the menu and the release no longer acts. [onPress] acts on press
/// (buttons with a menu).
class ToolbarSegment extends StatefulWidget {
  const ToolbarSegment({
    super.key,
    required this.icon,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onLongPressMenu,
    this.width = 38,
    this.chosen = false,
    this.enabled = true,
  });

  final Widget Function(Color color) icon;
  final VoidCallback? onTap;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;

  /// Like [onLongPress], with the global rect of the segment across the full capsule height:
  /// the history menu of Back / Forward opens below it (`rect.bottomLeft`).
  final ValueChanged<Rect>? onLongPressMenu;
  final double width;
  final bool chosen;
  final bool enabled;

  @override
  State<ToolbarSegment> createState() => _ToolbarSegmentState();
}

class _ToolbarSegmentState extends State<ToolbarSegment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: ToolbarGlassMetrics.hoverFade,
  );
  _ToolbarCapsuleState? _capsule;
  int? _index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final slot = _CapsuleSlot.maybeOf(context);
    if (slot?.capsule != _capsule || slot?.index != _index) {
      if (_index != null) _capsule?._unregister(_index!, this);
      _capsule = slot?.capsule;
      _index = slot?.index;
      if (_index != null) _capsule?._register(_index!, this);
    }
    final on = (slot?.highlighted ?? false) && widget.enabled;
    final target = on ? 1.0 : 0.0;
    if (_fade.value == target && !_fade.isAnimating) return;
    if (slot?.instant ?? true) {
      _fade.value = target;
    } else if (on) {
      _fade.forward();
    } else {
      _fade.reverse();
    }
  }

  @override
  void didUpdateWidget(ToolbarSegment old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) _fade.value = 0;
  }

  @override
  void dispose() {
    if (_index != null) _capsule?._unregister(_index!, this);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ToolbarColors.of(context);
    final active = ToolbarScope.maybeOf(context)?.active ?? true;
    final slot = _CapsuleSlot.maybeOf(context);
    final enabled = widget.enabled;
    final chosen = widget.chosen;
    final shape = slot?.shape;
    final pillWidth = switch (shape) {
      null => widget.width - 2,
      ToolbarHighlight.circle => ToolbarGlassMetrics.hoverDiameter,
      ToolbarHighlight.selection => math.max(
        ToolbarGlassMetrics.pillHeight,
        widget.width - ToolbarGlassMetrics.selectionInset,
      ),
    };
    final pillHeight = shape == null
        ? toolbarCapsuleHeight - 4
        : ToolbarGlassMetrics.pillHeight;
    final highlighted = (slot?.highlighted ?? false) && enabled;
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final rest = !enabled
            ? null
            : chosen
            ? (active ? colors.chosen : colors.chosenInactive)
            : null;
        final hover = chosen
            ? (active ? colors.chosenHover : colors.chosenHoverInactive)
            : (active ? colors.hover : colors.hoverInactive);
        final t = _fade.value;
        final Color? pill = !enabled
            ? null
            : (slot?.pressed ?? false)
            ? (chosen ? colors.chosenPressed : colors.pressed)
            : t > 0
            ? Color.lerp(rest ?? hover.withValues(alpha: 0), hover, t)
            : rest;
        final glyph = !enabled
            ? colors.iconDisabled
            : (slot?.held ?? false)
            ? colors.iconPressed
            : (!active && !highlighted)
            ? colors.iconInactive
            : colors.icon;
        return SizedBox(
          width: widget.width,
          height: toolbarCapsuleHeight - 2,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (pill != null)
                OverflowBox(
                  maxWidth: double.infinity,
                  child: Container(
                    key: const ValueKey('pill'),
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: pill,
                      borderRadius: BorderRadius.circular(pillHeight / 2),
                    ),
                  ),
                ),
              widget.icon(glyph),
            ],
          ),
        );
      },
    );
  }
}
