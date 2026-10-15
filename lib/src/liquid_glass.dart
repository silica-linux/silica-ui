// Liquid Glass: glass that reacts to touch. On press it swells with a spring, on
// release it comes back with a small bounce; a soft highlight follows the pointer. The swollen
// shape reaches the compositor too (the region follows the transforms), so the lens, the
// edge and the merging with nearby glass move with it.
//
// PROVISIONAL: press scale, springs and highlight are not measured on the reference yet
// (request G-01 of the observations). The values may change in a minor version; names and
// types may not.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'glass.dart';

/// How much pressed glass swells (provisional).
const double liquidPressScale = 1.08;

/// Press spring: fast and almost without bounce (provisional).
const SpringDescription liquidPressSpring = SpringDescription(
  mass: 1,
  stiffness: 600,
  damping: 40,
);

/// Release spring: a small bounce, like a liquid (provisional).
const SpringDescription liquidReleaseSpring = SpringDescription(
  mass: 1,
  stiffness: 350,
  damping: 18,
);

/// A Liquid Glass area that reacts to the pointer.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    this.radius = 0,
    this.material = GlassMaterial.regular,
    this.interactive = true,
    this.group = 0,
    this.tip,
    this.profile,
    this.profileShadow = false,
    this.child,
  });

  final double radius;
  final GlassMaterial material;

  /// Without interaction it is just a [Glass].
  final bool interactive;

  /// See [Glass.group] and [Glass.tip].
  final int group;
  final GlassTip? tip;

  /// See [Glass.profile] and [Glass.profileShadow].
  final GlassProfile? profile;
  final bool profileShadow;
  final Widget? child;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => setState(() {}));
  Offset? _pointer;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _springTo(double target, SpringDescription spring) {
    _press.animateWith(
      SpringSimulation(spring, _press.value, target, _press.velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = Glass(
      radius: widget.radius,
      material: widget.material,
      group: widget.group,
      tip: widget.tip,
      profile: widget.profile,
      profileShadow: widget.profileShadow,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (widget.child != null) widget.child!,
          if (widget.interactive && _pointer != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HighlightPainter(_pointer!, widget.radius),
                ),
              ),
            ),
        ],
      ),
    );
    if (!widget.interactive) return glass;
    final scale = 1 + (liquidPressScale - 1) * _press.value;
    return MouseRegion(
      onHover: (event) => setState(() => _pointer = event.localPosition),
      onExit: (_) => setState(() => _pointer = null),
      child: Listener(
        // The whole glass area responds, even where the child is transparent.
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _pointer = event.localPosition;
          _springTo(1, liquidPressSpring);
        },
        onPointerMove: (event) =>
            setState(() => _pointer = event.localPosition),
        onPointerUp: (_) => _springTo(0, liquidReleaseSpring),
        onPointerCancel: (_) => _springTo(0, liquidReleaseSpring),
        child: Transform.scale(scale: scale, child: glass),
      ),
    );
  }
}

/// Soft highlight around the pointer, stronger towards the edge (provisional).
class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.pointer, this.radius);

  final Offset pointer;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(shape);
    final reach = size.shortestSide;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x33FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromCircle(center: pointer, radius: reach));
    canvas.drawCircle(pointer, reach, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.pointer != pointer || old.radius != radius;
}
