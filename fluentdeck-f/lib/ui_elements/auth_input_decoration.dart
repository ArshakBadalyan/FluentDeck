import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

InputDecoration authInput(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: AppPageColors.subtitleOf(context),
      fontSize: 14,
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: AppPageColors.accentOf(context)),
    ),
  );
}
