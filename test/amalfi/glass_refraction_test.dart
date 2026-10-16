// The edge refraction of AmalfiGlass Regular and Thick (Flutter backend): the shader runs as a
// backdrop filter where the engine supports it, with the material's tokens as uniforms; without
// it the blurred backdrop is toned with colour filters only.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/glass_refraction.dart';

Widget _glass(AmalfiGlassMaterial material, {Brightness? brightness}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: AmalfiTheme(
        brightness: brightness ?? Brightness.light,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: AmalfiGlass(material: material, radius: 20),
          ),
        ),
      ),
    );

void main() {
  tearDown(() {
    GlassLens.debugRefractionSupportedOverride = null;
    GlassLens.debugShaderFilter = null;
    AmalfiGlassRefraction.debugReset();
  });

  testWidgets('without shader filters: no refraction layer', (tester) async {
    await tester.pumpWidget(_glass(AmalfiMaterials.regular));
    expect(find.byType(AmalfiGlassRefractionLayer), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  for (final (material, brightness, expected) in [
    (
      AmalfiMaterials.regular,
      Brightness.light,
      <double>[0.3, 0.35, 0.03, 1.1, 1.25],
    ),
    (
      AmalfiMaterials.regular,
      Brightness.dark,
      <double>[0.3, 0.35, 0.03, 1.1, 1.1],
    ),
    (
      AmalfiMaterials.thick,
      Brightness.light,
      <double>[0.22, 0.28, 0.015, 1.1, 1.12],
    ),
    (
      AmalfiMaterials.thick,
      Brightness.dark,
      <double>[0.22, 0.28, 0.015, 1.1, 1.05],
    ),
  ]) {
    testWidgets('${material.name} $brightness: shader uniforms', (
      tester,
    ) async {
      GlassLens.debugRefractionSupportedOverride = true;
      GlassLens.debugShaderFilter = (_) =>
          ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1);
      expect(await tester.runAsync(AmalfiGlassRefraction.load), isNotNull);
      await tester.pumpWidget(_glass(material, brightness: brightness));
      await tester.pump();
      await tester.pump();
      final box = tester.renderObject<RenderAmalfiGlassRefraction>(
        find.byType(AmalfiGlassRefractionLayer),
      );
      final u = box.debugUniforms;
      // centre x, y, half w, half h (physical px), pt, radius.
      expect(u.sublist(2, 4), [300, 150]); // dpr 3
      expect(u[4], 3);
      expect(u[5], 20);
      expect(u.sublist(6, 11), expected);
      expect(u[11], greaterThan(0));
    });
  }

  testWidgets('Clear glass does not refract', (tester) async {
    GlassLens.debugRefractionSupportedOverride = true;
    GlassLens.debugShaderFilter = (_) =>
        ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1);
    await tester.runAsync(AmalfiGlassRefraction.load);
    await tester.pumpWidget(_glass(AmalfiMaterials.clear));
    await tester.pump();
    expect(find.byType(AmalfiGlassRefractionLayer), findsNothing);
  });
}
