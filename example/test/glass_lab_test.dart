import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui_example/glass_lab.dart';
import 'package:silica_ui/silica_ui.dart';

void main() {
  testWidgets('capsules can be dragged', (tester) async {
    await tester.pumpWidget(const GlassLab());
    expect(find.byType(LiquidGlass), findsNWidgets(5));
    final start = tester.getTopLeft(find.byType(LiquidGlass).first);
    await tester.drag(find.text('Network'), const Offset(30, 20));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(LiquidGlass).first),
      start + const Offset(30, 20),
    );
  });
}
