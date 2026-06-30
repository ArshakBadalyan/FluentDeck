import 'package:fluentdeck/app_colors.dart';
import 'package:flutter/material.dart';

Widget decksSettingsSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}

Widget decksSettingsLabelField(
  String label,
  String value,
  ValueChanged<String> onSave,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onFieldSubmitted: onSave,
    ),
  );
}

Widget decksSettingsNote(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    ),
  );
}

Widget decksSettingsPickerTile({
  required String title,
  Widget? subtitle,
  required String valueLabel,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: subtitle,
    trailing: TextButton(onPressed: onTap, child: Text(valueLabel)),
  );
}

Widget? decksSettingsCheckIcon(bool selected) {
  return selected
      ? const Icon(Icons.check, color: AppColors.primaryPurple)
      : null;
}
