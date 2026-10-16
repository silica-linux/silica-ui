// A form row (kit `Forms/Row/Text|Popup|Check|Switch|Help|Error`): the label right-aligned in a
// 112 pt column, 12 pt, then the control and, under it, a help or error message as wide as
// the control. Rows lie on a 328 pt grid: text fields and labelled switches fill the 204 pt
// value column, pop-up buttons and checkboxes keep their own width.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';

/// The measures of the forms (`Forms/*`).
abstract final class AmalfiFormMetrics {
  /// The width of the label column.
  static const double labelWidth = 112;

  /// Between the label column and the control.
  static const double labelGap = 12;

  /// The width of the value column, which an expanded control fills (text fields and
  /// labelled switches in the kit).
  static const double valueWidth = 204;

  /// The width of a row in a section: the label column, the gap and the value column.
  static const double rowWidth = labelWidth + labelGap + valueWidth;

  /// The height of a row's first line: labels are centred on it, and so are controls
  /// shorter than it (checkboxes).
  static const double lineHeight = 28;

  /// Between a control and its message.
  static const double messageGap = 4;

  /// Between the rows of a section.
  static const double rowGap = 12;

  /// The padding of a section's group box.
  static const double sectionPadding = 12;

  /// The least width of a section: a row and the padding on both sides.
  static const double sectionWidth = rowWidth + 2 * sectionPadding;

  /// The corner radius of a section's group box.
  static const double sectionRadius = AmalfiRadii.menu;

  /// Between a section's title and its group box.
  static const double sectionTitleGap = 6;

  /// Between the buttons of the footer.
  static const double footerGap = 8;

  /// The least width of a footer button (the kit's `Cancel` and `Save` are 72 wide, as the
  /// dialogs' and alerts' buttons).
  static const double buttonMinWidth = 72;

  /// The padding of the form layout: 26 on top puts the title's 22 pt line and the 20 pt
  /// gap after it on the grid.
  static const EdgeInsets layoutPadding = EdgeInsets.fromLTRB(24, 26, 24, 24);

  /// Between the title, the sections and the footer of a layout.
  static const double layoutGap = 20;

  /// The default width of a form layout.
  static const double layoutWidth = 400;
}

/// What a row's message says.
enum AmalfiFormMessageKind {
  /// A hint (`Caption`, `Text/Tertiary`).
  help,

  /// What is wrong with the value (`Caption`, `Text/Secondary`, under a control in its
  /// error state).
  error,
}

/// One row of a form: [label] ("Name:") right-aligned in the label column, then [control];
/// [message] under the control, wrapped to its width.
///
/// A row without a label keeps the column empty (a second checkbox of a group). Controls
/// shorter than [AmalfiFormMetrics.lineHeight] are centred on the label's line. With
/// [expand] the control fills the value column ([AmalfiFormMetrics.valueWidth]), as text
/// fields and labelled switches do in the kit; otherwise it keeps its own width.
class AmalfiFormRow extends StatelessWidget {
  const AmalfiFormRow({
    super.key,
    this.label,
    required this.control,
    this.message,
    this.messageKind = AmalfiFormMessageKind.help,
    this.labelWidth = AmalfiFormMetrics.labelWidth,
    this.expand = false,
  });

  final String? label;
  final Widget control;
  final String? message;
  final AmalfiFormMessageKind messageKind;
  final double labelWidth;

  /// Whether [control] fills the value column.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final message = this.message;
    final label = this.label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          height: AmalfiFormMetrics.lineHeight,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: label == null
                ? null
                : SizedBox(
                    width: labelWidth,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AmalfiType.body(color: colors.textPrimary),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AmalfiFormMetrics.labelGap),
        Flexible(
          child: _ControlWithMessage(
            control: expand
                ? SizedBox(width: AmalfiFormMetrics.valueWidth, child: control)
                : control,
            message: message == null
                ? null
                : Text(
                    message,
                    style: AmalfiType.caption(
                      color: messageKind == AmalfiFormMessageKind.error
                          ? colors.textSecondary
                          : colors.textTertiary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// A control with an optional message under it: the control at its own size (centred on
/// the first [lineHeight] when shorter), the message [gap] below it and wrapped to the
/// control's width.
class _ControlWithMessage
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _ControlWithMessage({required this.control, this.message});

  final Widget control;
  final Widget? message;
  double get lineHeight => AmalfiFormMetrics.lineHeight;
  double get gap => AmalfiFormMetrics.messageGap;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.control => control,
    _Slot.message => message,
  };

  @override
  _RenderControlWithMessage createRenderObject(BuildContext context) =>
      _RenderControlWithMessage(lineHeight, gap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderControlWithMessage renderObject,
  ) {
    renderObject
      ..lineHeight = lineHeight
      ..gap = gap;
  }
}

enum _Slot { control, message }

class _RenderControlWithMessage extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderControlWithMessage(this._lineHeight, this._gap);

  double _lineHeight;
  set lineHeight(double v) {
    if (v == _lineHeight) return;
    _lineHeight = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  RenderBox? get _control => childForSlot(_Slot.control);
  RenderBox? get _message => childForSlot(_Slot.message);

  static BoxParentData _data(RenderBox box) => box.parentData! as BoxParentData;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final loose = constraints.loosen();
    final control = _control;
    var size = Size.zero;
    if (control != null) {
      size = dry
          ? control.getDryLayout(loose)
          : (control..layout(loose, parentUsesSize: true)).size;
    }
    final top = math.max(0.0, (_lineHeight - size.height) / 2);
    if (!dry && control != null) _data(control).offset = Offset(0, top);
    var height = math.max(_lineHeight, top + size.height);
    final message = _message;
    if (message != null) {
      final width = size.width.isFinite && size.width > 0
          ? size.width
          : loose.maxWidth;
      final c = width.isFinite
          ? BoxConstraints(minWidth: width, maxWidth: width)
          : const BoxConstraints();
      final m = dry
          ? message.getDryLayout(c)
          : (message..layout(c, parentUsesSize: true)).size;
      final y = top + size.height + _gap;
      if (!dry) _data(message).offset = Offset(0, y);
      height = math.max(height, y + m.height);
    }
    return constraints.constrain(Size(size.width, height));
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _control?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _control?.getMaxIntrinsicWidth(height) ?? 0;

  // From the children's intrinsics, not a dry layout: controls built with a LayoutBuilder
  // (labelled switches, pop-up buttons) cannot lay out dry.
  double _intrinsicHeight(double width, {required bool max}) {
    final control = _control;
    final controlHeight = control == null
        ? 0.0
        : max
        ? control.getMaxIntrinsicHeight(width)
        : control.getMinIntrinsicHeight(width);
    final top = math.max(0.0, (_lineHeight - controlHeight) / 2);
    var height = math.max(_lineHeight, top + controlHeight);
    final message = _message;
    if (message != null) {
      final controlWidth = control?.getMaxIntrinsicWidth(controlHeight) ?? 0;
      final messageWidth = controlWidth > 0
          ? math.min(controlWidth, width)
          : width;
      final messageHeight = max
          ? message.getMaxIntrinsicHeight(messageWidth)
          : message.getMinIntrinsicHeight(messageWidth);
      height = math.max(height, top + controlHeight + _gap + messageHeight);
    }
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, max: false);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, max: true);

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(child, offset + _data(child).offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final hit = result.addWithPaintOffset(
        offset: _data(child).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
