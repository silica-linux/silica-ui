// What every Amalfi field keeps: its text controller and focus node (given or its own), its
// interaction states (also published to a WidgetStatesController), and the tap that puts
// the caret in the field from anywhere on it.

import 'package:flutter/widgets.dart';

/// The parameters an Amalfi field shares with [AmalfiFieldStateMixin].
abstract interface class AmalfiFieldWidget {
  /// The text; null: the field keeps its own.
  TextEditingController? get controller;

  /// The keyboard focus; null: the field keeps its own.
  FocusNode? get focusNode;

  /// Whether the field takes input.
  bool get enabled;

  /// Receives the field's states (focused, hovered, pressed, disabled, error) as they change,
  /// and adds its own: a state set here shows even if the field is not in it (a gallery can
  /// show a focused field without focusing it).
  WidgetStatesController? get statesController;
}

/// The controller, focus node and states of an Amalfi field.
mixin AmalfiFieldStateMixin<T extends StatefulWidget> on State<T> {
  AmalfiFieldWidget get _field => widget as AmalfiFieldWidget;

  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  WidgetStatesController? _ownStates;

  /// The text controller in use.
  TextEditingController get controller =>
      _field.controller ?? (_ownController ??= TextEditingController());

  /// The focus node in use.
  FocusNode get focusNode =>
      _field.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: '$T'));

  /// The states controller in use.
  WidgetStatesController get states =>
      _field.statesController ?? (_ownStates ??= WidgetStatesController());

  /// Whether [state] is on.
  bool has(WidgetState state) => states.value.contains(state);

  /// Whether the field shows as focused.
  bool get focused => has(WidgetState.focused);

  FocusNode? _listened;
  WidgetStatesController? _statesListened;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant T old) {
    super.didUpdateWidget(old);
    _attach();
  }

  bool _attaching = false;

  void _attach() {
    _attaching = true;
    final node = focusNode;
    if (_listened != node) {
      _listened?.removeListener(_focusChanged);
      node.addListener(_focusChanged);
      _listened = node;
    }
    final s = states;
    if (_statesListened != s) {
      _statesListened?.removeListener(_statesChanged);
      s.addListener(_statesChanged);
      _statesListened = s;
    }
    s.update(WidgetState.disabled, !_field.enabled);
    if (node.hasFocus) s.update(WidgetState.focused, true);
    _attaching = false;
  }

  void _focusChanged() {
    states.update(WidgetState.focused, focusNode.hasFocus);
    onFocusChanged(focusNode.hasFocus);
  }

  /// Called when the field gains or loses the keyboard focus.
  void onFocusChanged(bool focused) {}

  void _statesChanged() {
    if (mounted && !_attaching) setState(() {});
  }

  @override
  void dispose() {
    _listened?.removeListener(_focusChanged);
    _statesListened?.removeListener(_statesChanged);
    _ownController?.dispose();
    _ownFocus?.dispose();
    _ownStates?.dispose();
    super.dispose();
  }

  /// Focuses the field from a tap outside its text, with the caret at the end.
  void focusFromTap() {
    if (!_field.enabled) return;
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
      final end = controller.text.length;
      controller.selection = TextSelection.collapsed(offset: end);
    }
  }
}
