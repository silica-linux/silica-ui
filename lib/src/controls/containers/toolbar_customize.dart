// The customize-toolbar sheet (CT-TL-02, MU-06), shown with [showWindowSheet] in the attached
// style: a palette of items 100 × 68 (38 pt icon and a label on up to 2 lines), 8 per row at a
// 78 pt row pitch, items already in the bar dimmed; then the default set on a rounded strip
// (1002 × 67) to drag as a whole; at the bottom "Show" with its pop-up (icons and text, icons
// only, text only) and the accent "Done" button (74 × 26). Items are dragged into the bar (the
// app's toolbar accepts [ToolbarItemDrag]); the sheet is 1066 × 500 with a 1000 pt window.

import 'package:flutter/widgets.dart';

import 'common.dart';

/// How the bar shows its items.
enum ToolbarDisplay { iconsAndText, iconsOnly, textOnly }

/// An item the bar can hold.
@immutable
class ToolbarItemSpec {
  const ToolbarItemSpec({required this.id, required this.label, this.icon});

  final String id;
  final String label;

  /// The glyph, drawn in the color it receives.
  final Widget Function(Color color)? icon;
}

/// The data of a drag from the palette: one item, or the whole default set.
@immutable
class ToolbarItemDrag {
  const ToolbarItemDrag(this.items, {this.defaults = false});
  final List<ToolbarItemSpec> items;
  final bool defaults;
}

abstract final class ToolbarCustomizeMetrics {
  static const Size sheet = Size(1066, 500);
  static const Size item = Size(100, 68);
  static const int perRow = 8;
  static const double rowPitch = 78;
  static const double icon = 38;
  static const Size defaults = Size(1002, 67);
  static const Size done = Size(74, 26);
  static const Size show = Size(129, 26);
  static const double dimmed = 0.35;
}

/// The texts of the sheet, localized by the app.
@immutable
class ToolbarCustomizeLabels {
  const ToolbarCustomizeLabels({
    this.intro = 'Drag your favorite items into the toolbar…',
    this.defaults = '…or drag the default set into the toolbar.',
    this.show = 'Show',
    this.done = 'Done',
    this.iconsAndText = 'Icon and Text',
    this.iconsOnly = 'Icon Only',
    this.textOnly = 'Text Only',
  });

  final String intro;
  final String defaults;
  final String show;
  final String done;
  final String iconsAndText;
  final String iconsOnly;
  final String textOnly;

  String display(ToolbarDisplay d) => switch (d) {
    ToolbarDisplay.iconsAndText => iconsAndText,
    ToolbarDisplay.iconsOnly => iconsOnly,
    ToolbarDisplay.textOnly => textOnly,
  };
}

/// The content of the sheet.
class ToolbarCustomizeSheet extends StatelessWidget {
  const ToolbarCustomizeSheet({
    super.key,
    required this.available,
    required this.defaults,
    required this.inBar,
    required this.display,
    required this.onDisplay,
    required this.onDone,
    this.labels = const ToolbarCustomizeLabels(),
  });

  final List<ToolbarItemSpec> available;
  final List<ToolbarItemSpec> defaults;

  /// The ids already in the bar: dimmed in the palette.
  final Set<String> inBar;
  final ToolbarDisplay display;
  final ValueChanged<ToolbarDisplay> onDisplay;
  final VoidCallback onDone;
  final ToolbarCustomizeLabels labels;

