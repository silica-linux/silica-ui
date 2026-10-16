// Gallery page: segmented controls (kit `Segments/*`): action segments, the Align group,
// select-one and select-any controls and their items, every variant × size × state. Hover
// and press the live ones: hover, pressed and the lens are real pointer states.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The segmented controls page.
final AmalfiGalleryPage segmentedPage = AmalfiGalleryPage(
  family: 'segmented',
  title: 'Segmented controls',
  build: (context) => const _SegmentedPage(),
);

const _sizes = [
  ('Mini', AmalfiControlSize.mini),
  ('Small', AmalfiControlSize.small),
  ('Regular', AmalfiControlSize.regular),
  ('Large', AmalfiControlSize.large),
];

/// An Icon Kit symbol from the installed silica-icons, or [fallback] (one of the built-in
/// control glyphs) when it is missing. Size and colour come from the segment.
Widget _symbol(String name, AmalfiGlyphData fallback) =>
    AmalfiSymbol(name, fallback: AmalfiGlyph(fallback));

/// The kit's glyphs of each action capsule (`Segments/Action/Icon n`).
final _actionGlyphs = <int, List<Widget>>{
  2: const [
    AmalfiGlyph(AmalfiGlyphs.chevronLeft),
    AmalfiGlyph(AmalfiGlyphs.chevronRight),
  ],
  3: [
    _symbol('reply', AmalfiGlyphs.chevronLeft),
    _symbol('reply-all', AmalfiGlyphs.chevronLeft),
    _symbol('forward', AmalfiGlyphs.chevronRight),
  ],
  4: [
    const AmalfiGlyph(AmalfiGlyphs.plus),
    const AmalfiGlyph(AmalfiGlyphs.tag),
    const AmalfiGlyph(AmalfiGlyphs.star),
    _symbol('flag', AmalfiGlyphs.warning),
  ],
  5: [
    const AmalfiGlyph(AmalfiGlyphs.plus),
    const AmalfiGlyph(AmalfiGlyphs.tag),
    const AmalfiGlyph(AmalfiGlyphs.star),
    _symbol('flag', AmalfiGlyphs.warning),
    const AmalfiGlyph(AmalfiGlyphs.share),
  ],
};

const _texts = {
  2: ['Back', 'Next'],
  3: ['Day', 'Week', 'Month'],
};

List<AmalfiSegment> _actionSegments(
  int count, {
  required bool text,
  bool lastDisabled = false,
}) => [
  for (var i = 0; i < count; i++)
    text
        ? AmalfiSegment.text(
            _texts[count]?[i] ?? 'Item',
            enabled: !(lastDisabled && i == count - 1),
          )
        : AmalfiSegment.icon(
            _actionGlyphs[count]?[i] ?? const AmalfiGlyph(AmalfiGlyphs.plus),
            semanticLabel: 'Action ${i + 1}',
            tooltip: 'Action ${i + 1}',
            enabled: !(lastDisabled && i == count - 1),
          ),
];

const _itemWords = ['One', 'Two', 'Three', 'Four', 'Five'];
const _itemGlyphs = [
  AmalfiGlyph(AmalfiGlyphs.sidebar),
  AmalfiGlyph(AmalfiGlyphs.listBullet),
  AmalfiGlyph(AmalfiGlyphs.squareGrid2x2),
  AmalfiGlyph(AmalfiGlyphs.photo),
  AmalfiGlyph(AmalfiGlyphs.doc),
];

List<AmalfiSegment> _items(int count, {required bool text}) => [
  for (var i = 0; i < count; i++)
    text
        ? AmalfiSegment.text(_itemWords[i])
        : AmalfiSegment.icon(_itemGlyphs[i], semanticLabel: _itemWords[i]),
];

