// The stepper (kit `Steppers/Stepper/<Mini|Small|Regular|Large>/*`): a small
// `Surface/Control` bezel split by a `Line/Separator` divider into an up and a down half,
// each with a 12 pt chevron. Hovering a half lays `Accent/Amalfi Soft` on it, pressing it
// `Surface/Control Pressed`; keyboard focus adds the halo; disabled is `Surface/Sunken`
// with `Text/Tertiary` chevrons. Holding a half repeats it.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../buttons/button_surface.dart' show amalfiControlShadows;
import '../sliders/thumb.dart' show AmalfiSliderFocusHalo;
import 'chevron.dart';

/// The measures of the steppers, from the kit masters `Steppers/Stepper/*`.
abstract final class AmalfiStepperMetrics {
  /// The bezel of [size]: 16 × 20, 20 × 24, 24 × 28, 28 × 32.
  static Size sizeOf(AmalfiControlSize size) =>
      Size(size.height - 4, size.height);

  /// The corner radius of [size].
  static double radiusOf(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini => 7,
    AmalfiControlSize.small => 8,
    AmalfiControlSize.regular => 9,
    AmalfiControlSize.large => 10,
  };

  /// Where the divider runs across a bezel of [size]: the middle on the 4 pt grid (12, 12,
  /// 16, 16), so the up half is the taller one in mini and regular.
  static double dividerOf(AmalfiControlSize size) =>
      AmalfiGrid.snap(size.height / 2);

  /// The divider is inset this much on each side.
  static const double dividerInset = 4;

  /// The chevrons, centred in their halves.
  static const double glyph = 12;

  /// The delay before a held half repeats, then the repeat interval (as `SilicaStepper`).
  static const Duration repeatDelay = Duration(milliseconds: 400);
  static const Duration repeatInterval = Duration(milliseconds: 80);
}

/// A stepper: the up half adds [step] to [value], the down half subtracts it, within [min]
/// and [max] (or around them with [wraps]). Holding a half repeats it after
/// [AmalfiStepperMetrics.repeatDelay]; with the keyboard focus, the up and down arrows step.
///
/// [onChanged] null disables it. A half that cannot step (at a limit) shows a dimmed
/// chevron and does not react.
class AmalfiStepper extends StatefulWidget {
  const AmalfiStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.wraps = false,
    this.size = AmalfiControlSize.regular,
    this.focusNode,
    this.autofocus = false,
    this.incrementStates,
    this.decrementStates,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final double step;

  /// Whether stepping past [max] goes to [min] and the other way round.
  final bool wraps;

  /// The control size.
  final AmalfiControlSize size;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The interaction states of the up half ([WidgetState.hovered], `pressed`; `focused`
  /// shows the halo); set states in it to show them without a pointer. Null: its own.
  final WidgetStatesController? incrementStates;

  /// The interaction states of the down half, as [incrementStates].
  final WidgetStatesController? decrementStates;

  /// What the stepper sets, for screen readers.
  final String? semanticLabel;

  @override
  State<AmalfiStepper> createState() => _AmalfiStepperState();
}

enum _Half { up, down }

class _AmalfiStepperState extends State<AmalfiStepper> {
  WidgetStatesController? _ownUp, _ownDown;
  bool _focusHighlight = false;

  /// The last value sent to `onChanged`, until the widget brings the new value (several
  /// steps can come between two frames: keys, repeats).
  double? _sent;
  double get _value => _sent ?? widget.value;
  Timer? _repeat;
  _Half? _held;

  WidgetStatesController get _up =>
      widget.incrementStates ?? (_ownUp ??= WidgetStatesController());
  WidgetStatesController get _down =>
      widget.decrementStates ?? (_ownDown ??= WidgetStatesController());
  WidgetStatesController _of(_Half h) => h == _Half.up ? _up : _down;

  @override
  void initState() {
    super.initState();
    _up.addListener(_repaint);
    _down.addListener(_repaint);
  }

