// Forms against the kit (`Forms/*`): rows, sections, footer and the full layout, in geometry
// and pixels; the nested buttons and toggles are this family's stand-ins until those
// families land. Checklist: docs/amalfi-checklist/forms.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_ui/src/amalfi/components/forms/stand_ins.dart';

import 'support/harness.dart';

/// The shape tolerance of the forms (as the fields': the borders' antialiased edges).
const KitPixelTolerance formsShapes = KitPixelTolerance(mean: 1.25, max: 128);

/// The text tolerance of the forms (CoreText draws Inter heavier than Skia; light text on
/// the transparent canvas of the dark rows feels it most: 3.3 on the switch row).
const KitPixelTolerance formsText = KitPixelTolerance(mean: 3.5, max: 255);

final Finder valueColumn = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_ControlWithMessage',
);

/// The label's text box (the 112 pt wide box, centred on the row's first line).
Finder labelBox(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(SizedBox)).first;

/// The label cell (112 × 28).
Finder labelCell(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(SizedBox)).at(1);

Widget field(String text, {String? error}) => AmalfiTextField(
  controller: TextEditingController(text: text),
  errorText: error,
);

const String help = 'This name is shown to people you share with.';
const String invalid = 'Enter an address such as name@example.com.';

/// Kit defect: Sketch did not resize the row instances to their content (rows 332, 300, 272,
/// 428 wide for 324, 292, 248, 324 of content): our rows are as wide as their content.
const String instanceWidth = 'kit row instance not resized to its content';

/// Kit defect: the check rows put the 20 pt checkbox at the top of the 28 pt line, 4 above
/// the label's centre; ours is centred on the line.
const String checkTop =
    'kit checkbox at the top of the 28 pt line, ours centred';

/// The kit's title frames are CoreText's width rounded to the grid; Skia measures these
/// semibold titles a few tenths of a point apart, which rounds to the next grid step.
const String titleWidth =
    'title text measured by CoreText, rounded to another grid step';

class FormCase {
  FormCase(
    this.key,
    this.widget,
    this.layers, {
    this.deviations = const {},
    this.maskLayers = const [],
    this.mask = const [],
  });

  final String key;
  final Widget widget;
  final Map<String, Finder> layers;
  final Map<String, String> deviations;
  final List<String> maskLayers;
  final List<Rect> mask;
}

Widget profile({double? width = 356}) => AmalfiFormSection(
  title: 'Profile',
  width: width,
  rows: [
    AmalfiFormRow(label: 'Name:', control: field('Marta Esposito')),
    AmalfiFormRow(label: 'Email:', control: field('marta@example.it')),
    AmalfiFormRow(
      label: 'Region:',
      control: const StandInPopUpButton(value: 'Lemon'),
    ),
  ],
);

Widget preferences() => const AmalfiFormSection(
  title: 'Preferences',
  width: 324,
  rows: [
    AmalfiFormRow(
      label: 'Options:',
      control: StandInCheckbox(label: 'Send me updates', value: true),
    ),
    AmalfiFormRow(
      control: StandInCheckbox(label: 'Keep me signed in', value: true),
    ),
  ],
);

Widget validation({double? width = 452}) => AmalfiFormSection(
  title: 'Validation',
  width: width,
  rows: [
    AmalfiFormRow(
      label: 'Display name:',
      control: field('Marta'),
      message: help,
    ),
    AmalfiFormRow(
      label: 'Email:',
      control: field('marta@example', error: 'invalid'),
      message: invalid,
      messageKind: AmalfiFormMessageKind.error,
    ),
  ],
);

Widget footer() => const AmalfiFormFooter(
  actions: [
    StandInPushButton(label: 'Cancel'),
    StandInPushButton(label: 'Save', primary: true),
  ],
);

final Finder rows = find.byType(AmalfiFormRow);
final Finder sectionBox = find
    .descendant(
      of: find.byType(AmalfiFormSection),
      matching: find.byType(DecoratedBox),
    )
    .first;

