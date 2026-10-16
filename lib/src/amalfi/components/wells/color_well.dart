// The Amalfi colour well (kit `Wells/Color Well/Minimal|Default|Expanded/*`): the colour in a
// `Surface/Raised` frame with a 1 pt `Line/Border`; hovered, an `Accent/Amalfi Soft` overlay;
// focused, the focus halo; disabled, the whole well at `States/disabledOpacity`. Default adds the
// picker chevron, Expanded the colour's name and the eyedropper.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../foundation/foundation.dart';
import '../fields/surface.dart';
import 'color_panel.dart';
import 'states.dart';

/// The three styles of a colour well.
enum AmalfiColorWellStyle {
  /// 44 × 24: the colour only.
  minimal(
    size: Size(44, 24),
    radius: 8,
    colourWidth: 36,
    colourRadius: 5,
    padding: EdgeInsets.all(4),
    gap: 4,
  ),

  /// 72 × 28: the colour and the picker chevron.
  standard(
    size: Size(72, 28),
    radius: AmalfiRadii.regularControl,
    colourWidth: 44,
    colourRadius: 6,
    padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
    gap: 4,
  ),

  /// 188 × 28: the colour, its name and the eyedropper.
  expanded(
    size: Size(188, 28),
    radius: AmalfiRadii.regularControl,
    colourWidth: 28,
    colourRadius: 6,
    padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
    gap: 8,
  );

  const AmalfiColorWellStyle({
    required this.size,
    required this.radius,
    required this.colourWidth,
    required this.colourRadius,
    required this.padding,
    required this.gap,
  });

  /// The well's size.
  final Size size;

  /// The well's corner radius.
  final double radius;

  /// The width of the colour (its height is the well's minus the padding).
  final double colourWidth;

  /// The colour's corner radius.
  final double colourRadius;

  /// Around the content.
  final EdgeInsets padding;

  /// Between the items.
  final double gap;
}

/// The measures shared by the colour well styles.
abstract final class AmalfiColorWellMetrics {
  /// The picker chevron of the standard style.
  static const double chevron = 12;

  /// The eyedropper of the expanded style.
  static const double eyedropper = 16;

  /// Between the well and its colour panel.
  static const double panelGap = 4;
}

/// A colour well showing [color].
///
/// A click, Space or Enter opens an [AmalfiColorPanel] under it ([swatches], or the Amalfi
/// colours); picking a swatch calls [onChanged] and closes it, as do Esc and a click
/// outside. The expanded style shows [name] and, when [onPickFromScreen] is set, the
/// eyedropper that calls it. [onChanged] null or [enabled] false disables the well.
class AmalfiColorWell extends StatefulWidget {
  const AmalfiColorWell({
    super.key,
    required this.color,
    required this.onChanged,
    this.style = AmalfiColorWellStyle.standard,
    this.name,
    this.enabled = true,
    this.swatches,
    this.panelTitle = 'Swatches',
    this.onPickFromScreen,
    this.eyedropperLabel = 'Pick a colour from the screen',
    this.focusNode,
    this.semanticLabel,
    this.statesController,
  });

  final Color color;
  final ValueChanged<Color>? onChanged;
  final AmalfiColorWellStyle style;

  /// The colour's name, shown by the expanded style.
  final String? name;
  final bool enabled;

  /// The swatches of the panel; null: [AmalfiColorPanel.amalfiSwatches].
  final List<List<Color>>? swatches;
  final String panelTitle;

  /// Called by the expanded style's eyedropper; null: no eyedropper.
  final VoidCallback? onPickFromScreen;

  /// What screen readers call the eyedropper.
  final String eyedropperLabel;
  final FocusNode? focusNode;
  final String? semanticLabel;

  /// Receives the well's states (hovered, focused, disabled); a state set here shows.
  final WidgetStatesController? statesController;

  /// The key of the hover overlay (for tests).
  static const Key stateKey = ValueKey('AmalfiColorWell.state');

  /// The key of the colour (for tests).
  static const Key colourKey = ValueKey('AmalfiColorWell.colour');

  /// The key of the name (for tests).
  static const Key nameKey = ValueKey('AmalfiColorWell.name');

  @override
  State<AmalfiColorWell> createState() => _AmalfiColorWellState();
}