  @override
  void didUpdateWidget(AmalfiStepper old) {
    super.didUpdateWidget(old);
    if (old.incrementStates != widget.incrementStates) {
      (old.incrementStates ?? _ownUp)?.removeListener(_repaint);
      _up.addListener(_repaint);
    }
    if (old.decrementStates != widget.decrementStates) {
      (old.decrementStates ?? _ownDown)?.removeListener(_repaint);
      _down.addListener(_repaint);
    }
    _sent = null;
    if (widget.onChanged == null) _release();
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _up.removeListener(_repaint);
    _down.removeListener(_repaint);
    _ownUp?.dispose();
    _ownDown?.dispose();
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  bool get _enabled => widget.onChanged != null;

  bool _can(_Half h) {
    if (!_enabled) return false;
    if (widget.wraps) return true;
    final v = _value;
    return h == _Half.up ? v < widget.max : v > widget.min;
  }

  void _stepBy(_Half h) {
    if (!_can(h)) return;
    final v = _next(h);
    if (v == _value) return;
    _sent = v;
    widget.onChanged?.call(v);
  }

  _Half _halfAt(Offset local) =>
      local.dy < AmalfiStepperMetrics.dividerOf(widget.size)
      ? _Half.up
      : _Half.down;

  void _hover(Offset? local) {
    final h = local == null || !_enabled ? null : _halfAt(local);
    for (final half in _Half.values) {
      final on = half == h && _can(half);
      if (_of(half).value.contains(WidgetState.hovered) != on) {
        _of(half).update(WidgetState.hovered, on);
      }
    }
  }

  void _press(Offset local) {
    final h = _halfAt(local);
    if (!_can(h)) return;
    _held = h;
    _of(h).update(WidgetState.pressed, true);
    _stepBy(h);
    _repeat?.cancel();
    _repeat = Timer(AmalfiStepperMetrics.repeatDelay, () {
      _repeat = Timer.periodic(AmalfiStepperMetrics.repeatInterval, (_) {
        final held = _held;
        if (!mounted || held == null || !_can(held)) {
          _release();
          return;
        }
        _stepBy(held);
      });
    });
  }

  void _release() {
    _repeat?.cancel();
    _repeat = null;
    final h = _held;
    _held = null;
    if (h != null && _of(h).value.contains(WidgetState.pressed)) {
      _of(h).update(WidgetState.pressed, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final size = widget.size;
    final box = AmalfiStepperMetrics.sizeOf(size);
    final radius = AmalfiStepperMetrics.radiusOf(size);
    final divider = AmalfiStepperMetrics.dividerOf(size);
    const glyph = AmalfiStepperMetrics.glyph;
    final enabled = _enabled;
    final focused =
        enabled &&
        (_focusHighlight ||
            _up.value.contains(WidgetState.focused) ||
            _down.value.contains(WidgetState.focused));

    Rect halfRect(_Half h) => h == _Half.up
        ? Rect.fromLTWH(0, 0, box.width, divider)
        : Rect.fromLTWH(0, divider, box.width, box.height - divider);

    Color? overlay(_Half h) {
      if (!_can(h)) return null;
      final s = _of(h).value;
      if (s.contains(WidgetState.pressed)) return colors.surfaceControlPressed;
      if (s.contains(WidgetState.hovered)) return colors.accentAmalfiSoft;
      return null;
    }

    Widget chevron(_Half h) {
      final r = halfRect(h);
      return Positioned(
        left: ((box.width - glyph) / 2).roundToDouble(),
        top: (r.top + (r.height - glyph) / 2).roundToDouble(),
        width: glyph,
        height: glyph,
        child: CustomPaint(
          painter: AmalfiChevronPainter(
            up: h == _Half.up,
            color: _can(h) ? colors.textPrimary : colors.textTertiary,
          ),
        ),
      );
    }

    final face = SizedBox.fromSize(
      size: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: enabled ? colors.surfaceControl : colors.surfaceSunken,
                shape: AmalfiSmoothBorder(
                  radius: radius,
                  side: enabled
                      ? BorderSide(
                          color: colors.lineBorder,
                          strokeAlign: BorderSide.strokeAlignInside,
                        )
                      : BorderSide.none,
                ),
                shadows: enabled ? amalfiControlShadows(colors) : null,
              ),
            ),
          ),
          for (final h in _Half.values)
            if (overlay(h) case final color?)
              Positioned.fill(
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: AmalfiSmoothBorder(radius: radius),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fromRect(
                        rect: halfRect(h),
                        child: ColoredBox(color: color),
                      ),
                    ],
                  ),
                ),
              ),
          if (focused)
            Positioned.fill(child: AmalfiSliderFocusHalo(radius: radius)),
          Positioned(
            left: AmalfiStepperMetrics.dividerInset,
            top: divider,
            width: box.width - 2 * AmalfiStepperMetrics.dividerInset,
            height: 1,
            child: ColoredBox(color: colors.lineSeparator),
          ),
          chevron(_Half.up),
          chevron(_Half.down),
        ],
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      value: _format(_value),
      enabled: enabled,
      increasedValue: _can(_Half.up) ? _format(_next(_Half.up)) : null,
      decreasedValue: _can(_Half.down) ? _format(_next(_Half.down)) : null,
      onIncrease: _can(_Half.up) ? () => _stepBy(_Half.up) : null,
      onDecrease: _can(_Half.down) ? () => _stepBy(_Half.down) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): _Step(_Half.up),
          SingleActivator(LogicalKeyboardKey.arrowDown): _Step(_Half.down),
        },
        actions: {
          _Step: CallbackAction<_Step>(onInvoke: (i) => _stepBy(i.half)),
        },
        onShowFocusHighlight: (v) {
          if (_focusHighlight != v) setState(() => _focusHighlight = v);
        },
        child: ExcludeSemantics(
          child: MouseRegion(
            onHover: (e) => _hover(e.localPosition),
            onExit: (_) => _hover(null),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: enabled ? (e) => _press(e.localPosition) : null,
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => _release(),
              child: face,
            ),
          ),
        ),
      ),
    );
  }

  double _next(_Half h) {
    final v = _value + (h == _Half.up ? widget.step : -widget.step);
    if (widget.wraps) {
      if (v > widget.max) return widget.min;
      if (v < widget.min) return widget.max;
      return v;
    }
    return v.clamp(widget.min, widget.max);
  }

  static String _format(double v) => v.isFinite && v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();
}

class _Step extends Intent {
  const _Step(this.half);
  final _Half half;
}
