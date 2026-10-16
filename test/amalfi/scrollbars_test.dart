// Scroll bars against the kit (`Scrollbars/*`). Checklist:
// docs/amalfi-checklist/scrollbars.md.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

Finder decoratedIn(Finder of, int index) =>
    find.descendant(of: of, matching: find.byType(DecoratedBox)).at(index);

/// Capsule ends and thin thumbs: Sketch antialiases them a little differently.
const KitPixelTolerance barTolerance = KitPixelTolerance(mean: 1, max: 96);

/// The content of the kit's scroll areas, sized and scrolled so that the thumbs fall where
/// the kit draws them: (content size, scroll offset) per style.
({Size content, Offset offset}) areaContent(AmalfiScrollbarStyle style) =>
    style == AmalfiScrollbarStyle.overlay
    // Viewport 264 × 180, tracks 168 and 252: thumbs 64 at 16, 88 at 20.
    ? (content: const Size(756, 472.5), offset: const Offset(60, 45))
    // Viewport 248 × 164, tracks 164 and 248.
    : (
        content: Size(248 * 248 / 88, 420.25),
        offset: Offset(20 / 160 * (248 * 248 / 88 - 248), 41),
      );

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final (axisName, axis) in [
        ('Vertical', Axis.vertical),
        ('Horizontal', Axis.horizontal),
      ]) {
        final vertical = axis == Axis.vertical;
        for (final state in ['Thin', 'Expanded', 'Dragging']) {
          testWidgets('Overlay $axisName $state', (tester) async {
            final master = KitMaster.load(
              'Scrollbars/Overlay/$axisName/$state/$appearance',
            );
            final track = AmalfiScrollbarTrack(
              axis: axis,
              expansion: state == 'Thin' ? 0 : 1,
              dragging: state == 'Dragging',
              thumbOffset: vertical ? 16 : 20,
              thumbExtent: vertical ? 64 : 88,
            );
            final scene = SizedBox(
              width: vertical ? null : master.size.width,
              height: vertical ? master.size.height : null,
              child: track,
            );
            final root = await pumpKitScene(tester, scene, master: master);
            final bar = find.byType(AmalfiScrollbarTrack);
            final thin = state == 'Thin';
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                if (!thin) 'Track': decoratedIn(bar, 0),
                'Thumb': decoratedIn(bar, thin ? 0 : 1),
              },
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              tolerance: barTolerance,
            );
          });
        }

        for (final state in ['Rest', 'Hover', 'Disabled']) {
          testWidgets('Legacy $axisName $state', (tester) async {
            final master = KitMaster.load(
              'Scrollbars/Legacy/$axisName/$state/$appearance',
            );
            final track = AmalfiScrollbarTrack(
              axis: axis,
              style: AmalfiScrollbarStyle.legacy,
              hovered: state == 'Hover',
              thumbOffset: vertical ? 16 : 20,
              thumbExtent: state == 'Disabled' ? null : (vertical ? 64 : 88),
            );
            final scene = SizedBox(
              width: vertical ? null : master.size.width,
              height: vertical ? master.size.height : null,
              child: track,
            );
            final root = await pumpKitScene(tester, scene, master: master);
            final bar = find.byType(AmalfiScrollbarTrack);
            expectKitGeometry(
              tester,
              master,
              root: root,
              layers: {
                'Track': decoratedIn(bar, 0),
                if (state != 'Disabled') 'Thumb': decoratedIn(bar, 1),
              },
            );
            await expectKitPixels(
              tester,
              master,
              scene,
              tolerance: barTolerance,
            );
          });
        }
      }

      testWidgets('Corner', (tester) async {
        final master = KitMaster.load('Scrollbars/Corner/Rest/$appearance');
        const corner = AmalfiScrollbarCorner();
        final root = await pumpKitScene(tester, corner, master: master);
        expectKitGeometry(
          tester,
          master,
          root: root,
          layers: {'Corner': find.byType(DecoratedBox)},
        );
        await expectKitPixels(tester, master, corner);
      });

      for (final (styleName, style, state) in [
        ('Overlay', AmalfiScrollbarStyle.overlay, 'Thin'),
        ('Overlay', AmalfiScrollbarStyle.overlay, 'Expanded'),
        ('Legacy', AmalfiScrollbarStyle.legacy, 'Rest'),
        ('Legacy', AmalfiScrollbarStyle.legacy, 'Hover'),
      ]) {
        testWidgets('Area $styleName $state', (tester) async {
          final master = KitMaster.load(
            'Scrollbars/Area/$styleName/$state/$appearance',
          );
          final (:content, :offset) = areaContent(style);
          // The kit shows both bars in the state; a pointer is over one at a time, so the
          // states are set (the bars' pointer behaviour is tested below).
          final held = state == 'Expanded' || state == 'Hover';
          Widget scene() {
            final v = ScrollController(initialScrollOffset: offset.dy);
            final h = ScrollController(initialScrollOffset: offset.dx);
            addTearDown(v.dispose);
            addTearDown(h.dispose);
            final vs = WidgetStatesController({if (held) WidgetState.hovered});
            final hs = WidgetStatesController({if (held) WidgetState.hovered});
            addTearDown(vs.dispose);
            addTearDown(hs.dispose);
            return _Area(
              style: style,
              content: content,
              vertical: v,
              horizontal: h,
              verticalStates: vs,
              horizontalStates: hs,
            );
          }

          // Overlay bars show while scrolling: nudge both views.
          Future<void> scroll(WidgetTester tester) async {
            if (style == AmalfiScrollbarStyle.legacy || held) {
              await tester.pump();
              return;
            }
            for (final c in tester.state<_AreaState>(find.byType(_Area)).all) {
              c.jumpTo(c.offset + 1);
              c.jumpTo(c.offset - 1);
            }
            await tester.pump();
            await tester.pump(AmalfiFades.quick.duration);
          }

          final root = await pumpKitScene(tester, scene(), master: master);
          await scroll(tester);
          Finder track(Axis axis) => find.byWidgetPredicate(
            (w) => w is AmalfiScrollbarTrack && w.axis == axis,
          );
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: {
              'Surface': find.byKey(_Area.surface),
              'Edge': find.byKey(_Area.edge),
              'Vertical scrollbar': track(Axis.vertical),
              'Horizontal scrollbar': track(Axis.horizontal),
              if (style == AmalfiScrollbarStyle.legacy)
                'Corner': find.byType(AmalfiScrollbarCorner),
            },
          );
          await expectKitPixels(
            tester,
            master,
            scene(),
            tolerance: barTolerance,
            // The text lines are placeholder content, not the scroll bars.
            mask: [const Rect.fromLTWH(16, 20, 200, 132)],
            prepare: scroll,
          );
          await tester.pump(AmalfiScrollbar.hideDelay * 2);
        });
      }
    });
  }

  group('behaviour', () {
    Future<ScrollController> pumpList(
      WidgetTester tester, {
      AmalfiScrollbarStyle style = AmalfiScrollbarStyle.overlay,
      double extent = 1000,
    }) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpKitScene(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: AmalfiScrollbar(
            style: style,
            child: SingleChildScrollView(
              controller: controller,
              child: SizedBox(height: extent, width: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byType(AmalfiScrollbarTrack),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    testWidgets('overlay: shows while scrolling, then fades', (tester) async {
      final controller = await pumpList(tester);
      expect(opacity(tester), 0);
      controller.jumpTo(100);
      await tester.pump();
      await tester.pump(AmalfiFades.quick.duration);
      expect(opacity(tester), 1);
      final track = tester.widget<AmalfiScrollbarTrack>(
        find.byType(AmalfiScrollbarTrack),
      );
      // 200 of 1000 visible: a 40 pt thumb, 100 of 800 scrolled.
      expect(track.thumbExtent, 40);
      expect(track.thumbOffset, closeTo(160 * 100 / 800, 1e-9));
      expect(track.expansion, 0);
      await tester.pump(AmalfiScrollbar.hideDelay);
      await tester.pump(AmalfiFades.standard.duration);
      expect(opacity(tester), 0);
    });

    testWidgets('overlay: the pointer expands it, dragging scrolls 1:1', (
      tester,
    ) async {
      final controller = await pumpList(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(100, 100));
      await mouse.moveTo(const Offset(194, 10));
      await tester.pump();
      await tester.pump(AmalfiFades.quick.duration);
      AmalfiScrollbarTrack track() =>
          tester.widget(find.byType(AmalfiScrollbarTrack));
      expect(track().expansion, 1);
      expect(opacity(tester), 1);
      // Drag the thumb (0–40) down by 40: 40 of the 160 pt room is a quarter of 800.
      await mouse.down(const Offset(194, 10));
      await tester.pump();
      expect(track().dragging, isTrue);
      await mouse.moveTo(const Offset(194, 30));
      await mouse.moveTo(const Offset(194, 50));
      await tester.pump();
      expect(controller.offset, closeTo(200, 1e-9));
      await mouse.up();
      await tester.pump();
      expect(track().dragging, isFalse);
      // A click on the track below the thumb pages down.
      await mouse.down(const Offset(194, 190));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(400, 1e-9));
      await mouse.moveTo(const Offset(50, 50));
      await tester.pump(AmalfiScrollbar.hideDelay * 2);
      await tester.pumpAndSettle();
      expect(opacity(tester), 0);
    });

    testWidgets('legacy: beside the content, no thumb when all fits', (
      tester,
    ) async {
      await pumpList(tester, style: AmalfiScrollbarStyle.legacy, extent: 100);
      expect(
        tester.getRect(find.byType(AmalfiScrollbarTrack)),
        const Rect.fromLTWH(184, 0, 16, 200),
      );
      expect(
        tester.getSize(find.byType(SingleChildScrollView)),
        const Size(184, 200),
      );
      expect(
        tester
            .widget<AmalfiScrollbarTrack>(find.byType(AmalfiScrollbarTrack))
            .thumbExtent,
        isNull,
      );
    });

    testWidgets('legacy: the pointer over the bar highlights the thumb', (
      tester,
    ) async {
      await pumpList(tester, style: AmalfiScrollbarStyle.legacy);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(100, 100));
      await mouse.moveTo(const Offset(192, 100));
      await tester.pump();
      expect(
        tester
            .widget<AmalfiScrollbarTrack>(find.byType(AmalfiScrollbarTrack))
            .hovered,
        isTrue,
      );
    });
  });
}

/// The kit's scroll area scene: a raised surface, radius 12, with an edge, scrolling
/// [content].
class _Area extends StatefulWidget {
  const _Area({
    required this.style,
    required this.content,
    required this.vertical,
    required this.horizontal,
    required this.verticalStates,
    required this.horizontalStates,
  });

  static const Key surface = ValueKey('surface');
  static const Key edge = ValueKey('edge');

  final AmalfiScrollbarStyle style;
  final Size content;
  final ScrollController vertical;
  final ScrollController horizontal;
  final WidgetStatesController verticalStates;
  final WidgetStatesController horizontalStates;

  @override
  State<_Area> createState() => _AreaState();
}

class _AreaState extends State<_Area> {
  List<ScrollController> get all => [widget.vertical, widget.horizontal];

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    const shape = AmalfiSmoothBorder(radius: 12);
    return SizedBox(
      width: 264,
      height: 180,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const ShapeBorderClipper(shape: shape),
              child: DecoratedBox(
                key: _Area.surface,
                decoration: ShapeDecoration(
                  color: colors.surfaceRaised,
                  shape: shape,
                ),
                child: AmalfiScrollArea(
                  style: widget.style,
                  vertical: widget.vertical,
                  horizontal: widget.horizontal,
                  verticalStates: widget.verticalStates,
                  horizontalStates: widget.horizontalStates,
                  child: SizedBox.fromSize(size: widget.content),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: _Area.edge,
                decoration: ShapeDecoration(
                  shape: shape.copyWith(
                    side: BorderSide(
                      color: colors.lineBorder,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
