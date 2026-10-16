// What the linear and the circular slider share: the value as a fraction, the interaction
// states, the keyboard, the semantics and the lens animation (`motion.md`: the lens grows in
// with `spring.snappy`, follows the pointer 1:1 and fades out with `fade.quick`).

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../tokens.g.dart';

/// The settings common to the Amalfi sliders.
abstract class AmalfiSliderBase extends StatefulWidget {
  const AmalfiSliderBase({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticLabel,
  }) : assert(divisions == null || divisions > 0);

  /// The value, between [min] and [max] (clamped when drawn).
  final double value;

  /// Called with the new value while the user changes it; null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called with the value when the user starts changing it (pointer down, or a key).
  final ValueChanged<double>? onChangeStart;

  /// Called with the value when the user stops changing it.
  final ValueChanged<double>? onChangeEnd;

  /// The smallest value.
  final double min;

  /// The largest value.
  final double max;

  /// The number of equal steps between [min] and [max]; null: continuous.
  final int? divisions;

  /// The focus node; null: the slider makes its own.
  final FocusNode? focusNode;

  /// Whether the slider takes the focus when it first appears.
  final bool autofocus;

  /// Holds the interaction states ([WidgetState.hovered], `pressed`, `dragged`, `focused`);
  /// set states in it to show them without a pointer. Null: the slider keeps its own.
  final WidgetStatesController? statesController;

  /// What the slider sets, for screen readers.
  final String? semanticLabel;

  /// Whether the user can change the value.
  bool get enabled => onChanged != null;
}

