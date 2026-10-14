// Catalog page: buttons and toggles, in light and dark, in the active and in an inactive window.
// Hover, press and keyboard focus (Tab with full keyboard access) are live; disabled states are
// shown next to the enabled ones.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart'
    show MenuAction, MenuDivider, ToolbarScope;
// Until the coordinator exports the controls from silica_ui.dart.
import 'package:silica_ui/src/controls/buttons/buttons.dart';

/// The buttons and toggles page: four panels (light/dark × active/inactive window).
Widget buttonsCatalog() => Overlay(
  initialEntries: [
    OverlayEntry(
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final dark in [false, true])
              for (final active in [true, false])
                _Appearance(dark: dark, active: active),
          ],
        ),
      ),
    ),
  ],
);

class _Appearance extends StatelessWidget {
  const _Appearance({required this.dark, required this.active});
  final bool dark;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(
        platformBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: ToolbarScope(
        active: active,
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF272727) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark ? const Color(0xFF3D3D3D) : const Color(0xFFDDDDDD),
            ),
          ),
          child: _Panel(
            title:
                '${dark ? 'Dark' : 'Light'} · '
                '${active ? 'active window' : 'inactive window'}',
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatefulWidget {
  const _Panel({required this.title});
  final String title;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  bool? _check = true;
  bool _check2 = false;
  String _radio = 'a';
  bool _switch = true;
  bool _toggle = false;
  bool _triangle = false;
  bool _disclosure = false;
  int _section = 0;
  Set<int> _styles = {0};
  String _sound = 'radial';
  final TextEditingController _city = TextEditingController(text: 'Rome');

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Widget _row(String label, List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: controlTextStyle(
              ControlSize.small,
              ControlColors.of(context).labelDisabled,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = ControlColors.of(context);
    Widget glyph(Color c) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: c, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: controlTextStyle(
            ControlSize.regular,
            colors.label,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _row('Push', [
          SilicaButton(label: 'Cancel', minWidth: 80, onPressed: () {}),
          SilicaButton(
            label: 'OK',
            role: ButtonRole.primary,
            minWidth: 80,
            onPressed: () {},
          ),
          SilicaButton(
            label: 'Delete',
            role: ButtonRole.destructive,
            onPressed: () {},
          ),
          const SilicaButton(label: 'Disabled', onPressed: null),
        ]),
        _row('Sizes', [
          for (final size in ControlSize.values)
            SilicaButton(label: size.name, size: size, onPressed: () {}),
        ]),
        _row('Bezels', [
          SilicaButton(
            label: 'Bevel',
            bezel: ButtonBezel.bevel,
            onPressed: () {},
          ),
          SilicaButton(
            label: 'Borderless',
            bezel: ButtonBezel.borderless,
            onPressed: () {},
          ),
          SilicaButton(
            icon: glyph,
            bezel: ButtonBezel.circle,
            semanticLabel: 'Round',
            onPressed: () {},
          ),
          HelpButton(onPressed: () {}),
          const HelpButton(onPressed: null),
        ]),
        _row('Toggle, image', [
          ToggleButton(
            label: '2nd',
            value: _toggle,
            onChanged: (v) => setState(() => _toggle = v),
          ),
          ImageButton(semanticLabel: 'Play', icon: glyph, onPressed: () {}),
          ImageButton(semanticLabel: 'Previous', icon: glyph, onPressed: null),
        ]),
        _row('Disclosure', [
          DisclosureTriangle(
            expanded: _triangle,
            onChanged: (v) => setState(() => _triangle = v),
          ),
          const DisclosureTriangle(expanded: true, onChanged: null),
          DisclosureButton(
            expanded: _disclosure,
            onChanged: (v) => setState(() => _disclosure = v),
          ),
        ]),
        _row('Checkbox', [
          SilicaCheckbox(
            value: _check,
            label: 'Mixed → on',
            onChanged: (v) => setState(() => _check = v),
          ),
          SilicaCheckbox(
            value: _check2,
            label: 'Snooze',
            onChanged: (v) => setState(() => _check2 = v),
          ),
          const SilicaCheckbox(value: null, onChanged: null),
          const SilicaCheckbox(value: true, label: 'Off', onChanged: null),
        ]),
        _row('Radio', [
          SilicaRadioGroup<String>(
            direction: Axis.horizontal,
            spacing: 12,
            value: _radio,
            onChanged: (v) => setState(() => _radio = v),
            options: const [
              RadioOption('a', 'One'),
              RadioOption('b', 'Two'),
              RadioOption('c', 'Three', enabled: false),
            ],
          ),
        ]),
        _row('Switch', [
          for (final size in ControlSize.values)
            SilicaSwitch(
              value: _switch,
              size: size,
              onChanged: (v) => setState(() => _switch = v),
            ),
          const SilicaSwitch(value: false, onChanged: null),
        ]),
        _row('Segmented', [
          SegmentedControl(
            segments: const [
              Segment(label: 'World'),
              Segment(label: 'Alarms'),
              Segment(label: 'Stopwatch'),
              Segment(label: 'Timer'),
            ],
            size: ControlSize.large,
            selected: {_section},
            onChanged: (i) => setState(() => _section = i),
          ),
          SegmentedControl(
            segments: const [
              Segment(label: 'B'),
              Segment(label: 'I'),
              Segment(label: 'U'),
              Segment(label: 'S', enabled: false),
            ],
            mode: SegmentedMode.selectAny,
            selected: _styles,
            onChanged: (i) => setState(
              () => _styles = _styles.contains(i)
                  ? ({..._styles}..remove(i))
                  : {..._styles, i},
            ),
          ),
          SegmentedControl(
            segments: const [
              Segment(label: '‹', semanticLabel: 'Previous'),
              Segment(label: '›', semanticLabel: 'Next'),
            ],
            mode: SegmentedMode.momentary,
            size: ControlSize.small,
            onChanged: (_) {},
          ),
        ]),
        _row('Menus', [
          PopUpButton<String>(
            width: 160,
            value: _sound,
            onChanged: (v) => setState(() => _sound = v),
            items: const [
              PopUpItem('radial', 'Radial'),
              PopUpItem('chime', 'Chime'),
              PopUpItem('pulse', 'Pulse'),
            ],
          ),
          PullDownButton(
            title: 'Group',
            entries: [
              MenuAction('By name', onSelected: () {}),
              MenuAction('By kind', onSelected: () {}),
              const MenuDivider(),
              const MenuAction('None'),
            ],
          ),
          const PullDownButton(
            title: 'Disabled',
            enabled: false,
            entries: [MenuAction('A')],
          ),
          ComboBox(
            controller: _city,
            items: const ['Rome', 'Milan', 'Naples', 'Amalfi'],
          ),
        ]),
      ],
    );
  }
}