class _SegmentedPage extends StatelessWidget {
  const _SegmentedPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final variant in [
        ('Icon', 2),
        ('Icon', 3),
        ('Icon', 4),
        ('Icon', 5),
        ('Text', 2),
        ('Text', 3),
      ])
        SpecimenSection(
          title: 'Action segments · ${variant.$1} ${variant.$2}',
          note:
              'Hover and press a segment. Disabled: the whole capsule at 35 %; '
              'Last disabled: one segment.',
          children: [
            for (final (name, size) in _sizes)
              for (final state in [
                'Rest',
                'Disabled',
                'Last disabled',
                'Inactive',
              ])
                Specimen(
                  label: '$name · $state',
                  child: AmalfiActionSegments(
                    size: size,
                    active: state != 'Inactive',
                    segments: _actionSegments(
                      variant.$2,
                      text: variant.$1 == 'Text',
                      lastDisabled: state == 'Last disabled',
                    ),
                    onPressed: state == 'Disabled' ? null : (_) {},
                  ),
                ),
          ],
        ),
      const SpecimenSection(
        title: 'Align',
        note: 'A toolbar selection group: click an alignment.',
        children: [Specimen(label: 'Small', child: _AlignGroup())],
      ),
      for (final selection in AmalfiSegmentedSelection.values)
        for (final text in [true, false])
          SpecimenSection(
            title:
                'Control · ${selection == AmalfiSegmentedSelection.one ? 'One' : 'Any'} · '
                '${text ? 'Text' : 'Icon'}',
            note: selection == AmalfiSegmentedSelection.one
                ? 'Press and drag: the lens follows the pointer and chooses on release. '
                      'Disabled: the selection stays, the control at 35 %.'
                : 'Each item turns on and off (a flat press, no lens).',
            children: [
              for (final count in [2, 3, 4, 5])
                for (final (name, size) in _sizes) ...[
                  Specimen(
                    label: '$count · $name',
                    child: _LiveControl(
                      count: count,
                      text: text,
                      size: size,
                      selection: selection,
                    ),
                  ),
                  if (size != AmalfiControlSize.mini)
                    Specimen(
                      label: '$count · $name · Disabled',
                      child: AmalfiSegmentedControl(
                        segments: _items(count, text: text),
                        selected: const {0},
                        selection: selection,
                        size: size,
                      ),
                    ),
                ],
            ],
          ),
      for (final text in [true, false])
        SpecimenSection(
          title: text ? 'Text Item' : 'Icon Item',
          children: [
            for (final (name, size) in _sizes)
              for (final state in ['Rest', 'Hover', 'Selected', 'Disabled'])
                Specimen(
                  label: '$name · $state',
                  child: AmalfiSegmentItem(
                    segment: text
                        ? const AmalfiSegment.text('Item')
                        : const AmalfiSegment.icon(
                            AmalfiGlyph(AmalfiGlyphs.sidebar),
                            semanticLabel: 'Sidebar',
                          ),
                    size: size,
                    hovered: state == 'Hover',
                    selected: state == 'Selected',
                    enabled: state != 'Disabled',
                  ),
                ),
          ],
        ),
    ],
  );
}

class _AlignGroup extends StatefulWidget {
  const _AlignGroup();

  @override
  State<_AlignGroup> createState() => _AlignGroupState();
}

class _AlignGroupState extends State<_AlignGroup> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => AmalfiActionSegments(
    size: AmalfiControlSize.small,
    selected: {_selected},
    segments: [
      for (final (symbol, name) in [
        ('text-align-left', 'Left'),
        ('text-align-center', 'Centre'),
        ('text-align-right', 'Right'),
        ('text-justify', 'Justify'),
      ])
        AmalfiSegment.icon(
          _symbol(symbol, AmalfiGlyphs.listBullet),
          semanticLabel: name,
          tooltip: name,
        ),
    ],
    onPressed: (i) => setState(() => _selected = i),
  );
}

class _LiveControl extends StatefulWidget {
  const _LiveControl({
    required this.count,
    required this.text,
    required this.size,
    required this.selection,
  });

  final int count;
  final bool text;
  final AmalfiControlSize size;
  final AmalfiSegmentedSelection selection;

  @override
  State<_LiveControl> createState() => _LiveControlState();
}

class _LiveControlState extends State<_LiveControl> {
  late Set<int> _selected = widget.selection == AmalfiSegmentedSelection.one
      ? {0}
      : {0, 2};

  @override
  Widget build(BuildContext context) => Padding(
    // Room for the lens above and below (12 beyond the items, 4 inside the track).
    padding: const EdgeInsets.symmetric(
      vertical: AmalfiLens.rise - AmalfiSegmentMetrics.trackPadding,
    ),
    child: AmalfiSegmentedControl(
      segments: _items(widget.count, text: widget.text),
      selected: _selected,
      selection: widget.selection,
      size: widget.size,
      onChanged: (s) => setState(() => _selected = s),
    ),
  );
}