/// The state shared by the Amalfi sliders: subclasses map pointer positions to fractions and
/// draw the face from [fraction], [states], [lensGrowth] and [lensOpacity].
abstract class AmalfiSliderBaseState<T extends AmalfiSliderBase>
    extends State<T>
    with TickerProviderStateMixin<T> {
  WidgetStatesController? _ownStates;

  /// The controller of the interaction states in use.
  WidgetStatesController get statesController =>
      widget.statesController ?? (_ownStates ??= WidgetStatesController());

  late final AnimationController _growth = AnimationController.unbounded(
    vsync: this,
  )..addListener(_repaint);
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    duration: AmalfiFades.quick.duration,
  )..addListener(_repaint);

  /// How far the lens has grown from the thumb (0) to its full size (1); may overshoot.
  double get lensGrowth => _growth.value.clamp(0.0, 1.2);

  /// The opacity of the lens.
  double get lensOpacity =>
      AmalfiFades.quick.curve.transform(_opacity.value.clamp(0.0, 1.0));

  /// The pointer is down on the slider.
  bool _active = false;

  void _repaint() => setState(() {});

  @override
  void initState() {
    super.initState();
    statesController.addListener(_repaint);
    final states = statesController.value;
    if (states.contains(WidgetState.dragged)) {
      _growth.value = 1;
      _opacity.value = 1;
    }
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    if (old.statesController != widget.statesController) {
      (old.statesController ?? _ownStates)?.removeListener(_repaint);
      if (widget.statesController != null) {
        _ownStates?.dispose();
        _ownStates = null;
      }
      statesController.addListener(_repaint);
    }
    if (!widget.enabled && _active) handleUp();
  }

  @override
  void dispose() {
    statesController.removeListener(_repaint);
    _ownStates?.dispose();
    _growth.dispose();
    _opacity.dispose();
    super.dispose();
  }

  /// The interaction states shown: the controller's, or only [WidgetState.disabled] when
  /// the slider is disabled.
  Set<WidgetState> get states =>
      widget.enabled ? statesController.value : const {WidgetState.disabled};

  void _set(WidgetState state, bool on) {
    if (statesController.value.contains(state) == on) return;
    statesController.update(state, on);
  }

  /// The value as a fraction of the range, 0–1.
  double get fraction {
    final span = widget.max - widget.min;
    if (!span.isFinite || span <= 0 || !widget.value.isFinite) return 0;
    return ((widget.value - widget.min) / span).clamp(0.0, 1.0);
  }

  /// [f] snapped to the divisions, as a value of the range.
  double valueOf(double f) {
    var t = f.isFinite ? f.clamp(0.0, 1.0) : 0.0;
    final d = widget.divisions;
    if (d != null) t = (t * d).roundToDouble() / d;
    return widget.min + t * (widget.max - widget.min);
  }

  void _emit(double f) {
    final v = valueOf(f);
    if (v != widget.value) widget.onChanged?.call(v);
  }

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  // Pointer.

  /// The fraction under [local] (a position in the slider), or null to keep the value.
  /// [grab] is the offset of the pointer from the thumb's centre when the press started on
  /// the thumb (zero otherwise).
  double? fractionAt(Offset local, {required Offset grab});

  /// The centre of the thumb, in the slider's coordinates.
  Offset get thumbCentre;

  /// The radius around the thumb's centre where a press grabs the thumb.
  double get grabRadius => 14;

  Offset _grab = Offset.zero;
  Offset _downAt = Offset.zero;

  /// How far the pointer moves before a press becomes a drag (and the lens grows in).
  static const double dragSlop = 2;

  /// Pointer down at [local].
  void handleDown(Offset local) {
    if (!widget.enabled) return;
    _active = true;
    _downAt = local;
    _set(WidgetState.pressed, true);
    widget.onChangeStart?.call(widget.value);
    final fromThumb = local - thumbCentre;
    if (fromThumb.distance <= grabRadius) {
      _grab = fromThumb;
    } else {
      _grab = Offset.zero;
      final f = fractionAt(local, grab: Offset.zero);
      if (f != null) _emit(f);
    }
  }

  /// The drag started (past [dragSlop]): the lens grows in.
  void _startDrag() {
    _set(WidgetState.dragged, true);
    _opacity.stop();
    if (_reducedMotion) {
      _growth.value = 1;
      _opacity.forward();
      return;
    }
    _opacity.value = 1;
    _growth.animateWith(
      SpringSimulation(
        AmalfiSprings.snappy,
        _growth.value,
        1,
        _growth.velocity,
      ),
    );
  }

  /// The pointer moved to [local] while dragging.
  void handleDragUpdate(Offset local) {
    if (!_active) return;
    if (!states.contains(WidgetState.dragged) &&
        (local - _downAt).distance >= dragSlop) {
      _startDrag();
    }
    final f = fractionAt(local, grab: _grab);
    if (f != null) _emit(f);
  }

  /// The pointer went up or the gesture was cancelled: the lens fades out.
  void handleUp() {
    if (!_active) return;
    _active = false;
    _set(WidgetState.pressed, false);
    if (states.contains(WidgetState.dragged)) {
      _set(WidgetState.dragged, false);
      _opacity.reverse().whenCompleteOrCancel(() {
        if (mounted && _opacity.value == 0) _growth.value = 0;
      });
    }
    widget.onChangeEnd?.call(widget.value);
  }

  /// Whether the lens is to be drawn.
  bool get showsLens => lensOpacity > 0 && lensGrowth > 0;

  // Keyboard.

  double get _step {
    final d = widget.divisions;
    return d != null ? 1 / d : 0.05;
  }

  void _key(double Function(double fraction) next) {
    if (!widget.enabled) return;
    widget.onChangeStart?.call(widget.value);
    _emit(next(fraction));
    widget.onChangeEnd?.call(valueOf(next(fraction)));
  }

  /// Increases the value by one step (an arrow key).
  void increase() => _key((f) => f + _step);

  /// Decreases the value by one step.
  void decrease() => _key((f) => f - _step);

  /// The shortcuts of a slider; [rtl] swaps left and right.
  Map<ShortcutActivator, Intent> shortcuts({required bool rtl}) => {
    const SingleActivator(LogicalKeyboardKey.arrowUp): const _Adjust(1),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const _Adjust(-1),
    const SingleActivator(LogicalKeyboardKey.arrowRight): _Adjust(rtl ? -1 : 1),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): _Adjust(rtl ? 1 : -1),
    const SingleActivator(LogicalKeyboardKey.home): const _Jump(0),
    const SingleActivator(LogicalKeyboardKey.end): const _Jump(1),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _Adjust: CallbackAction<_Adjust>(
      onInvoke: (i) => i.direction > 0 ? increase() : decrease(),
    ),
    _Jump: CallbackAction<_Jump>(onInvoke: (i) => _key((_) => i.fraction)),
  };

  String _percent(double f) => '${(f.clamp(0.0, 1.0) * 100).round()}%';

  /// Wraps [face] with focus, hover, keyboard, pointer and semantics.
  ///
  /// [face] is the drawing; the gestures are handed positions in its coordinates.
  Widget interactive({required Widget face, required bool rtl}) {
    final enabled = widget.enabled;
    final f = fraction;
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      enabled: enabled,
      value: _percent(f),
      increasedValue: enabled ? _percent(f + _step) : null,
      decreasedValue: enabled ? _percent(f - _step) : null,
      onIncrease: enabled ? increase : null,
      onDecrease: enabled ? decrease : null,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        shortcuts: shortcuts(rtl: rtl),
        actions: _actions,
        onShowFocusHighlight: (v) => _set(WidgetState.focused, v),
        onShowHoverHighlight: (v) => _set(WidgetState.hovered, v && enabled),
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: enabled ? (d) => handleDown(d.localPosition) : null,
            onPanUpdate: enabled
                ? (d) => handleDragUpdate(d.localPosition)
                : null,
            onPanEnd: enabled ? (_) => handleUp() : null,
            onPanCancel: enabled ? handleUp : null,
            child: face,
          ),
        ),
      ),
    );
  }
}

class _Adjust extends Intent {
  const _Adjust(this.direction);
  final int direction;
}

class _Jump extends Intent {
  const _Jump(this.fraction);
  final double fraction;
}
