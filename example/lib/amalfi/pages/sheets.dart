// Gallery page: sheets (kit `Windows/Window/Sheet Attached`): a window with an attached
// sheet; the button toggles it to show the motion.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';
import 'alerts.dart' show GalleryAppIcon;

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
  bool _suppress = false;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    void toggle() => setState(() => _open = !_open);
    return SpecimenSection(
      title: 'Sheet Attached',
      note: 'A document window with a sheet; the buttons toggle the sheet.',
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
                accessory: Center(
                  child: AmalfiCheckbox(
                    value: _suppress,
                    label: 'Do not ask again',
                    onChanged: (v) => setState(() => _suppress = v),
                  ),
                ),
                actions: [
                  AmalfiPushButton(label: 'Cancel', onPressed: toggle),
                  AmalfiPushButton(
                    label: 'Send',
                    variant: AmalfiPushButtonVariant.primary,
                    onPressed: toggle,
                  ),
                ],
              ),
              child: AmalfiWindow(
                child: AmalfiWindowLayout(
                  bar: AmalfiTitleBar(
                    title: 'Lemon cake.recipe',
                    document: true,
                    onClose: () {},
                    onMinimise: () {},
                    onZoom: () {},
                  ),
                  barHeight: AmalfiToolbarMetrics.titleBarHeight,
                  content: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lemon cake',
                          style: AmalfiType.title1(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        AmalfiPushButton(
                          label: 'Show the sheet',
                          variant: AmalfiPushButtonVariant.primary,
                          onPressed: toggle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
