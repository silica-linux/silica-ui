// The silica_ui catalog: every control group in one window, with a source list on the left
// and the glass toolbar over the scrolling page. The toolbar switches the appearance and the
// window state (following the real window, or forced active or inactive).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'catalog/buttons.dart';
import 'catalog/containers.dart';
import 'catalog/inputs.dart';
import 'glass_lab.dart';

void main() => runApp(const Catalog());

/// Which window state the catalog shows.
enum WindowMode { follow, active, inactive }

class Catalog extends StatelessWidget {
  const Catalog({super.key});

  // WidgetsApp gives the overlay (menus, popovers, sheets) and the text editing shortcuts.
  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: ControlPalette.accent,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    home: const _CatalogWindow(),
  );
}

class _CatalogWindow extends StatefulWidget {
  const _CatalogWindow();

  @override
  State<_CatalogWindow> createState() => _CatalogWindowState();
}

class _CatalogWindowState extends State<_CatalogWindow> {
  String _page = 'buttons';
  bool? _dark;
  WindowMode _window = WindowMode.follow;

  static const _pages = {
    'buttons': 'Buttons',
    'inputs': 'Inputs',
    'containers': 'Containers',
    'glass': 'Glass lab',
  };

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: ControlPalette.accent,
    debugShowCheckedModeBanner: false,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      final dark = _dark ?? media.platformBrightness == Brightness.dark;
      final page = MediaQuery(
        data: media.copyWith(
          platformBrightness: dark ? Brightness.dark : Brightness.light,
        ),
        child: Builder(builder: (context) => _window_(context, dark)),
      );
      return switch (_window) {
        WindowMode.follow => WindowActiveScope.follow(child: page),
        WindowMode.active => WindowActiveScope(active: true, child: page),
        WindowMode.inactive => WindowActiveScope(active: false, child: page),
      };
    },
  );

  Widget _window_(BuildContext context, bool dark) {
    final active = WindowActiveScope.of(context);
    return ToolbarScope(
      active: active,
      child: ColoredBox(
        color: dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        child: SplitView(
          behavior: SplitBehavior.sidebar,
          initialSize: 192,
          divider: SplitDividerStyle.none,
          leading: SourceList(
            selected: _page,
            onSelect: (item) => setState(() => _page = item.id),
            sections: [
              SourceListSection('Controls', [
                for (final id in ['buttons', 'inputs', 'containers'])
                  SourceListItem(id: id, label: _pages[id]!),
              ]),
              SourceListSection('Lab', [
                SourceListItem(id: 'glass', label: _pages['glass']!),
              ]),
            ],
          ),
          trailing: ScrollUnderToolbar(
            toolbar: _toolbar(dark),
            body: (context, padding) => KeyedSubtree(
              key: ValueKey(_page),
              child: switch (_page) {
                'inputs' => inputsCatalog(inset: padding),
                'containers' => containersCatalog(inset: padding),
                'glass' => Padding(padding: padding, child: const GlassLab()),
                _ => buttonsCatalog(inset: padding),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar(bool dark) => Row(
    children: [
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          _pages[_page]!,
          overflow: TextOverflow.ellipsis,
          style: uiText(
            size: 15,
            color: dark ? const Color(0xFFE6E6E6) : const Color(0xFF262626),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      SegmentedControl(
        segments: const [
          Segment(label: 'Light'),
          Segment(label: 'Dark'),
        ],
        selected: {dark ? 1 : 0},
        onChanged: (i) => setState(() => _dark = i == 1),
      ),
      const SizedBox(width: 12),
      PopUpButton<WindowMode>(
        width: 150,
        items: const [
          PopUpItem(WindowMode.follow, 'Follow the window'),
          PopUpItem(WindowMode.active, 'Active window'),
          PopUpItem(WindowMode.inactive, 'Inactive window'),
        ],
        value: _window,
        onChanged: (mode) => setState(() => _window = mode),
      ),
      const SizedBox(width: 16),
    ],
  );
}
