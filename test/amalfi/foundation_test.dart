// The shared Amalfi foundation: glyphs and their stroke rule, the runtime Icon Kit symbols,
// the kit's shadows, the focus halo and the interaction states.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// Renders [widget] in a [size] box at dpr 1 and returns its RGBA bytes.
Future<(Uint8List, int)> _render(
  WidgetTester tester,
  Widget widget,
  Size size,
) async {
  final key = GlobalKey();
  await pumpKitScene(
    tester,
    RepaintBoundary(
      key: key,
      child: SizedBox.fromSize(size: size, child: widget),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return (bytes!, size.width.toInt());
}

int _alpha((Uint8List, int) image, int x, int y) =>
    image.$1[(y * image.$2 + x) * 4 + 3];

void main() {
  setUpAll(loadAmalfiFonts);

  group('glyphs', () {
    test('the stroke scales linearly with the size', () {
      expect(AmalfiGlyphData.regularStrokeAt(24), 1.5);
      expect(AmalfiGlyphData.regularStrokeAt(16), 1);
      expect(AmalfiGlyphData.regularStrokeAt(12), 0.75);
      expect(AmalfiGlyphData.regularStrokeAt(8), 0.5);
    });

    test('path data parses absolute and relative commands', () {
      final path = parseAmalfiGlyphPath('M4 4 L20 4 l0 16 H4 Z');
      final bounds = path.getBounds();
      expect(bounds, const Rect.fromLTRB(4, 4, 20, 20));
      final arc = parseAmalfiGlyphPath(
        'M2.75 12A9.25 9.25 0 1 0 21.25 12A9.25 9.25 0 1 0 2.75 12Z',
      ).getBounds();
      expect(arc.left, moreOrLessEquals(2.75, epsilon: 1e-3));
      expect(arc.right, moreOrLessEquals(21.25, epsilon: 1e-3));
      expect(arc.top, moreOrLessEquals(2.75, epsilon: 1e-3));
      // Broken data ends the path instead of throwing.
      expect(() => parseAmalfiGlyphPath('M4 4 L 3 Q'), returnsNormally);
      expect(parseAmalfiGlyphPath('').getBounds(), Rect.zero);
    });

    test('an Icon Kit SVG reads as a glyph', () {
      const svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <g fill="none" stroke="currentColor" stroke-width="2.15" stroke-linecap="round">
    <path d="M4 12 L20 12"/>
    <path d="M11 6A1 1 0 1 0 13 6A1 1 0 1 0 11 6Z" fill="currentColor"/>
    <path d="M4 4H8V8H4Z" fill="currentColor" stroke="none" opacity="0.35"/>
  </g>
</svg>''';
      final glyph = AmalfiGlyphData.fromSvg('test', svg)!;
      expect(glyph.strokeWidth, 2.15);
      expect(glyph.paths, const [
        AmalfiGlyphPath('M4 12 L20 12'),
        AmalfiGlyphPath('M11 6A1 1 0 1 0 13 6A1 1 0 1 0 11 6Z', fill: true),
        AmalfiGlyphPath(
          'M4 4H8V8H4Z',
          fill: true,
          stroke: false,
          opacity: 0.35,
        ),
      ]);
      expect(AmalfiGlyphData.fromSvg('empty', '<svg></svg>'), isNull);
      expect(AmalfiGlyphData.fromSvg('junk', 'not svg <path'), isNull);
    });

    testWidgets('a glyph takes its size and colour from the IconTheme', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        const IconTheme(
          data: IconThemeData(size: 12, color: Color(0xFF123456)),
          child: AmalfiGlyph(AmalfiGlyphs.checkmark),
        ),
      );
      expect(tester.getSize(find.byType(AmalfiGlyph)), const Size(12, 12));
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AmalfiGlyph),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        (paint.painter! as AmalfiGlyphPainter).color,
        const Color(0xFF123456),
      );
    });

    testWidgets('a 24 pt minus is 1.5 thick, a 12 pt one 0.75', (tester) async {
      // The minus is a horizontal line at y 12 on the 24 pt canvas, from x 4 to 20.
      final big = await _render(
        tester,
        const AmalfiGlyph(
          AmalfiGlyphs.minus,
          size: 24,
          color: Color(0xFF000000),
        ),
        const Size(24, 24),
      );
      // 1.5 centred on y 12: rows 11 and 12 covered 75 %.
      expect(_alpha(big, 12, 11), inInclusiveRange(180, 200));
      expect(_alpha(big, 12, 12), inInclusiveRange(180, 200));
      expect(_alpha(big, 12, 10), 0);
      final small = await _render(
        tester,
        const AmalfiGlyph(
          AmalfiGlyphs.minus,
          size: 12,
          color: Color(0xFF000000),
        ),
        const Size(12, 12),
      );
      // 0.75 centred on y 6: rows 5 and 6 covered 37.5 %.
      expect(_alpha(small, 6, 5), inInclusiveRange(85, 105));
      expect(_alpha(small, 6, 6), inInclusiveRange(85, 105));
    });
  });

  group('runtime symbols', () {
    late Directory icons;

    setUp(() {
      icons = Directory.systemTemp.createTempSync('amalfi-symbols');
      Directory('${icons.path}/symbols/regular').createSync(recursive: true);
      File('${icons.path}/symbols/regular/bolt.svg').writeAsStringSync(
        '<svg><g stroke-width="1.5"><path d="M12 2 L12 22"/></g></svg>',
      );
      AmalfiSymbols.debugEnvironment = {
        'SILICA_ICONS_DIR': icons.path,
        'HOME': icons.path,
        'XDG_DATA_HOME': '${icons.path}/none',
        'XDG_DATA_DIRS': '${icons.path}/none',
      };
    });

    tearDown(() {
      AmalfiSymbols.debugEnvironment = null;
      AmalfiSymbols.clearCache();
      icons.deleteSync(recursive: true);
    });

    test('are read from SILICA_ICONS_DIR', () {
      final bolt = AmalfiSymbols.load('bolt')!;
      expect(bolt.name, 'bolt');
      expect(bolt.paths.single.data, 'M12 2 L12 22');
      expect(AmalfiSymbols.load('missing'), isNull);
      expect(
        AmalfiSymbols.load('bolt', weight: AmalfiSymbolWeight.light),
        isNull,
      );
      // Names that could leave the folder are refused.
      expect(AmalfiSymbols.file('../regular/bolt'), isNull);
      expect(AmalfiSymbols.file('Bolt'), isNull);
    });

    testWidgets('draw the symbol, or the fallback when it is missing', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmalfiSymbol('bolt', size: 16),
            AmalfiSymbol('missing', size: 16, fallback: Text('?')),
            AmalfiSymbol('also-missing', size: 20),
          ],
        ),
      );
      expect(find.byType(AmalfiGlyph), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AmalfiSymbol).last),
        const Size(20, 20),
      );
    });
  });

  group('shadows', () {
    test('a kit blur b is a Gaussian of σ = b / 2', () {
      expect(amalfiShadowSigma(2), 1);
      expect(amalfiShadowSigma(32), 16);
    });

    testWidgets('are drawn outside the shape only', (tester) async {
      // A translucent fill over a heavy shadow: inside, only the fill shows.
      final image = await _render(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: AmalfiShapeDecoration(
              color: Color(0x40000000),
              shape: AmalfiSmoothBorder(radius: 4),
              shadows: [
                BoxShadow(
                  color: Color(0xFF000000),
                  offset: Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const Size(64, 64),
      );
      expect(_alpha(image, 32, 32), 0x40);
      // Below the shape, the shadow.
      expect(_alpha(image, 32, 49), greaterThan(0x80));
    });
  });

  group('focus halo', () {
    testWidgets('is a ring outside the shape', (tester) async {
      final image = await _render(
        tester,
        const Padding(
          padding: EdgeInsets.all(8),
          child: AmalfiFocusHalo(radius: 4, color: Color(0xFF0000FF)),
        ),
        const Size(48, 48),
      );
      expect(_alpha(image, 24, 24), 0); // inside
      expect(_alpha(image, 24, 6), 255); // 2 above the top edge
      expect(_alpha(image, 24, 4), 0); // beyond the 3 pt ring
      expect(find.byKey(AmalfiLayerKeys.focusHalo), findsOneWidget);
    });
  });

  group('interaction', () {
    testWidgets('hover, press, release inside and Space activate', (
      tester,
    ) async {
      final states = <AmalfiInteractionState>[];
      var activations = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpKitScene(
        tester,
        AmalfiInteraction(
          focusNode: node,
          onActivate: () => activations++,
          onStateChanged: states.add,
          builder: (context, state) => const SizedBox(width: 40, height: 20),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(100, 100));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(states.last.hovered, isTrue);
      await mouse.down(const Offset(10, 10));
      await tester.pump();
      expect(states.last.pressed, isTrue);
      // Leaving while held releases the press look; back inside restores it.
      await mouse.moveTo(const Offset(80, 10));
      await tester.pump();
      expect(states.last.pressed, isFalse);
      await mouse.moveTo(const Offset(20, 10));
      await tester.pump();
      await mouse.up();
      await tester.pump();
      expect(activations, 1);
      // Keyboard focus shows the halo state; Space activates, Return does not.
      node.requestFocus();
      await tester.pump();
      expect(states.last.focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, 2);
    });

    testWidgets('a control nested in another takes the press', (tester) async {
      final log = <String>[];
      await pumpKitScene(
        tester,
        AmalfiInteraction(
          onActivate: () => log.add('outer'),
          builder: (context, _) => SizedBox(
            width: 100,
            height: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: AmalfiInteraction(
                onActivate: () => log.add('inner'),
                builder: (context, _) =>
                    const SizedBox(key: Key('inner'), width: 20, height: 20),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('inner')));
      await tester.tapAt(const Offset(10, 20));
      expect(log, ['inner', 'outer']);
    });

    testWidgets('a disabled control reports nothing', (tester) async {
      final states = <AmalfiInteractionState>[];
      await pumpKitScene(
        tester,
        AmalfiInteraction(
          onStateChanged: states.add,
          builder: (context, state) {
            expect(state.enabled, isFalse);
            return const SizedBox(width: 40, height: 20);
          },
        ),
      );
      await tester.tapAt(const Offset(10, 10));
      expect(states, isEmpty);
    });
  });

  testWidgets(
    'whole points: the width on the grid, the height on its own step',
    (tester) async {
      await pumpKitScene(
        tester,
        const AmalfiWholePoints(
          step: AmalfiGrid.base,
          heightStep: 1,
          child: SizedBox(width: 45.4, height: 19.2),
        ),
      );
      expect(
        tester.getSize(find.byType(AmalfiWholePoints)),
        const Size(48, 20),
      );
    },
  );
}
