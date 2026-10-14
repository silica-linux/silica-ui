// Sheets (CT-SH-01, CT-SH-02; dialogs.md › Save, MU-96, MU-06).
//
// Card (the modern sheet, Save and New folder): a rounded card (radius ~18–20) centered on the
// window, the window behind veiled (light white → `#bababa`, dark `#262726` → `#1c1c1c`: black
// at ~27 %). Opening: the veil fades in over ~295 ms; the card follows ~67 ms later, fading in
// and moving down 20 pt at constant width, still after ~268 ms. Closing: a fade without
// movement, ~224 ms, the veil ~40 ms later (~264 ms).
//
// Attached (Customize toolbar): hangs from the bottom of the toolbar, centered on the window
// (it may be wider than the window), translucent material with a dark 1 pt border and a shadow
// also above; it completes in ~95 ms and closes in 1–2 frames.
//
// The sheet is modal for its window: what is behind takes no clicks; Esc cancels when the sheet
// has a cancel action.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart' show GlassMaterial;
import '../../window.dart' show toolbarHeight;
import '../../window_glass.dart';
import 'common.dart';

enum SheetStyle { card, attached }

abstract final class SheetMetrics {
  static const double cardRadius = 19;

  /// Black at ~27 %: white → `#bababa`, `#262726` → `#1c1c1c`.
  static const Color veil = Color(0x45000000);

  static const Duration veilIn = Duration(milliseconds: 295);
  static const Duration cardDelay = Duration(milliseconds: 67);
  static const Duration cardIn = Duration(milliseconds: 268);
  static const double cardDrop = 20;
  static const Duration cardOut = Duration(milliseconds: 224);
  static const Duration veilOutDelay = Duration(milliseconds: 40);
  static const Duration attachedIn = Duration(milliseconds: 95);
  static const Duration attachedOut = Duration(milliseconds: 25);

  /// How far an attached sheet may overhang the window on each side.
  static const double overhang = 400;

  /// The attached sheet's radius at the bottom corners. *Provisional.*
  static const double attachedRadius = 12;
}

@immutable
class SheetColors {
  const SheetColors(this.card, this.border, this.shadow);
  final Color card;
  final Color border;
  final Color shadow;

  /// The card background. *Provisional: the expanded Save panel's dark background is measured
  /// `#272727`-like (MU-95); light estimated white.*
  static const SheetColors light = SheetColors(
    Color(0xFFF6F6F6),
    Color(0x26000000),
    Color(0x40000000),
  );
  static const SheetColors dark = SheetColors(
    Color(0xFF2B2B2C),
    Color(0xDB000000),
    Color(0x66000000),
  );

  static SheetColors of(BuildContext context) =>
      containerDark(context) ? dark : light;
}

/// Shows a sheet over the window of `context` (it needs an [Overlay], as in `WidgetsApp`). The
/// future completes with the value passed to [SheetRoute.close] (null if cancelled with Esc).
Future<T?> showWindowSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, SheetRoute<T> sheet) builder,
  SheetStyle style = SheetStyle.card,
  double top = toolbarHeight,
  bool cancelOnEscape = true,
  String? semanticLabel,
}) {
  final overlay = Overlay.of(context);
  final route = SheetRoute<T>._();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _SheetLayer<T>(
      route: route,
      style: style,
      top: top,
      cancelOnEscape: cancelOnEscape,
      semanticLabel: semanticLabel,
      builder: builder,
      onGone: () {
        entry.remove();
        entry.dispose();
      },
    ),
  );
  overlay.insert(entry);
  return route._done.future;
}

/// An open sheet: [close] hides it and completes [showWindowSheet] with a value.
class SheetRoute<T> {
  SheetRoute._();
  final Completer<T?> _done = Completer<T?>();
  VoidCallback? _hide;

  void close([T? value]) {
    if (_done.isCompleted) return;
    _done.complete(value);
    _hide?.call();
  }
}

