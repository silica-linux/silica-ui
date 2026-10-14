// Liquid Glass lab (M2 bis): regular glass capsules on a transparent window. They can be
// dragged, swell when pressed, and merge like drops when close (Ossido computes the merging
// and the lens). The desktop shows behind the window.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

void main() => runApp(const GlassLab());

const Size capsule = Size(140, 56);

class GlassLab extends StatefulWidget {
  const GlassLab({super.key});

  @override
  State<GlassLab> createState() => _GlassLabState();
}

class _GlassLabState extends State<GlassLab> {
  final List<Offset> positions = [
    const Offset(40, 60),
    const Offset(230, 60),
    const Offset(420, 60),
    const Offset(135, 180),
    const Offset(325, 180),
  ];
  final List<String> labels = [
    'Rete',
    'Bluetooth',
    'Condividi',
    'Luce',
    'Suono',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          for (var i = 0; i < positions.length; i++)
            Positioned(
              left: positions[i].dx,
              top: positions[i].dy,
              width: capsule.width,
              height: capsule.height,
              child: GestureDetector(
                onPanUpdate: (details) =>
                    setState(() => positions[i] += details.delta),
                child: LiquidGlass(
                  radius: capsule.height / 2,
                  child: Center(
                    child: Text(
                      labels[i],
                      style: uiText(size: 15, color: const Color(0xFF1D1D1F)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
