// The app window and the unified toolbar (windows.md, mustache-spec 1.2).
//
// With full-size content (Ossido's `silica-window-v1`, the embedder's `silica/window`
// channel) Ossido does not add its title bar: the app draws the toolbar at the top (52 pt)
// and Ossido puts the window buttons over it, centered in that band. Dragging the empty
// part of the bar moves the window (`WindowDragArea`).
//
// The toolbar capsules: 38 high with 7 pt above and below, radius 19; fill `#f6f6f6` →
// `#fdfdfd`, outline `#ebebeb` above, `#e8e7e8` below, `#c1c1c1` on the sides; the chosen segment
// is a 34 × 28 pill inset by 5 pt, `#e2e2e2` → `#e7e7e7`.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Height of the unified toolbar.
const double toolbarHeight = 52;
const double toolbarCapsuleHeight = 38;

/// The app window, towards Ossido.
abstract final class SilicaWindow {
  static const MethodChannel channel = MethodChannel(
    'silica/window',
    JSONMethodCodec(),
  );

  /// Full-size content with a toolbar `toolbar` high (0: back to Ossido's
  /// title bar). True if Ossido offers it.
  static Future<bool> setFullSizeContent(double toolbar) async {
    try {
      final reply = await channel.invokeMethod<Object?>('setFullSizeContent', {
        'toolbarHeight': toolbar,
      });
      return reply == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Chooses the window size (logical pixels). True if Silica applied it.
  static Future<bool> setSize(Size size) =>
      _call('setSize', {'width': size.width, 'height': size.height});

  /// Limits for resizing the window; `null` for no limit. `min` = `max` makes the window
  /// fixed-size: Ossido disables the zoom button. True if Silica applied them.
  static Future<bool> setSizeLimits({Size? min, Size? max}) =>
      _call('setSizeLimits', {
        if (min != null) 'minWidth': min.width,
        if (min != null) 'minHeight': min.height,
        if (max != null) 'maxWidth': max.width,
        if (max != null) 'maxHeight': max.height,
      });

  /// A fixed-size window of `size` (limits and size together).
  static Future<bool> setFixedSize(Size size) async =>
      await setSizeLimits(min: size, max: size) && await setSize(size);

  static Future<bool> _call(String method, Map<String, Object?> args) async {
    try {
      return await channel.invokeMethod<Object?>(method, args) == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Moves the window with the pointer pressed (from the toolbar).
  static Future<void> startMove() async {
    try {
      await channel.invokeMethod<Object?>('startMove');
    } on MissingPluginException {
      // Outside Silica the window does not move from here.
    } on PlatformException {
      // Likewise.
    }
  }
}

/// The empty part of the toolbar: dragging it moves the window. Controls inside
/// `child` receive their clicks as usual.
class WindowDragArea extends StatelessWidget {
  const WindowDragArea({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: {
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            PanGestureRecognizer.new,
            (r) => r.onStart = (_) => SilicaWindow.startMove(),
          ),
    },
    child: child,
  );
}

/// The toolbar colors (mustache-spec 1.2; states from mustache.md M6 › MU-07, measured at
/// the center of the pill, outside the glyph).
@immutable
class ToolbarColors {
  const ToolbarColors({
    required this.fill,
    required this.fillBarHover,
    required this.fillInactive,
    required this.borderTop,
    required this.borderBottom,
    required this.borderSide,
    required this.hover,
    required this.hoverInactive,
    required this.pressed,
    required this.chosen,
    required this.chosenHover,
    required this.chosenPressed,
    required this.chosenInactive,
    required this.chosenHoverInactive,
    required this.disabledPressed,
    required this.separator,
    required this.icon,
    required this.iconPressed,
    required this.iconInactive,
    required this.iconDisabled,
    required this.title,
    required this.titleInactive,
  });

  /// The capsule fill at rest; with the pointer in the bar (in dark +7 levels);
  /// in the inactive window.
  final Color fill;
  final Color fillBarHover;
  final Color fillInactive;
  final Color borderTop;
  final Color borderBottom;
  final Color borderSide;

  /// The pill under the pointer (active and inactive) and pressed.
  final Color hover;
  final Color hoverInactive;
  final Color pressed;

  /// The chosen segment: at rest, under the pointer, pressed; in the inactive window.
  final Color chosen;
  final Color chosenHover;
  final Color chosenPressed;
  final Color chosenInactive;
  final Color chosenHoverInactive;

  /// A disabled segment pressed (in dark a faint pill; in light nothing).
  final Color? disabledPressed;
  final Color separator;
  final Color icon;
  final Color iconPressed;
  final Color iconInactive;
  final Color iconDisabled;
  final Color title;
  final Color titleInactive;

  static const ToolbarColors light = ToolbarColors(
    fill: Color(0xFFF8F8F8),
    fillBarHover: Color(0xFFF8F8F8),
    fillInactive: Color(0xFFF0F0F0),
    borderTop: Color(0xFFEBEBEB),
    borderBottom: Color(0xFFE8E7E8),
    borderSide: Color(0xFFC1C1C1),
    hover: Color(0xFFEEEEEE),
    hoverInactive: Color(0xFFE6E6E6),
    pressed: Color(0xFFE8E8E8),
    chosen: Color(0xFFE5E5E5),
    chosenHover: Color(0xFFDBDBDB),
    chosenPressed: Color(0xFFD2D2D2),
    chosenInactive: Color(0xFFDCDCDC),
    chosenHoverInactive: Color(0xFFD2D2D2),
    disabledPressed: null,
    separator: Color(0xFFC7C7C7),
    icon: Color(0xFF000000),
    iconPressed: Color(0xFF232323),
    iconInactive: Color(0xFFA4A4A4),
    iconDisabled: Color(0xFFADADAD),
    title: Color(0xFF4D4D4D),
    titleInactive: Color(0xFFBEBEBE),
  );

  /// Dark: capsule `#434344` (`#4a4a4b` with the pointer in the bar), outline
  /// `#79797b` / `#6c6e6e` / `#131313`, separator `#7a7a7a`, title `#e9e9e9` / `#646464`.
  static const ToolbarColors dark = ToolbarColors(
    fill: Color(0xFF434344),
    fillBarHover: Color(0xFF4A4A4B),
    fillInactive: Color(0xFF424243),
    borderTop: Color(0xFF79797B),
    borderBottom: Color(0xFF6C6E6E),
    borderSide: Color(0xFF131313),
    hover: Color(0xFF5E5E5F),
    hoverInactive: Color(0xFF565657),
    pressed: Color(0xFF737374),
    chosen: Color(0xFF575758),
    chosenHover: Color(0xFF727273),
    chosenPressed: Color(0xFF757576),
    chosenInactive: Color(0xFF565657),
    chosenHoverInactive: Color(0xFF6A6A6B),
    disabledPressed: Color(0xFF626264),
    separator: Color(0xFF7A7A7A),
    icon: Color(0xFFFFFFFF),
    iconPressed: Color(0xFFF8F8F8),
    iconInactive: Color(0xFF757576),
    iconDisabled: Color(0xFF787879),
    title: Color(0xFFE9E9E9),
    titleInactive: Color(0xFF646464),
  );

  /// Following the system appearance (`MediaQuery.platformBrightness`).
  static ToolbarColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;
}

/// The bar state the controls read: the active window and the pointer in the bar
/// (in dark the capsules lighten by 7 levels).
class ToolbarScope extends InheritedWidget {
  const ToolbarScope({
    super.key,
    required super.child,
    this.active = true,
    this.hovered = false,
  });

  final bool active;
  final bool hovered;

  static ToolbarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolbarScope>();

  @override
  bool updateShouldNotify(ToolbarScope old) =>
      old.active != active || old.hovered != hovered;
}

/// The long-press delay (history menu on Back and Forward, MU-07).
const Duration toolbarLongPress = Duration(milliseconds: 295);

/// A toolbar capsule: 38 high, radius 19, with the segments in a row. A single segment as wide
/// as it is high becomes a circle (Search). Next to the segment under the pointer the
/// separators disappear; with a segment pressed the capsule grows by 1 pt per side.
class ToolbarCapsule extends StatefulWidget {
  const ToolbarCapsule({
    super.key,
    required this.children,
    this.separators = false,
  });

  final List<Widget> children;

  /// A 1 × 21 line between the segments (Back / Forward).
  final bool separators;

  @override
  State<ToolbarCapsule> createState() => _ToolbarCapsuleState();
}

class _ToolbarCapsuleState extends State<ToolbarCapsule> {
  int? _hovered;
  int? _pressed;

  void _hover(int index, bool on) {
    final next = on ? index : (_hovered == index ? null : _hovered);
    if (next != _hovered) setState(() => _hovered = next);
  }

  void _press(int index, bool on) {
    final next = on ? index : (_pressed == index ? null : _pressed);
    if (next != _pressed) setState(() => _pressed = next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ToolbarColors.of(context);
    final scope = ToolbarScope.maybeOf(context);
    final active = scope?.active ?? true;
    final fill = !active
        ? colors.fillInactive
        : (scope?.hovered ?? false)
        ? colors.fillBarHover
        : colors.fill;
    final children = widget.children;
    final capsule = Container(
      height: toolbarCapsuleHeight,
      // The outline: a 1 pt ring, light above and below, darker on the sides.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.borderTop, colors.borderSide, colors.borderBottom],
        ),
        borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2),
      ),
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2 - 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (widget.separators && i > 0)
                Container(
                  width: 1,
                  height: 21,
                  color: _hovered == i || _hovered == i - 1
                      ? null
                      : colors.separator,
                ),
              _CapsuleSlot(
                index: i,
                single: children.length == 1,
                onHover: _hover,
                onPress: _press,
                child: children[i],
              ),
            ],
          ],
        ),
      ),
    );
    // Pressed: +1 pt per side (Back/Forward 407–481 → 406–482).
    return _GrowByOne(grow: _pressed != null, child: capsule);
  }
}

