// Forms against the kit (`Forms/*`): rows, sections, footer and the full layout, in geometry
// and pixels, with the real nested buttons, fields and toggles. Checklist:
// docs/amalfi-checklist/forms.md.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';

import 'support/harness.dart';

/// The shape tolerance of the forms: the borders' antialiased edges and the pop-up's
/// chevron (measured with the real nested controls: mean ≤ 0.72, max 106 on the pop-up).
const KitPixelTolerance formsShapes = KitPixelTolerance(mean: 1, max: 112);

/// The text tolerance of the forms (CoreText draws Inter heavier than Skia; light text on
/// the transparent canvas of the dark rows feels it most).
const KitPixelTolerance formsText = KitPixelTolerance(mean: 3.5, max: 255);

/// The dark switch row: two lines of light text on a transparent canvas and little else
/// (measured mean 3.81 with the real labelled switch; its pixels match with text masked).
const KitPixelTolerance switchRowText = KitPixelTolerance(mean: 4, max: 255);

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

Widget popUp() => AmalfiPopUpButton<String>(
  items: const [
    AmalfiPopUpItem(value: 'Lemon', label: 'Lemon'),
    AmalfiPopUpItem(value: 'Olive', label: 'Olive'),
  ],
  value: 'Lemon',
  onChanged: (_) {},
);

Widget checkbox(String label) =>
    AmalfiCheckbox(label: label, value: true, onChanged: (_) {});

Widget pushButton(String label, {bool primary = false}) => AmalfiPushButton(
  label: label,
  variant: primary
      ? AmalfiPushButtonVariant.primary
      : AmalfiPushButtonVariant.secondary,
  onPressed: () {},
);

const String help = 'This name is shown to people you share with.';
const String invalid = 'Enter an address such as name@example.com.';

/// Kit defect: the check rows put the 20 pt checkbox at the top of the 28 pt line, 4 above
/// the label's centre; ours is centred on the line.
const String checkTop =
    'kit checkbox at the top of the 28 pt line, ours centred';

/// Kit defect: the check row's checkbox instance is 168 wide, not resized to its label
/// ("Send me updates": 148, as `Toggles/Checkbox/With Label` measures it).
const String checkWidth = 'kit checkbox instance not resized to its label';

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
    this.textTolerance = formsText,
  });

  final String key;
  final Widget widget;
  final Map<String, Finder> layers;
  final Map<String, String> deviations;
  final List<String> maskLayers;
  final List<Rect> mask;
  final KitPixelTolerance textTolerance;
}

Widget profile() => AmalfiFormSection(
  title: 'Profile',
  rows: [
    AmalfiFormRow(
      label: 'Name:',
      expand: true,
      control: field('Marta Esposito'),
    ),
    AmalfiFormRow(
      label: 'Email:',
      expand: true,
      control: field('marta@example.it'),
    ),
    AmalfiFormRow(label: 'Region:', control: popUp()),
  ],
);

Widget preferences() => AmalfiFormSection(
  title: 'Preferences',
  rows: [
    AmalfiFormRow(label: 'Options:', control: checkbox('Send me updates')),
    AmalfiFormRow(control: checkbox('Keep me signed in')),
  ],
);

Widget validation() => AmalfiFormSection(
  title: 'Validation',
  rows: [
    AmalfiFormRow(
      label: 'Display name:',
      expand: true,
      control: field('Marta'),
      message: help,
    ),
    AmalfiFormRow(
      label: 'Email:',
      expand: true,
      control: field('marta@example', error: 'invalid'),
      message: invalid,
      messageKind: AmalfiFormMessageKind.error,
    ),
  ],
);

