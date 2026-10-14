// Glass inside a window: a menu or popover drawn by the app over its own content. Ossido's
// glass would sit under the window surface (it would see the desktop, not the content), so here
// Flutter makes it with the same material: measured Gaussian blur and color matrix
// (ossido-render glass.rs, menubar.md › Material). On the reference gray `#7a7b80` it gives
// `#c7c8cd` (light) and `#6f7075` (dark), as in menubar.md; on white it saturates close to
// `#fcfcfd` (mustache.md MU-50).

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'glass.dart';

/// A material for Flutter: blur σ in pt, 3 × 3 matrix and offset (0–255) applied to the sRGB
/// color of the blurred background.
@immutable
class WindowGlassMaterial {
  const WindowGlassMaterial(this.sigma, this.matrix, this.offset);

  final double sigma;
  final List<List<double>> matrix;
  final List<double> offset;

  /// The thick material of menus: light (σ 9, b ≈ 141) and dark (b ≈ 59).
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

  /// The material for `material` and the appearance; for now only menus (thick) are measured,
  /// the others take the thick one.
  static WindowGlassMaterial of(GlassMaterial material, {required bool dark}) =>
      dark ? thickDark : thickLight;

  /// The color of a uniform background seen through the material.
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

  /// The filter: first the blur, then the matrix.
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

/// A glass panel inside the window, as large as its child, with corners of radius `radius`: it
/// blurs and tints the app content underneath.
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

  /// The hairline around it (null: none).
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
