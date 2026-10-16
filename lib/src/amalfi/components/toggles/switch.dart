// The Amalfi switch (kit `Toggles/Switch/*`): off and on, Mini / Small / Regular, at rest,
// hovered, pressed (the thumb stretches), focused, disabled and dragged (the thumb becomes a
// Glass/Clear lens, `materials.md`), alone or in a labelled row (`Toggles/Switch/With Label`).

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'control_kit.dart';

/// The measures of a switch of one size, from `Toggles/Switch/*`.
@immutable
class AmalfiSwitchMetrics {
  const AmalfiSwitchMetrics({
    required this.track,
    required this.trackRadius,
    required this.thumb,
    required this.thumbRadius,
  });

  /// The size of the track (the switch).
  final Size track;

  /// The corner radius of the track.
  final double trackRadius;

  /// The side of the (round) thumb.
  final double thumb;

  /// The corner radius of the thumb.
  final double thumbRadius;

  /// The space between the thumb at rest and the track's edges.
  double get inset => (track.height - thumb) / 2;

  /// How much wider the thumb gets while the switch is pressed (towards the other end).
  static const double pressedStretch = 4;

  /// How much the lens of a dragged thumb exceeds the thumb on each side (`materials.md`:
  /// the lens is the thumb's width + 8).
  static const double lensOutset = 4;

  /// The side of the lens over a dragged thumb.
  double get lens => thumb + 2 * lensOutset;

  /// The thumb's left edge at rest, off or on.
  double restX(bool on) => on ? track.width - inset - thumb : inset;

  /// The farthest a dragged thumb goes: from the track's left edge to its right edge.
  double clampX(double x) => x.clamp(0, math.max(0, track.width - thumb));

  /// A switch of [size]: Mini 24 × 16, Small 32 × 20, Regular 40 × 24 (Large draws as
  /// Regular), thumb 4 smaller than the track's height.
  static AmalfiSwitchMetrics of(AmalfiControlSize size) => switch (size) {
    AmalfiControlSize.mini => const AmalfiSwitchMetrics(
      track: Size(24, 16),
      trackRadius: 7,
      thumb: 12,
      thumbRadius: 5,
    ),
    AmalfiControlSize.small => const AmalfiSwitchMetrics(
      track: Size(32, 20),
      trackRadius: 9,
      thumb: 16,
      thumbRadius: 7,
    ),
    AmalfiControlSize.regular ||
    AmalfiControlSize.large => const AmalfiSwitchMetrics(
      track: Size(40, 24),
      trackRadius: 12,
      thumb: 20,
      thumbRadius: 10,
    ),
  };
}

/// The measures of a labelled switch row (`Toggles/Switch/With Label`).
abstract final class AmalfiSwitchRowMetrics {
  /// Around the label and the switch.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  );

  /// The least space between the label's text and the switch.
  static const double gap = 12;
}

/// The look of a switch in a given state, without any interaction.
///
/// The thumb sits at [thumbX] (its left edge in the track; null: at rest for [value]). While
/// [dragging] the thumb is drawn as a Glass/Clear lens grown to [lens] (0 → the thumb's size,
/// 1 → full) that magnifies the track under it. [AmalfiSwitch] draws this; use it directly
/// only to show a state statically.
class AmalfiSwitchFace extends StatelessWidget {
  const AmalfiSwitchFace({
    super.key,
    required this.value,
    this.size = AmalfiControlSize.regular,
    this.state = const AmalfiInteractionState(),
    this.thumbX,
    this.dragging = false,
    this.lens = 1,
    this.lensOpacity = 0,
  });

  /// Whether the switch is on.
  final bool value;

  /// Mini, Small or Regular (Large draws as Regular).
  final AmalfiControlSize size;

  final AmalfiInteractionState state;

  /// The thumb's left edge in the track; null: at rest.
  final double? thumbX;

  /// Whether the thumb is being dragged (drawn as the lens).
  final bool dragging;

  /// How far the lens has grown, 0–1.
  final double lens;

  /// The opacity of the lens fading out after a drag (when not [dragging]), 0–1; 0: none.
  final double lensOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final m = AmalfiSwitchMetrics.of(size);
    final enabled = state.enabled;
    final pressed = enabled && state.pressed && !dragging;
    final hovered = enabled && state.hovered && !state.pressed;
    final x = m.clampX(thumbX ?? m.restX(value));
    final opacity = enabled ? 1.0 : AmalfiStates.disabledOpacity;

