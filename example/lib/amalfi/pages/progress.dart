// Gallery page: progress (kit `Progress/*`). Bars, circular indicators and spinners in every
// size and state; the indeterminate bars and the spinners run live.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../specimen.dart';

/// The progress page.
final AmalfiGalleryPage progressPage = AmalfiGalleryPage(
  family: 'progress',
  title: 'Progress',
  build: (context) => const _ProgressPage(),
);

const List<(String, AmalfiProgressSize)> _sizes = [
  ('Small', AmalfiProgressSize.small),
  ('Regular', AmalfiProgressSize.regular),
  ('Large', AmalfiProgressSize.large),
];

const List<(String, double, bool)> _values = [
  ('25', 0.25, true),
  ('60', 0.6, true),
  ('100', 1, true),
  ('Disabled', 0.6, false),
];

/// The segment of the kit's three phases (at x 0, 64 and 132 of 200).
double _phase(double x) =>
    (x + AmalfiProgressBarMetrics.segment) /
    (AmalfiProgressBarMetrics.length + AmalfiProgressBarMetrics.segment);

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (sizeName, size) in _sizes) ...[
        SpecimenSection(
          title: 'Bar · Determinate · $sizeName',
          children: [
            for (final (name, value, enabled) in _values)
              Specimen(
                label: name,
                child: SizedBox(
                  width: 200,
                  child: AmalfiProgressBar(
                    value: value,
                    size: size,
                    enabled: enabled,
                  ),
                ),
              ),
          ],
        ),
        SpecimenSection(
          title: 'Bar · Indeterminate · $sizeName',
          children: [
            Specimen(
              label: 'Live',
              child: SizedBox(width: 200, child: AmalfiProgressBar(size: size)),
            ),
            for (final (name, x) in const [
              ('Phase 1', 0.0),
              ('Phase 2', 64.0),
              ('Phase 3', 132.0),
            ])
              Specimen(
                label: name,
                child: SizedBox(
                  width: 200,
                  child: AmalfiProgressBar(size: size, phase: _phase(x)),
                ),
              ),
            Specimen(
              label: 'Disabled',
              child: SizedBox(
                width: 200,
                child: AmalfiProgressBar(size: size, enabled: false),
              ),
            ),
          ],
        ),
      ],
      SpecimenSection(
        title: 'Circular',
        children: [
          for (final (sizeName, size) in _sizes)
            for (final (name, value, enabled) in _values)
              Specimen(
                label: '$sizeName · $name',
                child: AmalfiCircularProgress(
                  value: value,
                  size: size,
                  enabled: enabled,
                ),
              ),
        ],
      ),
      SpecimenSection(
        title: 'Spinner',
        children: [
          for (final (sizeName, size) in _sizes) ...[
            Specimen(
              label: sizeName,
              child: AmalfiSpinner(size: size),
            ),
            Specimen(
              label: '$sizeName · Disabled',
              child: AmalfiSpinner(size: size, enabled: false),
            ),
          ],
        ],
      ),
    ],
  );
}
