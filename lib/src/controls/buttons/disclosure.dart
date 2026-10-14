// The disclosure triangle (rows that open: list view nesting, "Other networks", Info sections)
// and the disclosure button (the Save card's ⌄ that shows more options).
//
// Measured: the triangle is a 5 × 8 chevron in a 15 pt box, and it turns at once on the click
// (one frame, no animation), mustache.md › MU-20 Nesting; the triangle acts on release (MU-25).
// The disclosure button is 26 × 26 in AX (24 × 24 visible), a rounded square, ⌄ collapsed and ∧
// expanded (dialogs.md › Save, CT-BTN-07). The chevron is `#bfbfbf` in light and `#808080` in
// dark (CT-BTN-06, INV-B gallery). Provisional: the disclosure button's corner radius.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'control_style.dart';
import 'push_button.dart';

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

  /// The chevron color in light and dark (CT-BTN-06).
  static const Color colorLight = Color(0xFFBFBFBF);
  static const Color colorDark = Color(0xFF808080);

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
              : color ?? (colors.dark ? colorDark : colorLight);
          return FocusRing(
            visible: state.focused,
            kind: FocusRingKind.control,
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
          bezel: ButtonBezel.bevel,
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
