// What a widget paints, read back from the widget tree in the kit's terms (fills, borders,
// shadows, corners, blurs), so that the geometry assertions can compare it with a master.
//
// Built in: [AmalfiGlass], [DecoratedBox] / [Container] with a [ShapeDecoration] or a
// [BoxDecoration], [ColoredBox]. A family that paints its own way registers an extractor with
// [RenderedStyle.register].

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

/// A border as painted.
@immutable
class RenderedBorder {
  const RenderedBorder(this.color, this.width, this.strokeAlign);

  final Color color;
  final double width;

  /// [BorderSide.strokeAlign]: -1 inside, 0 centre, 1 outside.
  final double strokeAlign;

  @override
  String toString() => 'RenderedBorder($color, $width, align $strokeAlign)';
}

/// A background blur as painted.
@immutable
class RenderedBlur {
  const RenderedBlur(this.radius, this.saturation);

  /// σ of the Gaussian, in points (the kit's `Background` radius).
  final double radius;
  final double saturation;
}

/// The style of a painted surface, in the kit's terms.
class RenderedStyle {
  RenderedStyle({
    this.fills = const [],
    this.gradients = const [],
    this.borders = const [],
    this.shadows = const [],
    this.innerShadows = const [],
    this.radii = const [],
    this.smoothing = 0,
    this.blurs = const [],
    this.source = '',
  });

  /// Flat fills, bottom to top.
  final List<Color> fills;

  /// Gradient fills.
  final List<Gradient> gradients;
  final List<RenderedBorder> borders;

  /// Drop shadows; `blurRadius` is the kit's blur (σ = blur / 2).
  final List<BoxShadow> shadows;

  /// Inner shadows, same convention.
  final List<BoxShadow> innerShadows;

  /// Corner radii top-left, top-right, bottom-right, bottom-left (empty: square), before
  /// clamping to the size.
  final List<double> radii;
  final double smoothing;
  final List<RenderedBlur> blurs;

  /// What it was read from (for messages).
  final String source;

  static final List<RenderedStyle? Function(Widget, BuildContext)> _extractors =
      [_glass, _decorated, _colored];

  /// Adds an extractor, tried before the built-in ones: it returns the style a widget paints,
  /// or null when it does not know the widget.
  static void register(
    RenderedStyle? Function(Widget widget, BuildContext context) extractor,
  ) => _extractors.insert(0, extractor);

  /// The style painted by the first widget at or below [finder] that an extractor knows
  /// (breadth first); null when there is none.
  static RenderedStyle? of(WidgetTester tester, Finder finder) {
    final queue = <Element>[tester.element(finder)];
    while (queue.isNotEmpty) {
      final element = queue.removeAt(0);
      for (final extract in _extractors) {
        final style = extract(element.widget, element);
        if (style != null) return style;
      }
      element.visitChildren(queue.add);
    }
    return null;
  }

  static RenderedStyle? _glass(Widget widget, BuildContext context) {
    if (widget is! AmalfiGlass) return null;
    final brightness = AmalfiTheme.of(context).brightness;
    final m = widget.material;
    final rimLight = m.rimLight(brightness);
    return RenderedStyle(
      fills: [
        if (widget.opaque) AmalfiTheme.of(context).colors.surfaceWindow,
        if (m.tint(brightness) case final tint?) tint,
      ],
      borders: [
        if (m.rimInsideWidth > 0)
          RenderedBorder(
            m.rimInside(brightness),
            m.rimInsideWidth,
            BorderSide.strokeAlignInside,
          ),
      ],
      shadows: AmalfiGlass.shadowsOf(m, brightness),
      innerShadows: [
        BoxShadow(
          color: rimLight,
          offset: m.rimLightOffset,
          blurRadius: m.rimLightBlur,
        ),
      ],
      radii: List.filled(4, widget.radius),
      smoothing: AmalfiRadii.smoothing,
      blurs: [if (!widget.opaque) RenderedBlur(m.backgroundBlur, m.saturation)],
      source: 'AmalfiGlass(${m.name})',
    );
  }

  static RenderedStyle? _decorated(Widget widget, BuildContext context) {
    if (widget is! DecoratedBox ||
        widget.position != DecorationPosition.background) {
      return null;
    }
    final d = widget.decoration;
    if (d is ShapeDecoration) {
      final (radii, smoothing, side) = _shape(d.shape);
      return RenderedStyle(
        fills: [if (d.color case final c?) c],
        gradients: [if (d.gradient case final g?) g],
        borders: [
          if (side != null && side.style != BorderStyle.none && side.width > 0)
            RenderedBorder(side.color, side.width, side.strokeAlign),
        ],
        shadows: d.shadows ?? const [],
        radii: radii,
        smoothing: smoothing,
        source: 'DecoratedBox(ShapeDecoration(${d.shape.runtimeType}))',
      );
    }
    if (d is BoxDecoration) {
      final border = d.border;
      final side = border is Border && border.isUniform ? border.top : null;
      final radius = d.borderRadius?.resolve(TextDirection.ltr);
      return RenderedStyle(
        fills: [if (d.color case final c?) c],
        gradients: [if (d.gradient case final g?) g],
        borders: [
          if (side != null && side.style != BorderStyle.none && side.width > 0)
            RenderedBorder(side.color, side.width, side.strokeAlign),
        ],
        shadows: d.boxShadow ?? const [],
        radii: d.shape == BoxShape.circle
            ? List.filled(4, double.infinity)
            : radius == null
            ? const []
            : [
                radius.topLeft.x,
                radius.topRight.x,
                radius.bottomRight.x,
                radius.bottomLeft.x,
              ],
        source: 'DecoratedBox(BoxDecoration)',
      );
    }
    return null;
  }

  static RenderedStyle? _colored(Widget widget, BuildContext context) =>
      widget is ColoredBox
      ? RenderedStyle(fills: [widget.color], source: 'ColoredBox')
      : null;

  static (List<double>, double, BorderSide?) _shape(ShapeBorder shape) =>
      switch (shape) {
        AmalfiSmoothBorder(:final radius, :final smoothing, :final side) => (
          List.filled(4, radius),
          smoothing,
          side,
        ),
        StadiumBorder(:final side) ||
        CircleBorder(:final side) => (List.filled(4, double.infinity), 0, side),
        RoundedRectangleBorder(:final borderRadius, :final side) => () {
          final r = borderRadius.resolve(TextDirection.ltr);
          return (
            [r.topLeft.x, r.topRight.x, r.bottomRight.x, r.bottomLeft.x],
            0.0,
            side,
          );
        }(),
        _ => (const <double>[], 0.0, null),
      };
}
