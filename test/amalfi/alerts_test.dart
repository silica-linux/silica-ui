// Alerts against the kit (`Alerts/Alert/*`). Checklist: docs/amalfi-checklist/alerts.md.
//
// The buttons, the suppression checkbox and the field are the real controls, compared with
// the kit's nested masters in the alert's pixels; only the app icons stay out (masked): the
// silica-icons app icons are not bundled with silica_ui.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'menus_support.dart';
import 'support/harness.dart';

/// The app icon's slot (an app passes its icon from silica-icons), masked out of the pixels.
class AppIconSlot extends StatelessWidget {
  const AppIconSlot({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(dimension: 56);
}

/// The box of a text (the whole-points box around it).
Finder wholeText(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(AmalfiWholePoints))
    .first;

/// The control keyed [name].
Finder keyedControl(String name) => find.byKey(ValueKey(name));

/// The row or column holding the button [name].
Finder buttonsOf(String name) => find
    .ancestor(
      of: keyedControl(name),
      matching: find.byWidgetPredicate((w) => w is Wrap || w is Column),
    )
    .first;

AmalfiPushButton _button(
  String label, [
  AmalfiPushButtonVariant variant = AmalfiPushButtonVariant.secondary,
]) => AmalfiPushButton(
  key: ValueKey(label),
  label: label,
  variant: variant,
  onPressed: () {},
);

const _primary = AmalfiPushButtonVariant.primary;

/// The kit variants: the alert, its button names, its accessory layer.
final Map<String, (AmalfiAlert, List<String>, String?)> alerts = {
  'One Button': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      title: 'Import complete',
      message: 'Twelve pictures were added to your library.',
      actions: [_button('OK', _primary)],
    ),
    ['OK'],
    null,
  ),
  'Two Buttons': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      title: 'Empty the outbox?',
      message: 'Messages waiting to be sent will be sent now.',
      // The kit's suppression checkbox is an instance 168 wide (its label frame wider than
      // the text, as the toggles' masters draw it); the app gives it that width.
      accessory: Center(
        child: SizedBox(
          width: 168,
          child: AmalfiCheckbox(
            key: const ValueKey('Suppression'),
            value: false,
            label: 'Do not ask again',
            onChanged: (_) {},
          ),
        ),
      ),
      actions: [_button('Cancel'), _button('Send', _primary)],
    ),
    ['Cancel', 'Send'],
    'Suppression',
  ),
  'Three Buttons': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      title: 'Save changes to “Lemon cake”?',
      message: 'Your edits will be lost if you close without saving.',
      actions: [
        _button('Cancel'),
        _button('Don’t Save'),
        _button('Save', _primary),
      ],
    ),
    ['Cancel', 'Don’t Save', 'Save'],
    null,
  ),
  'Critical': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      critical: true,
      title: 'Delete this list?',
      message: 'All reminders in it will be removed for good.',
      actions: [
        _button('Cancel'),
        _button('Delete', AmalfiPushButtonVariant.destructive),
      ],
    ),
    ['Cancel', 'Delete'],
    null,
  ),
  'With Field': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      title: 'Name the note',
      message: 'Choose a short name you will recognise later.',
      accessory: const AmalfiTextField(
        key: ValueKey('Accessory field'),
        placeholder: 'Name',
        width: 240,
      ),
      actions: [_button('Cancel'), _button('Save', _primary)],
    ),
    ['Cancel', 'Save'],
    'Accessory field',
  ),
  'Glass': (
    AmalfiAlert(
      icon: const AppIconSlot(),
      material: AmalfiAlertMaterial.glass,
      title: 'Event moved',
      message: 'Lunch with Marta now starts at 13:30.',
      actions: [_button('OK', _primary)],
    ),
    ['OK'],
    null,
  ),
};

const String kitStrayGlyph =
    'kit Critical master has a stray warning text at the top that adds 32 pt of height';

/// The deviations of each variant from its master.
Map<String, String> deviationsOf(String variant) {
  // Kit defect: the badge is scaled with the glyph to 24 x 23.79 (y 59.48), off whole
  // points; the code draws a 24 pt disc on whole points.
  const badge = 'kit badge disc 24 x 23.79 at y 59.48, off whole points';
  // Kit defect: these masters end 2 pt off the 4 pt grid (230, 214); the code adds the
  // remainder to the bottom padding (components.md), as the kit's other alerts do.
  const grid = 'kit height off the 4 pt grid (bottom padding 20, not 22)';
  const offGrid = {'#frame': grid, 'Surface': grid};
  return switch (variant) {
    'Critical' => {
      ...offGrid,
      'Badge disc': badge,
      'Glyph Warning': badge,
      // Kit defect (fd1719cf): the warning symbol is a text layer left at (132, 24), above
      // the app icon, and the master grew by 32 (262 tall): everything below the icon sits
      // 32 lower than in the other alerts and in the code.
      for (final layer in [
        'App icon',
        'Title',
        'Message',
        'Buttons',
        'Buttons/Cancel',
        'Buttons/Delete',
      ])
        layer: kitStrayGlyph,
    },
    'One Button' || 'Glass' => offGrid,
    // Kit defect: the label frame of `Don’t Save` is 68 while Inter measures the text wider
    // (the push button rounds it up to 72): the button is 96, the column centred at x 92.
    'Three Buttons' => {
      'Buttons': 'kit Don’t Save label frame narrower than its text',
      'Buttons/Don’t Save': 'kit Don’t Save label frame narrower than its text',
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
              'App icon': find.byType(AppIconSlot),
              'Title': wholeText(alert.title),
              'Message': wholeText(alert.message!),
              'Buttons': buttonsOf(buttons.first),
              for (final b in buttons) 'Buttons/$b': keyedControl(b),
              if (accessory != null) accessory: keyedControl(accessory),
              if (alert.critical) ...{
                'Badge disc': find.byType(AmalfiAlertSurface).last,
                'Glyph Warning': find.byType(AmalfiGlyph),
              },
            },
            deviations: deviationsOf(variant),
          );
          // The nested masters are the controls the alert uses.
          for (final b in buttons) {
            final variant = alert.actions
                .whereType<AmalfiPushButton>()
                .firstWhere((a) => a.label == b)
                .variant;
            expect(
              KitMaster.nested(master.layer('Buttons/$b')).name,
              startsWith('Buttons/Push/${_kitName(variant)}/Regular/Rest/'),
            );
          }
          // Where the kit ends 2 pt early (see deviationsOf), its bottom edge and the shadow
          // under it are left out.
          final h = master.size.height;
          // The kit's Critical master is laid out 32 pt off (kitStrayGlyph): no pixels.
          if (variant != 'Critical')
            await expectKitPixels(
              tester,
              master,
              alert,
              maskText: true,
              maskLayers: [
                'App icon',
                // Off whole points in the kit (see deviationsOf).
                if (alert.critical) ...['Badge disc', 'Glyph Warning'],
                if (variant == 'Three Buttons') 'Buttons/Don’t Save',
              ],
              mask: [
                if (h % AmalfiGrid.base != 0)
                  Rect.fromLTWH(-40, h - 24, master.size.width + 80, 80),
              ],
              tolerance: largeCorners,
            );
        });
      }
    });
  }
}

String _kitName(AmalfiPushButtonVariant variant) => switch (variant) {
  AmalfiPushButtonVariant.primary => 'Primary',
  AmalfiPushButtonVariant.destructive => 'Destructive',
  _ => 'Secondary',
};
