import 'package:flutter/material.dart';
import 'package:riovox/config/brand_config.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// White 52 dp field with a hairline border; 2 dp teal when focused, 2 dp red
/// with [error]. The label sits above the field (see [AuthField]).
InputDecoration authInput(BuildContext context, [String? hint, bool error = false]) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
  final idle = error
      ? border(BrandConfig.wrong, 2)
      : border(AppPageColors.subtleBorderOf(context), 1);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppPageColors.mutedOf(context), fontSize: 16),
    isDense: true,
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? AppPageColors.fieldBgOf(context)
        : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: idle,
    enabledBorder: idle,
    focusedBorder: error
        ? border(BrandConfig.wrong, 2)
        : border(AppPageColors.accentOf(context), 2),
  );
}

/// Label above a field, with an optional message under it.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
    this.suffix,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;

  /// Shown in red under the field; the border turns red too.
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPageColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: TextStyle(fontSize: 16, color: AppPageColors.textPrimaryOf(context)),
          decoration: authInput(context, null, hasError).copyWith(suffixIcon: suffix),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppPageColors.tintOf(context, AppTint.danger).fg,
            ),
          ),
        ],
      ],
    );
  }
}
