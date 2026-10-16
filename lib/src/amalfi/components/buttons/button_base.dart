// The interaction shared by every Amalfi button: pointer hover and press, keyboard focus and
// activation, semantics, and the hover/press transitions of `motion.md` ("Push / icon buttons:
// hover / press: overlay `fade.quick` in, 60 ms out").
//
// Exported for [AmalfiButtonPreview] only; the rest is what the buttons of this family are
// built on.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../tokens.g.dart';

/// How long the hover and press looks take to go away (`motion.md`: 60 ms out).
const Duration amalfiButtonFadeOut = Duration(milliseconds: 60);

/// What a button looks like at one moment: whether it is enabled and focused, and how far
/// its hover and press looks are faded in (0–1).
@immutable
class AmalfiButtonVisual {
  const AmalfiButtonVisual({
    required this.enabled,
    this.hover = 0,
    this.press = 0,
    this.focused = false,
  });

  /// A resting, enabled button.
  static const AmalfiButtonVisual rest = AmalfiButtonVisual(enabled: true);

  final bool enabled;

  /// How far the hover look is shown.
  final double hover;

  /// How far the press look is shown.
  final double press;

  /// Whether the keyboard focus halo is shown.
  final bool focused;

  /// Whether the pointer is over the button (the hover look is at least half in).
  bool get hovered => hover >= 0.5;

  /// Whether the button is held down (the press look is at least half in).
  bool get pressed => press >= 0.5;
}

/// [a] faded into [b] by [t]: exactly [a] at 0 and exactly [b] at 1.
Color? lerpButtonColor(Color? a, Color? b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  return Color.lerp(a, b, t);
}

/// A state an [AmalfiButtonPreview] shows.
enum AmalfiButtonPreviewState {
  /// As if the pointer were over the button.
  hover,

  /// As if the button were held down.
  pressed,

  /// As if the button had the keyboard focus.
  focused,
}

/// Shows the Amalfi buttons below it in [state] without any input: for galleries, previews
/// and screenshots. The buttons still work; only their look is forced (an enabled button;
/// a disabled one keeps its disabled look).
class AmalfiButtonPreview extends InheritedWidget {
  const AmalfiButtonPreview({
    super.key,
    required this.state,
    required super.child,
  });

  final AmalfiButtonPreviewState state;

  /// The state forced above [context]; null: none.
  static AmalfiButtonPreviewState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmalfiButtonPreview>()?.state;

  @override
  bool updateShouldNotify(AmalfiButtonPreview old) => old.state != state;
}

/// A button's behaviour: calls [onPressed] on a click (pointer down and up inside) or when
/// focused and Space or Return is pressed, tracks hover and press with the Amalfi fades, shows
/// the focus halo only for keyboard focus, and reports itself as a button to screen readers.
///
/// [onPressed] null disables it: no hover, press or focus. [pressed] forces the press look
/// (a pop-up button while its menu is open). A click does not move the keyboard focus, as on
/// the desktop.
class AmalfiButtonBehavior extends StatefulWidget {
  const AmalfiButtonBehavior({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.pressed = false,
    this.mouseCursor = SystemMouseCursors.basic,
    this.onPressedDown,
  });

  /// Called when the button is activated; null disables it.
  final VoidCallback? onPressed;

  /// Called when the pointer goes down on the button (a pull-down opens its menu then).
  final VoidCallback? onPressedDown;

  /// Builds the button for a [AmalfiButtonVisual].
  final Widget Function(BuildContext context, AmalfiButtonVisual visual)
  builder;

  /// What screen readers announce; null: the text below.
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  /// Forces the press look.
  final bool pressed;

  /// The pointer over the enabled button.
  final MouseCursor mouseCursor;

  @override
  State<AmalfiButtonBehavior> createState() => _AmalfiButtonBehaviorState();
}

class _AmalfiButtonBehaviorState extends State<AmalfiButtonBehavior>
    with TickerProviderStateMixin {
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: AmalfiFades.quick.duration,
    reverseDuration: amalfiButtonFadeOut,
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AmalfiFades.quick.duration,
    reverseDuration: amalfiButtonFadeOut,
    value: widget.pressed ? 1 : 0,
  );
  late final Animation<double> _hoverCurve = CurvedAnimation(
    parent: _hover,
    curve: AmalfiFades.quick.curve,
  );
  late final Animation<double> _pressCurve = CurvedAnimation(
    parent: _press,
    curve: AmalfiFades.quick.curve,
  );

  bool _hovering = false;
  bool _down = false;
  bool _focusHighlight = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(AmalfiButtonBehavior old) {
    super.didUpdateWidget(old);
    if (!_enabled) {
      _down = false;
      _focusHighlight = false;
      _hover.value = 0;
    }
    _updatePress();
  }

  @override
  void dispose() {
    _hover.dispose();
    _press.dispose();
    super.dispose();
  }

  void _updatePress() {
    final on = _enabled && (_down || widget.pressed);
    if (on && _press.status != AnimationStatus.forward && _press.value < 1) {
      _press.forward();
    } else if (!on &&
        _press.status != AnimationStatus.reverse &&
        _press.value > 0) {
      _press.reverse();
    }
  }

  void _onState(AmalfiInteractionState state) {
    _hovering = state.hovered;
    if (state.hovered && _enabled) {
      _hover.forward();
    } else {
      _hover.reverse();
    }
    if (state.focused != _focusHighlight) {
      setState(() => _focusHighlight = state.focused);
    }
    if (state.pressed != _down) {
      setState(() => _down = state.pressed);
      _updatePress();
    }
  }

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        onTap: enabled ? _activate : null,
        child: AmalfiInteraction(
          onActivate: enabled ? _activate : null,
          onPressDown: widget.onPressedDown,
          onStateChanged: _onState,
          activators: AmalfiInteraction.buttonActivates,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          cursor: widget.mouseCursor,
          builder: (context, _) => AnimatedBuilder(
            animation: Listenable.merge([_hoverCurve, _pressCurve]),
            builder: (context, _) {
              final preview = AmalfiButtonPreview.of(context);
              final built = widget.builder(
                context,
                AmalfiButtonVisual(
                  enabled: enabled,
                  hover: !enabled
                      ? 0
                      : preview == AmalfiButtonPreviewState.hover
                      ? 1
                      : _hoverCurve.value,
                  press: !enabled
                      ? 0
                      : preview == AmalfiButtonPreviewState.pressed
                      ? 1
                      : _pressCurve.value,
                  focused:
                      enabled &&
                      (_focusHighlight ||
                          preview == AmalfiButtonPreviewState.focused),
                ),
              );
              // The semantic label replaces the text drawn in the button.
              return widget.semanticLabel == null
                  ? built
                  : ExcludeSemantics(child: built);
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('hovering', value: _hovering, ifTrue: 'hovering'))
      ..add(FlagProperty('down', value: _down, ifTrue: 'down'));
  }
}
