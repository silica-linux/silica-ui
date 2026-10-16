// Whether the window is the active (key) window: title bars, pieces and window controls dim
// when it is not (kit `…/Inactive/…`).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Tells the chrome below it whether its window is [active].
///
/// [AmalfiWindow] puts one above its content; bars, pieces, window controls and titles read it
/// with [AmalfiWindowScope.isActive] (true when there is none).
class AmalfiWindowScope extends InheritedWidget {
  const AmalfiWindowScope({
    super.key,
    required this.active,
    required super.child,
  });

  /// Whether the window is the active one.
  final bool active;

  /// Whether the window around [context] is active; true without an [AmalfiWindowScope].
  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmalfiWindowScope>()?.active ??
      true;

  @override
  bool updateShouldNotify(AmalfiWindowScope old) => old.active != active;
}

/// Enter, numpad Enter and Space activate a focused chrome control (tabs, sidebar rows and
/// headers), also without a `WidgetsApp` above.
const Map<ShortcutActivator, Intent> amalfiActivateShortcuts = {
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};

/// Resolves an optional explicit [active] against the [AmalfiWindowScope] around [context].
bool amalfiResolveActive(BuildContext context, bool? active) =>
    active ?? AmalfiWindowScope.isActive(context);
