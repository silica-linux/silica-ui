// Gallery page: disclosure (kit `Disclosure/*`). Triangles and buttons in every state, group
// headers, and live groups.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The disclosure page.
final AmalfiGalleryPage disclosurePage = AmalfiGalleryPage(
  family: 'disclosure',
  title: 'Disclosure',
  build: (context) => const _DisclosurePage(),
);

const List<(String, AmalfiInteractionState)> _states = [
  ('Rest', AmalfiInteractionState()),
  ('Hover', AmalfiInteractionState(hovered: true)),
  ('Pressed', AmalfiInteractionState(pressed: true)),
  ('Disabled', AmalfiInteractionState(enabled: false)),
  ('Focused', AmalfiInteractionState(focused: true)),
];

class _DisclosurePage extends StatelessWidget {
  const _DisclosurePage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (kind, style) in [
        ('Triangle', AmalfiDisclosureStyle.triangle),
        ('Button', AmalfiDisclosureStyle.button),
      ])
        SpecimenSection(
          title: kind,
          children: [
            for (final (variant, expanded) in [
              ('Collapsed', false),
              ('Expanded', true),
            ])
              for (final (state, st) in _states)
                Specimen(
                  label: '$variant · $state',
                  child: AmalfiDisclosureFace(
                    expanded: expanded,
                    style: style,
                    state: st,
                  ),
                ),
            for (final expanded in [false, true])
              Specimen(
                label: 'Live · ${expanded ? 'Expanded' : 'Collapsed'}',
                child: _LiveDisclosure(style: style, initial: expanded),
              ),
          ],
        ),
      SpecimenSection(
        title: 'Group Header',
        children: [
          for (final (variant, expanded) in [('Closed', false), ('Open', true)])
            for (final (state, st) in _states.take(2))
              Specimen(
                label: '$variant · $state',
                child: SizedBox(
                  width: 280,
                  child: AmalfiDisclosureHeaderFace(
                    title: 'Advanced options',
                    expanded: expanded,
                    state: st,
                  ),
                ),
              ),
        ],
      ),
      const SpecimenSection(
        title: 'Group',
        note: 'Click a header, or Tab to it and press Space.',
        children: [
          Specimen(label: 'Closed', child: _LiveGroup(initial: false)),
          Specimen(label: 'Open', child: _LiveGroup(initial: true)),
        ],
      ),
    ],
  );
}

class _LiveDisclosure extends StatefulWidget {
  const _LiveDisclosure({required this.style, required this.initial});

  final AmalfiDisclosureStyle style;
  final bool initial;

  @override
  State<_LiveDisclosure> createState() => _LiveDisclosureState();
}

class _LiveDisclosureState extends State<_LiveDisclosure> {
  late bool _expanded = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiDisclosure(
    expanded: _expanded,
    style: widget.style,
    semanticLabel: 'Details',
    onChanged: (v) => setState(() => _expanded = v),
  );
}

class _LiveGroup extends StatefulWidget {
  const _LiveGroup({required this.initial});

  final bool initial;

  @override
  State<_LiveGroup> createState() => _LiveGroupState();
}

class _LiveGroupState extends State<_LiveGroup> {
  late bool _expanded = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return SizedBox(
      width: 280,
      child: AmalfiDisclosureGroup(
        title: 'Advanced options',
        expanded: _expanded,
        onExpandedChanged: (v) => setState(() => _expanded = v),
        child: Text(
          'The content of the group sits below its header and is indented '
          'to line up with the title.',
          style: AmalfiType.callout(color: colors.textSecondary),
        ),
      ),
    );
  }
}
