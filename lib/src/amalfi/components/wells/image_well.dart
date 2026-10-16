// The Amalfi image well (kit `Wells/Image Well/Empty|Filled/Small|Regular|Large/*`): a
// square that takes a dropped image. Empty, it is `Surface/Sunken` with a 1.5 pt `Line/Border`,
// the photo glyph and a hint; while an image is dragged over it, `Accent/Amalfi Soft` with an
// accent border, accent glyph and hint and the focus halo. Filled, the image fills it under a
// 1 pt `Line/Border` rim; focused, an accent rim and the halo.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../../foundation/foundation.dart';
import '../fields/surface.dart';
import 'dashed_border.dart';
import 'states.dart';

/// The three sizes of an image well.
enum AmalfiImageWellSize {
  /// 72 pt, radius 12, 20 pt glyph, no hint.
  small(side: 72, radius: 12, glyph: 20, showsHint: false),

  /// 120 pt, radius 16, 28 pt glyph and the hint.
  regular(side: 120, radius: 16, glyph: 28, showsHint: true),

  /// 168 pt, radius 20, 36 pt glyph and the hint.
  large(side: 168, radius: 20, glyph: 36, showsHint: true);

  const AmalfiImageWellSize({
    required this.side,
    required this.radius,
    required this.glyph,
    required this.showsHint,
  });

  /// The side of the square.
  final double side;

  /// The corner radius.
  final double radius;

  /// The side of the photo glyph of the empty well.
  final double glyph;

  /// Whether the empty well shows its hint under the glyph.
  final bool showsHint;
}

/// The measures shared by every image well size.
abstract final class AmalfiImageWellMetrics {
  /// The border of the empty well.
  static const double emptyBorder = 1.5;

  /// The rim over the image at rest.
  static const double rim = 1;

  /// The accent rim of a focused well and the border of a well dragged over.
  static const double strongBorder = 1.5;

  /// Between the glyph and the hint.
  static const double hintGap = 6;

  /// The dashes of the empty well's border.
  static const double dash = 6;

  /// The space between the dashes.
  static const double dashGap = 4;
}

/// An image well: shows [image] (any widget, typically an `Image` with `BoxFit.cover`)
/// clipped to the well, or, when [image] is null, the photo glyph and [hint].
///
/// Dragging data that [canAccept] accepts over the well shows the drop look and [dropHint];
/// dropping it calls [onDrop] (the app then sets [image]). A click focuses the well and runs
/// [onPressed] (to choose a file, say); with the keyboard focus, Space or Enter run
/// [onPressed] and Delete or Backspace run [onCleared] when the well is filled. [enabled]
/// false dims it and ignores input. [semanticLabel] names it for screen readers.
class AmalfiImageWell extends StatefulWidget {
  const AmalfiImageWell({
    super.key,
    this.image,
    this.size = AmalfiImageWellSize.regular,
    this.hint = 'Drop image',
    this.dropHint = 'Release to add',
    this.enabled = true,
    this.onDrop,
    this.canAccept,
    this.onPressed,
    this.onCleared,
    this.focusNode,
    this.semanticLabel,
    this.statesController,
  });

  /// The image; null: the well is empty.
  final Widget? image;
  final AmalfiImageWellSize size;

  /// The hint of the empty well (Regular and Large).
  final String hint;

  /// The hint while something droppable is dragged over the well.
  final String dropHint;
  final bool enabled;

  /// Called with the data dropped on the well; null: the well takes no drops.
  final ValueChanged<Object>? onDrop;

  /// Whether the well takes [data]; null: anything (when [onDrop] is set).
  final bool Function(Object data)? canAccept;

  /// Called on a click, Space or Enter.
  final VoidCallback? onPressed;

  /// Called on Delete or Backspace while the filled well has the focus.
  final VoidCallback? onCleared;
  final FocusNode? focusNode;
  final String? semanticLabel;

  /// Receives the well's states; a state set here shows (see [WidgetStatesController]).
  /// [WidgetState.selected] stands for "something is dragged over it".
  final WidgetStatesController? statesController;

  /// The key of the empty well's background (for tests).
  static const Key backgroundKey = ValueKey('AmalfiImageWell.background');

  @override
  State<AmalfiImageWell> createState() => _AmalfiImageWellState();
}

