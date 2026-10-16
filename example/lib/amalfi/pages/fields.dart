// Gallery page: fields (kit `Fields/*`). Every variant × size × state; the "Focused" specimens
// show the focused look through a states controller, and every field is live: click one to
// type in it.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The fields page.
final AmalfiGalleryPage fieldsPage = AmalfiGalleryPage(
  family: 'fields',
  title: 'Fields',
  build: (context) => const _FieldsPage(),
);

const List<String> _sizes = ['Small', 'Regular', 'Large'];
const List<String> _fruit = ['Orange', 'Lemon', 'Olive', 'Fig'];

AmalfiFieldSize _size(String name) => switch (name) {
  'Small' => AmalfiFieldSize.small,
  'Large' => AmalfiFieldSize.large,
  _ => AmalfiFieldSize.regular,
};

class _FieldsPage extends StatefulWidget {
  const _FieldsPage();

  @override
  State<_FieldsPage> createState() => _FieldsPageState();
}

class _FieldsPageState extends State<_FieldsPage> {
  final List<ChangeNotifier> _owned = [];
  List<String> _tags = ['Travel', 'Coast'];
  List<String> _searchTokens = ['Recipes'];

  TextEditingController _text(String value) {
    final c = TextEditingController(text: value);
    _owned.add(c);
    return c;
  }

  WidgetStatesController _focused() {
    final c = WidgetStatesController({WidgetState.focused});
    _owned.add(c);
    return c;
  }

  @override
  void dispose() {
    for (final c in _owned) {
      c.dispose();
    }
    super.dispose();
  }

  // Controllers are made once per specimen: the page builds them in initState-like fashion
  // through these caches, keyed by the specimen.
  final Map<String, TextEditingController> _texts = {};
  final Map<String, WidgetStatesController> _states = {};

  TextEditingController text(String key, String value) =>
      _texts.putIfAbsent(key, () => _text(value));

  WidgetStatesController? focusedIf(String key, bool focused) =>
      focused ? _states.putIfAbsent(key, _focused) : null;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final size in _sizes)
        SpecimenSection(
          title: 'Text Field · $size',
          children: [
            for (final state in [
              'Placeholder',
              'Filled',
              'Focused',
              'Disabled',
              'Error',
            ])
              Specimen(
                label: state,
                child: AmalfiTextField(
                  size: _size(size),
                  placeholder: 'Name',
                  enabled: state != 'Disabled',
                  errorText: state == 'Error' ? 'Enter a name' : null,
                  statesController: focusedIf(
                    'tf$size$state',
                    state == 'Focused',
                  ),
                  controller: text(
                    'tf$size$state',
                    state == 'Placeholder' || state == 'Disabled'
                        ? ''
                        : 'Amalfi coast',
                  ),
                ),
              ),
          ],
        ),
      SpecimenSection(
        title: 'Secure Field',
        children: [
          for (final state in ['Placeholder', 'Filled', 'Focused', 'Disabled'])
            Specimen(
              label: state,
              child: AmalfiSecureField(
                placeholder: 'Password',
                enabled: state != 'Disabled',
                statesController: focusedIf('sf$state', state == 'Focused'),
                controller: text(
                  'sf$state',
                  state == 'Filled' || state == 'Focused' ? 'positano' : '',
                ),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Text Area',
        children: [
          for (final state in ['Placeholder', 'Filled', 'Focused', 'Disabled'])
            Specimen(
              label: state,
              child: AmalfiTextArea(
                placeholder: 'Write a note',
                enabled: state != 'Disabled',
                statesController: focusedIf('ta$state', state == 'Focused'),
                controller: text(
                  'ta$state',
                  state == 'Placeholder'
                      ? ''
                      : 'Rooms face the sea.\nBreakfast is served on the '
                            'terrace until ten.',
                ),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Inline Button',
        children: [
          for (final state in ['Rest', 'Focused', 'Disabled'])
            Specimen(
              label: state,
              child: AmalfiTextField(
                width: 260,
                enabled: state != 'Disabled',
                statesController: focusedIf('ib$state', state == 'Focused'),
                controller: text('ib$state', 'Downloads'),
                trailing: AmalfiInlineButton(
                  label: 'Browse',
                  onPressed: state == 'Disabled'
                      ? null
                      : () => text('ib$state', '').text = 'Documents',
                ),
              ),
            ),
        ],
      ),
      for (final size in _sizes)
        SpecimenSection(
          title: 'Search Field · $size',
          children: [
            for (final state in ['Empty', 'Typing', 'Focused', 'Disabled'])
              Specimen(
                label: state,
                child: AmalfiSearchField(
                  size: _size(size),
                  enabled: state != 'Disabled',
                  statesController: focusedIf(
                    'sr$size$state',
                    state == 'Focused',
                  ),
                  controller: text(
                    'sr$size$state',
                    state == 'Typing' ? 'Limoni' : '',
                  ),
                ),
              ),
          ],
        ),
      SpecimenSection(
        title: 'Search Field · Token',
        note: 'Backspace at the start selects the token, again removes it.',
        children: [
          for (final state in ['Token', 'Token Focused'])
            Specimen(
              label: state,
              child: AmalfiSearchField(
                width: 240,
                tokens: _searchTokens,
                onTokensChanged: (t) => setState(() => _searchTokens = t),
                statesController: focusedIf('st$state', state != 'Token'),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Token and Token Field',
        note: 'Type a tag and press Enter or a comma.',
        children: [
          const Specimen(
            label: 'Token · Rest',
            child: AmalfiToken(label: 'Travel'),
          ),
          const Specimen(
            label: 'Token · Selected',
            child: AmalfiToken(label: 'Travel', selected: true),
          ),
          for (final state in ['Rest', 'Focused'])
            Specimen(
              label: 'Token Field · $state',
              child: AmalfiTokenField(
                tokens: _tags,
                placeholder: 'Add tag',
                onTokensChanged: (t) => setState(() => _tags = t),
                statesController: focusedIf('tk$state', state == 'Focused'),
              ),
            ),
          Specimen(
            label: 'Clear Button',
            child: AmalfiClearButton(onPressed: () {}),
          ),
        ],
      ),
      for (final size in _sizes)
        SpecimenSection(
          title: 'Combo Box · $size',
          note: size == 'Regular'
              ? 'Open the list with the button or ↓; ↑ ↓ Enter pick, Esc closes.'
              : null,
          children: [
            for (final state in ['Rest', 'Focused', 'Disabled'])
              Specimen(
                label: state,
                child: AmalfiComboBox(
                  options: _fruit,
                  size: _size(size),
                  enabled: state != 'Disabled',
                  statesController: focusedIf(
                    'cb$size$state',
                    state == 'Focused',
                  ),
                  controller: text('cb$size$state', 'Lemon'),
                ),
              ),
            for (final state in ['Rest', 'Pressed', 'Disabled'])
              Specimen(
                label: 'Combo Button · $state',
                child: AmalfiComboButton(
                  size: _size(size),
                  pressed: state == 'Pressed',
                  onPressed: state == 'Disabled' ? null : () {},
                ),
              ),
          ],
        ),
    ],
  );
}
