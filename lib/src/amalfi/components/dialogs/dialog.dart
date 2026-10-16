// The Amalfi dialog layouts (kit `Dialogs/Dialog/Save Panel|Open Panel|Generic`,
// `Dialogs/Browser/Files`, `Dialogs/Footer/Open|Save`). Layout only: what the rows do (the
// file dialog logic) stays with the code that fills them.
//
// A panel (the file dialogs, 600 wide) has 20 of padding and 12 between its rows; a generic
// dialog (400 wide) has 24 and 20, the padding of documents and settings. The title sits 2
// below the padding (a 24 pt row holding the 22 pt Title 3 line at its bottom).

import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import '../alerts/alert_surface.dart';

/// The two layouts of a dialog.
enum AmalfiDialogLayout {
  /// File panels (`Dialogs/Dialog/Save Panel|Open Panel`): 600 wide, padding 20, rows 12
  /// apart.
  panel(width: 600, padding: 20, gap: 12),

  /// Other dialogs (`Dialogs/Dialog/Generic`): 400 wide, padding 24, rows 20 apart.
  generic(width: 400, padding: 24, gap: 20);

  const AmalfiDialogLayout({
    required this.width,
    required this.padding,
    required this.gap,
  });

  /// The default width.
  final double width;

  /// The space around the content.
  final double padding;

  /// The space between the title, the rows and the footer.
  final double gap;
}

/// The measures of dialogs, from the kit masters `Dialogs/*`.
abstract final class AmalfiDialogMetrics {
  /// The corner radius (radius 20, as alerts and sheets).
  static const double radius = AmalfiRadii.sheetAlert;

  /// The space above the title's line inside its 24 pt row.
  static const double titleInset = 2;

  /// The space between the footer's buttons.
  static const double footerGap = 8;

  /// The space between the places and the files of a browser.
  static const double browserGap = 16;

  /// The width of the places pane of a browser.
  static const double placesWidth = 216;

  /// The height of a browser.
  static const double browserHeight = 152;

  /// The padding inside the panes of a browser.
  static const double paneInset = 8;

  /// The corner radius of the places pane.
  static const double placesRadius = AmalfiRadii.sidebarInsetPanel;

  /// The corner radius of the files pane.
  static const double filesRadius = 12;
}

/// A dialog: [title] in Title 3 `Text/Primary`, the [children] rows and a [footer], on an
/// opaque raised surface with radius 20, laid out as [layout].
class AmalfiDialog extends StatelessWidget {
  const AmalfiDialog({
    super.key,
    required this.title,
    this.children = const [],
    this.footer,
    this.layout = AmalfiDialogLayout.panel,
    this.width,
  });

  final String title;

  /// The rows between the title and the footer.
  final List<Widget> children;

  /// The buttons row ([AmalfiDialogFooter]); null: none.
  final Widget? footer;

  final AmalfiDialogLayout layout;

  /// The width; null: the layout's.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: AmalfiDialogMetrics.titleInset),
        child: Semantics(
          header: true,
          // The title's box is as tall as its line and as wide as its text rounded up to
          // the 4 pt grid ("Open recipe" 96, "Share recipe" 100).
          child: IntrinsicWidth(
            stepWidth: AmalfiGrid.base,
            child: Text(
              title,
              style: AmalfiType.title3(
                color: AmalfiTheme.of(context).colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
      ...children,
      ?footer,
    ];
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: SizedBox(
        width: width ?? layout.width,
        child: AmalfiAlertSurface(
          radius: AmalfiDialogMetrics.radius,
          child: Padding(
            padding: EdgeInsets.all(layout.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) SizedBox(height: layout.gap),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The buttons row of a dialog (kit `Dialogs/Footer/Open|Save`): [leading] buttons (New
/// Folder) at the leading end, [actions] (Cancel, then the default button) at the trailing
/// end, 8 apart.
class AmalfiDialogFooter extends StatelessWidget {
  const AmalfiDialogFooter({
    super.key,
    this.leading = const [],
    this.actions = const [],
  });

  final List<Widget> leading;

  /// The buttons at the trailing end, the default one last.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    List<Widget> spaced(List<Widget> items) => [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: AmalfiDialogMetrics.footerGap),
        items[i],
      ],
    ];
    return Row(
      children: [
        ...spaced(leading),
        if (leading.isNotEmpty)
          const SizedBox(width: AmalfiDialogMetrics.footerGap),
        const Spacer(),
        if (actions.isNotEmpty)
          const SizedBox(width: AmalfiDialogMetrics.footerGap),
        ...spaced(actions),
      ],
    );
  }
}

/// The browser of a file dialog (kit `Dialogs/Browser/Files`): the [places] pane (216 wide,
/// `Surface/Sidebar`, radius 14) and the [files] pane (the rest, `Surface/Raised`, radius
/// 12), both with a `Line/Border` rim and 8 of padding, 16 apart, [height] tall.
class AmalfiDialogBrowser extends StatelessWidget {
  const AmalfiDialogBrowser({
    super.key,
    required this.places,
    required this.files,
    this.height = AmalfiDialogMetrics.browserHeight,
  });

  /// The sidebar of places (a sidebar group).
  final Widget places;

  /// The list of files.
  final Widget files;

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    Widget pane(Widget child, Color color, double radius) => AmalfiAlertSurface(
      radius: radius,
      color: color,
      shadow: false,
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.all(AmalfiDialogMetrics.paneInset),
          child: child,
        ),
      ),
    );
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AmalfiDialogMetrics.placesWidth,
            child: pane(
              places,
              colors.surfaceSidebar,
              AmalfiDialogMetrics.placesRadius,
            ),
          ),
          const SizedBox(width: AmalfiDialogMetrics.browserGap),
          Expanded(
            child: pane(
              files,
              colors.surfaceRaised,
              AmalfiDialogMetrics.filesRadius,
            ),
          ),
        ],
      ),
    );
  }
}
