// File thumbnails: the system thumbnail service (silica-daemon,
// `dev.frascella.Silica.Thumbnails1`), cached per the freedesktop thumbnail specification.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The system thumbnail service over the embedder's `silica/dbus` channel. Outside Silica (no
/// channel, no daemon) there are no thumbnails and callers keep their fallback.
abstract final class SilicaThumbnails {
  static const MethodChannel channel = MethodChannel(
    'silica/dbus',
    JSONMethodCodec(),
  );

  static const String _name = 'dev.frascella.Silica';
  static const String _path = '/dev/frascella/Silica/Thumbnails1';
  static const String _interface = 'dev.frascella.Silica.Thumbnails1';

  static final Map<String, Future<String?>> _pending = {};

  static Future<List<Object?>> _call(
    String method,
    String signature,
    List<Object?> args,
  ) async {
    final reply = await channel.invokeMethod<List<Object?>>('call', {
      'bus': 'session',
      'destination': _name,
      'path': _path,
      'interface': _interface,
      'method': method,
      'signature': signature,
      'args': args,
    });
    return reply ?? const [];
  }

  /// The path of the cached PNG of [file] for [sizePx] device pixels, or null when the file has
  /// no thumbnail or the service is not there. Equal requests in flight share one call. The
  /// image is at least [sizePx] on its longest edge unless the source is smaller.
  static Future<String?> thumbnail(Uri file, int sizePx) {
    if (sizePx <= 0) return Future.value();
    final key = '$sizePx $file';
    return _pending[key] ??= _request(file, sizePx).whenComplete(() {
      _pending.remove(key);
    });
  }

  static Future<String?> _request(Uri file, int sizePx) async {
    try {
      final reply = await _call('Thumbnail', 'su', [file.toString(), sizePx]);
      final path = reply.isEmpty ? null : reply.first;
      return path is String && path.isNotEmpty ? path : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Tells the service that [files] changed, so it forgets their thumbnails.
  static Future<void> invalidate(List<Uri> files) async {
    if (files.isEmpty) return;
    try {
      await _call('Invalidate', 'as', [
        [for (final f in files) f.toString()],
      ]);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

/// The thumbnail of [file], [size] logical pixels square at most. It asks the service for
/// `size * devicePixelRatio` pixels and shows [fallback] (the file-type icon, say) until the
/// image is there, and for good when the file has no thumbnail or the service is missing.
class SilicaThumbnail extends StatefulWidget {
  const SilicaThumbnail({
    super.key,
    required this.file,
    required this.size,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  /// The file, as a `file://` URI.
  final Uri file;

  /// The edge of the box, in logical pixels.
  final double size;

  /// Shown until the thumbnail is ready, or when there is none. Sized by the caller.
  final Widget fallback;

  final BoxFit fit;

  @override
  State<SilicaThumbnail> createState() => _SilicaThumbnailState();
}

class _SilicaThumbnailState extends State<SilicaThumbnail> {
  String? _path;
  int _requested = 0;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(SilicaThumbnail old) {
    super.didUpdateWidget(old);
    if (old.file != widget.file || old.size != widget.size) _load();
  }

  void _load() {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final px = (widget.size * dpr).ceil();
    if (px <= 0 || !px.isFinite) return;
    // A bigger request than the last one for the same file asks again; a smaller one keeps the
    // image it has.
    final sameFile = _path != null && _file == widget.file;
    if (sameFile && px <= _requested) return;
    if (!sameFile) _path = null;
    _file = widget.file;
    _requested = px;
    final generation = ++_generation;
    SilicaThumbnails.thumbnail(widget.file, px).then((path) {
      if (!mounted || generation != _generation || path == null) return;
      setState(() => _path = path);
    });
  }

  Uri? _file;

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path == null) return widget.fallback;
    return Image.file(
      File(path),
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}
