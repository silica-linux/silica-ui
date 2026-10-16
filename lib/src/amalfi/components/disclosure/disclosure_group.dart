// The Amalfi disclosure group (kit `Disclosure/Group/*`, `Disclosure/Group Header/*`): a
// header row with a triangle and a title that shows or hides the content under it.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../toggles/control_kit.dart';
import 'disclosure_controls.dart';

/// The measures of a disclosure group, from `Disclosure/Group*`.
abstract final class AmalfiDisclosureGroupMetrics {
  /// The height of the header.
  static const double headerHeight = 28;

  /// The header's padding: the triangle 4 from the leading edge, the title 12 from the
  /// trailing edge.
  static const EdgeInsets headerPadding = EdgeInsets.only(left: 4, right: 12);

  /// Between the triangle and the title.
  static const double titleGap = 4;

  /// The corner radius of the header's hover background.
  static const double headerRadius = 9;

  /// How far the content is indented (`Disclosure/Group/Open`: x 28).
  static const double contentIndent = 28;

  /// The space above and below the content.
  static const double contentGap = 4;
}

/// The look of a disclosure group header in a given state, without any interaction: the
/// triangle (at rest) and [title] in Headline `Text/Primary`, on an `Accent/Amalfi Soft`
/// background while hovered or pressed. It fills the width it is given.
class AmalfiDisclosureHeaderFace extends StatelessWidget {
  const AmalfiDisclosureHeaderFace({
    super.key,
    required this.title,
    required this.expanded,
    this.state = const AmalfiInteractionState(),
    this.turn,
  });

  final String title;
  final bool expanded;
  final AmalfiInteractionState state;

  /// How far the triangle has turned towards expanded, 0–1; null: at rest.
  final double? turn;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final enabled = state.enabled;
    const radius = AmalfiDisclosureGroupMetrics.headerRadius;
    return SizedBox(
      height: AmalfiDisclosureGroupMetrics.headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (enabled && (state.hovered || state.pressed))
            Positioned.fill(
              child: DecoratedBox(
                key: AmalfiLayerKeys.body,
                decoration: AmalfiShapeDecoration(
                  color: colors.accentAmalfiSoft,
                  shape: const AmalfiSmoothBorder(radius: radius),
                ),
              ),
            ),
          if (enabled && state.focused)
            Positioned.fill(
              child: AmalfiToggleFocusHalo(radius: radius, colors: colors),
            ),
          Positioned.fill(
            child: Padding(
              padding: AmalfiDisclosureGroupMetrics.headerPadding,
              child: Row(
                children: [
                  KeyedSubtree(
                    key: AmalfiLayerKeys.control,
                    child: AmalfiDisclosureFace(
                      expanded: expanded,
                      turn: turn,
                      state: AmalfiInteractionState(enabled: enabled),
                    ),
                  ),
                  const SizedBox(width: AmalfiDisclosureGroupMetrics.titleGap),
                  Expanded(
                    child: Text(
                      title,
                      key: AmalfiLayerKeys.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmalfiType.headline(
                        color: enabled
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section that shows its [child] under a header with [title] while [expanded].
///
/// A click on the header (or Space with the keyboard focus on it) calls [onExpandedChanged]
/// with the other value; with it null the header is disabled. The triangle turns with
/// `spring.snappy` and the content opens and closes from the header with `spring.panel`.
/// The content is indented to the title.
class AmalfiDisclosureGroup extends StatefulWidget {
  const AmalfiDisclosureGroup({
    super.key,
    required this.title,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
    this.focusNode,
  });

  final String title;
  final bool expanded;

  /// Called with the new value; null: disabled.
  final ValueChanged<bool>? onExpandedChanged;

  /// The content, shown under the header while [expanded].
  final Widget child;

  final FocusNode? focusNode;

  @override
  State<AmalfiDisclosureGroup> createState() => _AmalfiDisclosureGroupState();
}

class _AmalfiDisclosureGroupState extends State<AmalfiDisclosureGroup>
    with TickerProviderStateMixin {
  late final AnimationController _turn = AnimationController.unbounded(
    vsync: this,
    value: widget.expanded ? 1 : 0,
  );
  late final AnimationController _open = AnimationController.unbounded(
    vsync: this,
    value: widget.expanded ? 1 : 0,
  );

  @override
  void didUpdateWidget(AmalfiDisclosureGroup old) {
    super.didUpdateWidget(old);
    if (old.expanded == widget.expanded) return;
    final target = widget.expanded ? 1.0 : 0.0;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _turn.value = _open.value = target;
      return;
    }
    for (final (controller, spring) in [
      (_turn, AmalfiSprings.snappy),
      (_open, AmalfiSprings.panel),
    ]) {
      controller
          .animateWith(SpringSimulation(spring, controller.value, target, 0))
          .then((_) {
            if (mounted) controller.value = target;
          });
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onExpandedChanged;
    final activate = onChanged == null
        ? null
        : () => onChanged(!widget.expanded);
    final header = Semantics(
      button: true,
      expanded: widget.expanded,
      enabled: onChanged != null,
      label: widget.title,
      onTap: activate,
      child: ExcludeSemantics(
        child: AmalfiInteraction(
          onActivate: activate,
          focusNode: widget.focusNode,
          builder: (context, state) => AnimatedBuilder(
            animation: _turn,
            builder: (context, _) => AmalfiDisclosureHeaderFace(
              title: widget.title,
              expanded: widget.expanded,
              state: state,
              turn: _turn.value,
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        AnimatedBuilder(
          animation: _open,
          builder: (context, child) {
            final open = _open.value;
            if (open <= 0) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: open.clamp(0, 1),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: AmalfiDisclosureGroupMetrics.contentIndent,
              top: AmalfiDisclosureGroupMetrics.contentGap,
              bottom: AmalfiDisclosureGroupMetrics.contentGap,
            ),
            child: KeyedSubtree(
              key: AmalfiLayerKeys.content,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
