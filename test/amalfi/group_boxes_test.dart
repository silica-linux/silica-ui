// Group boxes against the kit (`Group Boxes/Box/*`). Checklist:
// docs/amalfi-checklist/group_boxes.md.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'toggles_support.dart';

const appearances = ['Light', 'Dark'];

/// Stands in for `Fields/Text Field/Regular/Filled` (the fields family), masked in the
/// pixels.
const Widget field = SizedBox(key: ValueKey('field'), width: 200, height: 28);

Widget checkbox(String label, {bool value = true, bool enabled = true}) =>
    AmalfiCheckbox(
      key: ValueKey(label),
      value: value,
      label: label,
      onChanged: enabled ? (_) {} : null,
    );

/// The untitled box of `Group Boxes/Box/Untitled` (224 wide, as its instance in Nested).
Widget untitled() => SizedBox(
  key: const ValueKey('untitled'),
  width: 224,
  child: AmalfiGroupBox(children: [field, checkbox('Remember this name')]),
);

/// The labels of the kit's checkbox rows in [name] ([rows]), to the box's right edge: the
/// kit's text overflows its (stale) frames, which the text mask would leave out.
List<Rect> labels(String name, List<String> rows) {
  final master = KitMaster.load(name);
  final surface = master.layer('Box/Surface').rectInMaster;
  return [
    for (final row in rows)
      () {
        final r = master.layer(row).rectInMaster;
        return Rect.fromLTRB(r.left + 28, r.top, surface.right, r.bottom);
      }(),
  ];
}

Finder box(Finder root) => layerOf(root, AmalfiLayerKeys.body).first;

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in appearances) {
    for (final state in ['Rest', 'Disabled']) {
      final name = 'Group Boxes/Box/Titled/$state/$appearance';
      testWidgets(name, (tester) async {
        final enabled = state == 'Rest';
        // Kit defect: the rows keep the width of an earlier label (168), wider than the
        // box's content (160): "Show on lock screen" (168, as the code) overflows the box
        // and "Show banners" and "Play sound" are wider than their labels. The code sizes
        // rows to their labels and fits them in the box (the long label is cut).
        const rows = 'kit rows keep stale widths and overflow the box';
        await checkKit(
          tester,
          name,
          SizedBox(
            width: 184,
            child: AmalfiGroupBox(
              title: 'Notifications',
              enabled: enabled,
              children: [
                checkbox('Show banners', enabled: enabled),
                checkbox('Play sound', enabled: enabled),
                checkbox('Show on lock screen', value: false, enabled: enabled),
              ],
            ),
          ),
          layers: (root) => {
            'Title': find.byKey(AmalfiLayerKeys.label).first,
            'Box': box(root),
            'Box/Surface': box(root),
            'Box/Show banners': find.byKey(const ValueKey('Show banners')),
            'Box/Play sound': find.byKey(const ValueKey('Play sound')),
            'Box/Lock screen': find.byKey(
              const ValueKey('Show on lock screen'),
            ),
          },
          deviations: {
            'Title':
                'kit fixed-width title frame 88 for "Notifications" (84 on the grid)',
            'Box/Show banners': rows,
            'Box/Play sound': rows,
            'Box/Lock screen': rows,
          },
          mask: labels(name, [
            'Box/Show banners',
            'Box/Play sound',
            'Box/Lock screen',
          ]),
        );
      });
    }

    testWidgets('Group Boxes/Box/Untitled/Rest/$appearance', (tester) async {
      await checkKit(
        tester,
        'Group Boxes/Box/Untitled/Rest/$appearance',
        untitled(),
        layers: (root) => {
          'Box': box(root),
          'Box/Surface': box(root),
          'Box/Name': find.byKey(const ValueKey('field')),
          'Box/Remember': find.byKey(const ValueKey('Remember this name')),
        },
        deviations: {
          'Box/Remember':
              'kit row keeps a stale width (168), the code fits the label',
        },
        maskLayers: ['Box/Name'],
        mask: labels('Group Boxes/Box/Untitled/Rest/$appearance', [
          'Box/Remember',
        ]),
      );
    });

    testWidgets('Group Boxes/Box/Nested/Rest/$appearance', (tester) async {
      await checkKit(
        tester,
        'Group Boxes/Box/Nested/Rest/$appearance',
        SizedBox(
          width: 280,
          child: AmalfiGroupBox(
            title: 'Recipe sharing',
            children: [
              AmalfiSwitch(
                key: const ValueKey('sync'),
                value: true,
                label: 'Enable sync',
                onChanged: (_) {},
              ),
              untitled(),
            ],
          ),
        ),
        layers: (root) => {
          'Title': find.byKey(AmalfiLayerKeys.label).first,
          'Box': box(root),
          'Box/Surface': box(root),
          'Box/Enable': find.byKey(const ValueKey('sync')),
          'Box/Inner box': find.byKey(const ValueKey('untitled')),
        },
        // The nested switch's thumb (kit defect, see toggles_test.dart) and the field.
        mask: const [
          Rect.fromLTWH(12 + 204, 24 + 12 + 4, 40, 24),
          Rect.fromLTWH(24, 24 + 52 + 12, 200, 28),
          // The inner box's checkbox label (see Untitled).
          Rect.fromLTWH(24 + 28, 24 + 52 + 48, 236 - 52, 20),
        ],
      );
    });
  }

  testWidgets('an unbounded box hugs its widest child', (tester) async {
    await pumpKitScene(
      tester,
      UnconstrainedBox(
        child: AmalfiGroupBox(
          children: [
            const SizedBox(width: 100, height: 20),
            const SizedBox(width: 60, height: 20),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(AmalfiLayerKeys.body)),
      const Size(124, 72),
    );
  });
}
