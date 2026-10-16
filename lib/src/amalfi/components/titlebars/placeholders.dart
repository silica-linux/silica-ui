// Stand-ins for the buttons of the buttons family (toolbar icon button, round icon button,
// small square icon button), sized as the kit's buttons so the pieces, the tab bar and the
// sidebar footer can be laid out and shown before that family lands. They draw the button's
// surface and glyph and do nothing when clicked. (Action groups, segmented controls and search
// fields are the merged `AmalfiActionSegments`, `AmalfiSegmentedControl`, `AmalfiSearchField`.)
//
// TEMPORARY: replace with the public widgets of the buttons family once it is on main.

import 'package:flutter/widgets.dart';

import '../../../controls/control_base.dart' show WindowActiveScope;
import '../../glass.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import 'glyphs.dart';

enum _Kind { icon, round, square }

/// A non-interactive stand-in for a button of the buttons family, the size of the kit's
/// button.
///
/// In an inactive window the glyph of a toolbar button dims to
/// [AmalfiStates.disabledOpacity] (kit: the toolbar buttons of an inactive bar are their
/// Disabled masters).
class AmalfiToolbarPlaceholder extends StatelessWidget {
  /// A 32 pt round toolbar button on Glass/Regular (kit `Buttons/Toolbar/Icon`).
  const AmalfiToolbarPlaceholder.icon(this.glyph, {super.key})
    : _kind = _Kind.icon,
      size = 32;

  /// A round accent button (kit `Buttons/Icon/Round/Regular`, 28).
  const AmalfiToolbarPlaceholder.round(this.glyph, {super.key, this.size = 28})
    : _kind = _Kind.round;

  /// A small square icon button, 24 pt (kit `Buttons/Icon/Square/Small`: the sidebar
  /// footer's buttons, the tab bar's new-tab button).
  const AmalfiToolbarPlaceholder.square(this.glyph, {super.key})
    : _kind = _Kind.square,
      size = 24;

  final _Kind _kind;

  /// The glyph.
  final AmalfiTitlebarGlyphData glyph;

  /// The side of the button.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = AmalfiTheme.of(context);
    final colors = theme.colors;
    Widget icon(Color color) =>
        Center(child: AmalfiTitlebarGlyph(glyph, size: 16, color: color));
    return SizedBox.square(
      dimension: size,
      child: switch (_kind) {
        _Kind.icon => AmalfiGlass(
          material: AmalfiMaterials.regular,
          radius: size / 2,
          child: Opacity(
            opacity: WindowActiveScope.of(context)
                ? 1
                : AmalfiStates.disabledOpacity,
            child: icon(colors.textPrimary),
          ),
        ),
        _Kind.round => DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.accentAmalfi,
            shape: const StadiumBorder(),
          ),
          child: icon(colors.textOnAccent),
        ),
        _Kind.square => DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surfaceControl,
            shape: AmalfiSmoothBorder(
              radius: AmalfiRadii.smallControl,
              side: BorderSide(
                color: colors.lineBorder,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            shadows: theme.shadows.level1,
          ),
          child: icon(colors.textPrimary),
        ),
      },
    );
  }
}
