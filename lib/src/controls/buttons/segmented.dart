// The segmented control in window content: select one, select any, or momentary.
//
// Measured (docs/spec/segmented.md): the window segmented control (every style looks the same)
// is a gray capsule track 24 pt tall with the chosen segment an accent capsule and white text;
// no hover look; a pressed segment `#c5c5c5` / `#585859`; in an inactive window the accent turns
// gray; the keyboard ring surrounds only the focused segment (CT-SEG-02/05, CT-TF-09, INV-B).
// The large one is Clock's section switch, a 36 pt capsule (`#3d3d3d` in dark, rim `#727274`
// above and `#626262` below, outer line `#0b0b0b`) with a 28 pt pill inset by 4 pt (`#525252`–
// `#555555`, `#464646` in an inactive window), semibold 13 pt labels; the pill moves in ~300 ms,
// decelerating; hovering shows a highlight (clock.md › Section switch); light uses the toolbar
// capsule colors (MU-07). Provisional: the window track's exact gray (the push button fill), the
// mini size, Clock's dark pressed colors.

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass_lens.dart';
import 'control_style.dart';

/// How the segments behave.
enum SegmentedMode {
  /// One segment is chosen (a radio group); the arrows move the choice.
  selectOne,

  /// Each segment is on or off by itself.
  selectAny,

  /// Segments are buttons: highlighted only while pressed (previous / next).
  momentary,
}

/// A segment: a label and/or an icon drawn in the color it receives.
@immutable
class Segment {
  const Segment({
    this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  }) : assert(label != null || icon != null);

  final String? label;
  final Widget Function(Color color)? icon;
  final bool enabled;
  final String? semanticLabel;
}

/// The colors of the segmented control.
@immutable
class SegmentedColors {
  const SegmentedColors({
    required this.track,
    required this.rim,
    required this.outer,
    required this.pill,
    required this.pillInactive,
    required this.hover,
    required this.hoverChosen,
    required this.pressed,
    required this.pressedChosen,
    required this.text,
    required this.textInactive,
    required this.textDisabled,
    this.accentPill = false,
    this.chosenText,
  });

  /// The chosen pill takes the accent fill ([ControlAccent.fillOf]) instead of [pill], and its
  /// pressed step; [pill] is unused.
  final bool accentPill;

  /// The text on the chosen pill (null: [text]).
  final Color? chosenText;

  final Color track;

  /// The 1 pt rim, top to bottom.
  final List<Color> rim;

  /// A 1 pt line outside the rim (dark).
  final Color? outer;
  final Color pill;
  final Color pillInactive;
  final Color hover;
  final Color hoverChosen;
  final Color pressed;
  final Color pressedChosen;
  final Color text;
  final Color textInactive;
  final Color textDisabled;

  /// The toolbar capsule's colors (measured); the text color is provisional.
  static const SegmentedColors light = SegmentedColors(
    track: Color(0xFFF8F8F8),
    rim: [Color(0xFFEBEBEB), Color(0xFFC1C1C1), Color(0xFFE8E7E8)],
    outer: null,
    pill: Color(0xFFE5E5E5),
    pillInactive: Color(0xFFDCDCDC),
    hover: Color(0xFFEEEEEE),
    hoverChosen: Color(0xFFDBDBDB),
    pressed: Color(0xFFE8E8E8),
    pressedChosen: Color(0xFFD2D2D2),
    text: Color(0xFF262626),
    textInactive: Color(0xFFA4A4A4),
    textDisabled: Color(0xFFADADAD),
  );

  /// Clock's section switch (measured), hover, pressed and inactive text provisional.
  static const SegmentedColors dark = SegmentedColors(
    track: Color(0xFF3D3D3D),
    rim: [Color(0xFF727274), Color(0xFF626262)],
    outer: Color(0xFF0B0B0B),
    pill: Color(0xFF535353),
    pillInactive: Color(0xFF464646),
    hover: Color(0xFF474747),
    hoverChosen: Color(0xFF5C5C5C),
    pressed: Color(0xFF4B4B4B),
    pressedChosen: Color(0xFF626262),
    text: Color(0xFFFFFFFF),
    textInactive: Color(0xFF8C8C8C),
    textDisabled: Color(0xFF666666),
  );

