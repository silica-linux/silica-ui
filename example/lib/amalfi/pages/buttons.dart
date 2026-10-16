// Gallery page: buttons (kit `Buttons/*`). Every variant × size in the five states (Rest,
// Hover, Pressed, Disabled and Focused shown with AmalfiButtonPreview), then live buttons to
// hover, press, tab to and open.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The buttons page.
final AmalfiGalleryPage buttonsPage = AmalfiGalleryPage(
  family: 'buttons',
  title: 'Buttons',
  build: (context) => const _ButtonsPage(),
);

void _noop() {}

const _sizes = {
  'Mini': AmalfiControlSize.mini,
  'Small': AmalfiControlSize.small,
  'Regular': AmalfiControlSize.regular,
  'Large': AmalfiControlSize.large,
};

const _variants = {
  'Primary': AmalfiPushButtonVariant.primary,
  'Secondary': AmalfiPushButtonVariant.secondary,
  'Destructive': AmalfiPushButtonVariant.destructive,
  'Borderless': AmalfiPushButtonVariant.borderless,
  'Glass': AmalfiPushButtonVariant.glass,
};

/// The five kit states of a button built by [build] (enabled or not), labelled [name] · state.
List<Widget> _states(String name, Widget Function(bool enabled) build) => [
  Specimen(label: '$name · Rest', child: build(true)),
  for (final (state, label) in [
    (AmalfiButtonPreviewState.hover, 'Hover'),
    (AmalfiButtonPreviewState.pressed, 'Pressed'),
  ])
    Specimen(
      label: '$name · $label',
      child: AmalfiButtonPreview(state: state, child: build(true)),
    ),
  Specimen(label: '$name · Disabled', child: build(false)),
  Specimen(
    label: '$name · Focused',
    child: AmalfiButtonPreview(
      state: AmalfiButtonPreviewState.focused,
      child: build(true),
    ),
  ),
];

class _ButtonsPage extends StatelessWidget {
  const _ButtonsPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final MapEntry(key: v, value: variant) in _variants.entries)
        SpecimenSection(
          title: 'Push · $v',
          children: [
            for (final MapEntry(key: s, value: size) in _sizes.entries)
              ..._states(
                s,
                (enabled) => AmalfiPushButton(
                  label: 'Button',
                  variant: variant,
                  size: size,
                  onPressed: enabled ? _noop : null,
                ),
              ),
          ],
        ),
      for (final (name, shape) in [
        ('Round', AmalfiIconButtonShape.round),
        ('Square', AmalfiIconButtonShape.square),
      ])
        SpecimenSection(
          title: 'Icon · $name',
          children: [
            for (final MapEntry(key: s, value: size) in _sizes.entries)
              ..._states(
                s,
                (enabled) => AmalfiIconButton(
                  icon: const AmalfiGlyph(AmalfiGlyphShape.plus),
                  semanticLabel: 'Add',
                  shape: shape,
                  size: size,
                  onPressed: enabled ? _noop : null,
                ),
              ),
          ],
        ),
      SpecimenSection(
        title: 'Help and Link',
        children: [
          ..._states(
            'Help',
            (enabled) => AmalfiHelpButton(onPressed: enabled ? _noop : null),
          ),
          ..._states(
            'Link',
            (enabled) => AmalfiLinkButton(
              label: 'Learn more',
              onPressed: enabled ? _noop : null,
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Toolbar',
        children: [
          for (final label in [null, 'Label'])
            ..._states(
              label == null ? 'Icon' : 'Icon + Label',
              (enabled) => AmalfiToolbarButton(
                icon: const AmalfiGlyph(AmalfiGlyphShape.plus),
                label: label,
                semanticLabel: 'Add',
                onPressed: enabled ? _noop : null,
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Gradient · Add Remove',
        note: 'Each half is a button of its own: previews show both halves.',
        children: _states(
          'Add Remove',
          (enabled) => AmalfiGradientButtons(
            onAdd: enabled ? _noop : null,
            onRemove: enabled ? _noop : null,
          ),
        ),
      ),
      for (final kind in ['Pop-up', 'Pull-down'])
        SpecimenSection(
          title: kind,
          children: [
            for (final MapEntry(key: s, value: size) in _sizes.entries)
              ..._states(
                s,
                (enabled) => kind == 'Pop-up'
                    ? _Fruit(size: size, enabled: enabled)
                    : AmalfiPullDownButton(
                        label: 'Actions',
                        size: size,
                        items: [
                          for (final l in [
                            'New window',
                            'Duplicate',
                            'Rename',
                            'Delete',
                          ])
                            AmalfiPullDownItem(
                              label: l,
                              onSelected: enabled ? _noop : null,
                            ),
                        ],
                      ),
              ),
          ],
        ),
      const SpecimenSection(
        title: 'Live',
        note:
            'Hover, press, Tab to a button and press Space or Return; open the menus.',
        children: [
          Specimen(
            label: 'Primary',
            child: AmalfiPushButton(
              label: 'Save',
              variant: AmalfiPushButtonVariant.primary,
              onPressed: _noop,
            ),
          ),
          Specimen(
            label: 'Secondary',
            child: AmalfiPushButton(label: 'Cancel', onPressed: _noop),
          ),
          Specimen(
            label: 'Glass',
            child: AmalfiPushButton(
              label: 'Share',
              variant: AmalfiPushButtonVariant.glass,
              onPressed: _noop,
            ),
          ),
          Specimen(
            label: 'Pop-up',
            child: _Fruit(size: AmalfiControlSize.regular, enabled: true),
          ),
        ],
      ),
    ],
  );
}

/// A pop-up button that keeps its choice.
class _Fruit extends StatefulWidget {
  const _Fruit({required this.size, required this.enabled});

  final AmalfiControlSize size;
  final bool enabled;

  @override
  State<_Fruit> createState() => _FruitState();
}

class _FruitState extends State<_Fruit> {
  String _value = 'Lemon';

  @override
  Widget build(BuildContext context) => AmalfiPopUpButton<String>(
    items: const [
      AmalfiPopUpItem(value: 'Orange', label: 'Orange'),
      AmalfiPopUpItem(value: 'Lemon', label: 'Lemon'),
      AmalfiPopUpItem(value: 'Olive', label: 'Olive'),
      AmalfiPopUpItem(value: 'Fig', label: 'Fig'),
    ],
    value: _value,
    size: widget.size,
    onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
  );
}
