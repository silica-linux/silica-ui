// Action segments (kit `Segments/Action/*` and `Segments/Align/*`): a toolbar capsule of
// Glass/Regular holding a row of buttons (Back / Forward, Reply / Reply All / Forward, text
// alignment), split by 1 pt separators.
//
// Kit measures (per size in `AmalfiSegmentSizeMetrics`): icon segments are squares of the
// control height, text segments 40 / 44 / 52 / 56 wide, glyphs of the size's icon size
// (12 / 14 / 16 / 16); separators 1 × 12 (Mini, Small) or 1 × 16 (Regular, Large), centred,
// hidden next to a highlighted segment. Hover: a `Line/Separator` capsule on the segment
// (inset 4 from Regular up, 4 sideways on text); pressed: a flat `Line/Border` capsule as tall
// as the control (no lens: the lens is for select-one controls, kit 747ea80). Disabled: the
// whole capsule at 35 % (`AmalfiStates.disabledOpacity`, user decision 2026-10-16), a single
// disabled segment its content at 35 %. Every segment of an inactive window draws its content
// in `Text/Tertiary`; a selected segment (the Align group) keeps a `Line/Separator` highlight
// and draws its glyph in `Accent/Amalfi`.
//
// Behaviour as the toolbar capsules (`toolbar.dart`): the action fires on release over the
// pressed segment; the highlight fades in with `fade.quick` and out in 60 ms (`motion.md`,
// push / icon buttons).

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../../controls/control_base.dart' show WindowActiveScope;
import '../../glass.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../tooltips/tooltip_region.dart';
import 'metrics.dart';
import 'segment.dart';

/// How long a highlight takes to go away (`motion.md`: push / icon buttons, 60 ms out).
const Duration amalfiSegmentHighlightOut = Duration(milliseconds: 60);

