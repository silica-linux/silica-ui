// The value types of the Amalfi design tokens. The values themselves are generated into
// `tokens.g.dart` from `tool/amalfi/tokens.json` and `tool/amalfi/motion.md`.

import 'package:flutter/widgets.dart';

/// The palette of one app (`App/<App>/<Token>` in `tokens.json`), in one appearance.
///
/// Each app with a palette has a generated subclass with a typed field per token (for
/// example `AmalfiTerminalColors.selection`), reached from [AmalfiColors] by a field named
/// after the app (`AmalfiColors.light.terminal`) or by name
/// (`AmalfiColors.light.app('Terminal', 'Selection')`).
///
/// An app with a single appearance (for example a dark-only one) has the same palette in
/// both [AmalfiColors.light] and [AmalfiColors.dark]: [brightness] says which one it is and
/// [appearances] lists those the app defines. Such an app should also force its appearance
/// (`SilicaAppearance.dark` on its `SilicaApp` or window).
abstract class AmalfiAppColors {
  const AmalfiAppColors();

  /// The app's name as in the token names (`Terminal`, `Mission Control`).
  String get app;

  /// The appearance this palette belongs to.
  Brightness get brightness;

  /// The appearances the app defines a palette for.
  Set<Brightness> get appearances;

  /// The token names, without the `App/<App>/` prefix, in the order of `tokens.json`.
  List<String> get tokenNames;

  /// The colour of [token] (without the `App/<App>/` prefix); null when the app has no
  /// such token.
  Color? operator [](String token);
}

/// A text style token: family, size, line height and weight from `tokens.json`.
@immutable
final class AmalfiTextToken {
  const AmalfiTextToken({
    required this.name,
    required this.family,
    required this.size,
    required this.lineHeight,
    required this.weight,
    required this.colorTokens,
  });

  /// The style's name in `tokens.json` (`Title 1`).
  final String name;

  /// The font family, served by this package (`Inter`, `JetBrains Mono`).
  final String family;

  /// Font size in points.
  final double size;

  /// Line height in points; null for the font's natural line height.
  final double? lineHeight;

  /// Font weight.
  final FontWeight weight;

  /// The colour tokens the kit pairs with this style (`Text/Primary`, `Accent/Amalfi`, …),
  /// to be resolved with `AmalfiColors.byName`.
  final List<String> colorTokens;

  /// The style as a [TextStyle], in [color] (none: inherited). The extra line height is split
  /// evenly above and below the glyphs, as in the kit. The tokens give no tracking, so the
  /// font's own spacing applies.
  TextStyle style({Color? color}) => TextStyle(
    fontFamily: family,
    package: 'silica_ui',
    fontSize: size,
    height: lineHeight == null ? null : lineHeight! / size,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: weight,
    color: color,
  );
}

/// The colours of one window control disc (close, minimise, zoom), at rest in an active
/// light window.
@immutable
final class AmalfiWindowControl {
  const AmalfiWindowControl({
    required this.top,
    required this.bottom,
    required this.rim,
    required this.rimWidth,
  });

  /// The colour at the top of the vertical gradient.
  final Color top;

  /// The colour at the bottom of the vertical gradient.
  final Color bottom;

  /// The colour of the rim.
  final Color rim;

  /// The width of the rim in points (the number after the colour in `tokens.json`, read as a
  /// stroke width).
  final double rimWidth;
}

/// The refraction of a glass material: a lens (`Glass/Clear`, which also magnifies) or the edge
/// refraction of `Glass/Regular` and `Glass/Thick` (magnification 1).
@immutable
final class AmalfiRefraction {
  const AmalfiRefraction({
    required this.distortion,
    required this.depth,
    required this.chromaticAberration,
    required this.magnification,
  });

  /// How much the edge bends what is under it (0–1).
  final double distortion;

  /// The apparent depth of the lens (0–1).
  final double depth;

  /// How far the colour channels split at the edge (0–1).
  final double chromaticAberration;

  /// The scale of what is under the lens (1 = none).
  final double magnification;
}

/// A blur strip (`Blur/*` in tokens.json): the background blurred and saturated under a tint,
/// with no refraction, rim, shadow or specular: the title bar section over a sidebar.
@immutable
final class AmalfiBlurStrip {
  const AmalfiBlurStrip({
    required this.name,
    required this.backgroundBlur,
    required this.saturation,
    required this.tintLight,
    required this.tintDark,
  });

