// Sheets against the kit (`Windows/Window/Sheet Attached`). Checklist:
// docs/amalfi-checklist/sheets.md.
//
// The window is the real document window of `windows_test.dart` (its group box and button
// masked there and here) and the sheet the real Two Buttons alert with real buttons and
// checkbox; the sheet is Glass/Thick (`materials.md`) where the kit nests the opaque alert, so
// the pixels compare the window and the scrim and leave the sheet to `alerts_test.dart`.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'alerts_test.dart' show AppIconSlot;
import 'menus_support.dart';
import 'support/harness.dart';
import 'titlebars_kit_support.dart';
import 'windows_test.dart' show sampleContent;

/// The kit's document window (`Windows/Window/Document`), the sheet's window.
Widget _window() => AmalfiWindow(
  key: const ValueKey('Window'),
  child: AmalfiWindowLayout(
    bar: AmalfiTitleBar(
      title: 'Lemon cake.recipe',
      document: true,
      onClose: () {},
      onMinimise: () {},
      onZoom: () {},
    ),
    barHeight: AmalfiToolbarMetrics.titleBarHeight,
    content: sampleContent(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      gap: 12,
    ),
  ),
);

Widget _scene({required bool open}) => SizedBox(
  width: 540,
  height: 400,
  child: AmalfiAttachedSheet(
    open: open,
    sheet: AmalfiAlert(
      icon: const AppIconSlot(),
      material: AmalfiAlertMaterial.glass,
      title: 'Empty the outbox?',
      message: 'Messages waiting to be sent will be sent now.',
      accessory: Center(
        child: SizedBox(
          width: 168,
          child: AmalfiCheckbox(
            value: false,
            label: 'Do not ask again',
            onChanged: (_) {},
          ),
        ),
      ),
      actions: [
        AmalfiPushButton(label: 'Cancel', onPressed: () {}),
        AmalfiPushButton(
          label: 'Send',
          variant: AmalfiPushButtonVariant.primary,
          onPressed: () {},
        ),
      ],
    ),
    child: _window(),
  ),
);

final Finder _windowFinder = find.byKey(const ValueKey('Window'));

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerSurfaceStyles();
    registerChromeStyles();
  });

  for (final appearance in ['Light', 'Dark']) {
    testWidgets('kit $appearance Sheet Attached', (tester) async {
      final master = KitMaster.load(
        'Windows/Window/Sheet Attached/Active/$appearance',
      );
      final root = await pumpKitScene(
        tester,
        _scene(open: true),
        master: master,
      );
      expectKitGeometry(
        tester,
        master,
        root: root,
        layers: {
          'Window': _windowFinder,
          'Scrim': find.byType(AmalfiSheetScrim),
          'Sheet': find.byType(AmalfiAlert),
        },
      );
      await expectKitPixels(
        tester,
        master,
        _scene(open: true),
        maskLayers: ['Sheet'],
        // The window's group box and button (`Window/Options`, `Window/Done`), not built
        // here, as in windows_test.dart.
        mask: const [
          Rect.fromLTWH(28, 192, 184, 124),
          Rect.fromLTWH(436, 348, 72, 28),
        ],
        tolerance: KitPixelTolerance.withText,
      );
    });
  }

  testWidgets('opens from under the title bar, closes with a fade', (
    tester,
  ) async {
    final open = ValueNotifier(false);
    addTearDown(open.dispose);
    await pumpKitScene(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: open,
        builder: (_, value, _) => _scene(open: value),
      ),
    );
    expect(find.byType(AmalfiAlert), findsNothing);
    expect(find.byType(AmalfiSheetScrim), findsNothing);

    open.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // Moving down: still above its resting place, partly hidden under the title bar.
    expect(tester.getTopLeft(find.byType(AmalfiAlert)).dy, lessThan(40));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(find.byType(AmalfiAlert)), const Offset(130, 40));
    // The window's content ignores the pointer while the sheet is open.
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: _windowFinder,
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );

    open.value = false;
    await tester.pump();
    await tester.pump(AmalfiFades.instant.duration * 2);
    await tester.pump();
    expect(find.byType(AmalfiAlert), findsNothing);
  });
}
