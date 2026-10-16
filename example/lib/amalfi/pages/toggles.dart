// Gallery page: toggles (kit `Toggles/*`). Every variant × size × state of checkboxes, radio
// buttons and switches drawn statically, then live controls, labelled rows and groups.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The toggles page.
final AmalfiGalleryPage togglesPage = AmalfiGalleryPage(
  family: 'toggles',
  title: 'Toggles',
  build: (context) => const _TogglesPage(),
);

/// The kit's states, as the faces draw them.
const List<(String, AmalfiInteractionState)> _states = [
  ('Rest', AmalfiInteractionState()),
  ('Hover', AmalfiInteractionState(hovered: true)),
  ('Pressed', AmalfiInteractionState(pressed: true)),
  ('Disabled', AmalfiInteractionState(enabled: false)),
  ('Focused', AmalfiInteractionState(focused: true)),
];

const List<(String, AmalfiControlSize)> _boxSizes = [
  ('Small', AmalfiControlSize.small),
  ('Regular', AmalfiControlSize.regular),
  ('Large', AmalfiControlSize.large),
];

const List<(String, AmalfiControlSize)> _switchSizes = [
  ('Mini', AmalfiControlSize.mini),
  ('Small', AmalfiControlSize.small),
  ('Regular', AmalfiControlSize.regular),
];

class _TogglesPage extends StatelessWidget {
  const _TogglesPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (variant, value) in [
        ('Off', false),
        ('On', true),
        ('Mixed', null),
      ])
        SpecimenSection(
          title: 'Checkbox · $variant',
          children: [
            for (final (size, s) in _boxSizes)
              for (final (state, st) in _states)
                Specimen(
                  label: '$size · $state',
                  child: AmalfiCheckboxFace(value: value, size: s, state: st),
                ),
          ],
        ),
      for (final (variant, selected) in [('Off', false), ('On', true)])
        SpecimenSection(
          title: 'Radio · $variant',
          children: [
            for (final (size, s) in _boxSizes)
              for (final (state, st) in _states)
                Specimen(
                  label: '$size · $state',
                  child: AmalfiRadioFace(
                    selected: selected,
                    size: s,
                    state: st,
                  ),
                ),
          ],
        ),
      for (final (variant, value) in [('Off', false), ('On', true)])
        SpecimenSection(
          title: 'Switch · $variant',
          note:
              'Dragging: the thumb becomes a Glass/Clear lens over the track.',
          children: [
            for (final (size, s) in _switchSizes) ...[
              for (final (state, st) in _states)
                Specimen(
                  label: '$size · $state',
                  child: AmalfiSwitchFace(value: value, size: s, state: st),
                ),
              Specimen(
                label: '$size · Dragging',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AmalfiSwitchFace(
                    value: value,
                    size: s,
                    dragging: true,
                    state: const AmalfiInteractionState(pressed: true),
                  ),
                ),
              ),
            ],
          ],
        ),
      SpecimenSection(
        title: 'With Label',
        note: 'Live: click a box or its label, or Tab to one and press Space.',
        children: [
          for (final (state, enabled) in [('Rest', true), ('Disabled', false)])
            for (final value in [false, true, null])
              Specimen(
                label: '${_checkName(value)} · $state',
                child: _LiveCheckbox(initial: value, enabled: enabled),
              ),
          for (final (state, enabled) in [('Rest', true), ('Disabled', false)])
            for (final value in [false, true])
              Specimen(
                label: 'Radio ${value ? 'On' : 'Off'} · $state',
                child: AmalfiRadio(
                  selected: value,
                  label: 'Sort by name',
                  onSelected: enabled ? () {} : null,
                ),
              ),
          for (final (state, enabled) in [('Rest', true), ('Disabled', false)])
            for (final value in [false, true])
              Specimen(
                label: 'Switch ${value ? 'On' : 'Off'} · $state',
                child: SizedBox(
                  width: 240,
                  child: _LiveSwitch(initial: value, enabled: enabled),
                ),
              ),
        ],
      ),
      SpecimenSection(
        title: 'Live switches',
        note: 'Click, drag the thumb or press Space.',
        children: [
          for (final (size, s) in _switchSizes)
            Specimen(
              label: size,
              child: SizedBox(
                width: 240,
                child: _LiveSwitch(initial: false, size: s),
              ),
            ),
        ],
      ),
      const SpecimenSection(
        title: 'Groups',
        note: 'The arrow keys move the choice of a radio group.',
        children: [
          Specimen(label: 'Checkbox Group', child: _CheckboxGroup()),
          Specimen(label: 'Radio Group', child: _RadioGroup()),
        ],
      ),
    ],
  );

  static String _checkName(bool? value) => switch (value) {
    false => 'Off',
    true => 'On',
    null => 'Mixed',
  };
}

class _LiveCheckbox extends StatefulWidget {
  const _LiveCheckbox({required this.initial, this.enabled = true});

  final bool? initial;
  final bool enabled;

  @override
  State<_LiveCheckbox> createState() => _LiveCheckboxState();
}

class _LiveCheckboxState extends State<_LiveCheckbox> {
  late bool? _value = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiCheckbox(
    value: _value,
    label: 'Show hidden files',
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}

class _LiveSwitch extends StatefulWidget {
  const _LiveSwitch({
    required this.initial,
    this.enabled = true,
    this.size = AmalfiControlSize.regular,
  });

  final bool initial;
  final bool enabled;
  final AmalfiControlSize size;

  @override
  State<_LiveSwitch> createState() => _LiveSwitchState();
}

class _LiveSwitchState extends State<_LiveSwitch> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiSwitch(
    value: _value,
    size: widget.size,
    label: widget.size == AmalfiControlSize.regular ? 'Wi-Fi' : null,
    semanticLabel: 'Wi-Fi',
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}

class _CheckboxGroup extends StatefulWidget {
  const _CheckboxGroup();

  @override
  State<_CheckboxGroup> createState() => _CheckboxGroupState();
}

class _CheckboxGroupState extends State<_CheckboxGroup> {
  bool _hidden = true;
  bool _tabs = false;

  @override
  Widget build(BuildContext context) {
    final all = _hidden && _tabs
        ? true
        : !_hidden && !_tabs
        ? false
        : null;
    return AmalfiToggleGroup(
      heading: 'Browsing',
      children: [
        AmalfiCheckbox(
          value: all,
          label: 'Select all',
          onChanged: (v) => setState(() => _hidden = _tabs = v),
        ),
        AmalfiCheckbox(
          value: _hidden,
          label: 'Show hidden files',
          onChanged: (v) => setState(() => _hidden = v),
        ),
        AmalfiCheckbox(
          value: _tabs,
          label: 'Open folders in tabs',
          onChanged: (v) => setState(() => _tabs = v),
        ),
      ],
    );
  }
}

class _RadioGroup extends StatefulWidget {
  const _RadioGroup();

  @override
  State<_RadioGroup> createState() => _RadioGroupState();
}

class _RadioGroupState extends State<_RadioGroup> {
  String _order = 'date';

  @override
  Widget build(BuildContext context) => AmalfiRadioGroup<String>(
    heading: 'Order',
    value: _order,
    onChanged: (v) => setState(() => _order = v),
    options: const [
      AmalfiRadioOption(value: 'name', label: 'Sort by name'),
      AmalfiRadioOption(value: 'date', label: 'Sort by date'),
      AmalfiRadioOption(value: 'size', label: 'Sort by size'),
    ],
  );
}