  /// The window segmented control, light (INV-B): gray track, accent pill, no hover.
  static const SegmentedColors windowLight = SegmentedColors(
    track: Color(0xFFECECEC),
    rim: [Color(0xFFECECEC), Color(0xFFECECEC)],
    outer: null,
    pill: ControlPalette.accent,
    pillInactive: ControlPalette.inactiveAccentLight,
    hover: Color(0xFFECECEC),
    hoverChosen: ControlPalette.accent,
    pressed: Color(0xFFC5C5C5),
    pressedChosen: ControlPalette.accent,
    text: Color(0xFF242424),
    textInactive: Color(0xFF242424),
    textDisabled: Color(0xFFADADAD),
    accentPill: true,
    chosenText: Color(0xFFFFFFFF),
  );

  /// The window segmented control, dark (INV-B).
  static const SegmentedColors windowDark = SegmentedColors(
    track: Color(0xFF373738),
    rim: [Color(0xFF373738), Color(0xFF373738)],
    outer: null,
    pill: ControlPalette.accent,
    pillInactive: ControlPalette.inactiveAccentDark,
    hover: Color(0xFF373738),
    hoverChosen: ControlPalette.accent,
    pressed: Color(0xFF585859),
    pressedChosen: ControlPalette.accent,
    text: Color(0xFFE0E0E0),
    textInactive: Color(0xFFE0E0E0),
    textDisabled: Color(0xFF787879),
    accentPill: true,
    chosenText: Color(0xFFFFFFFF),
  );

  /// The large (section switch) colors, following the system appearance.
  static SegmentedColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;

  /// The colors for `size`: the window control below large, the section switch at large.
  static SegmentedColors forSize(BuildContext context, ControlSize size) {
    if (size == ControlSize.large) return of(context);
    return MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
        ? windowDark
        : windowLight;
  }
}

/// Height, pill inset and label padding of each size.
double segmentedHeight(ControlSize size) => switch (size) {
  ControlSize.mini => 18,
  ControlSize.small => 22,
  ControlSize.regular => 24,
  ControlSize.large => 36,
};

double segmentedInset(ControlSize size) => size == ControlSize.large ? 4 : 2;

double _segmentPadding(ControlSize size) => switch (size) {
  ControlSize.mini => 6,
  ControlSize.small => 8,
  ControlSize.regular => 10,
  ControlSize.large => 12,
};

/// The pill's move between segments (measured ~300 ms, decelerating).
const Duration segmentedPillDuration = Duration(milliseconds: 300);

