// Gallery page: forms (kit `Forms/*`): every row, the three sections, the footer and the full
// layout, all live. The pop-up, checkboxes, switch and push buttons are the forms family's
// stand-ins until the buttons and toggles families land.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';
// ignore: implementation_imports
import 'package:silica_ui/src/amalfi/components/forms/stand_ins.dart';

import '../specimen.dart';

/// The forms page.
final AmalfiGalleryPage formsPage = AmalfiGalleryPage(
  family: 'forms',
  title: 'Forms',
  build: (context) => const _FormsPage(),
);

const List<String> _regions = ['Lemon', 'Olive', 'Fig'];

class _FormsPage extends StatefulWidget {
  const _FormsPage();

  @override
  State<_FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<_FormsPage> {
  final TextEditingController _name = TextEditingController(
    text: 'Marta Esposito',
  );
  final TextEditingController _email = TextEditingController(
    text: 'marta@example',
  );
  final TextEditingController _display = TextEditingController(text: 'Marta');
  String _region = 'Lemon';
  bool _updates = true;
  bool _signedIn = true;
  bool _sync = true;
  String _saved = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _display.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text);

  Widget get _regionPopUp => StandInPopUpButton(
    value: _region,
    options: _regions,
    onChanged: (v) => setState(() => _region = v),
  );

  Widget _profile() => AmalfiFormSection(
    title: 'Profile',
    rows: [
      AmalfiFormRow(
        label: 'Name:',
        control: AmalfiTextField(controller: _name),
      ),
      AmalfiFormRow(
        label: 'Email:',
        control: AmalfiTextField(
          controller: _email,
          errorText: _emailValid ? null : 'Invalid address',
          onChanged: (_) => setState(() {}),
        ),
        message: _emailValid
            ? null
            : 'Enter an address such as name@example.com.',
        messageKind: AmalfiFormMessageKind.error,
      ),
      AmalfiFormRow(label: 'Region:', control: _regionPopUp),
    ],
  );

  Widget _preferences() => AmalfiFormSection(
    title: 'Preferences',
    rows: [
      AmalfiFormRow(
        label: 'Options:',
        control: StandInCheckbox(
          label: 'Send me updates',
          value: _updates,
          onChanged: (v) => setState(() => _updates = v),
        ),
      ),
      AmalfiFormRow(
        control: StandInCheckbox(
          label: 'Keep me signed in',
          value: _signedIn,
          onChanged: (v) => setState(() => _signedIn = v),
        ),
      ),
    ],
  );

  Widget _validation() => AmalfiFormSection(
    title: 'Validation',
    rows: [
      AmalfiFormRow(
        label: 'Display name:',
        control: AmalfiTextField(controller: _display),
        message: 'This name is shown to people you share with.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpecimenSection(
        title: 'Row',
        children: [
          const Specimen(
            label: 'Text',
            child: AmalfiFormRow(label: 'Label', control: AmalfiTextField()),
          ),
          Specimen(
            label: 'Popup',
            child: AmalfiFormRow(label: 'Label', control: _regionPopUp),
          ),
          Specimen(
            label: 'Check',
            child: AmalfiFormRow(
              label: 'Label',
              control: StandInCheckbox(
                label: 'Send me updates',
                value: _updates,
                onChanged: (v) => setState(() => _updates = v),
              ),
            ),
          ),
          Specimen(
            label: 'Switch',
            child: AmalfiFormRow(
              label: 'Label',
              control: StandInSwitch(
                label: 'Sync across devices',
                value: _sync,
                onChanged: (v) => setState(() => _sync = v),
              ),
            ),
          ),
          const Specimen(
            label: 'Help',
            child: AmalfiFormRow(
              label: 'Label',
              control: AmalfiTextField(),
              message: 'This name is shown to people you share with.',
            ),
          ),
          const Specimen(
            label: 'Error',
            child: AmalfiFormRow(
              label: 'Label',
              control: AmalfiTextField(errorText: 'Invalid address'),
              message: 'Enter an address such as name@example.com.',
              messageKind: AmalfiFormMessageKind.error,
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Section and Footer',
        children: [
          Specimen(label: 'Profile', child: _profile()),
          Specimen(label: 'Preferences', child: _preferences()),
          Specimen(label: 'Validation', child: _validation()),
          Specimen(
            label: 'Footer',
            child: SizedBox(
              width: 352,
              child: AmalfiFormFooter(
                actions: [
                  StandInPushButton(
                    label: 'Cancel',
                    onPressed: () => setState(() => _saved = 'Cancelled'),
                  ),
                  StandInPushButton(
                    label: 'Save',
                    primary: true,
                    onPressed: () => setState(() => _saved = 'Saved'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Layout',
        note: _saved.isEmpty ? 'Edit the fields; Save or Cancel.' : _saved,
        children: [
          Specimen(
            label: 'Full',
            child: AmalfiFormLayout(
              title: 'Account details',
              sections: [_profile(), _preferences()],
              footer: AmalfiFormFooter(
                actions: [
                  StandInPushButton(
                    label: 'Cancel',
                    onPressed: () => setState(() => _saved = 'Cancelled'),
                  ),
                  StandInPushButton(
                    label: 'Save',
                    primary: true,
                    onPressed: () => setState(
                      () => _saved = _emailValid
                          ? 'Saved'
                          : 'Fix the email address first',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
