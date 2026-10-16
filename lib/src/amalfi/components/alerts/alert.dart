// The Amalfi alert (kit `Alerts/Alert/One Button|Two Buttons|Three Buttons|Critical|With
// Field|Glass`): 280 wide, radius 20, the app icon centred at the top, the title and the
// message left aligned, an optional accessory (a suppression checkbox, a field) and the
// buttons centred at the bottom (stacked when there are three or more).
//
// Spacing: 24 above the icon, 20 at the sides and the bottom, 16 between the blocks. The kit
// uses 14 (One Button, Critical, Glass), 16 (Two Buttons, With Field) and 12 (Three
// Buttons), and its 16 masters are 8 shorter than their content; 16 is the one on the 4 pt
// grid that most masters use.

import 'package:flutter/widgets.dart';

import '../../glass.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import '../menus/glyphs.dart';
import 'alert_surface.dart';

/// The measures of alerts, from the kit masters `Alerts/Alert/*`.
abstract final class AmalfiAlertMetrics {
  /// The width of an alert.
  static const double width = 280;

  /// The corner radius (`materials.md`: radius 20).
  static const double radius = AmalfiRadii.sheetAlert;

  /// The space around the content.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 24, 20, 20);

  /// The space between the icon, the title, the message, the accessory and the buttons.
  static const double gap = 16;

  /// The side of the app icon.
  static const double icon = 56;

  /// Between two buttons, side by side or stacked.
  static const double buttonGap = 8;

  /// The disc of the critical badge, over the icon's bottom-trailing corner.
  static const double badge = 24;

  /// The warning glyph in the badge.
  static const double badgeGlyph = 16;
}

/// The surface of an alert.
enum AmalfiAlertMaterial {
  /// `Surface/Raised` with a `Line/Border` rim and the level 3 shadow: an app's alert in a
  /// window.
  opaque,

  /// Glass/Thick: a system alert (`materials.md`).
  glass,
}

/// An alert: an [icon] (the app icon, 56 pt) centred at the top, the [title] in Title 3
/// `Text/Primary`, the [message] in Callout `Text/Secondary`, an optional [accessory] (a
/// suppression checkbox, a text field) and the [actions].
///
/// [actions] are push buttons, the default one last: side by side, centred, up to two;
/// stacked and centred, the default one on top, with three or more. [critical] adds the
/// warning badge (`Palette/Terracotta` on a raised disc) over the icon's bottom-trailing
/// corner.
class AmalfiAlert extends StatelessWidget {
  const AmalfiAlert({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.accessory,
    this.actions = const [],
    this.critical = false,
    this.material = AmalfiAlertMaterial.opaque,
    this.opaque = false,
  });

  /// The app icon; null: none.
  final Widget? icon;

  final String title;

  /// The explanation under the title; null: none.
  final String? message;

  /// A control between the message and the buttons; null: none.
  final Widget? accessory;

  /// The buttons, the default one last.
  final List<Widget> actions;

  /// Whether the alert warns of something destructive (the warning badge).
  final bool critical;

  /// The surface.
  final AmalfiAlertMaterial material;

  /// With [AmalfiAlertMaterial.glass], whether the glass is drawn without blur.
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final icon = this.icon;
    final message = this.message;
    final accessory = this.accessory;
    final blocks = <Widget>[
      if (icon != null)
        Center(
          child: SizedBox.square(
            dimension: AmalfiAlertMetrics.icon,
            child: critical
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(child: icon),
                      const PositionedDirectional(
                        end: -8,
                        bottom: -4,
                        child: _CriticalBadge(),
                      ),
                    ],
                  )
                : icon,
          ),
        ),
      Semantics(
        header: true,
        child: AmalfiWholePoints(
          step: AmalfiGrid.base,
          child: Text(
            title,
            style: AmalfiType.title3(color: colors.textPrimary),
          ),
        ),
      ),
      if (message != null)
        AmalfiWholePoints(
          step: AmalfiGrid.base,
          child: Text(
            message,
            style: AmalfiType.callout(color: colors.textSecondary),
          ),
        ),
      ?accessory,
      if (actions.isNotEmpty) _buttons(),
    ];
    final content = Padding(
      padding: AmalfiAlertMetrics.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: AmalfiAlertMetrics.gap),
            blocks[i],
          ],
        ],
      ),
    );
    final surface = switch (material) {
      AmalfiAlertMaterial.opaque => AmalfiAlertSurface(
        radius: AmalfiAlertMetrics.radius,
        child: content,
      ),
      AmalfiAlertMaterial.glass => AmalfiGlass(
        material: AmalfiMaterials.thick,
        radius: AmalfiAlertMetrics.radius,
        opaque: opaque,
        child: content,
      ),
    };
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: SizedBox(width: AmalfiAlertMetrics.width, child: surface),
    );
  }

  Widget _buttons() {
    if (actions.length >= 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = actions.length - 1; i >= 0; i--) ...[
            if (i < actions.length - 1)
              const SizedBox(height: AmalfiAlertMetrics.buttonGap),
            actions[i],
          ],
        ],
      );
    }
    // Side by side, centred; wide buttons wrap onto a second line instead of overflowing.
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AmalfiAlertMetrics.buttonGap,
        runSpacing: AmalfiAlertMetrics.buttonGap,
        children: actions,
      ),
    );
  }
}

/// The warning badge of a critical alert: a 24 pt raised disc with the warning glyph.
class _CriticalBadge extends StatelessWidget {
  const _CriticalBadge();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AmalfiAlertMetrics.badge,
    child: AmalfiAlertSurface(
      radius: AmalfiAlertMetrics.badge / 2,
      shadow: false,
      child: Center(
        child: AmalfiMenuGlyphIcon(
          AmalfiMenuGlyph.warning,
          color: AmalfiTheme.of(context).colors.paletteTerracotta,
          size: AmalfiAlertMetrics.badgeGlyph,
        ),
      ),
    ),
  );
}