/// A segmented control. `selected` holds the chosen segments; `onChanged` receives the index
/// pressed (released inside it) or activated with Space: in [SegmentedMode.selectOne] the app
/// chooses it, in [SegmentedMode.selectAny] it toggles it, in [SegmentedMode.momentary] it acts.
/// Segments are as wide as the widest one unless `segmentWidth` is given.
///
/// With the [lens] (by default the large control in [SegmentedMode.selectOne], Clock's section
/// switch), pressing swells the selection into a [GlassLens] that magnifies the labels under it
/// and travels with a spring to the enabled segment under the pointer as it is dragged across
/// the control; releasing inside the control chooses the segment under the lens, and the lens
/// shrinks back into the pill. With reduced motion the lens appears, jumps and disappears
/// without animation.
class SegmentedControl extends StatefulWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.onChanged,
    this.selected = const {},
    this.mode = SegmentedMode.selectOne,
    this.size = ControlSize.regular,
    this.segmentWidth,
    this.focusNode,
    this.lens,
  });

  final List<Segment> segments;
  final Set<int> selected;
  final ValueChanged<int>? onChanged;
  final SegmentedMode mode;
  final ControlSize size;
  final double? segmentWidth;
  final FocusNode? focusNode;

  /// The glass lens while pressed, in [SegmentedMode.selectOne] only. Null: on for
  /// [ControlSize.large], off for the smaller sizes.
  final bool? lens;

  /// Whether the control shows the lens.
  bool get hasLens =>
      mode == SegmentedMode.selectOne && (lens ?? size == ControlSize.large);

  @override
  State<SegmentedControl> createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl>
    with TickerProviderStateMixin {
  int? _hovered;
  int? _pressed;
  bool _inside = false;
  bool _focused = false;
  int _focusIndex = 0;
  double _segment = 0;

  /// The chosen pill's left edge.
  late final AnimationController _pill = AnimationController.unbounded(
    vsync: this,
  )..addListener(_changed);
  double? _pillTarget;

  /// The lens's presence: 0 hidden, 1 swollen.
  late final AnimationController _lens = AnimationController.unbounded(
    vsync: this,
  )..addListener(_changed);

  /// While the lens is held: the segment it travels to.
  int? _lensAt;
  int? _lensPointer;

  bool get _enabled => widget.onChanged != null;
  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _segment = _measure();
    final rest = _restIndex;
    _pillTarget = _leftOf(rest ?? 0);
    _pill.value = _pillTarget!;
  }

  @override
  void didUpdateWidget(SegmentedControl old) {
    super.didUpdateWidget(old);
    final before = _segment;
    _segment = _measure();
    if (before != _segment || old.size != widget.size) {
      // The geometry changed: the pill goes straight to its place.
      _pillTarget = null;
      final i = _lensPointer != null ? _lensAt : _restIndex;
      if (i != null) {
        _pillTarget = _leftOf(i);
        _pill.value = _pillTarget!;
      }
      return;
    }
    if (_lensPointer == null) _settle();
  }

  @override
  void dispose() {
    _pill.dispose();
    _lens.dispose();
    super.dispose();
  }

  int? get _restIndex {
    if (widget.mode != SegmentedMode.selectOne || widget.selected.isEmpty) {
      return null;
    }
    final n = widget.segments.length;
    return n == 0 ? null : widget.selected.first.clamp(0, n - 1);
  }

  double _leftOf(int i) => segmentedInset(widget.size) + i * _segment;

  /// Moves the pill to segment `i`: on the lens spring while the lens shows, otherwise in the
  /// measured ~300 ms; at once with reduced motion.
  void _movePill(int i) {
    final target = _leftOf(i);
    if (_pillTarget == target) return;
    _pillTarget = target;
    if (_reduced) {
      _pill.value = target;
    } else if (_lensPointer != null || _lens.value > 0) {
      _pill.animateWith(
        SpringSimulation(
          GlassLensMetrics.travelSpring,
          _pill.value,
          target,
          _pill.velocity,
          tolerance: const Tolerance(distance: 0.01, velocity: 0.1),
        ),
      );
    } else {
      _pill.animateTo(
        target,
        duration: segmentedPillDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// At rest: the pill goes to the chosen segment.
  void _settle() {
    final rest = _restIndex;
    if (rest != null) _movePill(rest);
  }

  void _showLens(bool on) {
    final target = on ? 1.0 : 0.0;
    if (_reduced) {
      _lens.value = target;
      return;
    }
    _lens.animateWith(
      SpringSimulation(
        on ? GlassLensMetrics.appearSpring : GlassLensMetrics.disappearSpring,
        _lens.value,
        target,
        _lens.velocity,
        tolerance: const Tolerance(distance: 0.002, velocity: 0.05),
      ),
    );
    if (!on) {
      // Rest exactly at 0 once the spring settles (it may dip below).
      _lens
        ..removeStatusListener(_hidden)
        ..addStatusListener(_hidden);
    }
  }

  void _hidden(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _lens.removeStatusListener(_hidden);
    if (_lensPointer == null) _lens.value = 0;
  }

  TextStyle _style(Color color) => controlTextStyle(
    widget.size,
    color,
    weight: widget.size == ControlSize.large ? FontWeight.w600 : null,
  );

  double _measure() {
    final fixed = widget.segmentWidth;
    if (fixed != null) return fixed;
    var widest = 0.0;
    for (final s in widget.segments) {
      var w = 0.0;
      final label = s.label;
      if (label != null) {
        w += (TextPainter(
          text: TextSpan(text: label, style: _style(const Color(0xFF000000))),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout()).width;
      }
      if (s.icon != null) w += controlFontSize(widget.size) + 3;
      if (s.icon != null && label != null) w += 4;
      if (w > widest) widest = w;
    }
    return (widest + 2 * _segmentPadding(widget.size)).ceilToDouble();
  }

  int? _indexAt(Offset local) {
    final inset = segmentedInset(widget.size);
    final x = local.dx - inset;
    if (x < 0 || local.dy < 0 || local.dy > segmentedHeight(widget.size)) {
      return null;
    }
    final i = (x / _segment).floor();
    return i >= 0 && i < widget.segments.length ? i : null;
  }

  /// While the lens is held: the segment under the pointer along the row (clamped to the
  /// ends), or null over a disabled one.
  int? _lensIndexAt(Offset local) {
    final n = widget.segments.length;
    if (n == 0 || _segment <= 0) return null;
    final x = local.dx - segmentedInset(widget.size);
    final i = (x / _segment).floor().clamp(0, n - 1);
    return widget.segments[i].enabled ? i : null;
  }

  bool _within(Offset local) =>
      local.dx >= 0 &&
      local.dy >= 0 &&
      local.dx <=
          2 * segmentedInset(widget.size) + widget.segments.length * _segment &&
      local.dy <= segmentedHeight(widget.size);

  void _activate(int index) {
    if (!_enabled || !widget.segments[index].enabled) return;
    widget.onChanged?.call(index);
  }

  void _down(PointerDownEvent e) {
    if (!_enabled || e.buttons & kPrimaryButton == 0) return;
    final i = _indexAt(e.localPosition);
    if (i == null || !widget.segments[i].enabled) return;
    if (widget.hasLens) {
      if (_lensPointer != null) return;
      _lensPointer = e.pointer;
      _lensAt = i;
      _inside = true;
      // The lens grows out of the chosen pill and travels to the pressed segment; without a
      // choice it appears on the pressed one.
      if (_restIndex == null) {
        _pillTarget = _leftOf(i);
        _pill.value = _pillTarget!;
      }
      _showLens(true);
      _movePill(i);
      setState(() {});
      return;
    }
    setState(() {
      _pressed = i;
      _inside = true;
    });
  }

  void _move(PointerMoveEvent e) {
    if (_lensPointer != null) {
      if (e.pointer != _lensPointer) return;
      _inside = _within(e.localPosition);
      final i = _lensIndexAt(e.localPosition);
      if (i != null && i != _lensAt) {
        _lensAt = i;
        _movePill(i);
      }
      setState(() {});
      return;
    }
    final pressed = _pressed;
    if (pressed == null) return;
    final inside = _indexAt(e.localPosition) == pressed;
    if (inside != _inside) setState(() => _inside = inside);
  }

  void _up(PointerUpEvent e) {
    if (_lensPointer != null) {
      if (e.pointer != _lensPointer) return;
      final target = _within(e.localPosition) ? _lensAt : null;
      _releaseLens();
      if (target != null) {
        _focusIndex = target;
        _activate(target);
      }
      return;
    }
    final pressed = _pressed;
    if (pressed == null) return;
    final fire = _indexAt(e.localPosition) == pressed;
    setState(() => _pressed = null);
    if (fire) {
      _focusIndex = pressed;
      _activate(pressed);
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (_lensPointer != null) {
      if (e.pointer == _lensPointer) _releaseLens();
      return;
    }
    setState(() => _pressed = null);
  }

  void _releaseLens() {
    _lensPointer = null;
    _lensAt = null;
    _inside = false;
    _showLens(false);
    setState(() {});
    // After the app has answered (it may choose the segment, or not), the pill rests on the
    // chosen segment.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lensPointer == null) _settle();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!isKeyPress(event) || !_enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final n = widget.segments.length;
    if (key == LogicalKeyboardKey.space) {
      _activate(_focusIndex.clamp(0, n - 1));
      return KeyEventResult.handled;
    }
    final step = key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowLeft
        ? -1
        : 0;
    if (step == 0) return KeyEventResult.ignored;
    for (var k = 1; k < n; k++) {
      final i = (_focusIndex + step * k) % n;
      if (widget.segments[i].enabled) {
        setState(() => _focusIndex = i);
        if (widget.mode == SegmentedMode.selectOne) _activate(i);
        break;
      }
    }
    return KeyEventResult.handled;
  }

  /// The label (and icon) of segment `s` in `color`, centred in its segment.
  Widget _content(Segment s, Color color) {
    final icon = s.icon, label = s.label;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon(color),
          if (icon != null && label != null) const SizedBox(width: 4),
          if (label != null)
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _style(color),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SegmentedColors.forSize(context, widget.size);
    final active = WindowActiveScope.of(context);
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final accent = colors.accentPill ? ControlAccent.fillOf(context) : null;
    final lensHeld = _lensPointer != null;
    // The window control has no hover look (INV-B); the held lens is its own feedback.
    final hovered = accent == null && !lensHeld ? _hovered : null;
    final size = widget.size;
    final height = segmentedHeight(size);
    final inset = segmentedInset(size);
    final n = widget.segments.length;
    final lefts = [for (var i = 0; i < n; i++) _leftOf(i)];
    if (widget.mode == SegmentedMode.selectOne && widget.selected.isNotEmpty) {
      if (!_focused) _focusIndex = widget.selected.first;
    }
    final width = 2 * inset + n * _segment;
    final pillHeight = height - 2 * inset;
    final pillRadius = BorderRadius.circular(pillHeight / 2);
    final pressed = _inside ? _pressed : null;

    Widget pill(int i, Color color, {Key? key}) => Positioned(
      key: key,
      left: lefts[i],
      top: inset,
      width: _segment,
      height: pillHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: pillRadius),
      ),
    );

    final chosenColor = !active ? colors.pillInactive : accent ?? colors.pill;
    final pressedChosen = accent == null
        ? colors.pressedChosen
        : controlPressedFill(chosenColor, dark: dark);
    final hoverChosen = accent == null ? colors.hoverChosen : chosenColor;
    final layers = <Widget>[];
    // Hover and press under the chosen pill's layer.
    for (var i = 0; i < n; i++) {
      final chosen =
          widget.mode != SegmentedMode.momentary && widget.selected.contains(i);
      if (chosen) continue;
      if (pressed == i) {
        layers.add(pill(i, colors.pressed, key: ValueKey('pressed $i')));
      } else if (hovered == i && _enabled && widget.segments[i].enabled) {
        layers.add(pill(i, colors.hover, key: ValueKey('hover $i')));
      }
    }
    Rect? pillRect;
    switch (widget.mode) {
      case SegmentedMode.selectOne
          when widget.selected.isNotEmpty || _lens.value > 0:
        final i = _restIndex;
        final color = lensHeld
            ? chosenColor
            : pressed == i
            ? pressedChosen
            : hovered == i
            ? hoverChosen
            : chosenColor;
        pillRect = Rect.fromLTWH(_pill.value, inset, _segment, pillHeight);
        layers.add(
          Positioned.fromRect(
            key: const ValueKey('chosen pill'),
            rect: pillRect,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: pillRadius),
            ),
          ),
        );
      case SegmentedMode.selectAny:
        for (final i in widget.selected) {
          if (i < 0 || i >= n) continue;
          layers.add(
            pill(
              i,
              pressed == i
                  ? pressedChosen
                  : hovered == i
                  ? hoverChosen
                  : chosenColor,
              key: ValueKey('chosen pill $i'),
            ),
          );
        }
      default:
        break;
    }

    final onLensText = active && colors.chosenText != null
        ? colors.chosenText!
        : colors.text;
    for (var i = 0; i < n; i++) {
      final s = widget.segments[i];
      final enabled = _enabled && s.enabled;
      final chosen =
          widget.mode != SegmentedMode.momentary && widget.selected.contains(i);
      final onPill = chosen && active && colors.chosenText != null;
      final color = !enabled
          ? colors.textDisabled
          : onPill
          ? colors.chosenText!
          : !active && hovered != i
          ? colors.textInactive
          : colors.text;
      layers.add(
        Positioned(
          left: lefts[i],
          top: 0,
          width: _segment,
          height: height,
          child: Semantics(
            button: true,
            selected: chosen,
            enabled: enabled,
            inMutuallyExclusiveGroup: widget.mode == SegmentedMode.selectOne,
            label: s.semanticLabel ?? s.label,
            onTap: enabled ? () => _activate(i) : null,
            child: ExcludeSemantics(child: _content(s, color)),
          ),
        ),
      );
    }

    final presence = _lens.value;
    if (pillRect != null && presence > 0) {
      layers.add(
        Positioned.fill(
          child: GlassLens(
            rect: glassLensRect(pillRect, presence),
            presence: presence,
            style: GlassLensStyle.of(context).copyWith(fill: chosenColor),
            content: Stack(
              children: [
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: lefts[i],
                    top: 0,
                    width: _segment,
                    height: height,
                    child: _content(
                      widget.segments[i],
                      _enabled && widget.segments[i].enabled
                          ? onLensText
                          : colors.textDisabled,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final track = Container(
      key: const ValueKey('segmented track'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.outer,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      padding: EdgeInsets.all(colors.outer == null ? 0 : 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.rim,
          ),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.track,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _key,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        onShowFocusHighlight: (on) {
          if (on != _focused) setState(() => _focused = on);
        },
        child: MouseRegion(
          onHover: (e) {
            final i = _indexAt(e.localPosition);
            if (i != _hovered) setState(() => _hovered = i);
          },
          onExit: (_) {
            if (_hovered != null) setState(() => _hovered = null);
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _cancel,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: track),
                  ...layers,
                  // The keyboard ring surrounds only the focused segment (CT-TF-09).
                  if (_focused && n > 0)
                    Positioned(
                      left: lefts[_focusIndex.clamp(0, n - 1)],
                      top: inset,
                      width: _segment,
                      height: pillHeight,
                      child: IgnorePointer(
                        child: FocusRing(
                          visible: true,
                          kind: FocusRingKind.control,
                          radius: null,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
