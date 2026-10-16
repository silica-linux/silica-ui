// Gallery page: steppers (kit `Steppers/*`). Every size × state of the stepper with its
// states set, the value field, the two together, then live ones.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The steppers page.
final AmalfiGalleryPage steppersPage = AmalfiGalleryPage(
  family: 'steppers',
  title: 'Steppers',
  build: (context) => const _SteppersPage(),
);

const List<(String, AmalfiControlSize)> _sizes = [
  ('Mini', AmalfiControlSize.mini),
  ('Small', AmalfiControlSize.small),
  ('Regular', AmalfiControlSize.regular),
  ('Large', AmalfiControlSize.large),
];

/// The kit's states: the states of the up and the down half (null: disabled).
const List<(String, Set<WidgetState>, Set<WidgetState>)?> _states = [
  ('Rest', {}, {}),
  ('Hover Up', {WidgetState.hovered}, {}),
  ('Hover Down', {}, {WidgetState.hovered}),
  ('Pressed Up', {WidgetState.pressed}, {}),
  ('Pressed Down', {}, {WidgetState.pressed}),
  ('Focused', {WidgetState.focused}, {}),
  null,
];

class _SteppersPage extends StatelessWidget {
  const _SteppersPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (sizeName, size) in _sizes)
        SpecimenSection(
          title: 'Stepper · $sizeName',
          children: [
            for (final state in _states)
              Specimen(
                label: state?.$1 ?? 'Disabled',
                child: _StepperInState(
                  size: size,
                  up: state?.$2,
                  down: state?.$3,
                ),
              ),
          ],
        ),
      const SpecimenSection(
        title: 'Value Field',
        children: [
          Specimen(label: 'Rest', child: _Field()),
          Specimen(label: 'Focused', child: _Field(focused: true)),
          Specimen(label: 'Disabled', child: _Field(enabled: false)),
        ],
      ),
      const SpecimenSection(
        title: 'With Field',
        note: 'Type a number and press Return, or step with the arrows.',
        children: [
          Specimen(label: 'Live', child: _LiveField()),
          Specimen(label: 'Disabled', child: _LiveField(enabled: false)),
        ],
      ),
      SpecimenSection(
        title: 'Live',
        note:
            'Hold a half to repeat; with the focus, the up and down arrows step.',
        children: [
          for (final (name, size) in _sizes)
            Specimen(
              label: name,
              child: _LiveStepper(size: size),
            ),
        ],
      ),
    ],
  );
}

/// A stepper shown with its halves in fixed states; [up] null: disabled.
class _StepperInState extends StatefulWidget {
  const _StepperInState({required this.size, this.up, this.down});

  final AmalfiControlSize size;
  final Set<WidgetState>? up, down;

  @override
  State<_StepperInState> createState() => _StepperInStateState();
}

class _StepperInStateState extends State<_StepperInState> {
  late final WidgetStatesController _up = WidgetStatesController(
    widget.up ?? {},
  );
  late final WidgetStatesController _down = WidgetStatesController(
    widget.down ?? {},
  );

  @override
  void dispose() {
    _up.dispose();
    _down.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AmalfiStepper(
    value: 12,
    onChanged: widget.up == null ? null : (_) {},
    size: widget.size,
    incrementStates: _up,
    decrementStates: _down,
  );
}

class _Field extends StatefulWidget {
  const _Field({this.focused = false, this.enabled = true});

  final bool focused;
  final bool enabled;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final TextEditingController _text = TextEditingController(text: '12');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AmalfiValueField(
    controller: _text,
    enabled: widget.enabled,
    autofocus: widget.focused,
  );
}

class _LiveField extends StatefulWidget {
  const _LiveField({this.enabled = true});

  final bool enabled;

  @override
  State<_LiveField> createState() => _LiveFieldState();
}

class _LiveFieldState extends State<_LiveField> {
  double _value = 12;

  @override
  Widget build(BuildContext context) => AmalfiStepperField(
    value: _value,
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}

class _LiveStepper extends StatefulWidget {
  const _LiveStepper({required this.size});

  final AmalfiControlSize size;

  @override
  State<_LiveStepper> createState() => _LiveStepperState();
}

class _LiveStepperState extends State<_LiveStepper> {
  double _value = 5;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 28,
        child: Text(
          _value.toInt().toString(),
          style: AmalfiType.body(
            color: AmalfiTheme.of(context).colors.textPrimary,
          ),
        ),
      ),
      AmalfiStepper(
        value: _value,
        max: 10,
        size: widget.size,
        onChanged: (v) => setState(() => _value = v),
      ),
    ],
  );
}
