// The push button inside a field (kit `Fields/Inline Button`, which nests
// `Buttons/Push/Secondary/Small`): a 24 pt `Surface/Control` capsule with a 1 pt `Line/Border`,
// the `Shadow/Soft` lift and a Label text.
//
// Stand-in: it draws the small secondary push button itself until the buttons family lands;
// then it should become that button (same look and behaviour).

import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import 'surface.dart';

/// The measures of [AmalfiInlineButton] (`Buttons/Push/Secondary/Small`).
abstract final class AmalfiInlineButtonMetrics {
  /// The height.
  static const double height = 24;

  /// The space on each side of the label.
  static const double padding = 8;
}

/// A small secondary push button for the end of a field ("Browse", "Choose…").
///
/// [onPressed] runs on a click, or on Space / Enter while the button has the keyboard focus;
/// null disables it (`Surface/Sunken`, tertiary label).
class AmalfiInlineButton extends StatefulWidget {
  const AmalfiInlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  State<AmalfiInlineButton> createState() => _AmalfiInlineButtonState();
}

class _AmalfiInlineButtonState extends State<AmalfiInlineButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final enabled = _enabled;
    const radius = AmalfiInlineButtonMetrics.height / 2;
    final face = DecoratedBox(
      decoration: ShapeDecoration(
        color: !enabled
            ? colors.surfaceSunken
            : _pressed
            ? colors.surfaceControlPressed
            : colors.surfaceControl,
        shape: AmalfiSmoothBorder(
          radius: radius,
          side: enabled
              ? BorderSide(
                  color: colors.lineBorder,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : BorderSide.none,
        ),
        shadows: enabled
            ? [
                BoxShadow(
                  color: colors.shadowSoft,
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: AmalfiInlineButtonMetrics.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmalfiInlineButtonMetrics.padding,
          ),
          child: Center(
            widthFactor: 1,
            child: SizedBox(
              height: AmalfiType.labelToken.lineHeight,
              child: AmalfiWholePoints(
                step: AmalfiGrid.base,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: AmalfiType.label(
                    color: enabled ? colors.textPrimary : colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: widget.focusNode,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _activate(),
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: enabled
                ? (_) {
                    setState(() => _pressed = false);
                    _activate();
                  }
                : null,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                face,
                Positioned.fill(
                  child: AmalfiFocusHalo(
                    radius: radius,
                    color: colors.lineFocus,
                    visible: _focused && enabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
