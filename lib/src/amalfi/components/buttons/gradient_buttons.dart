// The add/remove pair under a list (kit `Buttons/Gradient/Add Remove/<state>`): one 56 × 24
// control, radius 7, split by a 1 × 12 divider into a "+" and a "−" button.

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'button_base.dart';
import 'button_surface.dart';

/// The measures of [AmalfiGradientButtons], from the kit masters.
abstract final class AmalfiGradientButtonsMetrics {
  /// The whole control.
  static const Size size = Size(56, 24);

  /// The corner radius.
  static const double radius = AmalfiRadii.smallControl;

  /// The glyph size.
  static const double glyph = AmalfiControlIcons.accessory;

  /// The divider between the two halves.
  static const Size divider = Size(1, 12);
}

/// The add and remove buttons under a list or table: a "+" and a "−" in one control with the
/// opaque control look.
///
/// Each half is its own button, with its own focus, hover and press: the hover overlay, the
/// pressed fill and the focus halo cover only that half, with the outer corners rounded. The
/// whole control is drawn at 35 % when both callbacks are null; a half without its callback
/// dims its glyph alone.
class AmalfiGradientButtons extends StatelessWidget {
  const AmalfiGradientButtons({
    super.key,
    required this.onAdd,
    required this.onRemove,
    this.addLabel = 'Add',
    this.removeLabel = 'Remove',
  });

  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  /// What screen readers announce for each half.
  final String addLabel;
  final String removeLabel;

  /// The key of the "+" half.
  static const Key addKey = ValueKey('amalfi-gradient-add');

  /// The key of the "−" half.
  static const Key removeKey = ValueKey('amalfi-gradient-remove');

  /// The key of the divider.
  static const Key dividerKey = ValueKey('amalfi-gradient-divider');

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final look = amalfiControlLook(colors);
    final enabled = onAdd != null || onRemove != null;
    const r = AmalfiGradientButtonsMetrics.radius;
    const size = AmalfiGradientButtonsMetrics.size;
    final half = Size(size.width / 2, size.height);
    final background = AmalfiButtonSurface(
      look: look,
      shape: const AmalfiSmoothBorder(radius: r),
      visual: AmalfiButtonVisual.rest,
      child: const SizedBox.shrink(),
    );
    final control = SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: background),
          Positioned(
            left: 0,
            top: 0,
            width: half.width,
            height: half.height,
            child: _Half(
              key: addKey,
              look: look,
              glyph: AmalfiGlyphs.plus,
              onPressed: onAdd,
              semanticLabel: addLabel,
              dim: enabled,
              shape: const AmalfiSmoothBorder.only(topLeft: r, bottomLeft: r),
            ),
          ),
          Positioned(
            left: half.width,
            top: 0,
            width: half.width,
            height: half.height,
            child: _Half(
              key: removeKey,
              look: look,
              glyph: AmalfiGlyphs.minus,
              onPressed: onRemove,
              semanticLabel: removeLabel,
              dim: enabled,
              shape: const AmalfiSmoothBorder.only(topRight: r, bottomRight: r),
            ),
          ),
          Positioned(
            key: dividerKey,
            left: half.width,
            top:
                (size.height - AmalfiGradientButtonsMetrics.divider.height) / 2,
            width: AmalfiGradientButtonsMetrics.divider.width,
            height: AmalfiGradientButtonsMetrics.divider.height,
            child: ColoredBox(color: colors.lineSeparator),
          ),
        ],
      ),
    );
    return AmalfiDisabledOpacity(enabled: enabled, child: control);
  }
}

class _Half extends StatelessWidget {
  const _Half({
    super.key,
    required this.look,
    required this.glyph,
    required this.onPressed,
    required this.semanticLabel,
    required this.shape,
    required this.dim,
  });

  final AmalfiButtonLook look;
  final AmalfiGlyphData glyph;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final AmalfiSmoothBorder shape;

  /// Whether this half dims itself when disabled (false: the whole control is dimmed).
  final bool dim;

  @override
  Widget build(BuildContext context) => AmalfiButtonBehavior(
    onPressed: onPressed,
    semanticLabel: semanticLabel,
    builder: (context, visual) {
      // The pressed fill stays inside the control's 1 pt border.
      final pressed = look.fillPressed;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (pressed != null && visual.press > 0)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: AmalfiButtonOverlay(
                  layerKey: AmalfiButtonLayers.press,
                  color: pressed,
                  shape: shape.inflateRadii(-1),
                  opacity: visual.press,
                ),
              ),
            ),
          Positioned.fill(
            child: AmalfiButtonSurface(
              look: look,
              shape: shape,
              visual: visual,
              background: false,
              dimDisabled: dim,
              child: Center(
                child: AmalfiButtonIconTheme(
                  color: look.content,
                  size: AmalfiGradientButtonsMetrics.glyph,
                  child: AmalfiGlyph(glyph),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