Widget footer() => AmalfiFormFooter(
  actions: [pushButton('Cancel'), pushButton('Save', primary: true)],
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
    AmalfiFormRow(label: 'Label', expand: true, control: field('Amalfi coast')),
    {
      'Label cell': labelCell('Label'),
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiTextField),
    },
  ),
  FormCase(
    'Forms/Row/Popup/Rest',
    AmalfiFormRow(label: 'Label', control: popUp()),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiPopUpButton<String>),
    },
  ),
  FormCase(
    'Forms/Row/Check/Rest',
    AmalfiFormRow(label: 'Label', control: checkbox('Send me updates')),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiCheckbox),
    },
    deviations: {
      '#frame': checkWidth,
      'Value': checkTop,
      'Value/Control': checkTop,
    },
    mask: const [Rect.fromLTWH(124, 0, 168, 28)],
  ),
  FormCase(
    'Forms/Row/Switch/Rest',
    AmalfiFormRow(
      label: 'Label',
      expand: true,
      control: AmalfiSwitch(
        label: 'Sync across devices',
        value: true,
        onChanged: (_) {},
      ),
    ),
    {
      'Label cell/Label': labelBox('Label'),
      'Value': valueColumn,
      'Value/Control': find.byType(AmalfiSwitch),
    },
    textTolerance: switchRowText,
  ),
  FormCase(
    'Forms/Row/Help/Rest',
    AmalfiFormRow(
      label: 'Label',
      expand: true,
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
      expand: true,
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
  FormCase(
    'Forms/Footer/Actions/Rest',
    SizedBox(width: 352, child: footer()),
    {
      'Cancel': find.byType(AmalfiPushButton).at(0),
      'Save': find.byType(AmalfiPushButton).at(1),
    },
    // The push button stretched to the footer's 72 pt minimum keeps its label at the
    // leading padding, the kit centres it ("Save", 56 pt of content): masked until the
    // buttons family centres it (requested).
    mask: const [Rect.fromLTWH(292, 5, 48, 18)],
  ),
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
    deviations: {'Title': titleWidth},
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
    mask: const [Rect.fromLTWH(136, 36, 188, 68)],
  ),
  FormCase('Forms/Section/Validation/Rest', validation(), {
    'Title': find.byType(AmalfiWholePoints).first,
    'Group/Surface': sectionBox,
    'Group/Display name Help': rows.at(0),
    'Group/Email Error': rows.at(1),
  }),
  FormCase(
    'Forms/Layout/Full/Rest',
    AmalfiFormLayout(
      title: 'Account details',
      sections: [profile(), validation()],
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
    deviations: {'Title': titleWidth},
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
            tolerance: c.textTolerance,
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
      await pumpKitScene(
        tester,
        AmalfiFormRow(
          label: 'Name:',
          expand: true,
          control: field('Marta'),
          message: help,
        ),
      );
      expect(
        tester.getSize(find.text(help)).width,
        AmalfiFormMetrics.valueWidth,
      );
      expect(tester.getTopLeft(find.text(help)).dy, 28 + 4);
    });

    testWidgets('a section is as wide as its widest row, at least 352', (
      tester,
    ) async {
      await pumpKitScene(tester, preferences());
      expect(
        tester.getSize(find.byType(AmalfiFormSection)).width,
        AmalfiFormMetrics.sectionWidth,
      );
      expect(
        tester.getSize(find.byType(AmalfiFormRow).first).width,
        AmalfiFormMetrics.rowWidth,
      );
      await pumpKitScene(
        tester,
        AmalfiFormSection(
          rows: [
            AmalfiFormRow(
              label: 'Notes:',
              control: AmalfiTextField(width: 300),
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(AmalfiFormSection)).width,
        12 + 112 + 12 + 300 + 12,
      );
    });

    testWidgets('the layout is as tall as its content, on the grid', (
      tester,
    ) async {
      await pumpKitScene(
        tester,
        AmalfiFormLayout(
          title: 'Account details',
          sections: [profile(), validation()],
          footer: footer(),
        ),
      );
      expect(
        tester.getSize(find.byType(AmalfiFormLayout)),
        const Size(400, 496),
      );
    });

    testWidgets('fields in a form take focus with Tab', (tester) async {
      await pumpKitScene(tester, profile());
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
