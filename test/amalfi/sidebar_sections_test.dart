// Sidebar section colours and the show/hide motion (silica-ui#95; `components.md`).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

Color glyphColorOf(WidgetTester tester, AmalfiGlyphData glyph) {
  final g = tester.widget<AmalfiGlyph>(
    find.byWidgetPredicate((w) => w is AmalfiGlyph && w.glyph == glyph),
  );
  return g.color!;
}

void main() {
  setUpAll(loadAmalfiFonts);
  final colors = AmalfiColors.light;

  testWidgets('glyphs take their section colour, selected or not', (
    tester,
  ) async {
    await pumpKitScene(
      tester,
      SizedBox(
        width: 240,
        child: AmalfiSidebarPanel(
          children: [
            AmalfiSidebarGroup(
              title: 'Places',
              expanded: true,
              glyphColor: colors.textSecondary,
              children: [
                AmalfiSidebarRow(
                  label: 'Home',
                  icon: AmalfiGlyphs.folder,
                  selected: true,
                  onTap: () {},
                ),
                AmalfiSidebarRow(
                  label: 'Trash',
                  icon: AmalfiGlyphs.trash,
                  onTap: () {},
                ),
              ],
            ),
            AmalfiSidebarRow(
              label: 'Tag',
              icon: AmalfiGlyphs.doc,
              glyphColor: const Color(0xFFFF0000),
              onTap: () {},
            ),
            AmalfiSidebarRow(
              label: 'Plain',
              icon: AmalfiGlyphs.search,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(glyphColorOf(tester, AmalfiGlyphs.folder), colors.textSecondary);
    expect(glyphColorOf(tester, AmalfiGlyphs.trash), colors.textSecondary);
    expect(glyphColorOf(tester, AmalfiGlyphs.doc), const Color(0xFFFF0000));
    expect(glyphColorOf(tester, AmalfiGlyphs.search), colors.accentAmalfi);
  });

  testWidgets('in an inactive window every glyph is secondary', (tester) async {
    await pumpKitScene(
      tester,
      WindowActiveScope(
        active: false,
        child: SizedBox(
          width: 240,
          child: AmalfiSidebarGlyphColor(
            color: colors.accentAmalfi,
            child: AmalfiSidebarRow(
              label: 'Home',
              icon: AmalfiGlyphs.folder,
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    expect(glyphColorOf(tester, AmalfiGlyphs.folder), colors.textSecondary);
  });

  group('show and hide', () {
    final visible = ValueNotifier<bool>(true);
    Widget scene() => ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, v, _) => SizedBox(
        width: 600,
        height: 200,
        child: AmalfiSidebarReveal(
          visible: v,
          sidebar: const SizedBox.expand(key: ValueKey('sidebar')),
          content: const SizedBox.expand(key: ValueKey('content')),
        ),
      ),
    );
    double edge(WidgetTester t) =>
        t.getTopLeft(find.byKey(const ValueKey('content'))).dx -
        t.getTopLeft(find.byType(AmalfiSidebarReveal)).dx;

    testWidgets('hiding takes 240 ms on the S curve', (tester) async {
      visible.value = true;
      await pumpKitScene(tester, scene());
      expect(edge(tester), 240);
      visible.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // The half-way point of cubic-bezier(0.42, 0, 0.58, 1) is at half the time.
      expect(edge(tester), closeTo(120, 1));
      await tester.pump(const Duration(milliseconds: 120));
      expect(edge(tester), 0);
      expect(find.byKey(const ValueKey('sidebar')), findsNothing);
    });

    testWidgets('showing starts 40 ms late and takes 230 ms', (tester) async {
      visible.value = false;
      await pumpKitScene(tester, scene());
      expect(edge(tester), 0);
      visible.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(edge(tester), 0);
      await tester.pump(const Duration(milliseconds: 115));
      expect(edge(tester), closeTo(120, 1));
      await tester.pump(const Duration(milliseconds: 115));
      expect(edge(tester), 240);
      // The sidebar keeps its width while it slides.
      expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 240);
    });
  });
}