/// The pressed capsule: 1 pt more per side, around the center (only when painting).
class _GrowByOne extends SingleChildRenderObjectWidget {
  const _GrowByOne({required this.grow, super.child});
  final bool grow;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGrow(grow);

  @override
  void updateRenderObject(BuildContext context, _RenderGrow renderObject) =>
      renderObject.grow = grow;
}

class _RenderGrow extends RenderProxyBox {
  _RenderGrow(this._grow);

  bool _grow;
  bool get grow => _grow;
  set grow(bool value) {
    if (value == _grow) return;
    _grow = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final w = size.width, h = size.height;
    if (!_grow || w <= 0 || h <= 0) return super.paint(context, offset);
    final sx = (w + 2) / w, sy = (h + 2) / h;
    final transform = Matrix4.identity()
      ..translateByDouble(w / 2, h / 2, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-w / 2, -h / 2, 0, 1);
    context.pushTransform(needsCompositing, offset, transform, super.paint);
  }
}

class _CapsuleSlot extends InheritedWidget {
  const _CapsuleSlot({
    required this.index,
    required this.single,
    required this.onHover,
    required this.onPress,
    required super.child,
  });

  final int index;

  /// The only segment: the pill is the capsule inset by 1 pt (Search 36 × 34).
  final bool single;
  final void Function(int index, bool on) onHover;
  final void Function(int index, bool on) onPress;

