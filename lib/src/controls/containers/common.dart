// Helpers shared by the containers.

import 'package:flutter/widgets.dart';

import '../control_base.dart';
import '../../appearance.dart';

export '../control_base.dart';

/// Dark appearance, following the appearance in effect.
bool containerDark(BuildContext context) => SilicaAppearance.isDark(context);

/// The window state: `active` when given, otherwise [WindowActiveScope.of].
bool containerActive(BuildContext context, bool? active) =>
    active ?? WindowActiveScope.of(context);

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
      painter: ChevronPainter(
        open ? ChevronDirection.down : ChevronDirection.right,
        color,
      ),
    ),
  );
}
