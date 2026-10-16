// Alerts against the kit (`Alerts/Alert/*`). Checklist: docs/amalfi-checklist/alerts.md.
//
// Kit defects (see AmalfiAlert): the masters space their blocks 14 (One Button, Critical,
// Glass), 16 (Two Buttons, With Field) or 12 (Three Buttons) apart, the 16 ones are 8 shorter
// than their content (their buttons sit 12 from the bottom, not 20), and the button rows are
// 8 apart in some masters and 16 in others. The code uses 16 between blocks, 20 at the
// bottom and 8 between buttons; each test lists what that moves.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/components/menus/glyphs.dart';

import 'menus_support.dart';
import 'support/harness.dart';

/// A stand-in for a control or an icon of another family, masked out of the pixel tests.
class StandIn extends StatelessWidget {
  const StandIn(this.name, this.width, this.height, {super.key});

  final String name;
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

Finder standIn(String name) =>
    find.byWidgetPredicate((w) => w is StandIn && w.name == name);

/// The box of a text (the whole-points box around it).
Finder wholeText(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(AmalfiWholePoints))
    .first;

/// The row or column holding the button stand-in [name].
Finder buttonsOf(String name) => find
    .ancestor(
      of: standIn(name),
      matching: find.byWidgetPredicate((w) => w is Wrap || w is Column),
    )
    .first;

const _icon = StandIn('App icon', 56, 56);

/// The kit variants: the alert, its button names, its accessory layer.
final Map<String, (AmalfiAlert, List<String>, String?)> alerts = {
  'One Button': (
    const AmalfiAlert(
      icon: _icon,
      title: 'Import complete',
      message: 'Twelve pictures were added to your library.',
      actions: [StandIn('OK', 72, 28)],
    ),
    ['OK'],
    null,
  ),
  'Two Buttons': (
    const AmalfiAlert(
      icon: _icon,
      title: 'Empty the outbox?',
      message: 'Messages waiting to be sent will be sent now.',
      accessory: Center(child: StandIn('Suppression', 168, 20)),
      actions: [StandIn('Cancel', 72, 28), StandIn('Send', 72, 28)],
    ),
    ['Cancel', 'Send'],
    'Suppression',
  ),
  'Three Buttons': (
    const AmalfiAlert(
      icon: _icon,
      title: 'Save changes to “Lemon cake”?',
      message: 'Your edits will be lost if you close without saving.',
      actions: [
        StandIn('Cancel', 72, 28),
        StandIn('Don’t Save', 92, 28),
        StandIn('Save', 72, 28),
      ],
    ),
    ['Cancel', 'Don’t Save', 'Save'],
    null,
  ),
  'Critical': (
    const AmalfiAlert(
      icon: _icon,
      critical: true,
      title: 'Delete this list?',
      message: 'All reminders in it will be removed for good.',
      actions: [StandIn('Cancel', 72, 28), StandIn('Delete', 72, 28)],
    ),
    ['Cancel', 'Delete'],
    null,
  ),
  'With Field': (
    const AmalfiAlert(
      icon: _icon,
      title: 'Name the note',
      message: 'Choose a short name you will recognise later.',
      accessory: StandIn('Accessory field', 240, 28),
      actions: [StandIn('Cancel', 72, 28), StandIn('Save', 72, 28)],
    ),
    ['Cancel', 'Save'],
    'Accessory field',
  ),
  'Glass': (
    const AmalfiAlert(
      icon: _icon,
      material: AmalfiAlertMaterial.glass,
      title: 'Event moved',
      message: 'Lunch with Marta now starts at 13:30.',
      actions: [StandIn('OK', 72, 28)],
    ),
    ['OK'],
    null,
  ),
};

/// The deviations of each variant from its master (see the file comment).
Map<String, String> deviationsOf(String variant) {
  const gap14 = 'kit blocks 14 apart (off the 4 pt grid), code 16';
  const gap12 = 'kit blocks 12 apart, code 16';
  const short = 'kit surface 8 shorter than its content';
  const lh24 = 'kit Title 3 line height 24, the token 22 (box rounded to 24)';
  const buttons16 = 'kit buttons 16 apart, code 8';
  const pad8 = 'kit button row has a stray 8 pt leading padding';
  return switch (variant) {
    'One Button' || 'Glass' => {
      '#frame': gap14,
      'Surface': gap14,
      'Title': gap14,
      'Message': gap14,
      'Buttons': '$gap14; $pad8',
      'Buttons/OK': gap14,
    },
    'Critical' => {
      '#frame': gap14,
      'Surface': gap14,
      'Title': gap14,
      'Message': gap14,
      'Buttons': '$gap14; $buttons16',
      'Buttons/Cancel': '$gap14; $buttons16',
      'Buttons/Delete': '$gap14; $buttons16',
    },
    'Three Buttons' => {
      '#frame': gap12,
      'Surface': gap12,
      'Title': gap12,
      'Message': gap12,
      'Buttons': gap12,
      'Buttons/Cancel': gap12,
      'Buttons/Don’t Save': gap12,
      'Buttons/Save': gap12,
    },
    'Two Buttons' => {
      '#frame': short,
      'Surface': short,
      'Title#font': lh24,
      'Title#style': lh24,
    },
    'With Field' => {
      '#frame': short,
      'Surface': short,
      'Title#font': lh24,
      'Title#style': lh24,
      'Buttons': buttons16,
      'Buttons/Cancel': buttons16,
      'Buttons/Save': buttons16,
    },
    _ => const {},
  };
}

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerSurfaceStyles();
  });

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final MapEntry(key: variant, value: (alert, buttons, accessory))
          in alerts.entries) {
        testWidgets(variant, (tester) async {
          final master = KitMaster.load(
            'Alerts/Alert/$variant/Rest/$appearance',
          );
          final root = await pumpKitScene(tester, alert, master: master);
          final glass = alert.material == AmalfiAlertMaterial.glass;
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Surface': glass
                  ? find.byType(AmalfiGlass)
                  : find.byType(AmalfiAlertSurface).first,
              'App icon': standIn('App icon'),
              'Title': wholeText(alert.title),
              'Message': wholeText(alert.message!),
              'Buttons': buttonsOf(buttons.first),
              for (final b in buttons) 'Buttons/$b': standIn(b),
              if (accessory != null) accessory: standIn(accessory),
              if (alert.critical) ...{
                'Badge disc': find.byType(AmalfiAlertSurface).last,
                'Glyph Warning': find.byType(AmalfiMenuGlyphIcon),
              },
            },
            deviations: deviationsOf(variant),
          );
          // Pixels where the layout agrees with the kit (Two Buttons, With Field: all but
          // the 8 pt the kit cuts off the bottom, masked with the shadow under it); the
          // icon and the controls of other families are masked.
          if (variant == 'Two Buttons' || variant == 'With Field') {
            final h = master.size.height;
            await expectKitPixels(
              tester,
              master,
              alert,
              maskText: true,
              maskLayers: [
                'App icon',
                for (final b in buttons) 'Buttons/$b',
                ?accessory,
              ],
              mask: [Rect.fromLTWH(-40, h - 28, master.size.width + 80, 80)],
              tolerance: largeCorners,
            );
          }
        });
      }
    });
  }
}
