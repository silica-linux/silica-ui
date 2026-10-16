// The sheet attached to a window (kit `Windows/Window/Sheet Attached`): the window's content
// below the title bar is dimmed by a scrim (`Text/Primary` at 16 %, the window's bottom
// corners), and the sheet hangs centred from the title bar, overlapping it by 8.
//
// The sheet is Glass/Thick, radius 20 (`materials.md`; the kit draws the opaque alert).
// Motion (`motion.md`): it slides down from under the title bar on `spring.panel` while the
// scrim and the sheet fade in with `fade.quick`; it closes with `fade.instant` (an
// assumption: the spec measures no close).

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../tokens.g.dart';

/// The measures of an attached sheet, from the kit master `Windows/Window/Sheet Attached`.
abstract final class AmalfiSheetMetrics {
  /// The opacity of the scrim (`Text/Primary`).
  static const double scrimOpacity = 0.16;

  /// How far the sheet overlaps the title bar.
  static const double titleBarOverlap = 8;

  /// The height of the title bar of a document window.
  static const double titleBarHeight = 48;

  /// The corner radius of the sheet (`materials.md`: radius 20).
  static const double radius = AmalfiRadii.sheetAlert;
}

/// The scrim over a window's content while a sheet is attached: [color] at
/// [AmalfiSheetMetrics.scrimOpacity], square at the top and with the window's smooth corners
/// of [radius] at the bottom.
class AmalfiSheetScrim extends StatelessWidget {
  const AmalfiSheetScrim({super.key, this.radius = AmalfiRadii.window});

  /// The scrim's colour: the light `Text/Primary` (a near black) in both appearances, as
  /// the kit draws it: a scrim darkens.
  static final Color color = AmalfiColors.light.textPrimary;

  /// The radius of the bottom corners (the window's).
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ScrimPainter(
      AmalfiSheetScrim.color.withValues(alpha: AmalfiSheetMetrics.scrimOpacity),
      radius,
    ),
    child: const SizedBox.expand(),
  );
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // The window's shape, extended upwards so that only its bottom corners show.
    final reach = radius * 2;
    final window = AmalfiSmoothBorder(
      radius: radius,
    ).getOuterPath(Rect.fromLTWH(0, -reach, size.width, size.height + reach));
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(window, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.color != color || old.radius != radius;
}

/// A window ([child]) with a [sheet] attached while [open]: the content below the
/// [titleBarHeight] is dimmed with an [AmalfiSheetScrim] and the sheet hangs centred from the
/// title bar, overlapping it by [AmalfiSheetMetrics.titleBarOverlap].
///
/// The sheet is typically an `AmalfiAlert` with `AmalfiAlertMaterial.glass` or an
/// `AmalfiDialog`. While it is open the window's content ignores the pointer. Animates on
/// [open] changes.
class AmalfiAttachedSheet extends StatefulWidget {
  const AmalfiAttachedSheet({
    super.key,
    required this.open,
    required this.sheet,
    required this.child,
    this.titleBarHeight = AmalfiSheetMetrics.titleBarHeight,
    this.windowRadius = AmalfiRadii.window,
  });

  /// Whether the sheet is shown.
  final bool open;

  final Widget sheet;

  /// The window.
  final Widget child;

  /// The height of the window's title bar (or toolbar).
  final double titleBarHeight;

  /// The window's corner radius.
  final double windowRadius;

  @override
  State<AmalfiAttachedSheet> createState() => _AmalfiAttachedSheetState();
}

class _AmalfiAttachedSheetState extends State<AmalfiAttachedSheet>
    with TickerProviderStateMixin {
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: widget.open ? 1 : 0,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: widget.open ? 1 : 0,
  );

  @override
  void didUpdateWidget(AmalfiAttachedSheet old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.open) {
      _fade.animateTo(
        1,
        duration: AmalfiFades.quick.duration,
        curve: AmalfiFades.quick.curve,
      );
      if (reduce) {
        _slide.value = 1;
      } else {
        _slide
            .animateWith(
              SpringSimulation(AmalfiSprings.panel, _slide.value, 1, 0),
            )
            .whenCompleteOrCancel(() {
              // Settle exactly (the simulation stops within its tolerance).
              if (mounted && widget.open) _slide.value = 1;
            });
      }
    } else {
      _fade.animateTo(
        0,
        duration: AmalfiFades.instant.duration,
        curve: AmalfiFades.instant.curve,
      );
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_slide, _fade]),
    builder: (context, _) {
      final shown = _fade.value > 0;
      final top = widget.titleBarHeight - AmalfiSheetMetrics.titleBarOverlap;
      return Stack(
        children: [
          IgnorePointer(ignoring: widget.open, child: widget.child),
          if (shown) ...[
            Positioned(
              left: 0,
              right: 0,
              top: widget.titleBarHeight,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _fade.value,
                  child: AmalfiSheetScrim(radius: widget.windowRadius),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top,
              bottom: 0,
              child: ClipRect(
                clipBehavior: _slide.value < 1 ? Clip.hardEdge : Clip.none,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, _slide.value - 1),
                    child: Opacity(
                      opacity: _fade.value,
                      child: IgnorePointer(
                        ignoring: !widget.open,
                        child: widget.sheet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
