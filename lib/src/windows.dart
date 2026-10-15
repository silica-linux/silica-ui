// Several windows in one app (silica-desktop#146): Get Info, a compose window, File › New
// Window, one window per document. Every window is a view of the app's one Flutter engine,
// with its own xdg_toplevel in Ossido (title, buttons, glass, resizing), so the windows share
// the app's state and its Dart isolate.
//
// The app must be started with `--multi-window` (its `.desktop` entry). Without it, or outside
// Silica, `SilicaWindows.open` returns null and the app can fall back to a sheet or a popover.
//
//     // Once, around the app's content (inside WidgetsApp's `builder`, so the windows get its
//     // localizations and theme; above SilicaAppWindow, so they outlive the main window):
//     SilicaWindowHost(child: child)
//
//     // Anywhere:
//     final info = await SilicaWindows.open(
//       title: 'Notes Info',
//       size: const Size(265, 520),
//       kind: SilicaWindowKind.utility,
//       parent: View.of(context).viewId,
//       builder: (context) => InfoPanel(file),
//     );
//     await info?.closed; // the user closed it, or the app did with info.close()

import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'appearance.dart';
import 'window.dart';

/// The kind of a window: a document or browser window, or a utility (an inspector, Get
/// Info).
enum SilicaWindowKind { regular, utility }

/// A window of the app other than its main one, from [SilicaWindows.open].
class SilicaWindowController {
  SilicaWindowController._(this.view, this.builder);

  /// The window's view in the engine; [viewId] names the window on `silica/window`.
  final FlutterView view;
  int get viewId => view.viewId;

  /// Builds the window's content, inside its own `View` (its MediaQuery, focus and size).
  final WidgetBuilder builder;

  /// Asked when the user presses the window's close button: complete with false to keep the
  /// window open (to ask to save a draft first, then [close] it). Without it the window
  /// closes at once.
  Future<bool> Function()? onCloseRequested;

  final Completer<void> _closed = Completer<void>();

  /// Completes when the window is gone (its close button, [close], or the app ending it).
  Future<void> get closed => _closed.future;

  /// Whether the window is still open.
  bool get isOpen => !_closed.isCompleted;

  /// Closes the window.
  Future<void> close() =>
      SilicaWindows._invoke('closeWindow', {'viewId': viewId});

  /// The window title (the Window menu, the switcher).
  Future<bool> setTitle(String title) async =>
      await SilicaWindows._invoke<bool>('setTitle', {
        'viewId': viewId,
        'title': title,
      }) ??
      false;

  /// Full-size content with the window's own toolbar this high (0: Ossido's title bar).
  Future<bool> setFullSizeContent(double toolbar) =>
      SilicaWindow.setFullSizeContent(toolbar, viewId: viewId);

  /// The window size, in logical pixels.
  Future<bool> setSize(Size size) => SilicaWindow.setSize(size, viewId: viewId);

  /// Limits for resizing the window; min = max makes it fixed-size.
  Future<bool> setSizeLimits({Size? min, Size? max}) =>
      SilicaWindow.setSizeLimits(min: min, max: max, viewId: viewId);

  void _gone() {
    if (!_closed.isCompleted) _closed.complete();
  }
}

/// Opens and tracks the app's other windows (silica-desktop#146); [SilicaWindowHost] builds
/// them.
abstract final class SilicaWindows {
  static final ValueNotifier<List<SilicaWindowController>> _open =
      ValueNotifier(const []);
  static bool _listening = false;

  static Future<bool> Function()? _onMainCloseRequested;

  /// Asked when the user closes the app's main window (its close button, Logo+W): complete
  /// with false to keep the window open (to ask "close anyway?" first), true to let it close.
  /// The same contract as [SilicaWindowController.onCloseRequested]. Without it, or outside
  /// Silica, the window closes at once. Closing it still follows the app lifecycle (the
  /// app keeps running when it is not the last window).
  static Future<bool> Function()? get onMainCloseRequested =>
      _onMainCloseRequested;
  static set onMainCloseRequested(Future<bool> Function()? ask) {
    _onMainCloseRequested = ask;
    if (ask != null) _listen();
  }

