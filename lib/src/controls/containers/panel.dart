// Panels (CT-PN-01, CT-PN-02): floating panels inside the app window (inspectors, Info, HUD).
// Silica apps have one window, so a panel floats over the content: a 28 pt title bar with a
// small close button and the title, dragged to move. The utility style uses the window colors,
// the HUD style the dark thick glass. *Provisional: the Info window is measured as a window
// (MU-60), the panel chrome and the HUD are not.*

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glass.dart' show GlassMaterial;
import '../../window_glass.dart';
import 'common.dart';

enum PanelStyle { utility, hud }

abstract final class PanelMetrics {
  static const double titleBar = 28;
  static const double radius = 12;
  static const double closeSize = 12;
  static const double titleSize = 13;
}

@immutable
class PanelColors {
  const PanelColors({
    required this.background,
    required this.border,
    required this.title,
    required this.close,
    required this.shadow,
  });

  final Color background;
  final Color border;
  final Color title;
  final Color close;
  final Color shadow;

  static const PanelColors light = PanelColors(
    background: Color(0xFFF6F6F6),
    border: Color(0x26000000),
    title: Color(0xFF4D4D4D),
    close: Color(0xFFFF5F57),
    shadow: Color(0x40000000),
  );
  static const PanelColors dark = PanelColors(
    background: Color(0xFF2B2B2C),
    border: Color(0xDB000000),
    title: Color(0xFFE9E9E9),
    close: Color(0xFFFF5F57),
    shadow: Color(0x66000000),
  );
  static const PanelColors hud = PanelColors(
    background: Color(0x99202020),
    border: Color(0x33FFFFFF),
    title: Color(0xFFFFFFFF),
    close: Color(0xFFBDBDBD),
    shadow: Color(0x66000000),
  );

  static PanelColors of(BuildContext context, PanelStyle style) =>
      style == PanelStyle.hud
      ? hud
      : containerDark(context)
      ? dark
      : light;
}

/// A floating panel at `position` in its parent `Stack`; dragging the title bar reports the new
/// position. Esc closes it.
class FloatingPanel extends StatefulWidget {
  const FloatingPanel({
    super.key,
    required this.title,
    required this.child,
    required this.size,
    this.position = Offset.zero,
    this.onMove,
    this.onClose,
    this.style = PanelStyle.utility,
    this.closeLabel = 'Close',
  });

  final String title;
  final Widget child;
  final Size size;
  final Offset position;
  final ValueChanged<Offset>? onMove;
  final VoidCallback? onClose;
  final PanelStyle style;

  /// The close button's accessibility label, localized by the app.
  final String closeLabel;

  @override
  State<FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<FloatingPanel> {
  Offset _from = Offset.zero;
  Offset _pointer = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final FloatingPanel(
      :title,
      :child,
      :size,
      :position,
      :onMove,
      :onClose,
      :style,
      :closeLabel,
    ) = widget;
    final colors = PanelColors.of(context, style);
    final radius = BorderRadius.circular(PanelMetrics.radius);
    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const ValueKey('panel title bar'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (d) {
            _from = position;
            _pointer = d.globalPosition;
          },
          onPanUpdate: onMove == null
              ? null
              : (d) => onMove(_from + d.globalPosition - _pointer),
          child: SizedBox(
            height: PanelMetrics.titleBar,
            child: Stack(
              children: [
                if (onClose != null)
                  Positioned(
                    left: 9,
                    top: (PanelMetrics.titleBar - PanelMetrics.closeSize) / 2,
                    width: PanelMetrics.closeSize,
                    height: PanelMetrics.closeSize,
                    child: Semantics(
                      button: true,
                      label: closeLabel,
                      child: GestureDetector(
                        key: const ValueKey('panel close'),
                        onTap: onClose,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.close,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: containerText(
                      PanelMetrics.titleSize,
                      colors.title,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
    body = style == PanelStyle.hud
        ? WindowGlass(
            radius: PanelMetrics.radius,
            material: GlassMaterial.thick,
            border: colors.border,
            child: ColoredBox(color: colors.background, child: body),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: radius,
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: ClipRRect(borderRadius: radius, child: body),
          );
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: size.width,
      height: size.height,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                onClose?.call();
                return null;
              },
            ),
          },
          child: FocusScope(
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: title,
              child: DecoratedBox(
                key: const ValueKey('panel'),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
