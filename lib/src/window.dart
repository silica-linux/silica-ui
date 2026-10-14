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

import 'package:flutter/gestures.dart';
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

/// I colori della barra degli strumenti (chiaro).
abstract final class ToolbarColors {
  static const Color fillTop = Color(0xFFF6F6F6);
  static const Color fillBottom = Color(0xFFFDFDFD);
  static const Color borderTop = Color(0xFFEBEBEB);
  static const Color borderBottom = Color(0xFFE8E7E8);
  static const Color borderSide = Color(0xFFC1C1C1);
  static const Color chosenTop = Color(0xFFE2E2E2);
  static const Color chosenBottom = Color(0xFFE7E7E7);
  static const Color separator = Color(0xFFC7C7C7);
  static const Color icon = Color(0xFF000000);
  static const Color iconDisabled = Color(0xFFABABAB);
  static const Color title = Color(0xFF4D4D4D);
  static const Color titleInactive = Color(0xFFBEBEBE);
}

/// Una capsula della barra: alta 38, raggio 19, con i segmenti in fila. Un solo segmento largo
/// quanto è alto diventa un cerchio (Cerca).
class ToolbarCapsule extends StatelessWidget {
  const ToolbarCapsule({
    super.key,
    required this.children,
    this.separators = false,
  });

  final List<Widget> children;

  /// Una riga di 1 × 21 fra i segmenti (Indietro / Avanti).
  final bool separators;

  @override
  Widget build(BuildContext context) => Container(
    height: toolbarCapsuleHeight,
    // Il contorno: un anello di 1 pt chiaro sopra e sotto, più scuro ai lati.
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ToolbarColors.borderTop,
          ToolbarColors.borderSide,
          ToolbarColors.borderBottom,
        ],
      ),
      borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2),
    ),
    padding: const EdgeInsets.all(1),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ToolbarColors.fillTop, ToolbarColors.fillBottom],
        ),
        borderRadius: BorderRadius.circular(toolbarCapsuleHeight / 2 - 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (separators && i > 0)
              Container(width: 1, height: 21, color: ToolbarColors.separator),
            children[i],
          ],
        ],
      ),
    ),
  );
}

/// Un segmento di capsula: largo `width`, con l'icona disegnata nel colore che riceve; la
/// pillola 34 × 28 se è il segmento scelto.
class ToolbarSegment extends StatelessWidget {
  const ToolbarSegment({
    super.key,
    required this.icon,
    this.onTap,
    this.width = 38,
    this.chosen = false,
    this.enabled = true,
  });

  final Widget Function(Color color) icon;
  final VoidCallback? onTap;
  final double width;
  final bool chosen;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: enabled ? onTap : null,
    child: SizedBox(
      width: width,
      height: toolbarCapsuleHeight - 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (chosen)
            Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ToolbarColors.chosenTop, ToolbarColors.chosenBottom],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          icon(enabled ? ToolbarColors.icon : ToolbarColors.iconDisabled),
        ],
      ),
    ),
  );
}
