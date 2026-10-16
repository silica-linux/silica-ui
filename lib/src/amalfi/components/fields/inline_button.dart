// The push button inside a field (kit `Fields/Inline Button`, which nests
// `Buttons/Push/Secondary/Small`): the buttons family's small secondary push button.

import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';
import '../buttons/push_button.dart';
import 'field_state.dart';

/// The measures of [AmalfiInlineButton] (`Buttons/Push/Secondary/Small`).
abstract final class AmalfiInlineButtonMetrics {
  /// The height.
  static const double height = 24;

  /// The space on each side of the label.
  static const double padding = 8;
}

/// A small secondary push button for the end of a field ("Browse", "Choose…"): an
/// [AmalfiPushButton] of [AmalfiControlSize.small].
///
/// [onPressed] runs on a click, or on Space / Return while the button has the keyboard
/// focus; null disables it. Inside a disabled field it keeps its rest look, dimmed once with
/// the whole field ([AmalfiFieldEnabledScope]), and takes no input.
class AmalfiInlineButton extends StatelessWidget {
  const AmalfiInlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  static void _inert() {}

  @override
  Widget build(BuildContext context) {
    if (AmalfiFieldEnabledScope.enabledOf(context)) {
      return AmalfiPushButton(
        label: label,
        onPressed: onPressed,
        size: AmalfiControlSize.small,
        focusNode: focusNode,
      );
    }
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: ExcludeFocus(
            child: AmalfiPushButton(
              label: label,
              onPressed: _inert,
              size: AmalfiControlSize.small,
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );
  }
}
