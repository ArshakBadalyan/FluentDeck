import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

InputDecoration authInput(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: AppPageColors.subtitleOf(context),
      fontSize: 14,
    ),
    // Filled, rounded fields (Lagoon Daylight) instead of a bare underline.
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? AppPageColors.fieldBgOf(context)
        : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 2),
    ),
  );
}
