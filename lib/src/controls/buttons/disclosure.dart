// The disclosure triangle (rows that open: list view nesting, "Other networks", Info sections)
// and the disclosure button (the Save card's ⌄ that shows more options).
//
// Measured: the triangle is a 5 × 8 chevron in a 15 pt box, and it turns at once on the click
// (one frame, no animation), mustache.md › MU-20 Nesting; the triangle acts on release (MU-25).
// The disclosure button is 26 × 26 in AX (24 × 24 visible), ⌄ collapsed and ∧ expanded
// (dialogs.md › Save). The triangle color is provisional (the list header's gray).

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'control_style.dart';
import 'push_button.dart';

/// Which way a chevron points.
enum ChevronDirection { up, down, left, right }

/// A stroked chevron that fills its box (`>` is `right`).
class ChevronPainter extends CustomPainter {
  const ChevronPainter(this.direction, this.color, {this.stroke = 1.5});

  final ChevronDirection direction;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = stroke / 2;
    final points = switch (direction) {
      ChevronDirection.right => [
        Offset(s, s),
        Offset(w - s, h / 2),
        Offset(s, h - s),
      ],
      ChevronDirection.left => [
        Offset(w - s, s),
        Offset(s, h / 2),
        Offset(w - s, h - s),
      ],
      ChevronDirection.down => [
        Offset(s, s),
        Offset(w / 2, h - s),
        Offset(w - s, s),
      ],
      ChevronDirection.up => [
        Offset(s, h - s),
        Offset(w / 2, s),
        Offset(w - s, h - s),
      ],
    };
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ChevronPainter old) =>
      old.direction != direction || old.color != color || old.stroke != stroke;
}

/// The disclosure triangle: a chevron pointing right when closed and down when open. It turns at
/// once on release; Space toggles it with the keyboard focus, → opens and ← closes.
class DisclosureTriangle extends StatelessWidget {
  const DisclosureTriangle({
    super.key,
    required this.expanded,
    required this.onChanged,
    this.semanticLabel,
    this.color,
    this.focusNode,
  });

  final bool expanded;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  /// The chevron color (default: the system gray).
  final Color? color;
  final FocusNode? focusNode;

  /// The box (measured: 15 pt wide).
  static const double side = 15;

  /// The chevron (measured: 5 × 8 pointing right).
  static const Size chevron = Size(5, 8);

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      button: true,
      expanded: expanded,
      enabled: onChanged != null,
      label: semanticLabel,
      child: ControlInteraction(
        enabled: onChanged != null,
        onActivate: onChanged == null ? null : () => onChanged(!expanded),
        focusNode: focusNode,
        onKey: (event) {
          if (!isKeyPress(event) || onChanged == null) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowRight && !expanded) {
            onChanged(true);
          } else if (key == LogicalKeyboardKey.arrowLeft && expanded) {
            onChanged(false);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        builder: (context, state) {
          final colors = ControlColors.of(context);
          final c = !state.enabled
              ? colors.textDisabled
              : state.pressed
              ? colors.glyphPressed
              : color ?? colors.glyph;
          return FocusRing(
            visible: state.focused,
            radius: 3,
            child: SizedBox.square(
              dimension: side,
              child: Center(
                // The turn is instant: one frame, no animation (MU-20).
                child: Transform.rotate(
                  angle: expanded ? math.pi / 2 : 0,
                  child: CustomPaint(
                    key: const ValueKey('disclosure chevron'),
                    size: chevron,
                    painter: ChevronPainter(ChevronDirection.right, c),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The disclosure button: a square push button with ⌄ (collapsed) or ∧ (expanded).
class DisclosureButton extends StatelessWidget {
  const DisclosureButton({
    super.key,
    required this.expanded,
    required this.onChanged,
    this.size = ControlSize.regular,
    this.semanticLabel,
    this.focusNode,
  });

  final bool expanded;
  final ValueChanged<bool>? onChanged;
  final ControlSize size;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final side = buttonHeight(size);
    return Semantics(
      button: true,
      expanded: expanded,
      enabled: onChanged != null,
      label: semanticLabel,
      child: ControlInteraction(
        enabled: onChanged != null,
        onActivate: onChanged == null ? null : () => onChanged(!expanded),
        focusNode: focusNode,
        builder: (context, state) => ButtonFace(
          state: state,
          size: size,
          width: side,
          padding: EdgeInsets.zero,
          child: (color) => CustomPaint(
            key: const ValueKey('disclosure chevron'),
            // Provisional glyph: 9 × 5 at 24 pt.
            size: Size(side * 0.375, side * 0.21),
            painter: ChevronPainter(
              expanded ? ChevronDirection.up : ChevronDirection.down,
              color,
            ),
          ),
        ),
      ),
    );
  }
}
