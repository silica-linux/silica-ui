// The Amalfi text field (kit `Fields/Text Field/*`, `Fields/Secure Field/*`,
// `Fields/Inline Button/*`): one line of editable text on `Surface/Raised` with a 1 pt
// `Line/Border`; focused, a 1.5 pt `Accent/Amalfi` border and the focus halo; with an error, a
// 1.5 pt `Palette/Terracotta` border, the same colour at 30 % as halo and the warning glyph;
// disabled, the rest look with the whole field at 35 % (user decision 2026-10-16).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../../tokens.g.dart';
import 'editable.dart';
import 'field_state.dart';
import '../../foundation/foundation.dart';
import 'metrics.dart';
import 'surface.dart';

/// A one-line text field.
///
/// It is [width] wide (200 by default; `double.infinity` fills the parent) and
/// [AmalfiFieldSize.height] tall. Before the text it can show a [leadingGlyph] (the secure
/// field's lock), after it the error mark when [errorText] is set and a [trailing] widget
/// (an [AmalfiInlineButton] such as "Browse"). A tap anywhere on the field puts the caret in
/// it; the text supports selection, IME and the clipboard ([AmalfiEditable]).
class AmalfiTextField extends StatefulWidget implements AmalfiFieldWidget {
  const AmalfiTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = AmalfiFieldSize.regular,
    this.width = AmalfiFieldMetrics.width,
    this.enabled = true,
    this.errorText,
    this.obscureText = false,
    this.leadingGlyph,
    this.trailing,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    this.statesController,
  });

  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;

  /// Shown in `Text/Tertiary` while the field is empty.
  final String? placeholder;
  final AmalfiFieldSize size;

  /// The field's width.
  final double width;
  @override
  final bool enabled;

  /// When set, the field shows the error look and the warning glyph, and screen readers read
  /// this text as the field's hint. Show the text itself next to the field (a form row).
  final String? errorText;

  /// Shows every character as `•`.
  final bool obscureText;

  /// A glyph before the text, in `Text/Secondary`.
  final AmalfiGlyphData? leadingGlyph;

  /// A widget after the text, vertically centred (an [AmalfiInlineButton]).
  final Widget? trailing;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// What screen readers call the field; the placeholder when null.
  final String? semanticLabel;
  @override
  final WidgetStatesController? statesController;

  @override
  State<AmalfiTextField> createState() => _AmalfiTextFieldState();
}

class _AmalfiTextFieldState extends State<AmalfiTextField>
    with AmalfiFieldStateMixin {
  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final size = widget.size;
    final enabled = widget.enabled;
    final error = widget.errorText != null;
    final isFocused = focused && enabled;
    final leading = widget.leadingGlyph;
    final trailing = widget.trailing;
    return Semantics(
      label: widget.semanticLabel ?? widget.placeholder,
      hint: widget.errorText,
      enabled: enabled,
      child: ExcludeFocus(
        excluding: !enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusFromTap,
          child: SizedBox(
            width: widget.width,
            height: size.height,
            child: amalfiFieldFace(
              colors: colors,
              radius: size.radius,
              enabled: enabled,
              focused: isFocused,
              error: error,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.padding),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      AmalfiGlyph(
                        leading,
                        size: size.glyph,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AmalfiFieldMetrics.gap),
                    ],
                    Expanded(
                      child: AmalfiEditable(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        autofocus: widget.autofocus,
                        obscureText: widget.obscureText,
                        placeholder: widget.placeholder,
                        style: size.textStyle(colors.textPrimary),
                        placeholderStyle: size.textStyle(colors.textTertiary),
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        inputFormatters: widget.inputFormatters,
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                      ),
                    ),
                    if (error) ...[
                      const SizedBox(width: AmalfiFieldMetrics.gap),
                      AmalfiGlyph(
                        AmalfiGlyphs.warning,
                        size: size.glyph,
                        color: colors.paletteTerracotta,
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(width: AmalfiFieldMetrics.gap),
                      trailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The face of a rectangular field in its state: `Surface/Raised` with a 1 pt `Line/Border`
/// at rest, a 1.5 pt `Accent/Amalfi` border and the `Line/Focus` halo when [focused], a
/// 1.5 pt `Palette/Terracotta` border and halo at 30 % with an [error]; not [enabled], the
/// rest look with the whole field (its [child] included) at 35 %
/// ([AmalfiFieldEnabledScope]).
Widget amalfiFieldFace({
  required AmalfiColors colors,
  required double radius,
  required bool enabled,
  required bool focused,
  bool error = false,
  required Widget child,
}) {
  final strong = enabled && (error || focused);
  final showError = enabled && error;
  return AmalfiFieldEnabledScope(
    enabled: enabled,
    child: AmalfiFieldSurface(
      radius: radius,
      fill: colors.surfaceRaised,
      border: !strong
          ? colors.lineBorder
          : showError
          ? colors.paletteTerracotta
          : colors.accentAmalfi,
      borderWidth: strong
          ? AmalfiFieldMetrics.strongBorder
          : AmalfiFieldMetrics.border,
      halo: showError ? colors.paletteTerracotta : colors.lineFocus,
      haloVisible: strong,
      haloOpacity: showError ? AmalfiFieldMetrics.errorHaloOpacity : 1,
      child: child,
    ),
  );
}

/// A secure field (kit `Fields/Secure Field`): an [AmalfiTextField] with the lock glyph
/// before the text, every character shown as `•`.
class AmalfiSecureField extends StatelessWidget {
  const AmalfiSecureField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = AmalfiFieldSize.regular,
    this.width = AmalfiFieldMetrics.width,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    this.statesController,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final AmalfiFieldSize size;
  final double width;
  final bool enabled;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) => AmalfiTextField(
    controller: controller,
    focusNode: focusNode,
    placeholder: placeholder,
    size: size,
    width: width,
    enabled: enabled,
    errorText: errorText,
    obscureText: true,
    leadingGlyph: AmalfiGlyphs.lock,
    autofocus: autofocus,
    keyboardType: TextInputType.visiblePassword,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    semanticLabel: semanticLabel,
    statesController: statesController,
  );
}
