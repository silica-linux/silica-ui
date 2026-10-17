// Pixel comparison: a widget rendered at 2× against the master's @2x PNG, with a tolerance.
//
// Sketch rasterises text with CoreText, so text pixels never match exactly: compare the
// geometry exactly (geometry.dart) and the pixels with a tolerance, masking text if needed.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fonts.dart';
import 'kit.dart';

/// The extra mean difference allowed on a Light master whose tint is drawn twice in the kit.
const double _doubleTintMean = 16;

bool _hasTintLayer(KitLayer layer) {
  if (layer.name.endsWith(' tint') || layer.children.any(_hasTintLayer)) {
    return true;
  }
  final nested = layer.master;
  if (layer.type != KitLayerType.symbolInstance || nested == null) return false;
  try {
    return _hasTintLayer(KitMaster.load(nested).root);
  } on Object {
    return false;
  }
}

/// Where diff images are written when a pixel test fails.
const String kitDiffPath = 'build/amalfi-diff';

/// How far a rendering may be from the kit PNG, per channel (0–255), premultiplied RGBA.
@immutable
class KitPixelTolerance {
  const KitPixelTolerance({this.mean = 1, this.max = 48});

  /// For a comparison with the text masked out (the default): shapes, fills, rims and
  /// shadows agree within antialiasing (the tooltips measure mean ≤ 0.75, max ≤ 44).
  static const KitPixelTolerance shapes = KitPixelTolerance();

  /// For a comparison that includes text, rasterised by CoreText in the kit: only the mean
  /// is meaningful (the tooltips measure ≤ 1.92).
  static const KitPixelTolerance withText = KitPixelTolerance(
    mean: 2.5,
    max: 255,
  );

  /// The largest allowed mean of the absolute channel differences over the compared pixels.
  final double mean;

  /// The largest allowed difference of any channel of any compared pixel.
  final int max;
}

/// The outcome of a comparison.
class KitPixelResult {
  KitPixelResult(
    this.mean,
    this.max,
    this.compared,
    this.worst,
    this.expectedAtWorst,
    this.actualAtWorst, {
    this.bandMasked = false,
  });

  KitPixelResult copyWith({bool? bandMasked}) => KitPixelResult(
    mean,
    max,
    compared,
    worst,
    expectedAtWorst,
    actualAtWorst,
    bandMasked: bandMasked ?? this.bandMasked,
  );

  /// Whether the comparison passed only with the glass refraction band masked (see
  /// [expectKitPixels]).
  final bool bandMasked;

  final double mean;
  final int max;

  /// Pixels compared (outside the mask).
  final int compared;

  /// The pixel with the largest difference, in PNG pixels.
  final Offset worst;

  /// The premultiplied RGBA of the kit and of the rendering at [worst].
  final List<int> expectedAtWorst, actualAtWorst;

  @override
  String toString() =>
      'mean ${mean.toStringAsFixed(3)}, max $max at $worst (kit $expectedAtWorst, '
      'rendered $actualAtWorst) over $compared pixels';
}

