// The keys of the layers the Amalfi controls draw, named as in the kit, so that a test (or a
// tool) can find each one.

import 'package:flutter/widgets.dart';

/// The keys of the layers a control draws, named as in the kit (`Box`, `State`,
/// `Focus Halo`, …).
abstract final class AmalfiLayerKeys {
  /// The body of a box, track or button (`Box`, `Track`, `Background`, `Surface`).
  static const Key body = ValueKey('amalfi.layer.body');

  /// The hover overlay (`State`).
  static const Key state = ValueKey('amalfi.layer.state');

  /// The keyboard focus halo (`Focus Halo`), drawn by `AmalfiFocusHalo`.
  static const Key focusHalo = ValueKey('amalfi.layer.focusHalo');

  /// A glyph or mark (`Glyph Check`, `Glyph Dash`, `Dot`, `Glyph Chevron …`).
  static const Key mark = ValueKey('amalfi.layer.mark');

  /// A switch thumb (`Thumb`).
  static const Key thumb = ValueKey('amalfi.layer.thumb');

  /// The lens over a dragged thumb or a pressed segment (`Lens`).
  static const Key lens = ValueKey('amalfi.layer.lens');

  /// The label of a labelled control (`Label`, `Title`, `Heading`).
  static const Key label = ValueKey('amalfi.layer.label');

  /// The content of a group or box (`Content`).
  static const Key content = ValueKey('amalfi.layer.content');

  /// The control inside a labelled row (`Checkbox box`, `Radio box`, `Switch`, `Triangle`).
  static const Key control = ValueKey('amalfi.layer.control');
}
