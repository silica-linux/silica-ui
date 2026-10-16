// Sidebar windows: the sidebar divider goes up through the toolbar section to the top edge of
// the window, and the sidebar scrolls under a glass section (silica-ui#91). A design change
// beyond the kit (`Windows/Sidebar Body/Full` has an opaque section).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadAmalfiFonts);

  Widget window({double? scroll}) => SizedBox(
    width: 600,
    height: 300,
    child: AmalfiSplitWindowLayout(
      columns: [
        AmalfiWindowColumn(
          width: 240,
          toolbarOverChild: true,
          ownEdge: true,
          toolbar: const AmalfiToolbar.sidebarSection(
            key: ValueKey('section'),
            surface: AmalfiToolbarSurface.blur,
            edge: true,
            children: [AmalfiSpacerPiece()],
          ),
          child: AmalfiSidebarPanel(
            topInset: 52,
            children: [
              for (var i = 0; i < 40; i++)
                AmalfiSidebarRow(label: 'Row $i', icon: AmalfiGlyphs.search),
            ],
          ),
        ),
        const AmalfiWindowColumn(child: SizedBox()),
      ],
    ),
  );

  testWidgets(
    'the section is a blur strip and carries the divider to the top',
    (tester) async {
      await pumpKitScene(tester, window());
      final strip = find.descendant(
        of: find.byKey(const ValueKey('section')),
        matching: find.byType(BackdropFilter),
      );
      expect(strip, findsOneWidget);
      // No glass, and the tint is Surface/Sidebar at 80 %.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('section')),
          matching: find.byType(AmalfiGlass),
        ),
        findsNothing,
      );
      expect(AmalfiBlurs.sidebarTitleBar.backgroundBlur, 10);
      expect(AmalfiBlurs.sidebarTitleBar.tintLight, const Color(0xCCF5F6F8));
      // The 1 pt line on the section's trailing edge, over its whole height.
      final section = tester.getRect(find.byKey(const ValueKey('section')));
      expect(section.top, 0);
      final line = find.descendant(
        of: find.byKey(const ValueKey('section')),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == AmalfiColors.light.lineSeparator,
        ),
      );
      expect(tester.getRect(line.last).right, section.right);
      expect(tester.getRect(line.last).height, section.height);
    },
  );

  testWidgets('the sidebar rows start below the section and scroll under it', (
    tester,
  ) async {
    await pumpKitScene(tester, window());
    final first = find.text('Row 0');
    expect(tester.getRect(first).top, greaterThanOrEqualTo(52));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pump();
    // Scrolled past the section: the row is now under the glass, not clipped at its edge.
    expect(tester.getRect(first).top, lessThan(52));
  });
}