List<FormCase> cases() => [
  FormCase(
    'Forms/Row/Text/Rest',
    AmalfiFormRow(label: 'Label', control: field('Amalfi coast')),
    {
      'Label cell': labelCell('Label'),
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiTextField),
    },
  ),
  FormCase(
    'Forms/Row/Popup/Rest',
    const AmalfiFormRow(
      label: 'Label',
      control: StandInPopUpButton(value: 'Lemon'),
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(StandInPopUpButton),
    },
  ),
  FormCase(
    'Forms/Row/Check/Rest',
    const AmalfiFormRow(
      label: 'Label',
      control: SizedBox(
        width: 168,
        child: StandInCheckbox(label: 'Send me updates', value: true),
      ),
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(StandInCheckbox),
    },
    deviations: {'Value': checkTop, 'Value/Control': checkTop},
    mask: const [Rect.fromLTWH(124, 0, 168, 28)],
  ),
  FormCase(
    'Forms/Row/Switch/Rest',
    const AmalfiFormRow(
      label: 'Label',
      control: StandInSwitch(
        label: 'Sync across devices',
        value: true,
        width: 256,
      ),
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(StandInSwitch),
    },
  ),
  FormCase(
    'Forms/Row/Help/Rest',
    AmalfiFormRow(
      label: 'Label',
      control: field('Amalfi coast'),
      message: help,
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiTextField),
      'Value/Message': find.text(help),
    },
  ),
  FormCase(
    'Forms/Row/Error/Rest',
    AmalfiFormRow(
      label: 'Label',
      control: field('Amalfi coast', error: 'invalid'),
      message: invalid,
      messageKind: AmalfiFormMessageKind.error,
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiTextField),
      'Value/Message': find.text(invalid),
    },
  ),
  FormCase('Forms/Footer/Actions/Rest', SizedBox(width: 352, child: footer()), {
    'Cancel': find.byType(StandInPushButton).at(0),
    'Save': find.byType(StandInPushButton).at(1),
  }),
  FormCase(
    'Forms/Section/Profile/Rest',
    profile(),
    {
      'Title': find.byType(AmalfiWholePoints).first,
      'Group': sectionBox,
      'Group/Surface': sectionBox,
      'Group/Name Text': rows.at(0),
      'Group/Email Text': rows.at(1),
      'Group/Region Popup': rows.at(2),
    },
    deviations: {
      'Title': titleWidth,
      'Group/Name Text': instanceWidth,
      'Group/Email Text': instanceWidth,
      'Group/Region Popup': instanceWidth,
    },
  ),
  FormCase(
    'Forms/Section/Preferences/Rest',
    preferences(),
    {
      'Title': find.byType(AmalfiWholePoints).first,
      'Group/Surface': sectionBox,
      'Group/Options Check': rows.at(0),
      'Group/Sign-in Check': rows.at(1),
    },
    deviations: {'Group/Options Check': instanceWidth},
    mask: const [Rect.fromLTWH(136, 36, 188, 68)],
  ),
  FormCase(
    'Forms/Section/Validation/Rest',
    validation(),
    {
      'Title': find.byType(AmalfiWholePoints).first,
      'Group/Surface': sectionBox,
      'Group/Display name Help': rows.at(0),
      'Group/Email Error': rows.at(1),
    },
    deviations: {
      'Group/Display name Help': instanceWidth,
      'Group/Email Error': instanceWidth,
    },
  ),
  FormCase(
    'Forms/Layout/Full/Rest',
    AmalfiFormLayout(
      title: 'Account details',
      sections: [profile(width: null), validation(width: null)],
      footer: footer(),
    ),
    {
      'Surface': find
          .descendant(
            of: find.byType(AmalfiFormLayout),
            matching: find.byType(DecoratedBox),
          )
          .first,
      'Title': find.byType(AmalfiWholePoints).first,
      'Profile': find.byType(AmalfiFormSection).at(0),
      'Validation': find.byType(AmalfiFormSection).at(1),
      'Footer': find.byType(AmalfiFormFooter),
    },
    deviations: {
      'Title': titleWidth,
      'Profile': 'kit section 372 wide in a 352 pt content column',
      'Validation': 'kit section 452 wide: it overflows the 400 pt layout',
    },
    maskLayers: const ['Profile', 'Validation'],
  ),
];

/// Where the master's origin is in its PNG: Sketch exports some masters clipped to their
/// frame (the halo and the shadows of nested controls cut off); for those the origin is the
/// PNG's corner, not `-renderBounds.topLeft`.
Offset? pngOrigin(KitMaster master) {
  final bytes = master.png.readAsBytesSync();
  final data = ByteData.sublistView(bytes, 16, 24);
  final clipped =
      data.getUint32(0) == (master.size.width * 2).round() &&
      data.getUint32(4) == (master.size.height * 2).round();
  return clipped ? Offset.zero : null;
}

void main() {
  setUpAll(loadAmalfiFonts);

  for (final appearance in ['Light', 'Dark']) {
    group('kit $appearance', () {
      for (final c in cases()) {
        testWidgets(c.key, (tester) async {
          final master = KitMaster.load('${c.key}/$appearance');
          final root = await pumpKitScene(tester, c.widget, master: master);
          expectKitGeometry(
            tester,
            master,
            root: root,
            layers: c.layers,
            deviations: c.deviations,
          );
          await expectKitPixels(
            tester,
            master,
            c.widget,
            tolerance: formsShapes,
            maskText: true,
            origin: pngOrigin(master),
            maskLayers: c.maskLayers,
            mask: c.mask,
          );
          await expectKitPixels(
            tester,
            master,
            c.widget,
            tolerance: formsText,
            origin: pngOrigin(master),
            maskLayers: c.maskLayers,
            mask: c.mask,
          );
        });
      }
    });
  }

  group('behaviour', () {
    testWidgets('the message wraps to the control width', (tester) async {
      await pumpKitScene(
        tester,
        AmalfiFormRow(label: 'Name:', control: field('Marta'), message: help),
      );
      expect(tester.getSize(find.text(help)).width, AmalfiFieldMetrics.width);
      expect(tester.getTopLeft(find.text(help)).dy, 28 + 4);
    });

    testWidgets('a section without a width is as wide as its widest row', (
      tester,
    ) async {
      await pumpKitScene(tester, profile(width: null));
      expect(
        tester.getSize(find.byType(AmalfiFormSection)).width,
        12 + 112 + 12 + 200 + 12,
      );
    });

    testWidgets('the layout is as tall as its content, on the grid', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        AmalfiFormLayout(
          title: 'Account details',
          sections: [profile(width: null), validation(width: null)],
          footer: footer(),
        ),
      );
      expect(
        tester.getSize(find.byType(AmalfiFormLayout)),
        const Size(400, 496),
      );
    });

    testWidgets('fields in a form take focus with Tab', (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF0E77E6),
          builder: (context, _) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.topLeft,
                  child: profile(width: null),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Marta Esposito'));
      await tester.pump();
      FocusNode node(int i) => tester
          .widget<EditableText>(find.byType(EditableText).at(i))
          .focusNode;
      expect(node(0).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node(1).hasFocus, isTrue);
    });
  });
}