  static _CapsuleSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CapsuleSlot>();

  @override
  bool updateShouldNotify(_CapsuleSlot old) =>
      old.index != index || old.single != single;
}

/// A capsule segment: `width` wide, with the icon drawn in the color it receives.
/// The pill (28 high, the segment width − 3) appears under the pointer and darkens on
/// press; the chosen segment always keeps it. Disabled: no pill, no action.
/// The click acts on release; with [onLongPress], held for [toolbarLongPress] it opens the menu and
/// the release no longer acts. [onPress] acts on press (buttons with a menu).
class ToolbarSegment extends StatefulWidget {
  const ToolbarSegment({
    super.key,
    required this.icon,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.width = 38,
    this.chosen = false,
    this.enabled = true,
  });

  final Widget Function(Color color) icon;
  final VoidCallback? onTap;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final double width;
  final bool chosen;
  final bool enabled;

  @override
  State<ToolbarSegment> createState() => _ToolbarSegmentState();
}

class _ToolbarSegmentState extends State<ToolbarSegment> {
  bool _hover = false;
  bool _pressed = false;
  bool _held = false;
  Timer? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _setHover(bool on) {
    if (on == _hover) return;
    setState(() => _hover = on);
    _CapsuleSlot.maybeOf(
      context,
    )?.onHover(_CapsuleSlot.maybeOf(context)?.index ?? 0, on && widget.enabled);
  }

  void _setPressed(bool on) {
    if (on == _pressed) return;
    setState(() => _pressed = on);
    final slot = _CapsuleSlot.maybeOf(context);
    if (widget.enabled) slot?.onPress(slot.index, on);
  }

  void _down(PointerDownEvent e) {
    if (e.buttons & kPrimaryButton == 0) return;
    _setPressed(true);
    if (!widget.enabled) return;
    _held = false;
    widget.onPress?.call();
    final long = widget.onLongPress;
    if (long != null) {
      _hold?.cancel();
      _hold = Timer(toolbarLongPress, () {
        _held = true;
        long();
      });
    }
  }

  void _up(PointerUpEvent e) {
    _hold?.cancel();
    final inside = _pressed;
    _setPressed(false);
    if (!widget.enabled || _held || !inside) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.size.contains(e.localPosition)) {
      widget.onTap?.call();
    }
  }

  void _cancel() {
    _hold?.cancel();
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ToolbarColors.of(context);
    final active = ToolbarScope.maybeOf(context)?.active ?? true;
    final slot = _CapsuleSlot.maybeOf(context);
    final enabled = widget.enabled;
    final chosen = widget.chosen;
    final Color? pill = !enabled
        ? (_pressed ? colors.disabledPressed : null)
        : _pressed
        ? (chosen ? colors.chosenPressed : colors.pressed)
        : _hover
        ? (chosen
              ? (active ? colors.chosenHover : colors.chosenHoverInactive)
              : (active ? colors.hover : colors.hoverInactive))
        : chosen
        ? (active ? colors.chosen : colors.chosenInactive)
        : null;
    final glyph = !enabled
        ? colors.iconDisabled
        : _pressed
        ? colors.iconPressed
        : (!active && !_hover)
        ? colors.iconInactive
        : colors.icon;
    final single = slot?.single ?? false;
    final pillWidth = single ? widget.width - 2 : widget.width - 3;
    final pillHeight = single ? toolbarCapsuleHeight - 4 : 28.0;
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: (_) => _cancel(),
        // The segment keeps tap and drag to itself: a drag from a control does not move the
        // window (WindowDragArea), MU-08.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onPanStart: (_) {},
          child: SizedBox(
            width: widget.width,
            height: toolbarCapsuleHeight - 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (pill != null)
                  Container(
                    key: const ValueKey('pill'),
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: pill,
                      borderRadius: BorderRadius.circular(pillHeight / 2),
                    ),
                  ),
                widget.icon(glyph),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
