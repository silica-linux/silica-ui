// Gallery page: alerts (kit `Alerts/Alert/*`): one, two and three buttons, critical, with a
// field, and the glass alert of the system.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';
import 'menus.dart' show GalleryButton;

/// The alerts page.
final AmalfiGalleryPage alertsPage = AmalfiGalleryPage(
  family: 'alerts',
  title: 'Alerts',
  build: (context) => const _AlertsPage(),
);

/// A 56 pt app icon standing in for the app icons (silica-icons).
class GalleryAppIcon extends StatelessWidget {
  const GalleryAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.paletteMare, colors.accentAmalfi],
        ),
        shape: const AmalfiSmoothBorder(radius: 13),
      ),
      child: const SizedBox.square(dimension: 56),
    );
  }
}

/// A checkbox with a label standing in for the toggles family.
class _Suppression extends StatelessWidget {
  const _Suppression();

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: ShapeDecoration(
            color: colors.surfaceControl,
            shape: AmalfiSmoothBorder(
              radius: 4,
              side: BorderSide(color: colors.lineBorder),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Do not ask again',
          style: AmalfiType.body(color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _AlertsPage extends StatelessWidget {
  const _AlertsPage();

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return SpecimenSection(
      title: 'Alert',
      children: [
        const Specimen(
          label: 'One Button',
          child: AmalfiAlert(
            icon: GalleryAppIcon(),
            title: 'Import complete',
            message: 'Twelve pictures were added to your library.',
            actions: [GalleryButton('OK', primary: true, width: 72)],
          ),
        ),
        const Specimen(
          label: 'Two Buttons',
          child: AmalfiAlert(
            icon: GalleryAppIcon(),
            title: 'Empty the outbox?',
            message: 'Messages waiting to be sent will be sent now.',
            accessory: Center(child: _Suppression()),
            actions: [
              GalleryButton('Cancel', width: 72),
              GalleryButton('Send', primary: true, width: 72),
            ],
          ),
        ),
        const Specimen(
          label: 'Three Buttons',
          child: AmalfiAlert(
            icon: GalleryAppIcon(),
            title: 'Save changes to “Lemon cake”?',
            message: 'Your edits will be lost if you close without saving.',
            actions: [
              GalleryButton('Cancel', width: 72),
              GalleryButton('Don’t Save'),
              GalleryButton('Save', primary: true, width: 72),
            ],
          ),
        ),
        const Specimen(
          label: 'Critical',
          child: AmalfiAlert(
            icon: GalleryAppIcon(),
            critical: true,
            title: 'Delete this list?',
            message: 'All reminders in it will be removed for good.',
            actions: [
              GalleryButton('Cancel', width: 72),
              GalleryButton('Delete', primary: true, width: 72),
            ],
          ),
        ),
        Specimen(
          label: 'With Field',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            title: 'Name the note',
            message: 'Choose a short name you will recognise later.',
            accessory: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: ShapeDecoration(
                color: colors.surfaceRaised,
                shape: AmalfiSmoothBorder(
                  radius: AmalfiRadii.field,
                  side: BorderSide(color: colors.lineBorder),
                ),
              ),
              child: Text(
                'Name',
                style: AmalfiType.body(color: colors.textTertiary),
              ),
            ),
            actions: const [
              GalleryButton('Cancel', width: 72),
              GalleryButton('Save', primary: true, width: 72),
            ],
          ),
        ),
        const Specimen(
          label: 'Glass',
          child: AmalfiAlert(
            icon: GalleryAppIcon(),
            material: AmalfiAlertMaterial.glass,
            title: 'Event moved',
            message: 'Lunch with Marta now starts at 13:30.',
            actions: [GalleryButton('OK', primary: true, width: 72)],
          ),
        ),
      ],
    );
  }
}
