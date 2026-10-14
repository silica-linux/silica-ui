// Drag and drop between apps (Ossido's `wl_data_device`), on the embedder's `silica/drag`
// channel: an app carries a list of files (`text/uri-list`) out of its window and receives
// them from others. Inside the window the drag stays Flutter's (`Draggable`): it is handed to
// Ossido when the pointer leaves, and the embedder cancels Flutter's gesture.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An event of a drag between apps.
@immutable
sealed class SilicaDragEvent {
  const SilicaDragEvent();
}

/// A drag carrying files enters the window, or moves over it (logical coordinates).
class SilicaDragOver extends SilicaDragEvent {
  const SilicaDragOver(this.position, {required this.entered});
  final ui.Offset position;
  final bool entered;
}

/// The drag leaves the window without a drop.
class SilicaDragLeave extends SilicaDragEvent {
  const SilicaDragLeave();
}

/// The drop in the window, with the URIs of the files.
class SilicaDrop extends SilicaDragEvent {
  const SilicaDrop(this.position, this.uris);
  final ui.Offset position;
  final List<Uri> uris;

  /// The local paths (`file://`), other URIs left out.
  List<String> get paths => [
    for (final uri in uris)
      if (uri.scheme == 'file') uri.toFilePath(),
  ];
}

/// The drag that left this window has finished: `copy`, `move` or `none` (cancelled).
class SilicaDragFinished extends SilicaDragEvent {
  const SilicaDragFinished(this.action);
  final String action;
}

/// Drag and drop between apps, through Ossido.
abstract final class SilicaDrag {
  static const MethodChannel channel = MethodChannel(
    'silica/drag',
    JSONMethodCodec(),
  );

  static final StreamController<SilicaDragEvent> _events =
      StreamController.broadcast(onListen: _listen);

  /// The events of drags between apps.
  static Stream<SilicaDragEvent> get events => _events.stream;

  static void _listen() => channel.setMethodCallHandler((call) async {
    final event = parse(call.method, call.arguments);
    if (event != null) _events.add(event);
    return null;
  });

  /// An event from the embedder's call; null if it is not one.
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

  /// Carries the files `paths` out of the window (with the button still pressed), with the
  /// image `icon` on the pointer. True if Ossido took it.
  static Future<bool> start(List<String> paths, {ui.Image? icon}) async {
    final args = <String, Object?>{
      'uris': [for (final p in paths) Uri.file(p).toString()],
    };
    if (icon != null) {
      // rawRgba: premultiplied, as Wayland wants.
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
