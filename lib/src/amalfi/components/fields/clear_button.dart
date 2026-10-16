// The clear button of a search field (kit `Fields/Clear Button`): a 16 pt `Text/Tertiary`
// disc with a 12 pt cross in the window colour.

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import 'glyph.dart';
import 'metrics.dart';

/// The button that empties a field: [onPressed] runs on a click.
///
/// It is not in the keyboard focus order (Esc clears a search field); screen readers see a
/// button named [semanticLabel].
class AmalfiClearButton extends StatefulWidget {
  const AmalfiClearButton({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Clear',
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  State<AmalfiClearButton> createState() => _AmalfiClearButtonState();
}

class _AmalfiClearButtonState extends State<AmalfiClearButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: enabled
                ? (_) {
                    setState(() => _pressed = false);
                    widget.onPressed?.call();
                  }
                : null,
            child: SizedBox.square(
              dimension: AmalfiFieldMetrics.clearButton,
              child: DecoratedBox(
                // Pressed: the disc darkens to Text/Secondary (assumption: the kit has
                // only the rest state).
                decoration: ShapeDecoration(
                  color: _pressed ? colors.textSecondary : colors.textTertiary,
                  shape: const AmalfiSmoothBorder(
                    radius: AmalfiFieldMetrics.clearRadius,
                  ),
                ),
                child: Center(
                  child: AmalfiGlyphIcon(
                    AmalfiGlyph.xmark,
                    size: AmalfiFieldMetrics.clearGlyph,
                    color: colors.surfaceWindow,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