class _AmalfiImageWellState extends State<AmalfiImageWell>
    with AmalfiWellStatesMixin {
  @override
  WidgetStatesController? get statesController => widget.statesController;

  @override
  bool get enabled => widget.enabled;

  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'image well'));

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  bool _accepts(Object? data) =>
      widget.enabled &&
      widget.onDrop != null &&
      data != null &&
      (widget.canAccept?.call(data) ?? true);

  void _press() {
    if (!widget.enabled) return;
    _focus.requestFocus();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final size = widget.size;
    final enabled = widget.enabled;
    final image = widget.image;
    final focused = enabled && has(WidgetState.focused);
    final focusable =
        enabled &&
        (widget.onPressed != null ||
            (image != null && widget.onCleared != null));
    return Semantics(
      label: widget.semanticLabel,
      image: image != null,
      button: widget.onPressed != null,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: focusable,
        focusNode: _focus,
        onFocusChange: (v) => setWellState(WidgetState.focused, v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.delete): _ClearIntent(),
          SingleActivator(LogicalKeyboardKey.backspace): _ClearIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onPressed?.call(),
          ),
          _ClearIntent: CallbackAction<_ClearIntent>(
            onInvoke: (_) {
              if (widget.image != null) widget.onCleared?.call();
              return null;
            },
          ),
        },
        child: DragTarget<Object>(
          onWillAcceptWithDetails: (d) {
            final ok = _accepts(d.data);
            if (ok) setWellState(WidgetState.selected, true);
            return ok;
          },
          onLeave: (_) => setWellState(WidgetState.selected, false),
          onAcceptWithDetails: (d) {
            setWellState(WidgetState.selected, false);
            widget.onDrop?.call(d.data);
          },
          builder: (context, candidates, rejected) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled && widget.onPressed != null ? _press : null,
            child: SizedBox.square(
              dimension: size.side,
              child: image == null
                  ? _empty(colors, size, enabled)
                  : _filled(colors, size, enabled, focused, image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(AmalfiColors colors, AmalfiImageWellSize size, bool enabled) {
    final over = enabled && has(WidgetState.selected);
    final focused = enabled && has(WidgetState.focused);
    final ink = !enabled
        ? colors.textTertiary
        : over
        ? colors.accentAmalfi
        : colors.textSecondary;
    final side = BorderSide(
      color: over ? colors.accentAmalfi : colors.lineBorder,
      width: over
          ? AmalfiImageWellMetrics.strongBorder
          : AmalfiImageWellMetrics.emptyBorder,
      strokeAlign: BorderSide.strokeAlignInside,
    );
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmalfiGlyph(AmalfiGlyphs.photo, size: size.glyph, color: ink),
          if (size.showsHint) ...[
            const SizedBox(height: AmalfiImageWellMetrics.hintGap),
            SizedBox(
              height:
                  AmalfiType.captionToken.lineHeight ??
                  AmalfiType.captionToken.size,
              child: AmalfiWholePoints(
                step: AmalfiGrid.base,
                child: Text(
                  over ? widget.dropHint : widget.hint,
                  maxLines: 1,
                  softWrap: false,
                  style: AmalfiType.caption(color: ink),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          key: AmalfiImageWell.backgroundKey,
          decoration: AmalfiShapeDecoration(
            color: over ? colors.accentAmalfiSoft : colors.surfaceSunken,
            // The drop zone is dashed at rest; dragged over, the border is solid.
            shape: over
                ? AmalfiSmoothBorder(radius: size.radius, side: side)
                : AmalfiDashedSmoothBorder(
                    radius: size.radius,
                    side: side,
                    dash: AmalfiImageWellMetrics.dash,
                    gap: AmalfiImageWellMetrics.dashGap,
                  ),
          ),
        ),
        AmalfiFocusHalo(
          radius: size.radius,
          color: colors.lineFocus,
          visible: over || focused,
        ),
        content,
      ],
    );
  }

  Widget _filled(
    AmalfiColors colors,
    AmalfiImageWellSize size,
    bool enabled,
    bool focused,
    Widget image,
  ) {
    final shape = AmalfiSmoothBorder(radius: size.radius);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Opacity(
            opacity: enabled ? 1 : AmalfiStates.disabledOpacity,
            child: image,
          ),
        ),
        AmalfiFieldSurface(
          radius: size.radius,
          border: focused ? colors.accentAmalfi : colors.lineBorder,
          borderWidth: focused
              ? AmalfiImageWellMetrics.strongBorder
              : AmalfiImageWellMetrics.rim,
          halo: colors.lineFocus,
          haloVisible: focused,
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class _ClearIntent extends Intent {
  const _ClearIntent();
}
