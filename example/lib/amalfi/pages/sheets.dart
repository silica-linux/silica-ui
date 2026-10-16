// Gallery page: sheets (kit `Windows/Window/Sheet Attached`): a window with an attached
// sheet; the button toggles it to show the motion.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';
import 'alerts.dart' show GalleryAppIcon;
import 'menus.dart' show GalleryButton;

/// The sheets page.
final AmalfiGalleryPage sheetsPage = AmalfiGalleryPage(
  family: 'sheets',
  title: 'Sheets',
  build: (context) => const _SheetsPage(),
);

class _SheetsPage extends StatefulWidget {
  const _SheetsPage();

  @override
  State<_SheetsPage> createState() => _SheetsPageState();
}

class _SheetsPageState extends State<_SheetsPage> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    void toggle() => setState(() => _open = !_open);
    return SpecimenSection(
      title: 'Sheet Attached',
      note:
          'A window stands in for the windows family; the buttons toggle the sheet.',
      children: [
        Specimen(
          label: 'Active',
          child: SizedBox(
            width: 540,
            height: 400,
            child: AmalfiAttachedSheet(
              open: _open,
              sheet: AmalfiAlert(
                icon: const GalleryAppIcon(),
                material: AmalfiAlertMaterial.glass,
                title: 'Empty the outbox?',
                message: 'Messages waiting to be sent will be sent now.',
                actions: [
                  GalleryButton('Cancel', width: 72, onPressed: toggle),
                  GalleryButton(
                    'Send',
                    primary: true,
                    width: 72,
                    onPressed: toggle,
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.surfaceWindow,
                  shape: AmalfiSmoothBorder(
                    radius: AmalfiRadii.window,
                    side: BorderSide(color: colors.lineBorder),
                  ),
                  shadows: AmalfiShadows.of(
                    AmalfiTheme.of(context).brightness,
                  ).level(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: AmalfiSheetMetrics.titleBarHeight,
                      child: Center(
                        child: Text(
                          'Lemon cake.recipe',
                          style: AmalfiType.headline(color: colors.textPrimary),
                        ),
                      ),
                    ),
                    Container(height: 1, color: colors.lineSeparator),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: GalleryButton(
                        'Show the sheet',
                        primary: true,
                        onPressed: toggle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