class _AmalfiColorWellState extends State<AmalfiColorWell>
    with AmalfiWellStatesMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _tapGroup = Object();
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'colour well'));

  @override
  WidgetStatesController? get statesController => widget.statesController;

  @override
  bool get enabled => widget.enabled && widget.onChanged != null;

  @override
  void didUpdateWidget(AmalfiColorWell old) {
    super.didUpdateWidget(old);
    if (!enabled && _portal.isShowing) _portal.hide();
  }

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!enabled) return;
    setState(() => _portal.isShowing ? _portal.hide() : _portal.show());
    _focus.requestFocus();
  }

  void _close() {
    if (_portal.isShowing) setState(_portal.hide);
  }

  void _pick(Color color) {
    _close();
    widget.onChanged?.call(color);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final style = widget.style;
    final on = enabled;
    final hovered = on && has(WidgetState.hovered);
    final focused = on && has(WidgetState.focused);
    final colourHeight = style.size.height - style.padding.vertical;
    final ink = colors.textSecondary;
    final eyedropper = widget.onPickFromScreen;

    final colour = DecoratedBox(
      key: AmalfiColorWell.colourKey,
      decoration: AmalfiShapeDecoration(
        color: widget.color,
        shape: AmalfiSmoothBorder(
          radius: style.colourRadius,
          side: BorderSide(
            color: colors.lineBorder,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: SizedBox(width: style.colourWidth, height: colourHeight),
    );

    final content = Padding(
      padding: style.padding,
      child: Row(
        children: [
          colour,
          if (style == AmalfiColorWellStyle.standard) ...[
            SizedBox(width: style.gap),
            AmalfiGlyph(
              AmalfiGlyphs.chevronDown,
              size: AmalfiColorWellMetrics.chevron,
              color: ink,
            ),
          ],
          if (style == AmalfiColorWellStyle.expanded) ...[
            SizedBox(width: style.gap),
            Expanded(
              child: SizedBox(
                key: AmalfiColorWell.nameKey,
                height:
                    AmalfiType.bodyToken.lineHeight ??
                    AmalfiType.bodyToken.size,
                child: Text(
                  widget.name ?? '',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AmalfiType.body(color: colors.textPrimary),
                ),
              ),
            ),
            if (eyedropper != null) ...[
              SizedBox(width: style.gap),
              Semantics(
                button: true,
                enabled: on,
                label: widget.eyedropperLabel,
                onTap: on ? eyedropper : null,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: on ? eyedropper : null,
                    child: AmalfiGlyph(
                      AmalfiGlyphs.eyedropper,
                      size: AmalfiColorWellMetrics.eyedropper,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    final Widget well = SizedBox.fromSize(
      size: style.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AmalfiFieldSurface(
            radius: style.radius,
            fill: colors.surfaceRaised,
            border: colors.lineBorder,
            halo: colors.lineFocus,
            haloVisible: focused,
            child: const SizedBox.expand(),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: hovered ? 1 : 0,
              duration: AmalfiFades.quick.duration,
              curve: AmalfiFades.quick.curve,
              child: DecoratedBox(
                key: AmalfiColorWell.stateKey,
                decoration: AmalfiShapeDecoration(
                  color: colors.accentAmalfiSoft,
                  shape: AmalfiSmoothBorder(radius: style.radius),
                ),
              ),
            ),
          ),
          content,
        ],
      ),
    );

    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _close(),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _panel,
        child: Semantics(
          button: true,
          enabled: on,
          expanded: _portal.isShowing,
          label: widget.semanticLabel ?? widget.name,
          child: FocusableActionDetector(
            enabled: on,
            focusNode: _focus,
            mouseCursor: on ? SystemMouseCursors.click : MouseCursor.defer,
            onShowHoverHighlight: (v) => setWellState(WidgetState.hovered, v),
            onFocusChange: (v) {
              setWellState(WidgetState.focused, v);
              if (!v) _close();
            },
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => _toggle(),
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => _close(),
              ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: on ? _toggle : null,
              child: on
                  ? well
                  : Opacity(opacity: AmalfiStates.disabledOpacity, child: well),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext overlayContext) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final theme = AmalfiTheme.of(context);
    return Positioned(
      left: origin.dx,
      top: origin.dy + box.size.height + AmalfiColorWellMetrics.panelGap,
      child: AmalfiTheme(
        brightness: theme.brightness,
        child: TapRegion(
          groupId: _tapGroup,
          child: AmalfiColorPanel(
            title: widget.panelTitle,
            swatches: widget.swatches,
            selected: widget.color,
            onSelected: _pick,
          ),
        ),
      ),
    );
  }
}
