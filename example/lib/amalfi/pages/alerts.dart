// Gallery page: alerts (kit `Alerts/Alert/*`): one, two and three buttons, critical, with a
// field, and the glass alert of the system.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

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

AmalfiPushButton _button(String label, {bool primary = false}) =>
    AmalfiPushButton(
      label: label,
      variant: primary
          ? AmalfiPushButtonVariant.primary
          : AmalfiPushButtonVariant.secondary,
      onPressed: () {},
    );

class _AlertsPage extends StatefulWidget {
  const _AlertsPage();

  @override
  State<_AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<_AlertsPage> {
  bool _suppress = false;

  @override
  Widget build(BuildContext context) {
    return SpecimenSection(
      title: 'Alert',
      children: [
        Specimen(
          label: 'One Button',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            title: 'Import complete',
            message: 'Twelve pictures were added to your library.',
            actions: [_button('OK', primary: true)],
          ),
        ),
        Specimen(
          label: 'Two Buttons',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            title: 'Empty the outbox?',
            message: 'Messages waiting to be sent will be sent now.',
            accessory: Center(
              child: AmalfiCheckbox(
                value: _suppress,
                label: 'Do not ask again',
                onChanged: (v) => setState(() => _suppress = v),
              ),
            ),
            actions: [_button('Cancel'), _button('Send', primary: true)],
          ),
        ),
        Specimen(
          label: 'Three Buttons',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            title: 'Save changes to “Lemon cake”?',
            message: 'Your edits will be lost if you close without saving.',
            actions: [
              _button('Cancel'),
              _button('Don’t Save'),
              _button('Save', primary: true),
            ],
          ),
        ),
        Specimen(
          label: 'Critical',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            critical: true,
            title: 'Delete this list?',
            message: 'All reminders in it will be removed for good.',
            actions: [
              _button('Cancel'),
              AmalfiPushButton(
                label: 'Delete',
                variant: AmalfiPushButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
        Specimen(
          label: 'With Field',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            title: 'Name the note',
            message: 'Choose a short name you will recognise later.',
            accessory: const AmalfiTextField(placeholder: 'Name', width: 240),
            actions: [_button('Cancel'), _button('Save', primary: true)],
          ),
        ),
        Specimen(
          label: 'Glass',
          child: AmalfiAlert(
            icon: const GalleryAppIcon(),
            material: AmalfiAlertMaterial.glass,
            title: 'Event moved',
            message: 'Lunch with Marta now starts at 13:30.',
            actions: [_button('OK', primary: true)],
          ),
        ),
      ],
    );
  }
}
