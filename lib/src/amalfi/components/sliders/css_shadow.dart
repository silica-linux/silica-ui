// Drop shadows with the kit's (CSS) blur: a blur b is a Gaussian of σ = b / 2, as
// `AmalfiGlass` draws them. A plain [BoxShadow] converts its blur radius to a wider σ
// (≈ 0.58 b + 0.5), which spreads the small shadows of raised controls too far.

import 'package:flutter/widgets.dart';

import '../../glass.dart';

/// A [BoxShadow] whose blur is painted as the kit's: σ = [blurRadius] / 2.
class AmalfiCssShadow extends BoxShadow {
  const AmalfiCssShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });

  /// [shadow] with the kit's blur.
  AmalfiCssShadow.of(BoxShadow shadow)
    : super(
        color: shadow.color,
        offset: shadow.offset,
        blurRadius: shadow.blurRadius,
        spreadRadius: shadow.spreadRadius,
      );

  /// [shadows] with the kit's blur.
  static List<BoxShadow> all(List<BoxShadow> shadows) => [
    for (final s in shadows) AmalfiCssShadow.of(s),
  ];

  @override
  double get blurSigma => amalfiShadowSigma(blurRadius);

  @override
  Paint toPaint() => Paint()
    ..color = color
    ..maskFilter = blurRadius > 0
        ? MaskFilter.blur(blurStyle, blurSigma)
        : null;

  @override
  AmalfiCssShadow scale(double factor) => AmalfiCssShadow(
    color: color,
    offset: offset * factor,
    blurRadius: blurRadius * factor,
    spreadRadius: spreadRadius * factor,
  );
}