class _SheetLayer<T> extends StatefulWidget {
  const _SheetLayer({
    required this.route,
    required this.style,
    required this.top,
    required this.cancelOnEscape,
    required this.semanticLabel,
    required this.builder,
    required this.onGone,
  });

  final SheetRoute<T> route;
  final SheetStyle style;
  final double top;
  final bool cancelOnEscape;
  final String? semanticLabel;
  final Widget Function(BuildContext context, SheetRoute<T> sheet) builder;
  final VoidCallback onGone;

  @override
  State<_SheetLayer<T>> createState() => _SheetLayerState<T>();
}

class _SheetLayerState<T> extends State<_SheetLayer<T>>
    with TickerProviderStateMixin {
  late final AnimationController _veil;
  late final AnimationController _sheet;
  final FocusScopeNode _focus = FocusScopeNode();
  Timer? _delay;

  bool get _card => widget.style == SheetStyle.card;

  @override
  void initState() {
    super.initState();
    _veil = AnimationController(
      vsync: this,
      duration: SheetMetrics.veilIn,
      reverseDuration: SheetMetrics.cardOut,
    );
    _sheet = AnimationController(
      vsync: this,
      duration: _card ? SheetMetrics.cardIn : SheetMetrics.attachedIn,
      reverseDuration: _card ? SheetMetrics.cardOut : SheetMetrics.attachedOut,
    );
    widget.route._hide = _hide;
    if (_card) {
      _veil.forward();
      _delay = Timer(SheetMetrics.cardDelay, () {
        if (mounted) _sheet.forward();
      });
    } else {
      _sheet.forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _veil.dispose();
    _sheet.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _hide() async {
    _delay?.cancel();
    final sheet = _sheet.reverse();
    if (_card) {
      await Future<void>.delayed(SheetMetrics.veilOutDelay);
      if (!mounted) return;
      await Future.wait([sheet, _veil.reverse()]);
    } else {
      await sheet;
    }
    if (mounted) widget.onGone();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SheetColors.of(context);
    final content = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (widget.cancelOnEscape) widget.route.close();
              return null;
            },
          ),
        },
        child: FocusScope(
          node: _focus,
          child: Focus(
            autofocus: true,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: widget.semanticLabel,
              child: Builder(
                builder: (context) => widget.builder(context, widget.route),
              ),
            ),
          ),
        ),
      ),
    );
    final Widget sheet;
    if (_card) {
      sheet = Center(
        child: AnimatedBuilder(
          animation: _sheet,
          builder: (context, child) {
            final t = _sheet.status == AnimationStatus.reverse
                ? 0.0
                : Curves.easeOut.transform(1 - _sheet.value);
            return Opacity(
              opacity: _sheet.value,
              child: Transform.translate(
                offset: Offset(0, -SheetMetrics.cardDrop * t),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            key: const ValueKey('sheet card'),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(SheetMetrics.cardRadius),
              border: Border.all(color: colors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    } else {
      // Centered on the window, it may be wider (1066 on a 1000 window, MU-06).
      sheet = Positioned(
        top: widget.top,
        left: -SheetMetrics.overhang,
        right: -SheetMetrics.overhang,
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _sheet,
            child: DecoratedBox(
              key: const ValueKey('sheet attached'),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(SheetMetrics.attachedRadius),
                ),
                boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 24)],
              ),
              child: WindowGlass(
                material: GlassMaterial.thick,
                child: ColoredBox(
                  color: colors.card.withValues(alpha: 0.6),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [
        // Modal: the window behind takes no clicks.
        Positioned.fill(
          child: AbsorbPointer(
            child: FadeTransition(
              opacity: _veil,
              child: const ColoredBox(
                key: ValueKey('sheet veil'),
                color: SheetMetrics.veil,
              ),
            ),
          ),
        ),
        if (_card) Positioned.fill(child: sheet) else sheet,
      ],
    );
  }
}
