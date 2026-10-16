// Gallery page: popovers (kit `Popovers/*`). The three contents, every arrow edge and
// position and the detached popover, and buttons that show a popover next to themselves.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The popovers page.
final AmalfiGalleryPage popoversPage = AmalfiGalleryPage(
  family: 'popovers',
  title: 'Popovers',
  build: (context) => const _PopoversPage(),
);

/// The form's name field, filled as in the kit.
class _NameField extends StatefulWidget {
  const _NameField();

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final _controller = TextEditingController(text: 'Amalfi coast');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AmalfiTextField(controller: _controller, width: 228);
}

void _pressed() {}

Widget _content(String variant) => switch (variant) {
  'Form' => const AmalfiPopoverForm(
    title: 'New collection',
    field: _NameField(),
    actions: [
      AmalfiPushButton(
        label: 'Cancel',
        size: AmalfiControlSize.small,
        onPressed: _pressed,
      ),
      AmalfiPushButton(
        label: 'Create',
        variant: AmalfiPushButtonVariant.primary,
        size: AmalfiControlSize.small,
        onPressed: _pressed,
      ),
    ],
  ),
  'List' => const AmalfiPopoverList(
    entries: [
      AmalfiMenuSection('Open in'),
      AmalfiMenuAction('Recents', icon: AmalfiSymbol('clock', size: 16)),
      AmalfiMenuAction(
        'Downloads',
        icon: AmalfiSymbol('arrow-down-circle', size: 16),
      ),
      AmalfiMenuAction('Pictures', icon: AmalfiSymbol('photo', size: 16)),
    ],
  ),
  _ => const AmalfiPopoverText(
    title: 'About this ingredient',
    body:
        'Olive oil keeps the crust tender and adds a peppery note. Use a mild, fruity one for sweet bakes.',
    action: AmalfiLinkButton(label: 'Learn more', onPressed: _pressed),
  ),
};

class _PopoversPage extends StatelessWidget {
  const _PopoversPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final variant in ['Form', 'List', 'Text'])
        SpecimenSection(
          title: 'Popover · $variant',
          children: [
            for (final edge in AmalfiPopoverArrowEdge.values)
              for (final alignment in AmalfiPopoverArrowAlignment.values)
                Specimen(
                  label: '${_name(edge.name)} ${_name(alignment.name)}',
                  child: AmalfiPopover(
                    arrowEdge: edge,
                    arrowAlignment: alignment,
                    padding: variant == 'List'
                        ? AmalfiPopoverMetrics.listPadding
                        : AmalfiPopoverMetrics.padding,
                    child: _content(variant),
                  ),
                ),
            Specimen(
              label: 'Detached',
              child: AmalfiPopover(
                padding: variant == 'List'
                    ? AmalfiPopoverMetrics.listPadding
                    : AmalfiPopoverMetrics.padding,
                child: _content(variant),
              ),
            ),
          ],
        ),
      SpecimenSection(
        title: 'Shown next to a control',
        note:
            'Click: the popover opens on that side (or flips); Esc or a click outside closes it.',
        children: [
          for (final placement in AmalfiPopoverPlacement.values)
            Specimen(
              label: _name(placement.name),
              child: Builder(
                builder: (context) => AmalfiPushButton(
                  label: 'Show',
                  onPressed: () {
                    final box = context.findRenderObject();
                    if (box is! RenderBox) return;
                    showAmalfiPopover(
                      context: context,
                      anchor: box.localToGlobal(Offset.zero) & box.size,
                      placement: placement,
                      builder: (_, _) => _content('Text'),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    ],
  );

  static String _name(String s) => s[0].toUpperCase() + s.substring(1);
}
