import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  test(
    'Arancia is the orange, Limone Scuro the glyph yellow (silica-ui#97)',
    () {
      expect(AmalfiColors.light.paletteArancia, const Color(0xFFF98A17));
      expect(AmalfiColors.dark.paletteArancia, const Color(0xFFFF9F40));
      expect(AmalfiColors.light.paletteLimoneScuro, const Color(0xFFA67600));
      expect(AmalfiColors.dark.paletteLimoneScuro, const Color(0xFFFFCF3D));
      expect(
        AmalfiColors.light.paletteArancia,
        isNot(AmalfiColors.light.paletteLimone),
      );
    },
  );
}