/// Renders [widget] at device pixel ratio 2 with its top-left corner on the master's origin,
/// in the master's appearance ([AmalfiTheme]), on a transparent canvas the size of the kit
/// PNG, and compares the pixels with the PNG.
///
/// - [maskText]: leave out every text frame of the master (nested masters included).
/// - [maskLayers]: leave out what these layers paint (frame, shadows, nested masters).
/// - [mask]: leave out these rectangles, in master coordinates.
/// - [maskGlassBand]: when the comparison fails and the master has Regular or Thick glass,
///   repeat it with the glass's refraction band masked (the Flutter side has no refraction
///   without shaders); on by default, with the same tolerance.
/// Masks are grown by [maskMargin] points for antialiasing.
/// - [origin]: where the master's origin is in the PNG, in points; by default
///   `-renderBounds.topLeft` (see [KitMaster.renderBounds]).
/// - [prepare]: runs after the first pump and before the capture, to bring the widget into
///   the state of the master (hover it, press it, wait for an animation).
///
/// The widget gets loose constraints (it sizes itself) and a [Directionality], a
/// [MediaQuery] and an [Overlay] above it. On failure the expected, rendered and difference
/// images are written side by side to `build/amalfi-diff/<key>.png`.
Future<KitPixelResult> expectKitPixels(
  WidgetTester tester,
  KitMaster master,
  Widget widget, {
  KitPixelTolerance tolerance = const KitPixelTolerance(),
  bool maskText = false,
  List<String> maskLayers = const [],
  List<Rect> mask = const [],
  double maskMargin = 1,
  bool maskGlassBand = true,
  Offset? origin,
  Future<void> Function(WidgetTester tester)? prepare,
}) async {
  await ensureAmalfiFonts(tester);
  final expected = await _decode(tester, master.png);
  final width = expected.width, height = expected.height;
  final at = origin ?? -master.renderBounds.topLeft;

  tester.view
    ..devicePixelRatio = 2
    ..physicalSize = Size(width.toDouble(), height.toDouble());
  addTearDown(tester.view.reset);
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width / 2, height / 2),
        devicePixelRatio: 2,
        platformBrightness: master.brightness,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AmalfiTheme(
          brightness: master.brightness,
          child: RepaintBoundary(
            key: boundary,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: at.dx, top: at.dy, child: widget),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (prepare != null) await prepare(tester);

  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final actual = (await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = _Pixels(
      image.width,
      image.height,
      data!.buffer.asUint8List(),
    );
    image.dispose();
    return pixels;
  }))!;
  if (actual.width != width || actual.height != height) {
    fail(
      '${master.name}: rendered ${actual.width}×${actual.height}, PNG $width×$height',
    );
  }

  // The mask, in PNG pixels.
  final masked = Uint8List(width * height);
  void cover(Rect r) {
    final px = r.inflate(maskMargin).shift(at);
    final x0 = math.max(0, (px.left * 2).floor());
    final y0 = math.max(0, (px.top * 2).floor());
    final x1 = math.min(width, (px.right * 2).ceil());
    final y1 = math.min(height, (px.bottom * 2).ceil());
    for (var y = y0; y < y1; y++) {
      masked.fillRange(y * width + math.min(x0, x1), y * width + x1, 1);
    }
  }

  if (maskText) master.textRects.forEach(cover);
  for (final path in maskLayers) {
    cover(master.paintBoundsOf(master.layer(path)));
  }
  mask.forEach(cover);

  // Compares outside [masked]; the diff image shows the masked pixels in blue.
  (KitPixelResult, Uint8List) compare(Uint8List masked, {int? meanOver}) {
    var sum = 0, compared = 0, max = 0, worst = 0;
    final diff = Uint8List(width * height * 4);
    for (var i = 0; i < width * height; i++) {
      final o = i * 4;
      if (masked[i] == 1) {
        diff
          ..[o] = 40
          ..[o + 1] = 40
          ..[o + 2] = 120
          ..[o + 3] = 255;
        continue;
      }
      var pixelMax = 0;
      for (var c = 0; c < 4; c++) {
        final d = (actual.bytes[o + c] - expected.bytes[o + c]).abs();
        sum += d;
        if (d > pixelMax) pixelMax = d;
      }
      compared++;
      if (pixelMax > max) {
        max = pixelMax;
        worst = i;
      }
      // Black where equal, brighter red the larger the difference (x4).
      diff
        ..[o] = math.min(255, pixelMax * 4)
        ..[o + 1] = 0
        ..[o + 2] = 0
        ..[o + 3] = 255;
    }
    return (
      KitPixelResult(
        (meanOver ?? compared) == 0 ? 0 : sum / ((meanOver ?? compared) * 4),
        max,
        compared,
        Offset((worst % width).toDouble(), (worst ~/ width).toDouble()),
        expected.bytes.sublist(worst * 4, worst * 4 + 4),
        actual.bytes.sublist(worst * 4, worst * 4 + 4),
      ),
      diff,
    );
  }

  // Light masters with a separate tint layer (`Glass tint`, `Track tint`): the export keeps
  // the glass layer's own white fill under it, so the kit PNG shows the tint twice (white at
  // 84 % where the material is 60 %: `docs/amalfi-checklist/kit-issues.md`). The code has the
  // tint once, as the docs say, so those masters are compared loosely (Dark ones, drawn with
  // the tint once, stay exact).
  final doubleTint =
      master.name.endsWith('/Light') && _hasTintLayer(master.root);
  bool within(KitPixelResult r) => doubleTint
      ? r.mean <= tolerance.mean + _doubleTintMean
      : r.mean <= tolerance.mean && r.max <= tolerance.max;

  var (result, diff) = compare(masked);
  // The edge of Regular and Thick is refracted in the kit (Sketch's `Glass` blur: the band
  // `depth` x half the shorter side inside the outline bends the backdrop and gets a specular
  // highlight and a chromatic split). The Flutter backend without shaders (Skia, these
  // tests) draws no refraction, so a comparison that fails is repeated with that band masked.
  // The tolerance is the same, and the mean still divides by the pixels compared before the
  // band was masked, so that text and glyphs weigh what they did; [KitPixelResult.bandMasked]
  // records it.
  if (!within(result) && maskGlassBand) {
    final bands = master.glassBands;
    if (bands.isNotEmpty) {
      final withBand = Uint8List.fromList(masked);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = Offset((x + 0.5) / 2, (y + 0.5) / 2) - at;
          for (final band in bands) {
            if (band.inBand(p)) {
              withBand[y * width + x] = 1;
              break;
            }
          }
        }
      }
      final (banded, bandedDiff) = compare(withBand, meanOver: result.compared);
      result = within(banded) ? banded.copyWith(bandMasked: true) : banded;
      diff = bandedDiff;
    }
  }
  if (!within(result)) {
    final file = await _writeDiff(tester, master, expected, actual, diff);
    fail(
      '${master.name}: pixels differ from the kit ($result; tolerance mean '
      '${tolerance.mean}, max ${tolerance.max}). Diff: ${file.path}',
    );
  }
  return result;
}