  @override
  Widget build(BuildContext context) {
    final dark = containerDark(context);
    final text = dark ? const Color(0xFFE6E6E6) : const Color(0xFF262626);
    final glyph = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final strip = dark ? const Color(0x14FFFFFF) : const Color(0x0D000000);
    return SizedBox(
      key: const ValueKey('toolbar customize'),
      width: ToolbarCustomizeMetrics.sheet.width,
      height: ToolbarCustomizeMetrics.sheet.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.intro, style: containerText(13, text)),
            const SizedBox(height: 12),
            Expanded(
              child: Wrap(
                runSpacing:
                    ToolbarCustomizeMetrics.rowPitch -
                    ToolbarCustomizeMetrics.item.height,
                spacing:
                    (ToolbarCustomizeMetrics.defaults.width -
                        ToolbarCustomizeMetrics.perRow *
                            ToolbarCustomizeMetrics.item.width) /
                    (ToolbarCustomizeMetrics.perRow - 1),
                children: [
                  for (final item in available)
                    Draggable<ToolbarItemDrag>(
                      key: ValueKey('palette ${item.id}'),
                      data: ToolbarItemDrag([item]),
                      feedback: _DragCircle(item: item, color: glyph),
                      child: Opacity(
                        opacity: inBar.contains(item.id)
                            ? ToolbarCustomizeMetrics.dimmed
                            : 1,
                        child: _PaletteItem(
                          item: item,
                          text: text,
                          glyph: glyph,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(labels.defaults, style: containerText(13, text)),
            const SizedBox(height: 8),
            Draggable<ToolbarItemDrag>(
              key: const ValueKey('palette defaults'),
              data: ToolbarItemDrag(defaults, defaults: true),
              feedback: const SizedBox(),
              child: Container(
                width: ToolbarCustomizeMetrics.defaults.width,
                height: ToolbarCustomizeMetrics.defaults.height,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: strip,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    for (final item in defaults)
                      SizedBox(
                        width: 64,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 22,
                            child: item.icon?.call(glyph),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${labels.show}:', style: containerText(13, text)),
                const SizedBox(width: 8),
                _DisplayChoice(
                  value: display,
                  labels: labels,
                  onChanged: onDisplay,
                  text: text,
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: labels.done,
                  child: GestureDetector(
                    key: const ValueKey('toolbar customize done'),
                    onTap: onDone,
                    child: Container(
                      width: ToolbarCustomizeMetrics.done.width,
                      height: ToolbarCustomizeMetrics.done.height,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        labels.done,
                        style: containerText(13, const Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({
    required this.item,
    required this.text,
    required this.glyph,
  });
  final ToolbarItemSpec item;
  final Color text;
  final Color glyph;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ToolbarCustomizeMetrics.item.width,
    height: ToolbarCustomizeMetrics.item.height,
    child: Column(
      children: [
        SizedBox.square(
          dimension: ToolbarCustomizeMetrics.icon,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: item.icon?.call(glyph),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: containerText(10, text).copyWith(height: 1.2),
        ),
      ],
    ),
  );
}

/// The dragged item: a circle with a shadow (MU-06).
class _DragCircle extends StatelessWidget {
  const _DragCircle({required this.item, required this.color});
  final ToolbarItemSpec item;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFF8F8F8),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: SizedBox.square(dimension: 20, child: item.icon?.call(color)),
  );
}

/// The "Show" choice: a pop-up that cycles through the three modes on click, with ↑ ↓.
/// *Simplified: the full pop-up button is a separate control.*
class _DisplayChoice extends StatelessWidget {
  const _DisplayChoice({
    required this.value,
    required this.labels,
    required this.onChanged,
    required this.text,
  });
  final ToolbarDisplay value;
  final ToolbarCustomizeLabels labels;
  final ValueChanged<ToolbarDisplay> onChanged;
  final Color text;

  @override
  Widget build(BuildContext context) {
    final dark = containerDark(context);
    return Semantics(
      button: true,
      value: labels.display(value),
      label: labels.show,
      child: GestureDetector(
        key: const ValueKey('toolbar customize show'),
        onTap: () => onChanged(
          ToolbarDisplay.values[(value.index + 1) %
              ToolbarDisplay.values.length],
        ),
        child: Container(
          width: ToolbarCustomizeMetrics.show.width,
          height: ToolbarCustomizeMetrics.show.height,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF555556) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: dark ? const Color(0x33FFFFFF) : const Color(0x26000000),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labels.display(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: containerText(13, text),
                ),
              ),
              SizedBox(
                width: 7,
                height: 4,
                child: CustomPaint(
                  painter: ChevronPainter(
                    ChevronDirection.down,
                    text,
                    stroke: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
