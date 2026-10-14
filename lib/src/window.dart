// La finestra dell'app e la barra degli strumenti unificata (windows.md, mustache-spec 1.2).
//
// Con il contenuto a tutta finestra (`silica-window-v1` di Ossido, canale `silica/window`
// dell'embedder) Ossido non aggiunge la sua barra del titolo: l'app disegna la barra degli
// strumenti in cima (52 pt) e Ossido mette i pulsanti della finestra sopra, centrati in quella
// fascia. Trascinando il vuoto della barra si sposta la finestra (`WindowDragArea`).
//
// Le capsule della barra: alte 38 con 7 pt sopra e sotto, raggio 19; fondo `#f6f6f6` →
// `#fdfdfd`, contorno `#ebebeb` sopra, `#e8e7e8` sotto, `#c1c1c1` ai lati; il segmento scelto è
// una pillola 34 × 28 rientrata di 5 pt, `#e2e2e2` → `#e7e7e7`.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Altezza della barra degli strumenti unificata.
const double toolbarHeight = 52;
const double toolbarCapsuleHeight = 38;

/// La finestra dell'app verso Ossido.
abstract final class SilicaWindow {
  static const MethodChannel channel = MethodChannel(
    'silica/window',
    JSONMethodCodec(),
  );

  /// Contenuto a tutta finestra con una barra degli strumenti alta `toolbar` (0: torna alla
  /// barra di Ossido). Vero se Ossido lo offre.
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

  /// Sposta la finestra con il puntatore premuto (dalla barra degli strumenti).
  static Future<void> startMove() async {
    try {
      await channel.invokeMethod<Object?>('startMove');
    } on MissingPluginException {
      // Fuori da Silica la finestra non si sposta da qui.
    } on PlatformException {
      // Idem.
    }
  }
}

/// Il vuoto della barra degli strumenti: trascinandolo si sposta la finestra. I controlli
/// dentro `child` ricevono i loro clic come sempre.
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

/// I colori della barra degli strumenti (mustache-spec 1.2; stati da mustache.md M6 › MU-07,
/// misurati al centro della pillola, fuori dal glifo).
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

  /// Il fondo della capsula a riposo; con il puntatore nella barra (in scuro +7 livelli);
  /// nella finestra inattiva.
  final Color fill;
  final Color fillBarHover;
  final Color fillInactive;
  final Color borderTop;
  final Color borderBottom;
  final Color borderSide;

  /// La pillola sotto il puntatore (attiva e inattiva) e premuta.
  final Color hover;
  final Color hoverInactive;
  final Color pressed;

  /// Il segmento scelto: riposo, sotto il puntatore, premuto; nella finestra inattiva.
  final Color chosen;
  final Color chosenHover;
  final Color chosenPressed;
  final Color chosenInactive;
  final Color chosenHoverInactive;

  /// Un segmento disattivato premuto (in scuro una pillola tenue; in chiaro niente).
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

  /// Scuro: capsula `#434344` (`#4a4a4b` con il puntatore nella barra), contorno
  /// `#79797b` / `#6c6e6e` / `#131313`, separatore `#7a7a7a`, titolo `#e9e9e9` / `#646464`.
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

  /// Secondo l'aspetto del sistema (`MediaQuery.platformBrightness`).
  static ToolbarColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;
}

/// Lo stato della barra che i controlli leggono: la finestra attiva e il puntatore nella barra
/// (in scuro le capsule si schiariscono di 7 livelli).
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

/// Il ritardo della pressione lunga (menu della cronologia su Indietro e Avanti, MU-07).
const Duration toolbarLongPress = Duration(milliseconds: 295);

/// Una capsula della barra: alta 38, raggio 19, con i segmenti in fila. Un solo segmento largo
/// quanto è alto diventa un cerchio (Cerca). Accanto al segmento sotto il puntatore i
/// separatori spariscono; con un segmento premuto la capsula cresce di 1 pt per lato.
class ToolbarCapsule extends StatefulWidget {
  const ToolbarCapsule({
    super.key,
    required this.children,
    this.separators = false,
  });

  final List<Widget> children;

  /// Una riga di 1 × 21 fra i segmenti (Indietro / Avanti).
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
      // Il contorno: un anello di 1 pt chiaro sopra e sotto, più scuro ai lati.
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
    // Premuta: +1 pt per lato (Indietro/Avanti 407–481 → 406–482).
    return _GrowByOne(grow: _pressed != null, child: capsule);
  }
}

/// La capsula premuta: 1 pt in più per lato, attorno al centro (solo nel disegno).
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

  /// L'unico segmento: la pillola è la capsula rientrata di 1 pt (Cerca 36 × 34).
  final bool single;
  final void Function(int index, bool on) onHover;
  final void Function(int index, bool on) onPress;

  static _CapsuleSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CapsuleSlot>();

  @override
  bool updateShouldNotify(_CapsuleSlot old) =>
      old.index != index || old.single != single;
}

/// Un segmento di capsula: largo `width`, con l'icona disegnata nel colore che riceve.
/// La pillola (alta 28, larga il segmento − 3) compare sotto il puntatore e si scurisce alla
/// pressione; il segmento scelto la tiene sempre. Disattivato: nessuna pillola, nessuna azione.
/// Il clic agisce al rilascio; con [onLongPress], tenuto [toolbarLongPress] apre il menu e il
/// rilascio non agisce più. [onPress] agisce alla pressione (i pulsanti con un menu).
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
        child: SizedBox(
          width: widget.width,
          height: toolbarCapsuleHeight - 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pill != null)
                Container(
                  key: const ValueKey('pillola'),
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
    );
  }
}