class _Pixels {
  _Pixels(this.width, this.height, this.bytes);

  final int width, height;

  /// Premultiplied RGBA.
  final Uint8List bytes;
}

Future<_Pixels> _decode(WidgetTester tester, File png) async {
  if (!png.existsSync()) {
    throw KitFormatException('no fixture ${png.path}: run tool/sync_kit.dart');
  }
  final bytes = png.readAsBytesSync();
  return (await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final pixels = _Pixels(
      frame.image.width,
      frame.image.height,
      data!.buffer.asUint8List(),
    );
    frame.image.dispose();
    codec.dispose();
    return pixels;
  }))!;
}

/// Writes expected | rendered | difference, side by side, over a checkerboard.
Future<File> _writeDiff(
  WidgetTester tester,
  KitMaster master,
  _Pixels expected,
  _Pixels actual,
  Uint8List diff,
) async {
  final w = expected.width, h = expected.height;
  final out = Uint8List(w * 3 * h * 4);
  void blit(Uint8List src, int column, {bool checker = true}) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final s = (y * w + x) * 4;
        final d = (y * w * 3 + column * w + x) * 4;
        final a = src[s + 3];
        final bg = checker && ((x ~/ 8 + y ~/ 8).isEven) ? 255 : 220;
        for (var c = 0; c < 3; c++) {
          // Premultiplied over the checkerboard.
          out[d + c] = (src[s + c] + bg * (255 - a) ~/ 255).clamp(0, 255);
        }
        out[d + 3] = 255;
      }
    }
  }

  blit(expected.bytes, 0);
  blit(actual.bytes, 1);
  blit(diff, 2, checker: false);
  final file = File('$kitDiffPath/${master.key}.png');
  final png = await tester.runAsync(() async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(out);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: w * 3,
      height: h,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return data!.buffer.asUint8List();
  });
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png!);
  return file;
}
