// Sheets against the kit (`Windows/Window/Sheet Attached`). Checklist:
// docs/amalfi-checklist/sheets.md.
//
// The window is the windows family's (stood in for here), so the master is checked for its
// geometry only: the pixels of the scrim cannot be compared without the window under it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'alerts_test.dart' show StandIn, standIn, alerts;
import 'menus_support.dart';
import 'support/harness.dart';

Widget _scene({required bool open}) => SizedBox(
  width: 540,
  height: 400,
  child: AmalfiAttachedSheet(
    open: open,
    sheet: const AmalfiAlert(
      icon: StandIn('App icon', 56, 56),
      material: AmalfiAlertMaterial.glass,
      title: 'Empty the outbox?',
      message: 'Messages waiting to be sent will be sent now.',
      accessory: Center(child: StandIn('Suppression', 168, 20)),
      actions: [StandIn('Cancel', 72, 28), StandIn('Send', 72, 28)],
    ),
    child: const StandIn('Window', 540, 400),
  ),
);

void main() {
  setUpAll(() async {
    await loadAmalfiFonts();
    registerSurfaceStyles();
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
          'Window': standIn('Window'),
          'Scrim': find.byType(AmalfiSheetScrim),
          'Sheet': find.byType(AmalfiAlert),
        },
      );
      // The alert in the sheet is the kit's Two Buttons alert, now 268 tall as the sheet's
      // instance (the master itself is 8 short).
      expect(alerts.containsKey('Two Buttons'), isTrue);
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
                  of: standIn('Window'),
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
