// Il vetro dentro una finestra: un menu o un popover disegnato dall'app sopra il proprio
// contenuto. Il vetro di Ossido starebbe sotto la superficie della finestra (vedrebbe la
// scrivania, non il contenuto), quindi qui lo fa Flutter con lo stesso materiale: sfocatura
// gaussiana e matrice di colore misurate (ossido-render glass.rs, menubar.md › Materiale).
// Sul grigio di riferimento `#7a7b80` dà `#c7c8cd` (chiaro) e `#6f7075` (scuro), come in
// menubar.md; sul bianco satura vicino a `#fcfcfd` (mustache.md MU-50).

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'glass.dart';

/// Un materiale per Flutter: σ della sfocatura in pt, matrice 3 × 3 e scostamento (0–255)
/// applicati al colore sRGB dello sfondo sfocato.
@immutable
class WindowGlassMaterial {
  const WindowGlassMaterial(this.sigma, this.matrix, this.offset);

  final double sigma;
  final List<List<double>> matrix;
  final List<double> offset;

  /// Il materiale spesso dei menu: chiaro (σ 9, b ≈ 141) e scuro (b ≈ 59).
  static const WindowGlassMaterial thickLight = WindowGlassMaterial(
    9,
    [
      [0.781, -0.200, -0.124],
      [-0.079, 0.579, -0.034],
      [-0.166, -0.263, 0.899],
    ],
    [142, 140, 140],
  );
  static const WindowGlassMaterial thickDark = WindowGlassMaterial(
    9,
    [
      [0.891, -0.347, -0.113],
      [-0.150, 0.580, 0.000],
      [-0.177, -0.391, 1.001],
    ],
    [59.4, 59.0, 58.6],
  );

  /// Il materiale per `material` e l'aspetto; per ora i menu (spesso) hanno le misure, gli
  /// altri prendono lo spesso.
  static WindowGlassMaterial of(GlassMaterial material, {required bool dark}) =>
      dark ? thickDark : thickLight;

  /// Il colore di uno sfondo uniforme visto attraverso il materiale.
  Color apply(Color background) {
    final rgb = [background.r * 255, background.g * 255, background.b * 255];
    int channel(int row) {
      var v = offset[row];
      for (var i = 0; i < 3; i++) {
        v += matrix[row][i] * rgb[i];
      }
      return v.round().clamp(0, 255);
    }

    return Color.fromARGB(255, channel(0), channel(1), channel(2));
  }

  /// Il filtro: prima la sfocatura, poi la matrice.
  ui.ImageFilter get filter => ui.ImageFilter.compose(
    outer: ui.ColorFilter.matrix([
      for (var row = 0; row < 3; row++) ...[...matrix[row], 0, offset[row]],
      0, 0, 0, 1, 0, //
    ]),
    inner: ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    ),
  );
}

/// Un pannello di vetro dentro la finestra, grande quanto il figlio, con gli angoli di raggio
/// `radius`: sfoca e tinge il contenuto dell'app che ha sotto.
class WindowGlass extends StatelessWidget {
  const WindowGlass({
    super.key,
    required this.child,
    this.radius = 0,
    this.material = GlassMaterial.thick,
    this.border,
  });

  final Widget child;
  final double radius;
  final GlassMaterial material;

  /// Il filo attorno (null: nessuno).
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: WindowGlassMaterial.of(material, dark: dark).filter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            border: border == null
                ? null
                : Border.all(color: border!, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
