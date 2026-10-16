// Gallery page: wells (kit `Wells/*`). Image wells empty and filled in every size and state,
// colour wells in every style and state, the colour panel and the swatches. The states
// that need a pointer or the focus are shown through a WidgetStatesController; the live
// specimens at the end take drops, clicks and the keyboard.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The wells page.
final AmalfiGalleryPage wellsPage = AmalfiGalleryPage(
  family: 'wells',
  title: 'Wells',
  build: (context) => const _WellsPage(),
);

class _WellsPage extends StatelessWidget {
  const _WellsPage();

  static const _imageSizes = {
    'Small': AmalfiImageWellSize.small,
    'Regular': AmalfiImageWellSize.regular,
    'Large': AmalfiImageWellSize.large,
  };

  static const _styles = {
    'Minimal': AmalfiColorWellStyle.minimal,
    'Default': AmalfiColorWellStyle.standard,
    'Expanded': AmalfiColorWellStyle.expanded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: name, value: size) in _imageSizes.entries)
          SpecimenSection(
            title: 'Image Well · $name',
            children: [
              Specimen(
                label: 'Empty · Rest',
                child: AmalfiImageWell(size: size, onDrop: (_) {}),
              ),
              Specimen(
                label: 'Empty · Drag Over',
                child: _Forced(
                  states: const {WidgetState.selected},
                  builder: (s) => AmalfiImageWell(
                    size: size,
                    onDrop: (_) {},
                    statesController: s,
                  ),
                ),
              ),
              Specimen(
                label: 'Empty · Disabled',
                child: AmalfiImageWell(size: size, enabled: false),
              ),
              Specimen(
                label: 'Filled · Rest',
                child: AmalfiImageWell(size: size, image: const _Picture()),
              ),
              Specimen(
                label: 'Filled · Focused',
                child: _Forced(
                  states: const {WidgetState.focused},
                  builder: (s) => AmalfiImageWell(
                    size: size,
                    image: const _Picture(),
                    statesController: s,
                  ),
                ),
              ),
              Specimen(
                label: 'Filled · Disabled',
                child: AmalfiImageWell(
                  size: size,
                  image: const _Picture(),
                  enabled: false,
                ),
              ),
            ],
          ),
        for (final MapEntry(key: name, value: style) in _styles.entries)
          SpecimenSection(
            title: 'Color Well · $name',
            children: [
              for (final (label, states) in const [
                ('Rest', <WidgetState>{}),
                ('Hover', {WidgetState.hovered}),
                ('Focused', {WidgetState.focused}),
              ])
                Specimen(
                  label: label,
                  child: _Forced(
                    states: states,
                    builder: (s) => _LiveColorWell(
                      style: style,
                      initial: colors.accentAmalfi,
                      statesController: s,
                    ),
                  ),
                ),
              Specimen(
                label: 'Disabled',
                child: AmalfiColorWell(
                  style: style,
                  color: colors.accentAmalfi,
                  name: 'Amalfi blue',
                  enabled: false,
                  onChanged: (_) {},
                  onPickFromScreen: () {},
                ),
              ),
            ],
          ),
        SpecimenSection(
          title: 'Color Panel',
          children: [
            Specimen(
              label: 'Swatch Grid',
              child: _LivePanel(initial: colors.accentAmalfi),
            ),
          ],
        ),
        SpecimenSection(
          title: 'Swatches',
          children: [
            Specimen(
              label: 'Chip · Rest',
              child: AmalfiSwatchChip(color: colors.accentAmalfi),
            ),
            Specimen(
              label: 'Chip · Selected',
              child: AmalfiSwatchChip(
                color: colors.accentAmalfi,
                selected: true,
              ),
            ),
            for (final (i, row) in AmalfiColorPanel.amalfiSwatches(
              colors,
            ).indexed)
              Specimen(
                label: 'Row ${i + 1}',
                child: AmalfiSwatchRow(
                  colors: row,
                  selected: i == 0 ? colors.accentAmalfi : null,
                ),
              ),
          ],
        ),
        SpecimenSection(
          title: 'Live',
          note:
              'Drag the swatch onto the well to fill it; click the filled well and press '
              'Delete to empty it.',
          children: [
            const Specimen(label: 'Drop target', child: _LiveImageWell()),
            Specimen(
              label: 'Drag me',
              child: Draggable<Object>(
                data: 'picture',
                feedback: AmalfiTheme(
                  brightness: AmalfiTheme.of(context).brightness,
                  child: AmalfiSwatchChip(color: colors.paletteLimone),
                ),
                child: AmalfiSwatchChip(color: colors.paletteLimone),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Builds a specimen with a states controller that starts with [states].
class _Forced extends StatefulWidget {
  const _Forced({required this.states, required this.builder});

  final Set<WidgetState> states;
  final Widget Function(WidgetStatesController states) builder;

  @override
  State<_Forced> createState() => _ForcedState();
}

class _ForcedState extends State<_Forced> {
  late final WidgetStatesController _states = WidgetStatesController({
    ...widget.states,
  });

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_states);
}

/// The kit's test picture: sky, sun, sea and a hill.
class _Picture extends StatelessWidget {
  const _Picture();

  @override
  Widget build(BuildContext context) {
    final c = AmalfiTheme.of(context).colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.biggest.shortestSide / 120;
        Widget at(
          double x,
          double y,
          double w,
          double h,
          Color color,
          double r,
        ) => Positioned(
          left: x * s,
          top: y * s,
          width: w * s,
          height: h * s,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: AmalfiSmoothBorder(radius: r * s),
            ),
          ),
        );
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.paletteLimone)),
            at(64, 24, 28, 28, c.paletteTerracotta, 14),
            at(0, 76, 120, 44, c.accentAmalfi, 0),
            at(16, 60, 48, 16, c.paletteUlivo, 8),
          ],
        );
      },
    );
  }
}

class _LiveColorWell extends StatefulWidget {
  const _LiveColorWell({
    required this.style,
    required this.initial,
    required this.statesController,
  });

  final AmalfiColorWellStyle style;
  final Color initial;
  final WidgetStatesController statesController;

  @override
  State<_LiveColorWell> createState() => _LiveColorWellState();
}

class _LiveColorWellState extends State<_LiveColorWell> {
  late Color _color = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiColorWell(
    style: widget.style,
    color: _color,
    name: _color == widget.initial ? 'Amalfi blue' : 'Custom colour',
    onChanged: (c) => setState(() => _color = c),
    // The gallery cannot sample the screen: picking resets to the accent instead.
    onPickFromScreen: () => setState(() => _color = widget.initial),
    statesController: widget.statesController,
  );
}

class _LivePanel extends StatefulWidget {
  const _LivePanel({required this.initial});

  final Color initial;

  @override
  State<_LivePanel> createState() => _LivePanelState();
}

class _LivePanelState extends State<_LivePanel> {
  late Color _selected = widget.initial;

  @override
  Widget build(BuildContext context) => AmalfiColorPanel(
    selected: _selected,
    onSelected: (c) => setState(() => _selected = c),
  );
}

class _LiveImageWell extends StatefulWidget {
  const _LiveImageWell();

  @override
  State<_LiveImageWell> createState() => _LiveImageWellState();
}

class _LiveImageWellState extends State<_LiveImageWell> {
  bool _filled = false;

  @override
  Widget build(BuildContext context) => AmalfiImageWell(
    image: _filled ? const _Picture() : null,
    semanticLabel: 'Picture',
    onDrop: (_) => setState(() => _filled = true),
    onPressed: () {},
    onCleared: () => setState(() => _filled = false),
  );
}
