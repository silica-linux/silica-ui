// Gallery page: scroll bars (kit `Scrollbars/*`). The bars in every state, the corner, then
// live scroll areas: scroll one, or move the pointer over its bars.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The scroll bars page.
final AmalfiGalleryPage scrollbarsPage = AmalfiGalleryPage(
  family: 'scrollbars',
  title: 'Scrollbars',
  build: (context) => const _ScrollbarsPage(),
);

class _ScrollbarsPage extends StatelessWidget {
  const _ScrollbarsPage();

  static Widget _bar(
    Axis axis, {
    AmalfiScrollbarStyle style = AmalfiScrollbarStyle.overlay,
    double expansion = 0,
    bool hovered = false,
    bool dragging = false,
    bool enabled = true,
  }) {
    final vertical = axis == Axis.vertical;
    final legacy = style == AmalfiScrollbarStyle.legacy;
    return SizedBox(
      width: vertical ? null : (legacy ? 248 : 252),
      height: vertical ? (legacy ? 164 : 168) : null,
      child: AmalfiScrollbarTrack(
        axis: axis,
        style: style,
        expansion: expansion,
        hovered: hovered,
        dragging: dragging,
        thumbOffset: vertical ? 16 : 20,
        thumbExtent: vertical ? 64 : 88,
        enabled: enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (axisName, axis) in const [
        ('Vertical', Axis.vertical),
        ('Horizontal', Axis.horizontal),
      ]) ...[
        SpecimenSection(
          title: 'Overlay · $axisName',
          children: [
            Specimen(label: 'Thin', child: _bar(axis)),
            Specimen(label: 'Expanded', child: _bar(axis, expansion: 1)),
            Specimen(
              label: 'Dragging',
              child: _bar(axis, expansion: 1, dragging: true),
            ),
          ],
        ),
        SpecimenSection(
          title: 'Legacy · $axisName',
          children: [
            Specimen(
              label: 'Rest',
              child: _bar(axis, style: AmalfiScrollbarStyle.legacy),
            ),
            Specimen(
              label: 'Hover',
              child: _bar(
                axis,
                style: AmalfiScrollbarStyle.legacy,
                hovered: true,
              ),
            ),
            Specimen(
              label: 'Disabled',
              child: _bar(
                axis,
                style: AmalfiScrollbarStyle.legacy,
                enabled: false,
              ),
            ),
          ],
        ),
      ],
      const SpecimenSection(
        title: 'Corner',
        children: [Specimen(label: 'Rest', child: AmalfiScrollbarCorner())],
      ),
      const SpecimenSection(
        title: 'Area',
        note:
            'Scroll an area: overlay bars show while scrolling and expand under the '
            'pointer; legacy bars stay.',
        children: [
          Specimen(
            label: 'Overlay',
            child: _Area(style: AmalfiScrollbarStyle.overlay),
          ),
          Specimen(
            label: 'Legacy',
            child: _Area(style: AmalfiScrollbarStyle.legacy),
          ),
        ],
      ),
    ],
  );
}

/// A 264 × 180 raised area scrolling rows of placeholder lines both ways.
class _Area extends StatelessWidget {
  const _Area({required this.style});

  final AmalfiScrollbarStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    const shape = AmalfiSmoothBorder(radius: 12);
    return SizedBox(
      width: 264,
      height: 180,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: shape.copyWith(
            side: BorderSide(
              color: colors.lineBorder,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: shape),
          child: ColoredBox(
            color: colors.surfaceRaised,
            child: AmalfiScrollArea(
              style: style,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 24; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: 200.0 + (i * 37) % 280,
                          height: i.isEven ? 4 : 8,
                          decoration: ShapeDecoration(
                            color: colors.lineBorder,
                            shape: const AmalfiSmoothBorder(radius: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
