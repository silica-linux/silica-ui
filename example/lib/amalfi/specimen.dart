// Building blocks of the Amalfi gallery pages: a titled section and a labelled specimen, so
// that every page lays out variants × sizes × states the same way.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

/// One page of the Amalfi gallery: a component family.
class AmalfiGalleryPage {
  const AmalfiGalleryPage({
    required this.family,
    required this.title,
    required this.build,
  });

  /// The family id, as in `docs/amalfi-checklist/<family>.md`.
  final String family;

  /// The title in the gallery.
  final String title;

  /// Builds the page content (it scrolls with the gallery).
  final WidgetBuilder build;
}

/// A titled group of specimens, laid out in a wrapping row.
class SpecimenSection extends StatelessWidget {
  const SpecimenSection({
    super.key,
    required this.title,
    required this.children,
    this.note,
  });

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AmalfiSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AmalfiType.headline(color: colors.textPrimary)),
          if (note case final note?)
            Padding(
              padding: const EdgeInsets.only(top: AmalfiSpacing.xs),
              child: Text(
                note,
                style: AmalfiType.caption(color: colors.textSecondary),
              ),
            ),
          const SizedBox(height: AmalfiSpacing.m),
          Wrap(
            spacing: AmalfiSpacing.xxl,
            runSpacing: AmalfiSpacing.l,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// A component with its label (variant, size, state) under it.
class Specimen extends StatelessWidget {
  const Specimen({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: AmalfiSpacing.s),
        Text(label, style: AmalfiType.caption(color: colors.textTertiary)),
      ],
    );
  }
}

/// The page of a family that has no components yet.
Widget pendingFamily(BuildContext context, String family) {
  final colors = AmalfiTheme.of(context).colors;
  return Text(
    'Not built yet: see docs/amalfi-checklist/$family.md.',
    style: AmalfiType.body(color: colors.textSecondary),
  );
}
