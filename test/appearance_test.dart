// The appearance override (`SilicaAppearance`): every component resolves against it instead of
// the system brightness, at the window level and the app level, and the embedder is told.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

/// What the library resolves under a context: one value per kind of color set.
class _Seen {
  _Seen(BuildContext context)
    : isDark = SilicaAppearance.isDark(context),
      toolbar = ToolbarColors.of(context),
      segmented = SegmentedColors.of(context),
      segmentedWindow = SegmentedColors.forSize(context, ControlSize.regular),
      control = ControlColors.of(context),
      input = InputColors.of(context),
      menu = MenuColors.of(context),
      imageButton = ImageButtonColors.of(context),
      veil = ToolbarVeil.of(context),
      platform = MediaQuery.platformBrightnessOf(context);

  final bool isDark;
  final ToolbarColors toolbar;
  final SegmentedColors segmented;
  final SegmentedColors segmentedWindow;
  final ControlColors control;
  final InputColors input;
  final MenuColors menu;
  final ImageButtonColors imageButton;
  final ToolbarVeil veil;
  final Brightness platform;
}

Widget _host(
  Brightness system,
  Widget Function(Widget child) wrap,
  void Function(_Seen) seen,
) => MediaQuery(
  data: MediaQueryData(platformBrightness: system),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: wrap(
      Builder(
        builder: (context) {
          seen(_Seen(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    SilicaApp.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SilicaWindow.channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SilicaWindow.channel, null);
    SilicaApp.reset();
  });

  void expectDark(_Seen seen) {
    expect(seen.isDark, isTrue);
    expect(identical(seen.toolbar, ToolbarColors.dark), isTrue);
    expect(identical(seen.segmented, SegmentedColors.dark), isTrue);
    expect(identical(seen.segmentedWindow, SegmentedColors.windowDark), isTrue);
    expect(identical(seen.control, ControlColors.darkColors), isTrue);
    expect(identical(seen.input, InputColors.dark), isTrue);
    expect(identical(seen.menu, MenuColors.dark), isTrue);
    expect(identical(seen.imageButton, ImageButtonColors.dark), isTrue);
    expect(identical(seen.veil, ToolbarVeil.dark), isTrue);
  }

  void expectLight(_Seen seen) {
    expect(seen.isDark, isFalse);
    expect(identical(seen.toolbar, ToolbarColors.light), isTrue);
    expect(identical(seen.segmented, SegmentedColors.light), isTrue);
    expect(
      identical(seen.segmentedWindow, SegmentedColors.windowLight),
      isTrue,
    );
    expect(identical(seen.control, ControlColors.light), isTrue);
    expect(identical(seen.input, InputColors.light), isTrue);
    expect(identical(seen.menu, MenuColors.light), isTrue);
    expect(identical(seen.imageButton, ImageButtonColors.light), isTrue);
    expect(identical(seen.veil, ToolbarVeil.light), isTrue);
  }

  testWidgets('without an override the components follow the system', (
    tester,
  ) async {
    late _Seen seen;
    await tester.pumpWidget(_host(Brightness.dark, (c) => c, (s) => seen = s));
    expectDark(seen);
    await tester.pumpWidget(_host(Brightness.light, (c) => c, (s) => seen = s));
    expectLight(seen);
  });

  testWidgets('a dark window in a light system is dark', (tester) async {
    late _Seen seen;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        (c) =>
            SilicaAppearanceScope(appearance: SilicaAppearance.dark, child: c),
        (s) => seen = s,
      ),
    );
    expectDark(seen);
    // The widgets of the app that read MediaQuery follow too.
    expect(seen.platform, Brightness.dark);
  });

  testWidgets('a light window in a dark system is light', (tester) async {
    late _Seen seen;
    await tester.pumpWidget(
      _host(
        Brightness.dark,
        (c) =>
            SilicaAppearanceScope(appearance: SilicaAppearance.light, child: c),
        (s) => seen = s,
      ),
    );
    expectLight(seen);
    expect(seen.platform, Brightness.light);
  });

  testWidgets('system follows the system', (tester) async {
    late _Seen seen;
    await tester.pumpWidget(
      _host(
        Brightness.dark,
        (c) => SilicaAppearanceScope(child: c),
        (s) => seen = s,
      ),
    );
    expectDark(seen);
  });

  testWidgets('an override changes with the scope and with the system', (
    tester,
  ) async {
    late _Seen seen;
    Widget build(Brightness system, SilicaAppearance appearance) => _host(
      system,
      (c) => SilicaAppearanceScope(appearance: appearance, child: c),
      (s) => seen = s,
    );
    await tester.pumpWidget(build(Brightness.light, SilicaAppearance.dark));
    expectDark(seen);
    await tester.pumpWidget(build(Brightness.light, SilicaAppearance.system));
    expectLight(seen);
    // A dark override ignores a change of the system.
    await tester.pumpWidget(build(Brightness.light, SilicaAppearance.dark));
    await tester.pumpWidget(build(Brightness.dark, SilicaAppearance.dark));
    expectDark(seen);
    await tester.pumpWidget(build(Brightness.light, SilicaAppearance.dark));
    expectDark(seen);
  });

  testWidgets('the app-level override applies, the window-level one wins', (
    tester,
  ) async {
    late _Seen seen;
    SilicaApp.appearance = SilicaAppearance.dark;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        (c) => SilicaAppearanceScope(child: c),
        (s) => seen = s,
      ),
    );
    expectDark(seen);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        (c) =>
            SilicaAppearanceScope(appearance: SilicaAppearance.light, child: c),
        (s) => seen = s,
      ),
    );
    expectLight(seen);
    // The scopes follow the app-level setter while it is live.
    await tester.pumpWidget(
      _host(
        Brightness.dark,
        (c) => SilicaAppearanceScope(child: c),
        (s) => seen = s,
      ),
    );
    SilicaApp.appearance = SilicaAppearance.light;
    await tester.pump();
    expectLight(seen);
  });

  testWidgets('the override reaches menus and alerts drawn in the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SilicaAppearanceScope(
            appearance: SilicaAppearance.dark,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text('${MenuColors.of(context).hashCode}'),
                  Text('${SilicaAppearance.isDark(context)}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('true'), findsOneWidget);
    expect(find.text('${MenuColors.dark.hashCode}'), findsOneWidget);
  });

  group('towards the embedder', () {
    testWidgets('the scope sends its appearance once and on change', (
      tester,
    ) async {
      Widget build(SilicaAppearance appearance) => _host(
        Brightness.light,
        (c) => SilicaAppearanceScope(appearance: appearance, child: c),
        (_) {},
      );
      await tester.pumpWidget(build(SilicaAppearance.dark));
      await tester.pumpWidget(build(SilicaAppearance.dark));
      expect(calls.map((c) => c.method), ['setAppearance']);
      expect(calls.single.arguments, {'appearance': 'dark'});
      await tester.pumpWidget(build(SilicaAppearance.light));
      expect(calls.last.arguments, {'appearance': 'light'});
      expect(calls.length, 2);
    });

    testWidgets('the app-level override is sent when there is no scope', (
      tester,
    ) async {
      SilicaApp.appearance = SilicaAppearance.dark;
      SilicaApp.appearance = SilicaAppearance.dark;
      await tester.pump();
      expect(calls.map((c) => c.arguments), [
        {'appearance': 'dark'},
      ]);
    });

    test('an embedder without the call is not an error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SilicaWindow.channel, null);
      expect(await SilicaWindow.setAppearance(SilicaAppearance.dark), isFalse);
    });
  });
}
