// Catalog page: containers, navigation and presentation (M6 group C). Each control in light or
// dark following the system, active window.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';
// Until the barrel is exported by `silica_ui.dart`.
import 'package:silica_ui/src/controls/containers/containers.dart';

/// The containers page; it needs an `Overlay` above it (`WidgetsApp`).
Widget containersCatalog() => const _ContainersCatalog();

class _ContainersCatalog extends StatefulWidget {
  const _ContainersCatalog();

  @override
  State<_ContainersCatalog> createState() => _ContainersCatalogState();
}

class _Row {
  const _Row(this.name, this.kind, this.size, {this.depth = 0, this.open});
  final String name;
  final String kind;
  final String size;
  final int depth;
  final bool? open;
}

class _ContainersCatalogState extends State<_ContainersCatalog> {
  String _place = 'docs';
  Set<int> _rows = {1};
  Set<int> _icons = {2};
  String _sort = 'name';
  bool _descending = false;
  bool _folderOpen = true;
  int _tab = 0;
  int _pane = 0;
  Offset _panel = const Offset(24, 40);
  bool _panelOpen = true;
  ToolbarDisplay _display = ToolbarDisplay.iconsOnly;
  final GlobalKey<PopoverAnchorState> _popover = GlobalKey();
  final List<String> _tabs = ['Documents', 'Downloads', 'Pictures'];

  static const List<TableColumnSpec> _columns = [
    TableColumnSpec(id: 'name', label: 'Name', width: 240),
    TableColumnSpec(id: 'kind', label: 'Kind', width: 121),
    TableColumnSpec(
      id: 'size',
      label: 'Size',
      width: 97,
      alignRight: true,
      descendingFirst: true,
    ),
  ];

