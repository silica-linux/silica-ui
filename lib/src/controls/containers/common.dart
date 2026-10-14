// Helpers shared by the containers.

import 'package:flutter/widgets.dart';

import '../../window.dart';

/// Dark appearance, following the system (`MediaQuery.platformBrightness`).
bool containerDark(BuildContext context) =>
    MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;

/// The window state: `active` when given, otherwise the toolbar scope, otherwise active.
bool containerActive(BuildContext context, bool? active) =>
    active ?? ToolbarScope.maybeOf(context)?.active ?? true;

/// Inter from this package, with line height 1.
TextStyle containerText(double size, Color color, {FontWeight? weight}) =>
    TextStyle(
      fontFamily: 'Inter',
      package: 'silica_ui',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1,
    );

/// The width of a one-line text.
double containerTextWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// A chevron drawn with a round 1.5 pt stroke: `>` (right), `v` (down), `<`, `^`.
class ContainerChevron extends CustomPainter {
  const ContainerChevron(this.color, this.direction, {this.stroke = 1.5});
  final Color color;
  final AxisDirection direction;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, i = stroke / 2;
    final path = switch (direction) {
      AxisDirection.right =>
        Path()
          ..moveTo(i, i)
          ..lineTo(w - i, h / 2)
          ..lineTo(i, h - i),
      AxisDirection.left =>
        Path()
          ..moveTo(w - i, i)
          ..lineTo(i, h / 2)
          ..lineTo(w - i, h - i),
      AxisDirection.down =>
        Path()
          ..moveTo(i, i)
          ..lineTo(w / 2, h - i)
          ..lineTo(w - i, i),
      AxisDirection.up =>
        Path()
          ..moveTo(i, h - i)
          ..lineTo(w / 2, i)
          ..lineTo(w - i, h - i),
    };
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(ContainerChevron old) =>
      old.color != color || old.direction != direction || old.stroke != stroke;
}

/// The disclosure triangle of outlines and sidebars: › closed, ⌄ open (5 × 8, changes in one
/// frame, MU-20).
class OutlineTriangle extends StatelessWidget {
  const OutlineTriangle({super.key, required this.open, required this.color});
  final bool open;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: open ? 8 : 5,
    height: open ? 5 : 8,
    child: CustomPaint(
      painter: ContainerChevron(
        color,
        open ? AxisDirection.down : AxisDirection.right,
      ),
    ),
  );
}
