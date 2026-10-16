// Gallery page: sliders (kit `Sliders/*`). Every variant × state, shown with their states
// set, then live sliders to drag, click and use with the keyboard.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The sliders page.
final AmalfiGalleryPage slidersPage = AmalfiGalleryPage(
  family: 'sliders',
  title: 'Sliders',
  build: (context) => const _SlidersPage(),
);

/// The kit's states as interaction states (null: disabled).
const List<(String, Set<WidgetState>?)> _states = [
  ('Rest', {}),
  ('Hover', {WidgetState.hovered}),
  ('Pressed', {WidgetState.pressed}),
  ('Focused', {WidgetState.focused}),
  ('Disabled', null),
];

/// A slider shown in fixed states, holding the controller of those states.
class _InState extends StatefulWidget {
  const _InState(this.states, this.builder);

  final Set<WidgetState> states;
  final Widget Function(WidgetStatesController states) builder;

  @override
  State<_InState> createState() => _InStateState();
}

class _InStateState extends State<_InState> {
  late final WidgetStatesController _states = WidgetStatesController(
    widget.states,
  );

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_states);
}

class _SlidersPage extends StatelessWidget {
  const _SlidersPage();

  /// The kit's speakers (Icon Kit `volume-0`, `volume-2`), or a drawn speaker when
  /// silica-icons is not installed.
  static Widget _speaker(bool loud) => AmalfiSymbol(
    loud ? 'volume-2' : 'volume-0',
    fallback: Builder(
      builder: (context) => CustomPaint(
        painter: _Speaker(
          loud: loud,
          color: IconTheme.of(context).color ?? const Color(0xFF000000),
        ),
      ),
    ),
  );

  Widget _horizontal(String variant, Set<WidgetState>? states) => _InState(
    states ?? const {},
    (controller) => SizedBox(
      width: variant == 'Glyphs' ? 248 : 200,
      child: AmalfiSlider(
        value: 0.6,
        onChanged: states == null ? null : (_) {},
        divisions: variant == 'Ticks' ? 10 : null,
        tickMarks: variant == 'Ticks',
        minimumGlyph: variant == 'Glyphs' ? _speaker(false) : null,
        maximumGlyph: variant == 'Glyphs' ? _speaker(true) : null,
        statesController: controller,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final variant in ['Plain', 'Ticks', 'Glyphs'])
        SpecimenSection(
          title: 'Horizontal · $variant',
          children: [
            for (final (name, states) in _states)
              Specimen(label: name, child: _horizontal(variant, states)),
          ],
        ),
      SpecimenSection(
        title: 'Horizontal · Dragging',
        note: 'The dragged thumb is a Glass/Clear lens.',
        children: [
          Specimen(
            label: 'Pressed',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _InState(
                const {WidgetState.dragged},
                (c) => SizedBox(
                  width: 200,
                  child: AmalfiSlider(
                    value: 0.6,
                    onChanged: (_) {},
                    statesController: c,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      SpecimenSection(
        title: 'Vertical',
        children: [
          for (final (name, states) in _states)
            Specimen(
              label: name,
              child: _InState(
                states ?? const {},
                (c) => SizedBox(
                  height: 160,
                  child: AmalfiSlider(
                    value: 0.6,
                    axis: Axis.vertical,
                    onChanged: states == null ? null : (_) {},
                    statesController: c,
                  ),
                ),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Circular',
        children: [
          for (final (name, states) in _states)
            Specimen(
              label: name,
              child: _InState(
                states ?? const {},
                (c) => AmalfiCircularSlider(
                  value: 0.625,
                  onChanged: states == null ? null : (_) {},
                  statesController: c,
                ),
              ),
            ),
        ],
      ),
      SpecimenSection(
        title: 'Thumb',
        children: [
          for (final (name, states) in _states)
            Specimen(
              label: name,
              child: AmalfiSliderThumb(
                states: states ?? const {WidgetState.disabled},
              ),
            ),
          const Specimen(
            label: 'Lens · Dragging',
            child: SizedBox(width: 36, height: 28, child: AmalfiSliderLens()),
          ),
        ],
      ),
      const SpecimenSection(
        title: 'Live',
        note: 'Drag, click the track, or focus with Tab and use the arrows.',
        children: [
          Specimen(label: 'Horizontal', child: _LiveSlider()),
          Specimen(label: 'Ticks', child: _LiveSlider(divisions: 10)),
          Specimen(
            label: 'Vertical',
            child: _LiveSlider(axis: Axis.vertical),
          ),
          Specimen(label: 'Circular', child: _LiveSlider(circular: true)),
        ],
      ),
    ],
  );
}

class _LiveSlider extends StatefulWidget {
  const _LiveSlider({
    this.divisions,
    this.axis = Axis.horizontal,
    this.circular = false,
  });

  final int? divisions;
  final Axis axis;
  final bool circular;

  @override
  State<_LiveSlider> createState() => _LiveSliderState();
}

class _LiveSliderState extends State<_LiveSlider> {
  double _value = 0.4;

  @override
  Widget build(BuildContext context) {
    void set(double v) => setState(() => _value = v);
    if (widget.circular) {
      return AmalfiCircularSlider(value: _value, onChanged: set);
    }
    final vertical = widget.axis == Axis.vertical;
    return SizedBox(
      width: vertical ? null : 200,
      height: vertical ? 160 : null,
      child: AmalfiSlider(
        value: _value,
        onChanged: set,
        axis: widget.axis,
        divisions: widget.divisions,
        tickMarks: widget.divisions != null,
      ),
    );
  }
}

/// The Icon Kit's `volume-0` (quiet) and `volume-2` (loud) speakers, drawn from their 24 pt
/// paths: the body, then one or three waves (faint in the quiet one).
class _Speaker extends CustomPainter {
  const _Speaker({required this.loud, required this.color});

  final bool loud;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 24;
    canvas.scale(k);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = Path()
      ..moveTo(3.25, 9.4)
      ..lineTo(6.1, 9.4)
      ..lineTo(10.1, 5.9)
      ..lineTo(10.1, 18.1)
      ..lineTo(6.1, 14.6)
      ..lineTo(3.25, 14.6)
      ..close();
    canvas
      ..drawPath(body, Paint()..color = color)
      ..drawPath(body, stroke);
    // Each wave: where its ends are across, half its height, its radius.
    for (final (x, h, r) in const [
      (13.18, 2.96, 4.8),
      (15.68, 6.06, 8.73),
      (18.03, 9.25, 12.65),
    ]) {
      final half = math.asin(h / r);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x - r * math.cos(half), 12), radius: r),
        -half,
        2 * half,
        false,
        stroke..color = loud ? color : color.withValues(alpha: color.a * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_Speaker old) => old.loud != loud || old.color != color;
}
