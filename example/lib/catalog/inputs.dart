// Catalog page: inputs and indicators, every control with live state.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

// The inputs are wired into the package exports at release time.

/// The inputs and indicators page, with its own overlay for menus and the color panel.
Widget inputsCatalog() => Overlay(
  initialEntries: [OverlayEntry(builder: (_) => const _InputsCatalog())],
);

const _months = [
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
];

class _InputsCatalog extends StatefulWidget {
  const _InputsCatalog();

  @override
  State<_InputsCatalog> createState() => _InputsCatalogState();
}

class _InputsCatalogState extends State<_InputsCatalog> {
  bool _enabled = true;
  double _small = 24;
  double _regular = 0.6;
  double _ticked = 2;
  double _dial = 90;
  double _count = 3;
  double _rating = 3;
  double _progress = 0.4;
  DateTime _date = DateTime(2026, 10, 14, 12, 11);
  Color _color = const Color(0xFF0021B2);
  List<FieldToken> _tags = const [FieldToken('Work', color: Color(0xFF8ADC98))];
  List<SearchToken> _searchTokens = const [
    SearchToken(
      label: 'Name',
      value: 'report',
      options: ['Name', 'Everything'],
    ),
  ];
  final List<String> _recents = ['invoice', 'holiday photos'];

  static const _labels = DatePickerLabels(
    monthNames: _months,
    weekdayInitials: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    previousMonth: 'Previous month',
    nextMonth: 'Next month',
    today: 'Today',
  );

  Widget _row(String title, List<Widget> children) {
    final colors = InputColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                title,
                style: uiText(size: 13, color: colors.secondaryText),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = InputColors.of(context);
    final e = _enabled;
    return ColoredBox(
      color: colors.panel,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _enabled = !_enabled),
              child: Text(
                e ? 'Enabled (tap to disable)' : 'Disabled (tap to enable)',
                style: uiText(size: 13, color: colors.accent),
              ),
            ),
            const SizedBox(height: 18),
            _row('Text fields', [
              SilicaTextField(width: 232, placeholder: 'Untitled', enabled: e),
              SilicaTextField(
                width: 160,
                placeholder: 'Square',
                bezel: FieldBezel.square,
                enabled: e,
              ),
              SilicaTextField(
                width: 200,
                placeholder: 'Password',
                secure: true,
                capsLockLabel: 'Caps Lock is on',
                enabled: e,
              ),
              SilicaTextField(
                width: 232,
                placeholder: 'Comments',
                maxLines: 4,
                minLines: 3,
                enabled: e,
              ),
            ]),
            _row('Search', [
              SilicaSearchField(
                labels: const SearchFieldLabels(
                  placeholder: 'Search',
                  clear: 'Clear',
                  recentsTitle: 'Recent Searches',
                  clearRecents: 'Clear Recent Searches',
                  noRecents: 'No Recent Searches',
                ),
                width: 205,
                enabled: e,
                recents: _recents,
                onClearRecents: () => setState(_recents.clear),
                onSubmitted: (v) => setState(() {
                  if (v.isNotEmpty && !_recents.contains(v)) {
                    _recents.insert(0, v);
                  }
                }),
              ),
              SilicaSearchField(
                labels: const SearchFieldLabels(placeholder: 'Search'),
                style: SearchFieldStyle.toolbar,
                enabled: e,
                tokens: _searchTokens,
                onTokensChanged: (t) => setState(() => _searchTokens = t),
              ),
            ]),
            _row('Tokens', [
              SilicaTokenField(
                width: 232,
                placeholder: 'Tags',
                enabled: e,
                tokens: _tags,
                complete: (p) => const ['Work', 'Home', 'Important']
                    .where((t) => t.toLowerCase().startsWith(p.toLowerCase()))
                    .firstOrNull,
                onChanged: (t) => setState(() => _tags = t),
              ),
            ]),
            _row('Sliders', [
              SilicaSlider(
                value: _small,
                min: 0,
                max: 112,
                width: 80,
                size: SliderSize.small,
                enabled: e,
                onChanged: (v) => setState(() => _small = v),
              ),
              SilicaSlider(
                value: _regular,
                width: 200,
                enabled: e,
                onChanged: (v) => setState(() => _regular = v),
              ),
              SilicaSlider(
                value: _ticked,
                max: 4,
                divisions: 4,
                ticks: true,
                width: 200,
                labels: const ['Slow', 'Fast'],
                enabled: e,
                onChanged: (v) => setState(() => _ticked = v),
              ),
              SilicaCircularSlider(
                value: _dial,
                max: 360,
                enabled: e,
                onChanged: (v) => setState(() => _dial = v),
              ),
            ]),
            _row('Stepper', [
              Text(
                _count.toInt().toString(),
                style: uiText(size: 13, color: colors.text),
              ),
              SilicaStepper(
                value: _count,
                max: 10,
                enabled: e,
                onChanged: (v) => setState(() => _count = v),
              ),
            ]),
            _row('Date and time', [
              SilicaDateField(
                value: _date,
                labels: _labels,
                stepper: true,
                enabled: e,
                onChanged: (v) => setState(() => _date = v),
              ),
              SilicaDateField(
                value: _date,
                mode: DateFieldMode.time,
                labels: _labels,
                use24Hour: false,
                enabled: e,
                onChanged: (v) => setState(() => _date = v),
              ),
              SilicaCalendar(
                value: _date,
                labels: _labels,
                enabled: e,
                onChanged: (v) => setState(() => _date = v),
              ),
              SilicaClockFace(
                value: _date,
                enabled: e,
                onChanged: (v) => setState(() => _date = v),
              ),
            ]),
            _row('Color', [
              SilicaColorWell(
                color: _color,
                enabled: e,
                onChanged: (c) => setState(() => _color = c),
              ),
            ]),
            _row('Levels', [
              const SilicaLevelIndicator(
                value: 7.5,
                max: 10,
                warning: 7,
                critical: 9,
              ),
              const SilicaLevelIndicator(
                value: 3,
                max: 8,
                style: LevelIndicatorStyle.discrete,
              ),
              SilicaLevelIndicator(
                value: _rating,
                style: LevelIndicatorStyle.rating,
                onChanged: e ? (v) => setState(() => _rating = v) : null,
              ),
            ]),
            _row('Progress', [
              GestureDetector(
                onTap: () =>
                    setState(() => _progress = (_progress + 0.1) % 1.1),
                child: SilicaProgressBar(value: _progress, width: 200),
              ),
              const SilicaProgressBar(value: null, width: 200),
              const SilicaProgressBar(
                value: 0.3,
                width: 154,
                size: ProgressSize.small,
              ),
              const SilicaSpinner(),
              const SilicaSpinner(size: 16),
              SilicaProgressRing(value: 1 - _progress, diameter: 64, stroke: 4),
            ]),
          ],
        ),
      ),
    );
  }
}
