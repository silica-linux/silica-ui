// Il trascinamento fra app (`wl_data_device` di Ossido), canale `silica/drag` dell'embedder:
// un'app porta fuori dalla sua finestra un elenco di file (`text/uri-list`) e ne riceve da
// altre. Dentro la finestra il trascinamento resta di Flutter (`Draggable`): si passa a Ossido
// quando il puntatore esce, e l'embedder annulla il gesto di Flutter.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Un evento del trascinamento fra app.
@immutable
sealed class SilicaDragEvent {
  const SilicaDragEvent();
}

/// Un trascinamento con dei file entra nella finestra, o vi si muove (coordinate logiche).
class SilicaDragOver extends SilicaDragEvent {
  const SilicaDragOver(this.position, {required this.entered});
  final ui.Offset position;
  final bool entered;
}

/// Il trascinamento esce dalla finestra senza rilascio.
class SilicaDragLeave extends SilicaDragEvent {
  const SilicaDragLeave();
}

/// Il rilascio nella finestra, con gli URI dei file.
class SilicaDrop extends SilicaDragEvent {
  const SilicaDrop(this.position, this.uris);
  final ui.Offset position;
  final List<Uri> uris;

  /// I percorsi locali (`file://`), gli altri URI esclusi.
  List<String> get paths => [
    for (final uri in uris)
      if (uri.scheme == 'file') uri.toFilePath(),
  ];
}

/// Il trascinamento uscito da questa finestra è finito: `copy`, `move` o `none` (annullato).
class SilicaDragFinished extends SilicaDragEvent {
  const SilicaDragFinished(this.action);
  final String action;
}

/// Il trascinamento fra app verso Ossido.
abstract final class SilicaDrag {
  static const MethodChannel channel = MethodChannel(
    'silica/drag',
    JSONMethodCodec(),
  );

  static final StreamController<SilicaDragEvent> _events =
      StreamController.broadcast(onListen: _listen);

  /// Gli eventi del trascinamento fra app.
  static Stream<SilicaDragEvent> get events => _events.stream;

  static void _listen() => channel.setMethodCallHandler((call) async {
    final event = parse(call.method, call.arguments);
    if (event != null) _events.add(event);
    return null;
  });

  /// Un evento dalla chiamata dell'embedder; null se non lo è.
  static SilicaDragEvent? parse(String method, Object? args) {
    final map = args is Map ? args : const {};
    final x = map['x'], y = map['y'];
    final at = x is num && y is num
        ? ui.Offset(x.toDouble(), y.toDouble())
        : ui.Offset.zero;
    return switch (method) {
      'enter' => SilicaDragOver(at, entered: true),
      'motion' => SilicaDragOver(at, entered: false),
      'leave' => const SilicaDragLeave(),
      'drop' => SilicaDrop(at, [
        for (final u in map['uris'] is List ? map['uris'] as List : const [])
          if (u is String) ?Uri.tryParse(u),
      ]),
      'finished' => SilicaDragFinished(
        map['action'] is String ? map['action'] as String : 'none',
      ),
      _ => null,
    };
  }

  /// Porta fuori dalla finestra i file `paths` (con il pulsante ancora premuto), con
  /// l'immagine `icon` sul puntatore. Vero se Ossido l'ha preso.
  static Future<bool> start(List<String> paths, {ui.Image? icon}) async {
    final args = <String, Object?>{
      'uris': [for (final p in paths) Uri.file(p).toString()],
    };
    if (icon != null) {
      // rawRgba: premoltiplicato, come vuole Wayland.
      final bytes = await icon.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes != null) {
        args['icon'] = {
          'width': icon.width,
          'height': icon.height,
          'rgba': base64Encode(bytes.buffer.asUint8List()),
        };
      }
    }
    try {
      return await channel.invokeMethod<bool>('start', args) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
