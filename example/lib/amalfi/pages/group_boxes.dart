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
  const _Check(this.label, {this.initial = true, this.enabled = true});

  final String label;
  final bool initial;
  final bool enabled;

  @override
  State<_Check> createState() => _CheckState();
}

class _CheckState extends State<_Check> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiCheckbox(
    value: _value,
    label: widget.label,
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}

class _Titled extends StatelessWidget {
  const _Titled({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: AmalfiGroupBox(
      title: 'Notifications',
      enabled: enabled,
      children: [
        _Check('Show banners', enabled: enabled),
        _Check('Play sound', enabled: enabled),
        _Check('Show on lock screen', initial: false, enabled: enabled),
      ],
    ),
  );
}

class _Untitled extends StatelessWidget {
  const _Untitled();

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return AmalfiGroupBox(
      children: [
        // A stand-in for the text field of the fields family.
        SizedBox(
          width: 200,
          height: 28,
          child: DecoratedBox(
            decoration: AmalfiShapeDecoration(
              color: colors.surfaceRaised,
              shape: AmalfiSmoothBorder(
                radius: AmalfiRadii.field,
                side: BorderSide(color: colors.lineBorder),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                'Amalfi coast',
                style: AmalfiType.body(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        const _Check('Remember this name'),
      ],
    );
  }
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
        const SizedBox(width: 224, child: _Untitled()),
      ],
    ),
  );
}
