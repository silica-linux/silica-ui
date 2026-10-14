import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'harness.dart';

const labels = DatePickerLabels(
  monthNames: [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
  weekdayInitials: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  previousMonth: 'Previous month',
  nextMonth: 'Next month',
  today: 'Today',
);

void main() {
  late DateTime value;
  late FocusNode focus;

  setUp(() {
    value = DateTime(2026, 10, 14, 12, 11);
    focus = FocusNode();
  });

  Widget field({
    DateFieldMode mode = DateFieldMode.date,
    bool use24Hour = true,
    bool stepper = false,
    bool enabled = true,
    List<DatePart>? order,
  }) => StatefulBuilder(
    builder: (context, setState) => SilicaDateField(
      value: value,
      mode: mode,
      use24Hour: use24Hour,
      stepper: stepper,
      enabled: enabled,
      order: order,
      focusNode: focus,
      labels: labels,
      onChanged: (v) => setState(() => value = v),
    ),
  );

  test('part order follows the locale', () {
    expect(datePartOrder(const Locale('en', 'US')).first, DatePart.month);
    expect(datePartOrder(const Locale('it', 'IT')).first, DatePart.day);
    expect(datePartOrder(const Locale('ja')).first, DatePart.year);
  });

  testWidgets('date field: day first by default, 26 tall', (tester) async {
    await pumpControl(
      tester,
      field(order: const [DatePart.day, DatePart.month, DatePart.year]),
    );
    expect(find.text('14'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(tester.getSize(find.byType(SilicaDateField)).height, 26);
  });

  testWidgets('arrows choose and change parts; the part is accent-filled', (
    tester,
  ) async {
    await pumpControl(
      tester,
      field(order: const [DatePart.day, DatePart.month, DatePart.year]),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.pump();
    BoxDecoration deco(int i) =>
        tester.widget<Container>(find.byKey(ValueKey('datePart$i'))).decoration!
            as BoxDecoration;
    expect(deco(0).color, InputColors.light.accent);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(value.day, 15);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value.month, 9);
    expect(deco(1).color, InputColors.light.accent);
    expect(deco(0).color, isNull);
  });

  testWidgets('day wraps within the month; digits type', (tester) async {
    value = DateTime(2026, 2, 28);
    await pumpControl(
      tester,
      field(order: const [DatePart.day, DatePart.month, DatePart.year]),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(value.day, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pump();
    expect(value.day, 25);
    // After two digits the month is chosen.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(value.month, 7);
  });

  testWidgets('time field: 12-hour with the day period label', (tester) async {
    value = DateTime(2026, 10, 14, 15, 5);
    await pumpControl(
      tester,
      field(mode: DateFieldMode.time, use24Hour: false),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(value.hour, 3);
  });

  testWidgets('stepper changes the focused part', (tester) async {
    await pumpControl(tester, field(mode: DateFieldMode.time, stepper: true));
    await tester.tap(find.byKey(const ValueKey('datePart1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('stepperUp')));
    await tester.pump();
    expect(value.minute, 12);
  });

  testWidgets('no part fill in an inactive window; disabled ignores keys', (
    tester,
  ) async {
    await pumpControl(tester, field(), active: false);
    focus.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    final deco =
        tester
                .widget<Container>(find.byKey(const ValueKey('datePart0')))
                .decoration!
            as BoxDecoration;
    expect(deco.color, isNull);
    await pumpControl(tester, field(enabled: false));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(value, DateTime(2026, 10, 14, 12, 11));
  });

  testWidgets('calendar: month grid, choose, navigate', (tester) async {
    await pumpControl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SilicaCalendar(
          value: value,
          today: DateTime(2026, 10, 14),
          labels: labels,
          focusNode: focus,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(find.text('October 2026'), findsOneWidget);
    // Monday first: 1 October 2026 is a Thursday, three days of September before it.
    expect(find.byKey(const ValueKey('day-2026-9-28')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-2026-10-20')));
    await tester.pump();
    expect(value.day, 20);
    expect(value.hour, 12);
    await tester.tap(find.byKey(const ValueKey('calendarNext')));
    await tester.pump();
    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendarToday')));
    await tester.pump();
    expect(value.day, 14);
    expect(find.text('October 2026'), findsOneWidget);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value.day, 21);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(value.month, 11);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('calendar in dark: panel color', (tester) async {
    await pumpControl(
      tester,
      SilicaCalendar(value: value, labels: labels, onChanged: (_) {}),
      dark: true,
    );
    final panel = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SilicaCalendar),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((panel.decoration! as BoxDecoration).color, InputColors.dark.panel);
    // The selected day is a gray square, not an accent circle (CT-DP-02).
    final squares = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SilicaCalendar),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == SilicaCalendar.selectionDark);
    expect(squares, hasLength(1));
    expect(squares.single.shape, BoxShape.rectangle);
  });

  testWidgets('clock face: drag hands, keyboard', (tester) async {
    await pumpControl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SilicaClockFace(
          value: value,
          focusNode: focus,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(SilicaClockFace));
    // Near the rim on the right: minute 15.
    await tester.tapAt(rect.centerRight - const Offset(5, 0));
    await tester.pump();
    expect(value.minute, 15);
    // Inside at the bottom: hour 6 (afternoon kept).
    await tester.tapAt(rect.center + const Offset(0, 20));
    await tester.pump();
    expect(value.hour, 18);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value.minute, 14);
  });
}
