// The Amalfi disclosure controls (kit `Disclosure/Triangle/*`, `Disclosure/Button/*`): a
// chevron that shows whether a section is collapsed or expanded, turning between the two on
// `spring.snappy`.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../foundation/foundation.dart';

/// The measures of the disclosure controls, from `Disclosure/*`.
abstract final class AmalfiDisclosureMetrics {
  /// The side of a triangle or button.
  static const double side = 24;

  /// The side of the chevron, centred.
  static const double glyph = 12;

  /// The corner radius of the triangle's hover and press background.
  static const double triangleRadius = 7;

  /// The corner radius of the disclosure button.
  static const double buttonRadius = 11;
}

/// The two looks of a disclosure control.
enum AmalfiDisclosureStyle {
  /// A bare chevron pointing right (collapsed) or down (expanded), with a background only
  /// while hovered or pressed (`Disclosure/Triangle`).
  triangle,

  /// A raised round button with a chevron pointing down (collapsed) or up (expanded)
  /// (`Disclosure/Button`).
  button,
}

/// The look of a disclosure control in a given state, without any interaction. [turn]
/// (0 collapsed → 1 expanded) turns the chevron; null: from [expanded].
///
/// [AmalfiDisclosure] draws this; use it directly only to show a state statically.
class AmalfiDisclosureFace extends StatelessWidget {
  const AmalfiDisclosureFace({
    super.key,
    required this.expanded,
    this.style = AmalfiDisclosureStyle.triangle,
    this.state = const AmalfiInteractionState(),
    this.turn,
  });

  final bool expanded;
  final AmalfiDisclosureStyle style;
  final AmalfiInteractionState state;

  /// How far the chevron has turned towards expanded, 0–1; null: at rest.
  final double? turn;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = state.enabled;
    final pressed = enabled && state.pressed;
    final hovered = enabled && state.hovered && !pressed;
    final t = turn ?? (expanded ? 1.0 : 0.0);
    final button = style == AmalfiDisclosureStyle.button;
    final radius = button
        ? AmalfiDisclosureMetrics.buttonRadius
        : AmalfiDisclosureMetrics.triangleRadius;

    final Color? fill;
    var side = BorderSide.none;
    var shadows = const <BoxShadow>[];
    if (button) {
      if (!enabled) {
        fill = colors.surfaceSunken;
      } else {
        fill = pressed ? colors.surfaceControlPressed : colors.surfaceControl;
        side = BorderSide(color: colors.lineBorder);
        shadows = amalfiControlShadows(colors);
      }
    } else {
      fill = pressed
          ? colors.surfaceControlPressed
          : hovered
          ? colors.accentAmalfiSoft
          : null;
    }
    final glyphColor = !enabled
        ? colors.textTertiary
        : button || pressed || hovered
        ? colors.textPrimary
        : colors.textSecondary;
    final inset =
        (AmalfiDisclosureMetrics.side - AmalfiDisclosureMetrics.glyph) / 2;

    return SizedBox.square(
      dimension: AmalfiDisclosureMetrics.side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: AmalfiLayerKeys.body,
              decoration: AmalfiShapeDecoration(
                color: fill,
                shape: AmalfiSmoothBorder(radius: radius, side: side),
                shadows: shadows,
              ),
            ),
          ),
          if (button && hovered)
            Positioned.fill(
              child: DecoratedBox(
                key: AmalfiLayerKeys.state,
                decoration: AmalfiShapeDecoration(
                  color: colors.accentAmalfiSoft,
                  shape: AmalfiSmoothBorder(radius: radius),
                ),
              ),
            ),
          if (state.focused && enabled)
            Positioned.fill(child: AmalfiFocusHalo(radius: radius)),
          Positioned(
            left: inset,
            top: inset,
            child: AmalfiGlyph(
              key: AmalfiLayerKeys.mark,
              button ? AmalfiGlyphs.chevronDown : AmalfiGlyphs.chevronRight,
              size: AmalfiDisclosureMetrics.glyph,
              color: glyphColor,
              // Right → down is a quarter turn; down → up a half turn.
              turns: t * (button ? 0.5 : 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns [expanded] into an animated turn of the chevron (`spring.snappy`).
mixin _DisclosureTurn<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController turn = AnimationController.unbounded(
    vsync: this,
    value: expandedNow ? 1 : 0,
  );

  /// The current value of the widget's `expanded`.
  bool get expandedNow;

  void retarget() {
    final target = expandedNow ? 1.0 : 0.0;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      turn.value = target;
      return;
    }
    turn
        .animateWith(
          SpringSimulation(AmalfiSprings.snappy, turn.value, target, 0),
        )
        .then((_) {
          if (mounted) turn.value = target;
        });
  }

  @override
  void dispose() {
    turn.dispose();
    super.dispose();
  }
}

/// A disclosure control: a chevron for a section that is [expanded] or collapsed.
///
/// A click or Space calls [onChanged] with the other value; with [onChanged] null it is
/// disabled. The chevron turns with `spring.snappy`. [style] picks the bare triangle or the
/// round button.
class AmalfiDisclosure extends StatefulWidget {
  const AmalfiDisclosure({
    super.key,
    required this.expanded,
    required this.onChanged,
    this.style = AmalfiDisclosureStyle.triangle,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool expanded;

  /// Called with the new value; null: disabled.
  final ValueChanged<bool>? onChanged;

  final AmalfiDisclosureStyle style;

  /// The name of the section for screen readers.
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AmalfiDisclosure> createState() => _AmalfiDisclosureState();
}

class _AmalfiDisclosureState extends State<AmalfiDisclosure>
    with SingleTickerProviderStateMixin, _DisclosureTurn {
  @override
  bool get expandedNow => widget.expanded;

  @override
  void didUpdateWidget(AmalfiDisclosure old) {
    super.didUpdateWidget(old);
    if (old.expanded != widget.expanded) retarget();
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    final activate = onChanged == null
        ? null
        : () => onChanged(!widget.expanded);
    return Semantics(
      button: true,
      expanded: widget.expanded,
      enabled: onChanged != null,
      label: widget.semanticLabel,
      onTap: activate,
      child: ExcludeSemantics(
        child: AmalfiInteraction(
          onActivate: activate,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          builder: (context, state) => AnimatedBuilder(
            animation: turn,
            builder: (context, _) => AmalfiDisclosureFace(
              expanded: widget.expanded,
              style: widget.style,
              state: state,
              turn: turn.value,
            ),
          ),
        ),
      ),
    );
  }
}
