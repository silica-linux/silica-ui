// Disclosure against the kit (`Disclosure/*`): triangles, buttons, group headers and groups.
// Checklist: docs/amalfi-checklist/disclosure.md.

import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';
import 'toggles_support.dart';

const appearances = ['Light', 'Dark'];
const states = ['Rest', 'Hover', 'Pressed', 'Disabled'];
const content =
    'The content of the group sits below its header and is indented to line up with the title.';

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in appearances) {
    for (final (kind, style) in [
      ('Triangle', AmalfiDisclosureStyle.triangle),
      ('Button', AmalfiDisclosureStyle.button),
    ]) {
      for (final (variant, expanded) in [
        ('Collapsed', false),
        ('Expanded', true),
      ]) {
        for (final state in states) {
          final name = 'Disclosure/$kind/$variant/$state/$appearance';
          testWidgets(name, (tester) async {
            final kitState = KitState.parse(state);
            final glyph = switch ((kind, expanded)) {
              ('Triangle', false) => 'Glyph Chevron Right',
              ('Triangle', true) => 'Glyph Chevron Down',
              (_, false) => 'Glyph Chevron Down',
              _ => 'Glyph Chevron Up',
            };
            // Kit defect (still in 747ea80): the expanded button's chevron-up has no
            // per-size layer style and keeps the 24 pt stroke (1.5) at 12 pt; the Icon Kit
            // rule scales it to 0.75 (README).
            final thickGlyph = kind == 'Button' && expanded;
            await checkKit(
              tester,
              name,
              AmalfiDisclosure(
                expanded: expanded,
                style: style,
                onChanged: kitState.enabled ? (_) {} : null,
              ),
              state: kitState,
              layers: (root) => {
                'Background': layerOf(root, AmalfiLayerKeys.body),
                if (kind == 'Button' && kitState == KitState.hover)
                  'State': layerOf(root, AmalfiLayerKeys.state),
                glyph: layerOf(root, AmalfiLayerKeys.mark),
              },
              maskLayers: [if (thickGlyph) glyph],
              maskMargin: 0,
              tolerance: tolerance(masked: thickGlyph),
            );
          });
        }
      }
    }

    for (final (variant, expanded) in [('Closed', false), ('Open', true)]) {
      for (final state in ['Rest', 'Hover']) {
        final name = 'Disclosure/Group Header/$variant/$state/$appearance';
        testWidgets(name, (tester) async {
          final kitState = KitState.parse(state);
          await checkKit(
            tester,
            name,
            SizedBox(
              width: 280,
              child: AmalfiDisclosureGroup(
                title: 'Advanced options',
                expanded: expanded,
                onExpandedChanged: (_) {},
                child: const SizedBox.shrink(),
              ),
            ),
            state: kitState,
            target: (root) => find.descendant(
              of: root,
              matching: find.byType(AmalfiInteraction),
            ),
            layers: (root) => {
              if (kitState == KitState.hover)
                'Background': layerOf(root, AmalfiLayerKeys.body).first,
              'Title': layerOf(root, AmalfiLayerKeys.label),
              'Triangle': layerOf(root, AmalfiLayerKeys.control),
            },
            deviations: {
              // An open group's (empty) content adds its 8 pt of padding under the header.
              if (expanded)
                '#frame': 'the group, not only its header, is pumped',
            },
            pixels: !expanded,
          );
          if (expanded) {
            // The open header alone, for the pixels.
            await expectKitPixels(
              tester,
              KitMaster.load(name),
              SizedBox(
                width: 280,
                child: AmalfiDisclosureHeaderFace(
                  title: 'Advanced options',
                  expanded: true,
                  state: AmalfiInteractionState(
                    hovered: kitState == KitState.hover,
                  ),
                ),
              ),
              maskText: true,
              tolerance: smallShapes,
            );
          }
        });
      }
      final name = 'Disclosure/Group/$variant/Rest/$appearance';
      testWidgets(name, (tester) async {
        final master = KitMaster.load(name);
        final colors = AmalfiColors.of(master.brightness);
        await checkKit(
          tester,
          name,
          SizedBox(
            width: 280,
            child: AmalfiDisclosureGroup(
              title: 'Advanced options',
              expanded: expanded,
              onExpandedChanged: (_) {},
              child: Text(
                content,
                style: AmalfiType.callout(color: colors.textSecondary),
              ),
            ),
          ),
          layers: (root) => {
            'Header': find.descendant(
              of: root,
              matching: find.byType(AmalfiDisclosureHeaderFace),
            ),
            if (expanded) 'Content': find.text(content),
          },
        );
      });
    }
  }

  group('behaviour', () {
    testWidgets(
      'a disclosure toggles on click and Space, turning its chevron',
      (tester) async {
        var expanded = false;
        await pumpKitScene(
          tester,
          StatefulBuilder(
            builder: (context, setState) => AmalfiDisclosure(
              expanded: expanded,
              onChanged: (v) => setState(() => expanded = v),
            ),
          ),
        );
        double turns() =>
            tester.widget<AmalfiGlyph>(find.byType(AmalfiGlyph)).turns;
        await tester.tap(find.byType(AmalfiDisclosure));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(expanded, isTrue);
        expect(turns(), inExclusiveRange(0, 0.25));
        await tester.pumpAndSettle();
        expect(turns(), 0.25);
        await focusOn(tester, find.byType(AmalfiDisclosure));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(expanded, isFalse);
        expect(turns(), 0);
      },
    );

    testWidgets('a group opens and closes its content from the header', (
      tester,
    ) async {
      var expanded = false;
      await pumpKitScene(
        tester,
        SizedBox(
          width: 280,
          child: StatefulBuilder(
            builder: (context, setState) => AmalfiDisclosureGroup(
              title: 'Advanced options',
              expanded: expanded,
              onExpandedChanged: (v) => setState(() => expanded = v),
              child: const SizedBox(height: 48, child: Text('Body')),
            ),
          ),
        ),
      );
      expect(find.text('Body'), findsNothing);
      expect(tester.getSize(find.byType(AmalfiDisclosureGroup)).height, 28);
      await tester.tap(find.text('Advanced options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final opening = tester.getSize(find.byType(AmalfiDisclosureGroup)).height;
      expect(opening, inExclusiveRange(28, 84));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AmalfiDisclosureGroup)).height, 84);
      expect(tester.getTopLeft(find.text('Body')), const Offset(32, 32));
      await tester.tap(find.text('Advanced options'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('semantics: an expandable button', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKitScene(
        tester,
        SizedBox(
          width: 280,
          child: AmalfiDisclosureGroup(
            title: 'Advanced options',
            expanded: true,
            onExpandedChanged: (_) {},
            child: const Text('Body'),
          ),
        ),
      );
      final header = tester.getSemantics(
        find.byType(AmalfiDisclosureHeaderFace),
      );
      expect(header.label, 'Advanced options');
      expect(
        header.getSemanticsData().flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      semantics.dispose();
    });
  });
}
