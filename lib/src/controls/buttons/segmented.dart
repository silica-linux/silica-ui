// The segmented control in window content: select one, select any, or momentary.
//
// Measured: the large one is Clock's section switch, a 36 pt capsule (`#3d3d3d` in dark, rim
// `#727274` above and `#626262` below, outer line `#0b0b0b`) with a 28 pt pill inset by 4 pt
// (`#525252`–`#555555`, `#464646` in an inactive window), semibold 13 pt labels; the pill moves in
// ~300 ms, decelerating; hovering shows a highlight (clock.md › Section switch). The small one is
// 22 high (terminal.md › Find bar). Light uses the toolbar capsule colors, the closest measured
// sibling (mustache-spec 1.2, MU-07). Regular and mini sizes, dark hover and pressed, and the
// inactive dark text are provisional.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
  });

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

  static SegmentedColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;
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
  });

  final List<Segment> segments;
  final Set<int> selected;
  final ValueChanged<int>? onChanged;
  final SegmentedMode mode;
  final ControlSize size;
  final double? segmentWidth;
  final FocusNode? focusNode;

  @override
  State<SegmentedControl> createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl> {
  int? _hovered;
  int? _pressed;
  bool _inside = false;
  bool _focused = false;
  int _focusIndex = 0;
  List<double> _lefts = const [];
  double _segment = 0;

  bool get _enabled => widget.onChanged != null;

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

  void _activate(int index) {
    if (!_enabled || !widget.segments[index].enabled) return;
    widget.onChanged?.call(index);
  }

  void _down(PointerDownEvent e) {
    if (!_enabled || e.buttons & kPrimaryButton == 0) return;
    final i = _indexAt(e.localPosition);
    if (i == null || !widget.segments[i].enabled) return;
    setState(() {
      _pressed = i;
      _inside = true;
    });
  }

  void _move(PointerMoveEvent e) {
    final pressed = _pressed;
    if (pressed == null) return;
    final inside = _indexAt(e.localPosition) == pressed;
    if (inside != _inside) setState(() => _inside = inside);
  }

  void _up(PointerUpEvent e) {
    final pressed = _pressed;
    if (pressed == null) return;
    final fire = _indexAt(e.localPosition) == pressed;
    setState(() => _pressed = null);
    if (fire) {
      _focusIndex = pressed;
      _activate(pressed);
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = SegmentedColors.of(context);
    final active = controlWindowActive(context);
    final size = widget.size;
    final height = segmentedHeight(size);
    final inset = segmentedInset(size);
    final n = widget.segments.length;
    _segment = _measure();
    _lefts = [for (var i = 0; i < n; i++) inset + i * _segment];
    if (widget.mode == SegmentedMode.selectOne && widget.selected.isNotEmpty) {
      if (!_focused) _focusIndex = widget.selected.first;
    }
    final width = 2 * inset + n * _segment;
    final pillHeight = height - 2 * inset;
    final pillRadius = BorderRadius.circular(pillHeight / 2);
    final pressed = _inside ? _pressed : null;

    Widget pill(int i, Color color, {Key? key}) => Positioned(
      key: key,
      left: _lefts[i],
      top: inset,
      width: _segment,
      height: pillHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: pillRadius),
      ),
    );

    final chosenColor = active ? colors.pill : colors.pillInactive;
    final layers = <Widget>[];
    // Hover and press under the chosen pill's layer.
    for (var i = 0; i < n; i++) {
      final chosen =
          widget.mode != SegmentedMode.momentary && widget.selected.contains(i);
      if (chosen) continue;
      if (pressed == i) {
        layers.add(pill(i, colors.pressed, key: ValueKey('pressed $i')));
      } else if (_hovered == i && _enabled && widget.segments[i].enabled) {
        layers.add(pill(i, colors.hover, key: ValueKey('hover $i')));
      }
    }
    switch (widget.mode) {
      case SegmentedMode.selectOne when widget.selected.isNotEmpty:
        final i = widget.selected.first.clamp(0, n - 1);
        final color = pressed == i
            ? colors.pressedChosen
            : _hovered == i
            ? colors.hoverChosen
            : chosenColor;
        layers.add(
          AnimatedPositioned(
            key: const ValueKey('chosen pill'),
            duration: segmentedPillDuration,
            curve: Curves.easeOutCubic,
            left: _lefts[i],
            top: inset,
            width: _segment,
            height: pillHeight,
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
                  ? colors.pressedChosen
                  : _hovered == i
                  ? colors.hoverChosen
                  : chosenColor,
              key: ValueKey('chosen pill $i'),
            ),
          );
        }
      default:
        break;
    }

    for (var i = 0; i < n; i++) {
      final s = widget.segments[i];
      final enabled = _enabled && s.enabled;
      final chosen =
          widget.mode != SegmentedMode.momentary && widget.selected.contains(i);
      final color = !enabled
          ? colors.textDisabled
          : !active && _hovered != i
          ? colors.textInactive
          : colors.text;
      final icon = s.icon, label = s.label;
      layers.add(
        Positioned(
          left: _lefts[i],
          top: 0,
          width: _segment,
          height: height,
          child: Semantics(
            button: true,
            selected: chosen,
            enabled: enabled,
            inMutuallyExclusiveGroup: widget.mode == SegmentedMode.selectOne,
            label: s.semanticLabel ?? label,
            onTap: enabled ? () => _activate(i) : null,
            child: ExcludeSemantics(
              child: Center(
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
              ),
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
            onPointerCancel: (_) => setState(() => _pressed = null),
            child: FocusRing(
              visible: _focused,
              radius: null,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(child: track),
                    ...layers,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