  final String name;

  /// The blur sigma, in points.
  final double backgroundBlur;
  final double saturation;
  final Color tintLight;
  final Color tintDark;

  /// The tint in [brightness].
  Color tint(Brightness brightness) =>
      brightness == Brightness.dark ? tintDark : tintLight;
}

/// The parameters of a glass material (`Glass/Regular`, `Glass/Thick`, `Glass/Clear`), as
/// plain data. How to render them: `docs/design/amalfi/materials.md` in silica-desktop.
@immutable
final class AmalfiGlassMaterial {
  const AmalfiGlassMaterial({
    required this.name,
    required this.backgroundBlur,
    required this.saturation,
    required this.tintLight,
    required this.tintDark,
    required this.rimInsideWidth,
    required this.rimInsideLight,
    required this.rimInsideDark,
    required this.rimLightOffset,
    required this.rimLightBlur,
    required this.rimLightLight,
    required this.rimLightDark,
    required this.shadowLevel,
    required this.lens,
    required this.refraction,
    required this.specularHighlights,
    required this.brightnessLight,
    required this.brightnessDark,
  });

  /// The material's name in `tokens.json` (`Glass/Regular`).
  final String name;

  /// The Gaussian blur radius of the backdrop, in points.
  final double backgroundBlur;

  /// The saturation factor applied to the blurred backdrop (1 = unchanged).
  final double saturation;

  /// The tint over the backdrop in the light appearance; null: no tint.
  final Color? tintLight;

  /// The tint over the backdrop in the dark appearance; null: no tint.
  final Color? tintDark;

  /// The width of the rim drawn inside the shape, in points.
  final double rimInsideWidth;

  /// The inside rim's colour, light appearance.
  final Color rimInsideLight;

  /// The inside rim's colour, dark appearance.
  final Color rimInsideDark;

  /// The offset of the rim light (an inner shadow along the top edge).
  final Offset rimLightOffset;

  /// The blur of the rim light, in points.
  final double rimLightBlur;

  /// The rim light's colour, light appearance.
  final Color rimLightLight;

  /// The rim light's colour, dark appearance.
  final Color rimLightDark;

  /// The level of `AmalfiShadows` dropped outside the shape (1–3); null: no shadow.
  final int? shadowLevel;

  /// Whether the material is a lens (it refracts and magnifies what is under it).
  final bool lens;

  /// The refraction; null for a material that does not refract.
  final AmalfiRefraction? refraction;

  /// Whether the material draws specular highlights along its rim.
  final bool specularHighlights;

  /// The brightness factor of what is under the material, light appearance (1 = unchanged).
  final double brightnessLight;

  /// The brightness factor of what is under the material, dark appearance (1 = unchanged).
  final double brightnessDark;

  /// The tint in [brightness]; null: no tint.
  Color? tint(Brightness brightness) =>
      brightness == Brightness.dark ? tintDark : tintLight;

  /// The inside rim's colour in [brightness].
  Color rimInside(Brightness brightness) =>
      brightness == Brightness.dark ? rimInsideDark : rimInsideLight;

  /// The rim light's colour in [brightness].
  Color rimLight(Brightness brightness) =>
      brightness == Brightness.dark ? rimLightDark : rimLightLight;
}

/// A spring motion token: a [SpringDescription] (mass 1) with the response and damping ratio
/// it was derived from (stiffness k = (2π / response)², damping c = 2 ζ √k).
final class AmalfiSpring extends SpringDescription {
  const AmalfiSpring({
    required this.name,
    required this.response,
    required this.dampingRatio,
    required super.stiffness,
    required super.damping,
  }) : super(mass: 1);

  /// The token's name in `motion.md` (`spring.snappy`).
  final String name;

  /// The response (period of the undamped spring), in seconds.
  final double response;

  /// The damping ratio ζ (1 = critically damped).
  final double dampingRatio;
}

/// A fade motion token: a duration and a curve.
@immutable
final class AmalfiFade {
  const AmalfiFade({
    required this.name,
    required this.duration,
    required this.curve,
  });

  /// The token's name in `motion.md` (`fade.quick`).
  final String name;

  /// How long the fade lasts.
  final Duration duration;

  /// The easing curve.
  final Curve curve;
}
