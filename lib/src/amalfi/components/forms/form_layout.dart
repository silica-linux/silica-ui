// Form sections, footer and layout (kit `Forms/Section/*`, `Forms/Footer/Actions`,
// `Forms/Layout/Full`).

import 'package:flutter/widgets.dart';

import '../../foundation/foundation.dart';
import '../../smooth_border.dart';
import '../../theme.dart';
import '../../tokens.g.dart';
import '../../whole_points.dart';
import 'form_row.dart';

/// A titled group of form rows: [title] in `Headline` `Text/Secondary`, then the [rows] in a
/// `Surface/Raised` box with a 1 pt `Line/Border`, radius 12, padding 12, 12 between rows.
///
/// The section is as wide as its widest row plus the padding, or [width] when given.
class AmalfiFormSection extends StatelessWidget {
  const AmalfiFormSection({
    super.key,
    this.title,
    required this.rows,
    this.width,
  });

  final String? title;
  final List<Widget> rows;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final title = this.title;
    const pad = AmalfiFormMetrics.sectionPadding;
    final box = DecoratedBox(
      decoration: AmalfiShapeDecoration(
        color: colors.surfaceRaised,
        shape: AmalfiSmoothBorder(
          radius: AmalfiFormMetrics.sectionRadius,
          side: BorderSide(
            color: colors.lineBorder,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AmalfiFormMetrics.rowGap),
              rows[i],
            ],
          ],
        ),
      ),
    );
    final section = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              height: AmalfiType.headlineToken.lineHeight,
              child: AmalfiWholePoints(
                step: AmalfiGrid.base,
                child: Text(
                  title,
                  style: AmalfiType.headline(color: colors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AmalfiFormMetrics.sectionTitleGap),
        ],
        box,
      ],
    );
    final width = this.width;
    return Semantics(
      container: true,
      label: title,
      explicitChildNodes: true,
      child: width == null
          ? IntrinsicWidth(child: section)
          : SizedBox(width: width, child: section),
    );
  }
}

/// The buttons at the end of a form ([actions], usually Cancel then the default button),
/// aligned to the trailing edge, 8 apart.
class AmalfiFormFooter extends StatelessWidget {
  const AmalfiFormFooter({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: AmalfiFormMetrics.footerGap),
        actions[i],
      ],
    ],
  );
}

/// A whole form: [title] in `Title 3`, the [sections], then the [footer], on
/// `Surface/Window` with a 1 pt border and the window radius, [width] wide (400).
///
/// Sections take the full content width; the layout is as tall as its content.
class AmalfiFormLayout extends StatelessWidget {
  const AmalfiFormLayout({
    super.key,
    this.title,
    required this.sections,
    this.footer,
    this.width = AmalfiFormMetrics.layoutWidth,
  });

  final String? title;
  final List<Widget> sections;
  final Widget? footer;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final title = this.title;
    final footer = this.footer;
    final children = <Widget>[
      if (title != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            height: AmalfiType.title3Token.lineHeight,
            child: AmalfiWholePoints(
              step: AmalfiGrid.base,
              child: Text(
                title,
                style: AmalfiType.title3(color: colors.textPrimary),
              ),
            ),
          ),
        ),
      ...sections,
      ?footer,
    ];
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: colors.surfaceWindow,
          shape: AmalfiSmoothBorder(
            radius: AmalfiRadii.window,
            side: BorderSide(
              color: colors.lineBorder,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
        ),
        child: Padding(
          padding: AmalfiFormMetrics.layoutPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AmalfiFormMetrics.layoutGap),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
