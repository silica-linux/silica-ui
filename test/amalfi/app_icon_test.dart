// The 16 pt app icons of the menus against the kit (`Icons/App/16/<App>`, Light and Dark),
// drawn from the app layers in silica-icons. Checklist: docs/amalfi-checklist/menus.md.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// The kit's PNGs are the 1024 icons resampled by Sketch; Flutter resamples the rendered PNGs
/// itself, so only the mean is compared (measured 6 to 10, the dynamic Calendar and Clock the most).
void main() {
  final iconsDir = Platform.environment['SILICA_ICONS_DIR'];
  final apps = <String>[
    for (final d in Directory('test/amalfi/kit/Icons/App/16').listSync())
      if (d is Directory && !d.path.endsWith('/Apps')) d.path.split('/').last,
  ]..sort();

  for (final appearance in ['Light', 'Dark']) {
    for (final name in apps) {
      final id = name.toLowerCase().replaceAll(' ', '-');
      testWidgets(
        'kit $appearance $name',
        skip: iconsDir == null || iconsDir.isEmpty,
        (tester) async {
          final master = KitMaster.load('Icons/App/16/$name/$appearance');
          final icon = AmalfiTheme(
            brightness: appearance == 'Dark'
                ? Brightness.dark
                : Brightness.light,
            child: AmalfiAppIcon(id),
          );
          expect(master.size, const Size(16, 16));
          await expectKitPixels(
            tester,
            master,
            icon,
            tolerance: const KitPixelTolerance(mean: 12, max: 255),
            prepare: (tester) async {
              // The SVG layers load from disk.
              for (var i = 0; i < 20; i++) {
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 50)),
                );
                await tester.pump();
              }
            },
          );
        },
      );
    }
  }

  testWidgets('an unknown app leaves its 16 pt box empty', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: AmalfiAppIcon('no-such-app', env: {})),
      ),
    );
    expect(tester.getSize(find.byType(AmalfiAppIcon)), const Size(16, 16));
  });
}
