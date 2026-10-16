// The interaction states of a well (hovered, focused, pressed, dragged over, disabled), kept
// in a WidgetStatesController: the well writes its own states into it, and a state set from
// outside shows even if the well is not in it (the gallery shows a focused well that way).

import 'package:flutter/widgets.dart';

/// The states of a well, published to [statesController] when one is given.
mixin AmalfiWellStatesMixin<T extends StatefulWidget> on State<T> {
  /// The controller given by the widget; null: the well keeps its own.
  WidgetStatesController? get statesController;

  /// Whether the well takes input.
  bool get enabled;

  WidgetStatesController? _own;
  WidgetStatesController? _listened;
  bool _attaching = false;

  /// The controller in use.
  WidgetStatesController get states =>
      statesController ?? (_own ??= WidgetStatesController());

  /// Whether [state] is on.
  bool has(WidgetState state) => states.value.contains(state);

  /// Turns [state] on or off.
  void setWellState(WidgetState state, bool on) => states.update(state, on);

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

  void _attach() {
    _attaching = true;
    final s = states;
    if (_listened != s) {
      _listened?.removeListener(_changed);
      s.addListener(_changed);
      _listened = s;
    }
    s.update(WidgetState.disabled, !enabled);
    if (!enabled) {
      s
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
    _attaching = false;
  }

  void _changed() {
    if (mounted && !_attaching) setState(() {});
  }

  @override
  void dispose() {
    _listened?.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }
}
