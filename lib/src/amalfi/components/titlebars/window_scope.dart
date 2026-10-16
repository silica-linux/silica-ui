// Whether the window is the active (key) window: title bars, pieces, window controls and the
// controls in them dim when it is not (kit `…/Inactive/…`). The state is silica_ui's
// [WindowActiveScope], shared with the other Amalfi controls (action segments, fields).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../controls/control_base.dart' show WindowActiveScope;

/// Enter, numpad Enter and Space activate a focused chrome control (tabs, sidebar rows and
/// headers), also without a `WidgetsApp` above.
const Map<ShortcutActivator, Intent> amalfiTitlebarActivateShortcuts = {
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};

/// Resolves an optional explicit [active] against the [WindowActiveScope] around [context].
bool amalfiTitlebarResolveActive(BuildContext context, bool? active) =>
    active ?? WindowActiveScope.of(context);
