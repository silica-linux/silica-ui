import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  test('events from the embedder', () {
    final over = SilicaDrag.parse('enter', {'x': 10, 'y': 20.5});
    expect(over, isA<SilicaDragOver>());
    expect((over! as SilicaDragOver).position, const Offset(10, 20.5));
    expect((over as SilicaDragOver).entered, isTrue);
    expect(
      (SilicaDrag.parse('motion', {'x': 1, 'y': 2})! as SilicaDragOver).entered,
      isFalse,
    );
    expect(SilicaDrag.parse('leave', null), isA<SilicaDragLeave>());
    final drop =
        SilicaDrag.parse('drop', {
              'x': 5,
              'y': 6,
              'uris': ['file:///tmp/a%20b.txt', 'https://example.org/', 3],
            })!
            as SilicaDrop;
    expect(drop.uris.length, 2);
    expect(drop.paths, ['/tmp/a b.txt']);
    expect(
      (SilicaDrag.parse('finished', {'action': 'move'})! as SilicaDragFinished)
          .action,
      'move',
    );
    expect(SilicaDrag.parse('other', null), isNull);
  });

  testWidgets('start: encoded URIs and RGBA icon in base64', (tester) async {
    MethodCall? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SilicaDrag.channel, (call) async {
          sent = call;
          return true;
        });
    final icon = await tester.runAsync(() {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 2, 1),
        ui.Paint()..color = const Color(0xFFFF0000),
      );
      return recorder.endRecording().toImage(2, 1);
    });
    final ok = await tester.runAsync(
      () => SilicaDrag.start(['/tmp/a b.txt'], icon: icon),
    );
    expect(ok, isTrue);
    final args = sent!.arguments as Map;
    expect(sent!.method, 'start');
    expect(args['uris'], ['file:///tmp/a%20b.txt']);
    final iconArgs = args['icon'] as Map;
    expect((iconArgs['width'], iconArgs['height']), (2, 1));
    expect(base64Decode(iconArgs['rgba'] as String), [
      255, 0, 0, 255, 255, 0, 0, 255, //
    ]);
  });
}
