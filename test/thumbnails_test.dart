import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final file = Uri.file('/home/a/My File.png');

  tearDown(
    () => messenger.setMockMethodCallHandler(SilicaThumbnails.channel, null),
  );

  test('the request carries the URI and the pixel size', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(SilicaThumbnails.channel, (call) async {
      calls.add(call);
      return ['/cache/thumbnails/large/x.png'];
    });
    expect(
      await SilicaThumbnails.thumbnail(file, 200),
      '/cache/thumbnails/large/x.png',
    );
    final args = calls.single.arguments as Map;
    expect(args['interface'], 'dev.frascella.Silica.Thumbnails1');
    expect(args['method'], 'Thumbnail');
    expect(args['signature'], 'su');
    expect(args['args'], ['file:///home/a/My%20File.png', 200]);
  });

  test(
    'an empty path, a missing service or a bad size mean no thumbnail',
    () async {
      messenger.setMockMethodCallHandler(
        SilicaThumbnails.channel,
        (call) async => [''],
      );
      expect(await SilicaThumbnails.thumbnail(file, 64), isNull);
      messenger.setMockMethodCallHandler(SilicaThumbnails.channel, (
        call,
      ) async {
        throw PlatformException(
          code: 'org.freedesktop.DBus.Error.ServiceUnknown',
        );
      });
      expect(await SilicaThumbnails.thumbnail(file, 64), isNull);
      messenger.setMockMethodCallHandler(SilicaThumbnails.channel, null);
      expect(await SilicaThumbnails.thumbnail(file, 64), isNull);
      expect(await SilicaThumbnails.thumbnail(file, 0), isNull);
      await SilicaThumbnails.invalidate([file]);
    },
  );

  test('invalidate sends the URIs', () async {
    Map? sent;
    messenger.setMockMethodCallHandler(SilicaThumbnails.channel, (call) async {
      sent = call.arguments as Map;
      return const [];
    });
    await SilicaThumbnails.invalidate([file]);
    expect(sent?['method'], 'Invalidate');
    expect(sent?['signature'], 'as');
    expect(sent?['args'], [
      ['file:///home/a/My%20File.png'],
    ]);
  });

  testWidgets('the fallback shows until the PNG is ready, at size x ratio', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<List<Object?>>();
    Map? sent;
    messenger.setMockMethodCallHandler(SilicaThumbnails.channel, (call) {
      sent = call.arguments as Map;
      return gate.future;
    });
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: SilicaThumbnail(
            file: file,
            size: 64,
            fallback: const SizedBox(key: Key('icon'), width: 64, height: 64),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('icon')), findsOneWidget);
    expect((sent?['args'] as List?)?.last, 128);
    gate.complete(['/cache/thumbnails/normal/x.png']);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('icon')), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as FileImage).file.path,
      '/cache/thumbnails/normal/x.png',
    );
    expect(image.width, 64);
    expect(image.height, 64);
  });

  testWidgets('no service: the fallback stays', (tester) async {
    messenger.setMockMethodCallHandler(SilicaThumbnails.channel, (call) async {
      throw PlatformException(
        code: 'org.freedesktop.DBus.Error.ServiceUnknown',
      );
    });
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SilicaThumbnail(
          file: file,
          size: 32,
          fallback: const SizedBox(key: Key('icon')),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('icon')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(File('/nonexistent').existsSync(), isFalse);
  });
}