    Widget track({Key? key}) => DecoratedBox(
      key: key,
      decoration: AmalfiShapeDecoration(
        color: value
            ? (pressed ? colors.accentAmalfiPressed : colors.accentAmalfi)
            : colors.surfaceSunken,
        shape: AmalfiSmoothBorder(
          radius: m.trackRadius,
          side: value ? BorderSide.none : BorderSide(color: colors.lineBorder),
        ),
      ),
    );

    final stretch = pressed ? AmalfiSwitchMetrics.pressedStretch : 0.0;
    final thumbLeft = value ? x - stretch : x;
    final lensSide = m.thumb + (m.lens - m.thumb) * lens.clamp(0, 1);
    final lensRect = Rect.fromCenter(
      center: Offset(x + m.thumb / 2, m.track.height / 2),
      width: lensSide,
      height: lensSide,
    );

    return SizedBox.fromSize(
      size: m.track,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: track(key: AmalfiLayerKeys.body),
            ),
          ),
          if (hovered)
            Positioned.fill(
              child: DecoratedBox(
                key: AmalfiLayerKeys.state,
                decoration: AmalfiShapeDecoration(
                  color: value
                      ? colors.stateHoverOverlay
                      : colors.accentAmalfiSoft,
                  shape: AmalfiSmoothBorder(radius: m.trackRadius),
                ),
              ),
            ),
          if (state.focused && enabled)
            Positioned.fill(
              child: AmalfiFocusHalo(radius: m.trackRadius, colors: colors),
            ),
          if (!dragging)
            Positioned(
              left: thumbLeft,
              top: m.inset,
              width: m.thumb + stretch,
              height: m.thumb,
              child: Opacity(
                opacity: opacity,
                child: DecoratedBox(
                  key: AmalfiLayerKeys.thumb,
                  decoration: AmalfiShapeDecoration(
                    color: colors.textOnAccent,
                    shape: AmalfiSmoothBorder(radius: m.thumbRadius),
                    shadows: amalfiControlShadow(colors),
                  ),
                ),
              ),
            ),
          if (dragging || lensOpacity > 0 && lens > 0)
            Positioned.fromRect(
              rect: lensRect,
              child: Opacity(
                opacity: dragging ? 1 : lensOpacity.clamp(0, 1),
                child: _Lens(
                  key: AmalfiLayerKeys.lens,
                  rect: lensRect,
                  track: m.track,
                  under: track(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Glass/Clear lens over a dragged thumb: a capsule that shows the track under it
/// magnified ([AmalfiMaterials.clear]'s magnification) inside the glass's rims.
class _Lens extends StatelessWidget {
  const _Lens({
    super.key,
    required this.rect,
    required this.track,
    required this.under,
  });

  /// The lens in the track's coordinates.
  final Rect rect;

  /// The size of the track.
  final Size track;

  /// A copy of the track, magnified under the lens.
  final Widget under;

  @override
  Widget build(BuildContext context) {
    final magnification =
        AmalfiMaterials.clear.refraction?.magnification ?? 1.0;
    final radius = rect.shortestSide / 2;
    return AmalfiGlass(
      material: AmalfiMaterials.clear,
      radius: radius,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: AmalfiSmoothBorder(radius: radius)),
        child: Transform.scale(
          scale: magnification,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -rect.left,
                top: -rect.top,
                width: track.width,
                height: track.height,
                child: under,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A switch: [value] on or off.
///
/// A click or Space calls [onChanged] with the other value; dragging the thumb moves it 1:1
/// with the pointer (it becomes a Glass/Clear lens) and the release chooses the end it is
/// nearer to. The thumb travels with `spring.snappy`. With [onChanged] null it is disabled.
///
/// With a [label] it is a settings row (`Toggles/Switch/With Label`): the label at the
/// leading edge, the switch at the trailing edge, 12 × 4 padding; the row fills the width it
/// is given (or hugs its content when the width is unbounded), and a click anywhere on it
/// toggles the switch.
class AmalfiSwitch extends StatefulWidget {
  const AmalfiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = AmalfiControlSize.regular,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool value;

  /// Called with the new value; null: disabled.
  final ValueChanged<bool>? onChanged;

  /// The text of a settings row; null: the switch alone.
  final String? label;

  /// Mini, Small or Regular (Large draws as Regular). A labelled switch is Regular in the kit.
  final AmalfiControlSize size;

  /// The name for screen readers when there is no [label].
  final String? semanticLabel;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AmalfiSwitch> createState() => _AmalfiSwitchState();
}

class _AmalfiSwitchState extends State<AmalfiSwitch>
    with TickerProviderStateMixin {
  late final AnimationController _thumb = AnimationController.unbounded(
    vsync: this,
    value: _metrics.restX(widget.value),
  )..addListener(_changed);
  late final AnimationController _lens = AnimationController(
    vsync: this,
    duration: AmalfiFades.quick.duration,
  )..addListener(_changed);

  bool _dragging = false;
  double _dragFrom = 0;
  double _thumbFrom = 0;

  AmalfiSwitchMetrics get _metrics => AmalfiSwitchMetrics.of(widget.size);

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _changed() => setState(() {});

  @override
  void didUpdateWidget(AmalfiSwitch old) {
    super.didUpdateWidget(old);
    if (old.size != widget.size) {
      _thumb.value = _metrics.restX(widget.value);
    } else if (old.value != widget.value && !_dragging) {
      _settle();
    }
  }

  @override
  void dispose() {
    _thumb.dispose();
    _lens.dispose();
    super.dispose();
  }

  /// Moves the thumb to its rest position for the current value.
  void _settle() {
    final target = _metrics.restX(widget.value);
    if (_reduceMotion) {
      _thumb.value = target;
      return;
    }
    _thumb
        .animateWith(
          SpringSimulation(AmalfiSprings.snappy, _thumb.value, target, 0),
        )
        .then((_) {
          // A spring stops within its tolerance: land exactly on the rest position.
          if (mounted && !_dragging) _thumb.value = target;
        });
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _dragStart(Offset at) {
    _thumb.stop();
    setState(() {
      _dragging = true;
      _dragFrom = at.dx;
      _thumbFrom = _thumb.value;
    });
    if (_reduceMotion) {
      _lens.value = 1;
    } else {
      _lens.animateWith(SpringSimulation(AmalfiSprings.snappy, 0, 1, 0));
    }
  }

  void _dragUpdate(Offset at) {
    _thumb.value = _metrics.clampX(_thumbFrom + at.dx - _dragFrom);
  }

  void _dragEnd() {
    final m = _metrics;
    final on = _thumb.value + m.thumb / 2 > m.track.width / 2;
    setState(() => _dragging = false);
    // The lens fades out (fade.quick) over the thumb as it settles.
    _lens.reverse();
    if (on != widget.value) widget.onChanged?.call(on);
    _settle();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final enabled = widget.onChanged != null;
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      label: label ?? widget.semanticLabel,
      onTap: enabled ? _toggle : null,
      child: ExcludeSemantics(
        child: AmalfiInteraction(
          onActivate: enabled ? _toggle : null,
          onDragStart: _dragStart,
          onDragUpdate: _dragUpdate,
          onDragEnd: _dragEnd,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          builder: (context, state) {
            final face = AmalfiSwitchFace(
              value: widget.value,
              size: widget.size,
              state: state,
              thumbX: _thumb.value,
              dragging: _dragging,
              lens: _dragging ? _lens.value : 1,
              lensOpacity: _dragging ? 1 : _lens.value,
            );
            return label == null
                ? face
                : AmalfiSwitchRow(label: label, enabled: enabled, child: face);
          },
        ),
      ),
    );
  }
}

/// A settings row: [label] at the leading edge in Body (`Text/Primary`, `Text/Tertiary`
/// when not [enabled]), [child] (a switch) at the trailing edge (`Toggles/Switch/With
/// Label`). [AmalfiSwitch] builds it when it has a label.
class AmalfiSwitchRow extends StatelessWidget {
  const AmalfiSwitchRow({
    super.key,
    required this.label,
    required this.child,
    this.enabled = true,
  });

  final String label;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final text = Padding(
      padding: const EdgeInsets.only(right: AmalfiSwitchRowMetrics.gap),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmalfiType.body(
          color: enabled ? colors.textPrimary : colors.textTertiary,
        ),
      ),
    );
    final control = KeyedSubtree(key: AmalfiLayerKeys.control, child: child);
    return Padding(
      padding: AmalfiSwitchRowMetrics.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedWidth;
          return Row(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (bounded)
                Expanded(
                  child: KeyedSubtree(key: AmalfiLayerKeys.label, child: text),
                )
              else
                KeyedSubtree(key: AmalfiLayerKeys.label, child: text),
              control,
            ],
          );
        },
      ),
    );
  }
}
