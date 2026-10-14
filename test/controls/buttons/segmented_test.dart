import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

const sections = [
  Segment(label: 'World'),
  Segment(label: 'Alarms'),
  Segment(label: 'Stopwatch'),
  Segment(label: 'Timer'),
];

Color pillColor(WidgetTester tester, Key key) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(key),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

void main() {
  tearDown(resetHighlight);

  testWidgets('large (Clock): 36 high, pill 28 inset 4, measured dark', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: sections,
          selected: const {2},
          size: ControlSize.large,
          segmentWidth: 94,
          onChanged: (_) {},
        ),
        dark: true,
      ),
    );
    final track = find.byKey(const ValueKey('segmented track'));
    expect(tester.getSize(track), const Size(4 + 4 * 94 + 4, 36));
    final pill = find.byKey(const ValueKey('chosen pill'));
    expect(tester.getSize(pill), const Size(94, 28));
    expect(
      tester.getTopLeft(pill) - tester.getTopLeft(track),
      const Offset(4 + 2 * 94, 4),
    );
    expect(
      pillColor(tester, const ValueKey('chosen pill')),
      const Color(0xFF535353),
    );
    final label = tester.widget<Text>(find.text('Stopwatch'));
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.style?.color, const Color(0xFFFFFFFF));

    // Inactive window: the pill turns #464646 (measured).
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: sections,
          selected: const {2},
          size: ControlSize.large,
          onChanged: (_) {},
        ),
        dark: true,
        active: false,
      ),
    );
    expect(
      pillColor(tester, const ValueKey('chosen pill')),
      const Color(0xFF464646),
    );
  });

  testWidgets('select one: the pill moves in ~300 ms', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => harness(
          SegmentedControl(
            segments: sections,
            selected: {selected},
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    final pill = find.byKey(const ValueKey('chosen pill'));
    final start = tester.getTopLeft(pill).dx;
    await tester.tap(find.text('Timer'));
    await tester.pump();
    expect(selected, 3);
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(pill).dx;
    expect(mid, greaterThan(start));
    await tester.pump(const Duration(milliseconds: 250));
    final end = tester.getTopLeft(pill).dx;
    expect(end, greaterThan(mid));
    expect(
      end,
      tester.getTopLeft(find.byKey(const ValueKey('segmented track'))).dx +
          2 +
          3 * tester.getSize(pill).width,
    );
  });

  testWidgets('window style: no hover, pressed #c5c5c5, accent pill (INV-B)', (
    tester,
  ) async {
    final pressed = <int>[];
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: sections,
          selected: const {0},
          onChanged: pressed.add,
        ),
      ),
    );
    expect(
      pillColor(tester, const ValueKey('chosen pill')),
      const Color(0xFF0077F9),
    );
    expect(
      tester.widget<Text>(find.text('Alarms').first).style?.color,
      const Color(0xFF242424),
    );
    final mouse = await hover(tester, find.text('Alarms'));
    expect(find.byKey(const ValueKey('hover 1')), findsNothing);
    await mouse.down(tester.getCenter(find.text('Alarms')));
    await tester.pump();
    expect(
      pillColor(tester, const ValueKey('pressed 1')),
      const Color(0xFFC5C5C5),
    );
    expect(pressed, isEmpty);
    await mouse.up();
    await tester.pump();
    expect(pressed, [1]);
    await mouse.removePointer();
  });

  testWidgets('select any keeps one pill per chosen segment', (tester) async {
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: const [
            Segment(label: 'B'),
            Segment(label: 'I'),
            Segment(label: 'U'),
          ],
          mode: SegmentedMode.selectAny,
          selected: const {0, 2},
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('chosen pill 0')), findsOneWidget);
    expect(find.byKey(const ValueKey('chosen pill 2')), findsOneWidget);
    expect(find.byKey(const ValueKey('chosen pill')), findsNothing);
  });

  testWidgets('momentary: a pill only while pressed', (tester) async {
    final pressed = <int>[];
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: const [
            Segment(label: '<', semanticLabel: 'Previous'),
            Segment(label: '>', semanticLabel: 'Next'),
          ],
          mode: SegmentedMode.momentary,
          size: ControlSize.small,
          selected: const {0},
          onChanged: pressed.add,
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('segmented track'))).height,
      22,
    );
    expect(find.byKey(const ValueKey('chosen pill')), findsNothing);
    final press = await tester.startGesture(tester.getCenter(find.text('>')));
    await tester.pump();
    expect(find.byKey(const ValueKey('pressed 1')), findsOneWidget);
    await press.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('pressed 1')), findsNothing);
    expect(pressed, [1]);
  });

  testWidgets('keyboard: arrows choose, skipping disabled segments', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => harness(
          SegmentedControl(
            segments: const [
              Segment(label: 'A'),
              Segment(label: 'B', enabled: false),
              Segment(label: 'C'),
            ],
            selected: {selected},
            focusNode: node,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    await keyboardFocus(tester, node);
    expect(find.byKey(const ValueKey('focus ring')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, 0);
  });

  testWidgets('semantics: selected buttons in a group', (tester) async {
    await tester.pumpWidget(
      harness(
        SegmentedControl(
          segments: sections,
          selected: const {1},
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Alarms')),
      matchesSemantics(
        label: 'Alarms',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });
}