/// A toolbar capsule of action segments: buttons side by side on Glass/Regular, split by
/// separators (kit `Segments/Action/*`).
///
/// [onPressed] receives the index of the segment released on; null disables the whole capsule
/// (drawn at 35 %, [AmalfiStates.disabledOpacity]; a disabled segment dims its content).
/// With [selected], the capsule is also a toolbar selection group (kit `Segments/Align/*`):
/// those segments keep a highlight and draw their content in `Accent/Amalfi`; choosing one
/// is up to [onPressed]. Text segments share one width: the kit's for [size], or the widest
/// label's on the 4 pt grid.
///
/// Keyboard: the arrows move the focus between enabled segments, Space and Enter press the
/// focused one. In an inactive window ([active] false, by default [WindowActiveScope]) the
/// content turns `Text/Tertiary`.
class AmalfiActionSegments extends StatefulWidget {
  const AmalfiActionSegments({
    super.key,
    required this.segments,
    this.onPressed,
    this.selected = const {},
    this.size = AmalfiControlSize.large,
    this.active,
    this.opaque = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The segments, leading to trailing.
  final List<AmalfiSegment> segments;

  /// Called with the index of the segment pressed; null: the capsule is disabled.
  final ValueChanged<int>? onPressed;

  /// The segments shown as selected (a toolbar selection group).
  final Set<int> selected;

  /// The control size; toolbars use [AmalfiControlSize.large].
  final AmalfiControlSize size;

  /// Whether the window is active; null: [WindowActiveScope.of].
  final bool? active;

  /// Whether the glass is drawn without blur (see [AmalfiGlass.opaque]).
  final bool opaque;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AmalfiActionSegments> createState() => _AmalfiActionSegmentsState();
}

/// The look of an action segment.
enum _Look { none, hover, pressed, selected }

class _AmalfiActionSegmentsState extends State<AmalfiActionSegments> {
  int? _hovered;
  int? _pressed;
  int? _pointer;
  bool _inside = false;
  bool _focused = false;
  int _focusIndex = 0;
  List<double> _lefts = const [];
  List<double> _widths = const [];

  bool get _enabled => widget.onPressed != null;

  bool _canPress(int i) =>
      _enabled &&
      i >= 0 &&
      i < widget.segments.length &&
      widget.segments[i].enabled;

  int? _indexAt(Offset local) {
    if (local.dy < 0 || local.dy > widget.size.height) return null;
    for (var i = 0; i < _lefts.length; i++) {
      if (local.dx >= _lefts[i] && local.dx < _lefts[i] + _widths[i]) return i;
    }
    return null;
  }

  @override
  void didUpdateWidget(AmalfiActionSegments old) {
    super.didUpdateWidget(old);
    final n = widget.segments.length;
    if (_hovered case final h? when h >= n) _hovered = null;
    if (_pressed case final p? when p >= n) {
      _pressed = null;
      _pointer = null;
    }
    if (_focusIndex >= n) _focusIndex = 0;
  }

  void _down(PointerDownEvent e) {
    if (!mounted) return;
    if (_pointer != null || e.buttons & kPrimaryButton == 0) return;
    final i = _indexAt(e.localPosition);
    if (i == null || !_canPress(i)) return;
    setState(() {
      _pointer = e.pointer;
      _pressed = i;
      _inside = true;
      _focusIndex = i;
    });
  }

  void _move(PointerMoveEvent e) {
    if (!mounted) return;
    if (e.pointer != _pointer) return;
    final inside = _indexAt(e.localPosition) == _pressed;
    if (inside != _inside) setState(() => _inside = inside);
  }

  void _up(PointerUpEvent e) {
    if (!mounted) return;
    if (e.pointer != _pointer) return;
    final pressed = _pressed;
    final fire = pressed != null && _indexAt(e.localPosition) == pressed;
    setState(() {
      _pointer = null;
      _pressed = null;
      _inside = false;
      _hovered = _hoverable(_indexAt(e.localPosition));
    });
    if (fire && _canPress(pressed)) widget.onPressed?.call(pressed);
  }

  void _cancel(PointerCancelEvent e) {
    if (!mounted) return;
    if (e.pointer != _pointer) return;
    setState(() {
      _pointer = null;
      _pressed = null;
      _inside = false;
    });
  }

  int? _hoverable(int? i) => i != null && _canPress(i) ? i : null;

  void _hover(PointerHoverEvent e) {
    if (!mounted) return;
    final i = _hoverable(_indexAt(e.localPosition));
    if (i != _hovered) setState(() => _hovered = i);
  }

  void _exit(PointerExitEvent e) {
    if (!mounted) return;
    if (_hovered != null) setState(() => _hovered = null);
  }

  /// Moves the focus by [step] to the next enabled segment, without wrapping.
  void _moveFocus(int step) {
    final n = widget.segments.length;
    for (var i = _focusIndex + step; i >= 0 && i < n; i += step) {
      if (_canPress(i)) {
        setState(() => _focusIndex = i);
        return;
      }
    }
  }

  void _activateFocused() {
    if (_canPress(_focusIndex)) widget.onPressed?.call(_focusIndex);
  }

  _Look _lookOf(int i) {
    if (_pressed == i && _inside) return _Look.pressed;
    if (widget.selected.contains(i)) return _Look.selected;
    if (_hovered == i && _pointer == null) return _Look.hover;
    return _Look.none;
  }

  /// The highlight of segment [i] in [look], in the capsule.
  Rect _highlightRect(int i, _Look look, AmalfiSegmentSizeMetrics m) {
    final x = _lefts[i], w = _widths[i], h = m.height;
    final pressed = look == _Look.pressed;
    if (widget.segments[i].isIcon) {
      final inset = pressed ? 0.0 : m.hoverInset;
      return Rect.fromLTWH(x + inset, inset, w - 2 * inset, h - 2 * inset);
    }
    const side = AmalfiSegmentMetrics.textHighlightInset;
    final inset = pressed ? 0.0 : m.hoverInset;
    return Rect.fromLTWH(x + side, inset, w - 2 * side, h - 2 * inset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    final m = AmalfiSegmentSizeMetrics.of(widget.size);
    final active = widget.active ?? WindowActiveScope.of(context);
    final segments = widget.segments;
    final n = segments.length;
    final h = m.height;

    // Widths: icons are squares, text segments share the widest label's width.
    var textWidth = m.textSegmentWidth;
    for (final s in segments) {
      if (s.label case final label?) {
        final w = amalfiSegmentLabelWidth(context, label, m.labelStyle());
        if (w > textWidth) textWidth = w;
      }
    }
    final lefts = <double>[], widths = <double>[];
    var x = 0.0;
    for (final s in segments) {
      final w = s.isIcon ? m.iconSegmentWidth : textWidth;
      lefts.add(x);
      widths.add(w);
      x += w;
    }
    if (Directionality.of(context) == TextDirection.rtl) {
      for (var i = 0; i < n; i++) {
        lefts[i] = x - lefts[i] - widths[i];
      }
    }
    _lefts = lefts;
    _widths = widths;
    final width = x;
    final looks = [for (var i = 0; i < n; i++) _lookOf(i)];

    final layers = <Widget>[
      Positioned.fill(
        child: AmalfiGlass(
          material: AmalfiMaterials.regular,
          radius: h / 2,
          opaque: widget.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    ];

    // Highlights: one per segment, faded in and out.
    for (var i = 0; i < n; i++) {
      final look = looks[i];
      final shown = look != _Look.none;
      final rect = _highlightRect(i, shown ? look : _Look.hover, m);
      layers.add(
        Positioned.fromRect(
          rect: rect,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: shown
                ? AmalfiFades.quick.duration
                : amalfiSegmentHighlightOut,
            curve: AmalfiFades.quick.curve,
            child: DecoratedBox(
              key: ValueKey('amalfi-segment-highlight-$i'),
              decoration: AmalfiShapeDecoration(
                color: look == _Look.pressed
                    ? colors.lineBorder
                    : colors.lineSeparator,
                shape: AmalfiSmoothBorder(radius: rect.height / 2),
              ),
            ),
          ),
        ),
      );
    }

    // Separators, hidden next to a highlighted segment: on the leading edge of every segment
    // but the first.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    for (var i = 1; i < n; i++) {
      final shown = looks[i - 1] == _Look.none && looks[i] == _Look.none;
      layers.add(
        Positioned(
          left: rtl
              ? lefts[i] + widths[i] - AmalfiSegmentMetrics.separatorWidth
              : lefts[i],
          top: (h - m.separatorHeight) / 2,
          width: AmalfiSegmentMetrics.separatorWidth,
          height: m.separatorHeight,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: shown
                ? AmalfiFades.quick.duration
                : amalfiSegmentHighlightOut,
            child: ColoredBox(
              key: ValueKey('amalfi-segment-separator-$i'),
              color: colors.lineSeparator,
            ),
          ),
        ),
      );
    }

    // Content.
    for (var i = 0; i < n; i++) {
      final s = segments[i];
      final color = !active
          ? colors.textTertiary
          : widget.selected.contains(i)
          ? colors.accentAmalfi
          : colors.textPrimary;
      // A disabled segment of an enabled capsule dims its content; a disabled capsule dims
      // as a whole, below.
      final dim = _enabled && !s.enabled;
      Widget content;
      if (s.icon case final icon?) {
        content = Positioned(
          left: lefts[i] + (widths[i] - m.glyph) / 2,
          top: (h - m.glyph) / 2,
          child: AmalfiSegmentGlyph(
            key: ValueKey('amalfi-segment-glyph-$i'),
            size: m.glyph,
            color: color,
            child: icon,
          ),
        );
      } else {
        final lineHeight = m.labelToken.lineHeight ?? m.labelToken.size;
        content = Positioned(
          left: lefts[i],
          top: (h - lineHeight) / 2,
          width: widths[i],
          height: lineHeight,
          child: Text(
            s.label ?? '',
            key: ValueKey('amalfi-segment-label-$i'),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: m.labelStyle(color: color),
          ),
        );
      }
      if (dim) {
        content = Positioned.fill(
          child: Opacity(
            opacity: AmalfiStates.disabledOpacity,
            child: Stack(clipBehavior: Clip.none, children: [content]),
          ),
        );
      }
      layers.add(content);
    }

    // Semantics and tooltips, one box per segment.
    for (var i = 0; i < n; i++) {
      final s = segments[i];
      final enabled = _canPress(i);
      Widget box = const SizedBox.expand();
      if (s.tooltip case final tip?) {
        box = AmalfiTooltipRegion(message: tip, child: box);
      }
      layers.add(
        Positioned(
          left: lefts[i],
          top: 0,
          width: widths[i],
          height: h,
          child: Semantics(
            button: true,
            enabled: enabled,
            selected: widget.selected.contains(i) ? true : null,
            label: s.semanticsLabel,
            onTap: enabled ? () => widget.onPressed?.call(i) : null,
            child: box,
          ),
        ),
      );
    }

    if (_focused && n > 0 && _focusIndex < n) {
      final rect = _highlightRect(_focusIndex, _Look.hover, m);
      layers.add(
        Positioned.fromRect(
          rect: rect,
          child: AmalfiFocusHalo(radius: rect.height / 2),
        ),
      );
    }

    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (on) {
        if (on != _focused) setState(() => _focused = on);
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            final rtl = Directionality.of(context) == TextDirection.rtl;
            _moveFocus(rtl ? -intent.step : intent.step);
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activateFocused();
            return null;
          },
        ),
      },
      child: MouseRegion(
        onHover: _hover,
        onExit: _exit,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _cancel,
          child: SizedBox(
            width: width,
            height: h,
            child: _enabled
                ? Stack(clipBehavior: Clip.none, children: layers)
                : Opacity(
                    opacity: AmalfiStates.disabledOpacity,
                    child: Stack(clipBehavior: Clip.none, children: layers),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Moves the keyboard focus to the next ([step] 1) or previous (-1) segment.
class _MoveIntent extends Intent {
  const _MoveIntent(this.step);

  final int step;
}