  List<_Row> get _outline => [
    _Row('Projects', 'Folder', '--', open: _folderOpen),
    if (_folderOpen) ...const [
      _Row('silica.md', 'Markdown', '4 KB', depth: 1),
      _Row('notes.txt', 'Plain text', '1 KB', depth: 1),
    ],
    const _Row('Budget.ods', 'Spreadsheet', '18 KB'),
    const _Row('Holiday.png', 'PNG image', '2.1 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final text = dark ? const Color(0xFFE6E6E6) : const Color(0xFF262626);
    final background = dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    Widget section(String title, double height, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: uiText(
              size: 15,
              color: text,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x22000000)),
              ),
              child: ClipRect(child: child),
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: background,
      child: ScrollConfiguration(
        behavior: const SilicaScrollBehavior(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            section('Toolbar over scrolling content', 320, _toolbar(text)),
            section('Sidebar and split view', 300, _sidebar()),
            section('Table view', 200, _table()),
            section('Outline view', 160, _outlineView()),
            section('Collection view', 300, _collection()),
            section(
              'Window tabs and tab view',
              220,
              Column(
                children: [
                  WindowTabBar(
                    titles: _tabs,
                    active: _tab,
                    onSelect: (i) => setState(() => _tab = i),
                    onClose: (i) => setState(() {
                      if (_tabs.length > 1) _tabs.removeAt(i);
                      _tab = _tab.clamp(0, _tabs.length - 1);
                    }),
                    onNew: () => setState(() => _tabs.add('New tab')),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SilicaTabView(
                        labels: const ['Text', 'Window', 'Shell'],
                        selected: _pane,
                        onSelect: (i) => setState(() => _pane = i),
                        page: Text(
                          'Page ${_pane + 1}',
                          style: uiText(size: 13, color: text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            section(
              'Path control',
              28,
              PathControl(
                items: const [
                  PathItem('Disk'),
                  PathItem('Users'),
                  PathItem('me'),
                  PathItem('Documents'),
                  PathItem('A rather long folder name'),
                ],
                onSelect: (_) {},
              ),
            ),
            section('Popovers, sheets, tooltips, panels', 260, _present(text)),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(Color text) => ScrollUnderToolbar(
    toolbar: Row(
      children: [
        const SizedBox(width: 80),
        ToolbarCapsule(
          separators: true,
          children: [
            ToolbarSegment(
              icon: (c) => Text('‹', style: uiText(size: 18, color: c)),
            ),
            ToolbarSegment(
              icon: (c) => Text('›', style: uiText(size: 18, color: c)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Text(
          'Scrolls under the bar',
          style: uiText(
            size: 15,
            color: text,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
    body: (context, padding) => ListView(
      padding: padding,
      children: [
        for (var i = 0; i < 30; i++)
          Container(
            height: 40,
            color: HSVColor.fromAHSV(1, i * 24 % 360, 0.7, 0.95).toColor(),
          ),
      ],
    ),
  );

  Widget _sidebar() => SplitView(
    behavior: SplitBehavior.sidebar,
    initialSize: 192,
    divider: SplitDividerStyle.none,
    leading: SourceList(
      topInset: 24,
      selected: _place,
      onSelect: (item) => setState(() => _place = item.id),
      sections: const [
        SourceListSection('Favorites', [
          SourceListItem(id: 'home', label: 'Home', accent: false),
          SourceListItem(id: 'docs', label: 'Documents'),
          SourceListItem(id: 'down', label: 'Downloads', badge: '2'),
        ]),
        SourceListSection('Mailboxes', [
          SourceListItem(
            id: 'inbox',
            label: 'Inbox',
            badge: '12',
            children: [
              SourceListItem(id: 'work', label: 'Work'),
              SourceListItem(id: 'family', label: 'Family'),
            ],
          ),
        ]),
      ],
    ),
    trailing: const SizedBox.expand(),
  );

  Widget _table() => TableView<_Row>(
    columns: _columns,
    rows: _outline.where((r) => r.depth == 0).toList(),
    selection: _rows,
    onSelectionChanged: (s) => setState(() => _rows = s),
    sortColumn: _sort,
    descending: _descending,
    onSort: (id) => setState(() {
      _descending = id == _sort && !_descending;
      _sort = id;
    }),
    cell: (context, row, column, style) => Text(
      switch (column.id) {
        'name' => row.name,
        'kind' => row.kind,
        _ => row.size,
      },
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.text(secondary: column.id != 'name'),
    ),
  );

  Widget _outlineView() => TableView<_Row>(
    columns: _columns,
    rows: _outline,
    outline: OutlineDelegate(
      depth: (r) => r.depth,
      expandable: (r) => r.open != null,
      expanded: (r) => r.open ?? false,
      onToggle: (r, open) => setState(() => _folderOpen = open),
    ),
    cell: (context, row, column, style) => Text(
      column.id == 'name'
          ? row.name
          : (column.id == 'kind' ? row.kind : row.size),
      style: style.text(secondary: column.id != 'name'),
    ),
  );

  Widget _collection() => CollectionView<int>(
    items: [for (var i = 0; i < 14; i++) i],
    selection: _icons,
    onSelectionChanged: (s) => setState(() => _icons = s),
    label: (i) => i == 3 ? 'A file with a rather long name.txt' : 'Item $i',
    icon: (context, i, size) => DecoratedBox(
      decoration: BoxDecoration(
        color: HSVColor.fromAHSV(1, i * 40 % 360, 0.5, 0.9).toColor(),
        borderRadius: BorderRadius.circular(size / 5),
      ),
    ),
  );

  Widget _present(Color text) {
    Widget button(String label, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x14000000),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label, style: uiText(size: 13, color: text)),
      ),
    );
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PopoverAnchor(
                key: _popover,
                size: const Size(228, 160),
                builder: (context) => Center(
                  child: Text(
                    'A popover',
                    style: uiText(size: 13, color: text),
                  ),
                ),
                child: button('Popover', () => _popover.currentState?.toggle()),
              ),
              Builder(
                builder: (context) => button(
                  'Card sheet',
                  () => showWindowSheet<void>(
                    context,
                    builder: (context, sheet) => SizedBox(
                      width: 413,
                      height: 218,
                      child: Center(
                        child: GestureDetector(
                          onTap: sheet.close,
                          child: Text(
                            'Click to close',
                            style: uiText(size: 13, color: text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) => button(
                  'Customize toolbar',
                  () => showWindowSheet<void>(
                    context,
                    style: SheetStyle.attached,
                    builder: (context, sheet) => StatefulBuilder(
                      builder: (context, setSheet) => ToolbarCustomizeSheet(
                        available: [
                          for (final id in [
                            'Back/Forward',
                            'Path',
                            'Group',
                            'View',
                            'Action',
                            'Eject',
                            'Space',
                            'Flexible space',
                            'New folder',
                            'Delete',
                            'Get info',
                            'Search',
                          ])
                            ToolbarItemSpec(id: id, label: id),
                        ],
                        defaults: const [
                          ToolbarItemSpec(
                            id: 'Back/Forward',
                            label: 'Back/Forward',
                          ),
                          ToolbarItemSpec(id: 'View', label: 'View'),
                          ToolbarItemSpec(id: 'Search', label: 'Search'),
                        ],
                        inBar: const {'Back/Forward', 'View', 'Search'},
                        display: _display,
                        onDisplay: (d) => setSheet(() => _display = d),
                        onDone: sheet.close,
                      ),
                    ),
                  ),
                ),
              ),
              SilicaTooltip(
                message: 'Shows help after a second',
                child: button('Rest here', () {}),
              ),
              button('Panel', () => setState(() => _panelOpen = true)),
            ],
          ),
        ),
        if (_panelOpen)
          FloatingPanel(
            title: 'Inspector',
            size: const Size(220, 140),
            position: _panel,
            onMove: (p) => setState(() => _panel = p),
            onClose: () => setState(() => _panelOpen = false),
            child: Center(
              child: Text(
                'Drag the title',
                style: uiText(size: 13, color: text),
              ),
            ),
          ),
      ],
    );
  }
}