  /// The windows open now (not the main one), in opening order.
  static ValueListenable<List<SilicaWindowController>> get open => _open;

  /// Opens a window of [size] (logical pixels) and builds it with [builder]. [parent] is the
  /// view id of the window it belongs to (0 for the main window): it stays above it, as Get
  /// Info and compose windows do. [toolbarHeight] gives the window full-size content from
  /// its first frame. Null when the system cannot open windows (an app not started with
  /// `--multi-window`, an older Silica, tests).
  static Future<SilicaWindowController?> openWindow({
    required String title,
    required Size size,
    required WidgetBuilder builder,
    Size? minSize,
    Size? maxSize,
    SilicaWindowKind kind = SilicaWindowKind.regular,
    int? parent,
    double? toolbarHeight,
  }) async {
    _listen();
    final id = await _invoke<Object?>('openWindow', {
      'title': title,
      'width': size.width,
      'height': size.height,
      if (minSize != null) 'minWidth': minSize.width,
      if (minSize != null) 'minHeight': minSize.height,
      if (maxSize != null) 'maxWidth': maxSize.width,
      if (maxSize != null) 'maxHeight': maxSize.height,
      'kind': kind.name,
      'parent': ?parent,
      'toolbarHeight': ?toolbarHeight,
    });
    if (id is! int) return null;
    final view = _viewWithId(id);
    if (view == null) return null;
    final controller = SilicaWindowController._(view, builder);
    _open.value = [..._open.value, controller];
    // The app-wide appearance override, when no scope of the app sends its own.
    if (activeAppearanceScopes == 0 &&
        appAppearance.value != SilicaAppearance.system) {
      unawaited(SilicaWindow.setAppearance(appAppearance.value, viewId: id));
    }
    return controller;
  }

  static FlutterView? _viewWithId(int id) {
    for (final view in WidgetsBinding.instance.platformDispatcher.views) {
      if (view.viewId == id) return view;
    }
    return null;
  }

  static SilicaWindowController? _withId(Object? id) {
    for (final window in _open.value) {
      if (window.viewId == id) return window;
    }
    return null;
  }

  /// A call from the embedder on `silica/window`; the reply goes back to it (for tests).
  @visibleForTesting
  static Future<Object?> handle(String method, Object? args) async {
    final id = args is Map ? args['viewId'] : null;
    switch (method) {
      case 'closeRequested':
        final window = _withId(id);
        if (window == null) {
          // The main window: true tells the embedder the app dealt with it (kept it open);
          // false lets the embedder close it.
          final ask = id == 0 ? _onMainCloseRequested : null;
          return ask != null && !await ask();
        }
        final ask = window.onCloseRequested;
        if (ask != null && !await ask()) return true;
        await window.close();
        return true;
      case 'windowClosed':
        final window = _withId(id);
        if (window == null) return null;
        _open.value = [
          for (final other in _open.value)
            if (other != window) other,
        ];
        window._gone();
    }
    return null;
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    SilicaWindow.channel.setMethodCallHandler(
      (call) => handle(call.method, call.arguments),
    );
  }

  static Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await SilicaWindow.channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      // Outside Silica (tests, another embedder): no other windows.
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Back to the initial state (tests).
  @visibleForTesting
  static void reset() {
    for (final window in _open.value) {
      window._gone();
    }
    _open.value = const [];
    _onMainCloseRequested = null;
    _listening = false;
  }
}

/// Builds the app's other windows next to [child], each in its own `View`: they inherit
/// what is above the host (localizations, theme, the app's models). Put it once around the
/// app's content, above `SilicaAppWindow` (the other windows outlive the main one).
class SilicaWindowHost extends StatelessWidget {
  const SilicaWindowHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SilicaWindowController>>(
        valueListenable: SilicaWindows.open,
        builder: (context, windows, child) => ViewAnchor(
          view: windows.isEmpty
              ? null
              : ViewCollection(
                  views: [
                    for (final window in windows)
                      View(
                        key: ValueKey(window.viewId),
                        view: window.view,
                        child: Builder(builder: window.builder),
                      ),
                  ],
                ),
          child: child!,
        ),
        child: child,
      );
}
