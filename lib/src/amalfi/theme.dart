// The Amalfi theme: which appearance (and which app palette) the widgets below draw with.

import 'package:flutter/widgets.dart';

import '../appearance.dart' show SilicaAppearance;
import 'token_types.dart';
import 'tokens.g.dart';

/// The Amalfi tokens in effect: the colours and shadows of one appearance, and optionally the
/// palette of one app.
@immutable
class AmalfiThemeData {
  const AmalfiThemeData({required this.brightness, this.app});

  /// The light appearance, with the palette of [app] if given.
  const AmalfiThemeData.light({this.app}) : brightness = Brightness.light;

  /// The dark appearance, with the palette of [app] if given.
  const AmalfiThemeData.dark({this.app}) : brightness = Brightness.dark;

  /// The appearance.
  final Brightness brightness;

  /// The app whose palette [appColors] gives (`Mail`, `Mission Control`); null: none.
  final String? app;

  /// Whether this is the dark appearance.
  bool get isDark => brightness == Brightness.dark;

  /// The colours of [brightness].
  AmalfiColors get colors => AmalfiColors.of(brightness);

  /// The drop shadows of [brightness].
  AmalfiShadows get shadows => AmalfiShadows.of(brightness);

  /// The palette of [app] in [brightness]; null when there is no app or it has no palette.
  AmalfiAppColors? get appColors {
    final name = app;
    return name == null ? null : colors.palette(name);
  }

  /// The colour [token] of the app palette (`Flag`); null when there is none.
  Color? appColor(String token) => appColors?[token];

  /// A copy with the given fields replaced.
  AmalfiThemeData copyWith({Brightness? brightness, String? app}) =>
      AmalfiThemeData(
        brightness: brightness ?? this.brightness,
        app: app ?? this.app,
      );

  @override
  bool operator ==(Object other) =>
      other is AmalfiThemeData &&
      other.brightness == brightness &&
      other.app == app;

  @override
  int get hashCode => Object.hash(brightness, app);

  @override
  String toString() => 'AmalfiThemeData($brightness, app: $app)';
}

/// Gives the widgets below it an [AmalfiThemeData], read with [AmalfiTheme.of].
///
/// [brightness] null follows the appearance in effect ([SilicaAppearance.brightnessOf]: the
/// window's or the app's override, otherwise the system's); [app] null keeps the app of an
/// enclosing [AmalfiTheme]. Without any [AmalfiTheme] above, [AmalfiTheme.of] still answers,
/// with the appearance in effect and no app palette.
///
/// An app with a single appearance (the dark-only Calculator and Clock) should force it with
/// [SilicaAppearance] rather than here, so that the window and Ossido agree.
class AmalfiTheme extends StatelessWidget {
  const AmalfiTheme({
    super.key,
    this.brightness,
    this.app,
    required this.child,
  });

  /// The appearance to force; null: the one in effect.
  final Brightness? brightness;

  /// The app palette to use; null: the enclosing theme's.
  final String? app;

  final Widget child;

  /// The theme in effect under [context].
  static AmalfiThemeData of(BuildContext context) =>
      maybeOf(context) ??
      AmalfiThemeData(brightness: SilicaAppearance.brightnessOf(context));

  /// The theme of the closest [AmalfiTheme] above [context]; null when there is none.
  static AmalfiThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AmalfiScope>()?.data;

  @override
  Widget build(BuildContext context) {
    final data = AmalfiThemeData(
      brightness: brightness ?? SilicaAppearance.brightnessOf(context),
      app: app ?? maybeOf(context)?.app,
    );
    return _AmalfiScope(data: data, child: child);
  }
}

class _AmalfiScope extends InheritedWidget {
  const _AmalfiScope({required this.data, required super.child});

  final AmalfiThemeData data;

  @override
  bool updateShouldNotify(_AmalfiScope old) => old.data != data;
}
