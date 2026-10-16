// The Amalfi gallery: one page per component family (`pages/`), each showing every variant ×
// size × state of the family, in light or dark (the switch at the top). Reached from the
// catalog's sidebar.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'pages.dart';
import 'specimen.dart';

/// The gallery; it needs an `Overlay` above it. [inset] pads the scrolling content.
class AmalfiGallery extends StatefulWidget {
  const AmalfiGallery({
    super.key,
    this.inset = EdgeInsets.zero,
    this.initialFamily = 'tooltips',
    this.initialBrightness = Brightness.light,
  });

  final EdgeInsets inset;
  final String initialFamily;
  final Brightness initialBrightness;

  @override
  State<AmalfiGallery> createState() => _AmalfiGalleryState();
}

class _AmalfiGalleryState extends State<AmalfiGallery> {
  late String _family = widget.initialFamily;
  late Brightness _brightness = widget.initialBrightness;

  AmalfiGalleryPage get _page => amalfiGalleryPages.firstWhere(
    (p) => p.family == _family,
    orElse: () => amalfiGalleryPages.first,
  );

  @override
  Widget build(BuildContext context) => AmalfiTheme(
    brightness: _brightness,
    child: Builder(
      builder: (context) {
        final colors = AmalfiTheme.of(context).colors;
        return ColoredBox(
          color: colors.surfaceWindow,
          child: SingleChildScrollView(
            padding: widget.inset.add(
              const EdgeInsets.all(AmalfiSpacing.paddingDocumentAndSettings),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Amalfi · ${_page.title}',
                        style: AmalfiType.title2(color: colors.textPrimary),
                      ),
                    ),
                    PopUpButton<String>(
                      width: 200,
                      items: [
                        for (final p in amalfiGalleryPages)
                          PopUpItem(p.family, p.title),
                      ],
                      value: _page.family,
                      onChanged: (f) => setState(() => _family = f),
                    ),
                    const SizedBox(width: AmalfiSpacing.m),
                    SegmentedControl(
                      segments: const [
                        Segment(label: 'Light'),
                        Segment(label: 'Dark'),
                      ],
                      selected: {_brightness == Brightness.dark ? 1 : 0},
                      onChanged: (i) => setState(
                        () => _brightness = i == 1
                            ? Brightness.dark
                            : Brightness.light,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmalfiSpacing.xxl),
                KeyedSubtree(
                  key: ValueKey(_page.family),
                  child: _page.build(context),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
