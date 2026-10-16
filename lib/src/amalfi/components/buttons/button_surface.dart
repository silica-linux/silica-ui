// The layers of an Amalfi button, as the kit stacks them: Background (an opaque fill with
// border and shadow, or glass), State (the hover or press overlay), Focus Halo, then the
// content. Not exported.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../glass.dart';
import '../../smooth_border.dart';
import '../../token_types.dart';
import '../../tokens.g.dart';
import 'button_base.dart';

/// The keys of the layers a [AmalfiButtonSurface] draws, to find them in tests.
abstract final class AmalfiButtonLayers {
  /// The background: a `DecoratedBox` or an `AmalfiGlass`.
  static const Key background = ValueKey('amalfi-button-background');

  /// The hover overlay.
  static const Key hover = ValueKey('amalfi-button-hover');

  /// The press overlay.
  static const Key press = ValueKey('amalfi-button-press');

  /// The keyboard focus halo (drawn by `AmalfiFocusHalo`).
  static const Key halo = AmalfiLayerKeys.focusHalo;
}

/// The colours and materials of one kind of button in one appearance, per state, from the
/// kit masters. A disabled button keeps its resting look and is drawn whole at
/// `AmalfiStates.disabledOpacity` (user decision 2026-10-16).
@immutable
class AmalfiButtonLook {
  const AmalfiButtonLook({
    this.fill,
    this.fillHovered,
    this.fillPressed,
    this.border,
    this.shadows = const [],
    this.hoverOverlay,
    this.pressOverlay,
    this.glass,
    this.glassActive,
    required this.content,
  });

  /// The background at rest; null: none.
  final Color? fill;

  /// The background while hovered; null: [fill].
  final Color? fillHovered;

  /// The background while pressed; null: [fill].
  final Color? fillPressed;

  /// The border of the background (`Line/Border`, 1 inside).
  final BorderSide? border;

  /// The drop shadows of the background.
  final List<BoxShadow> shadows;

  /// Drawn over the background while hovered (and not pressed).
  final Color? hoverOverlay;

  /// Drawn over the background while pressed.
  final Color? pressOverlay;

  /// A glass background instead of [fill]; [glassActive] while hovered or pressed.
  final AmalfiGlassMaterial? glass;
  final AmalfiGlassMaterial? glassActive;

  /// The colour of the label and glyph.
  final Color content;
}

/// The kit's opaque control background: `Surface/Control` with a 1 pt `Line/Border` inside
/// and the control shadow (`amalfiControlShadows`); `Surface/Control Pressed` when pressed. The hover overlay
/// is `Accent/Amalfi Soft`.
AmalfiButtonLook amalfiControlLook(AmalfiColors colors, {Color? content}) =>
    AmalfiButtonLook(
      fill: colors.surfaceControl,
      fillPressed: colors.surfaceControlPressed,
      border: BorderSide(
        color: colors.lineBorder,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
      shadows: amalfiControlShadows(colors),
      hoverOverlay: colors.accentAmalfiSoft,
      content: content ?? colors.textPrimary,
    );

/// [child] at `AmalfiStates.disabledOpacity` when [enabled] is false: the disabled look of
/// every control (user decision 2026-10-16).
class AmalfiDisabledOpacity extends StatelessWidget {
  const AmalfiDisabledOpacity({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => enabled
      ? child
      : Opacity(opacity: AmalfiStates.disabledOpacity, child: child);
}

/// An overlay of [color] in [shape], faded by [opacity].
class AmalfiButtonOverlay extends StatelessWidget {
  const AmalfiButtonOverlay({
    super.key,
    required this.layerKey,
    required this.color,
    required this.shape,
    required this.opacity,
  });

  final Key layerKey;
  final Color color;
  final ShapeBorder shape;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      key: layerKey,
      decoration: AmalfiShapeDecoration(color: color, shape: shape),
      child: const SizedBox.expand(),
    );
    return opacity >= 1 ? box : Opacity(opacity: opacity, child: box);
  }
}

/// A button's layers in [shape] for [visual], with [child] (the content) on top, sized by
/// [child].
class AmalfiButtonSurface extends StatelessWidget {
  const AmalfiButtonSurface({
    super.key,
    required this.look,
    required this.shape,
    required this.visual,
    required this.child,
    this.background = true,
    this.dimDisabled = true,
  });

  final AmalfiButtonLook look;
  final AmalfiSmoothBorder shape;
  final AmalfiButtonVisual visual;
  final Widget child;

  /// Whether to draw the background (false: a part of a larger control that draws it).
  final bool background;

  /// Whether a disabled [visual] dims the whole surface (false: a part of a larger control
  /// that dims itself).
  final bool dimDisabled;

  @override
  Widget build(BuildContext context) {
    final look = this.look;
    final press = visual.press;
    final hover = visual.hover * (1 - press);
    final glass = look.glass;
    Widget? back;
    if (background && glass != null) {
      final active = look.glassActive;
      back = AmalfiGlass(
        key: AmalfiButtonLayers.background,
        material: active != null && (visual.hovered || visual.pressed)
            ? active
            : glass,
        radius: shape.radius,
        kind: AmalfiGlassKind.control,
        child: const SizedBox.expand(),
      );
    } else if (background) {
      final hovered = lerpButtonColor(
        look.fill,
        look.fillHovered ?? look.fill,
        hover,
      );
      final fill = lerpButtonColor(
        hovered,
        look.fillPressed ?? look.fill,
        press,
      );
      back = DecoratedBox(
        key: AmalfiButtonLayers.background,
        decoration: AmalfiShapeDecoration(
          color: fill,
          shape: shape.copyWith(side: look.border ?? BorderSide.none),
          shadows: look.shadows.isNotEmpty ? look.shadows : null,
        ),
        child: const SizedBox.expand(),
      );
    }
    final hoverOverlay = look.hoverOverlay;
    final pressOverlay = look.pressOverlay;
    // Given more room than its content (a footer's minimum width), the content centres.
    final stack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (back != null) Positioned.fill(child: back),
        if (hoverOverlay != null && hover > 0)
          Positioned.fill(
            child: AmalfiButtonOverlay(
              layerKey: AmalfiButtonLayers.hover,
              color: hoverOverlay,
              shape: shape,
              opacity: hover,
            ),
          ),
        if (pressOverlay != null && press > 0)
          Positioned.fill(
            child: AmalfiButtonOverlay(
              layerKey: AmalfiButtonLayers.press,
              color: pressOverlay,
              shape: shape,
              opacity: press,
            ),
          ),
        if (visual.focused)
          Positioned.fill(child: AmalfiFocusHalo(shape: shape)),
        child,
      ],
    );
    return AmalfiDisabledOpacity(
      enabled: visual.enabled || !dimDisabled,
      child: stack,
    );
  }
}

/// [child] with the icon colour and size of a button's glyph.
class AmalfiButtonIconTheme extends StatelessWidget {
  const AmalfiButtonIconTheme({
    super.key,
    required this.color,
    required this.size,
    required this.child,
  });

  final Color color;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => IconTheme.merge(
    data: IconThemeData(color: color, size: size),
    child: SizedBox.square(
      dimension: size,
      child: Center(child: child),
    ),
  );
}
