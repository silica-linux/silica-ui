// Gallery page: group boxes (kit `Group Boxes/Box/*`): titled, titled and disabled,
// untitled and nested.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The group boxes page.
final AmalfiGalleryPage groupBoxesPage = AmalfiGalleryPage(
  family: 'group_boxes',
  title: 'Group Boxes',
  build: (context) => const _GroupBoxesPage(),
);

class _GroupBoxesPage extends StatelessWidget {
  const _GroupBoxesPage();

  @override
  Widget build(BuildContext context) => const SpecimenSection(
    title: 'Box',
    children: [
      Specimen(label: 'Titled', child: _Titled(enabled: true)),
      Specimen(label: 'Titled · Disabled', child: _Titled(enabled: false)),
      Specimen(
        label: 'Untitled',
        child: SizedBox(width: 224, child: _Untitled()),
      ),
      Specimen(label: 'Nested', child: _Nested()),
    ],
  );
}

/// A checkbox row that keeps its own value.
class _Check extends StatefulWidget {
  const _Check(this.label, {this.initial = true});

  final String label;
  final bool initial;

  @override
  State<_Check> createState() => _CheckState();
}

class _CheckState extends State<_Check> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiCheckbox(
    value: _value,
    label: widget.label,
    onChanged: (v) => setState(() => _value = v),
  );
}

class _Titled extends StatelessWidget {
  const _Titled({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 192,
    // Disabled, the box dims and blocks its (enabled) controls as a whole.
    child: AmalfiGroupBox(
      title: 'Notifications',
      enabled: enabled,
      children: const [
        _Check('Show banners'),
        _Check('Play sound'),
        _Check('Show on lock screen', initial: false),
      ],
    ),
  );
}

class _Untitled extends StatefulWidget {
  const _Untitled();

  @override
  State<_Untitled> createState() => _UntitledState();
}

class _UntitledState extends State<_Untitled> {
  final _name = TextEditingController(text: 'Amalfi coast');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AmalfiGroupBox(
    children: [
      AmalfiTextField(controller: _name, placeholder: 'Name'),
      const _Check('Remember this name'),
    ],
  );
}

class _Nested extends StatefulWidget {
  const _Nested();

  @override
  State<_Nested> createState() => _NestedState();
}

class _NestedState extends State<_Nested> {
  bool _sync = true;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: AmalfiGroupBox(
      title: 'Recipe sharing',
      children: [
        AmalfiSwitch(
          value: _sync,
          label: 'Enable sync',
          onChanged: (v) => setState(() => _sync = v),
        ),
        const _Untitled(),
      ],
    ),
  );
}
