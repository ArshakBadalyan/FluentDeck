import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:flutter/material.dart';

Widget decksSettingsNavTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final subtitleColor = AppPageColors.subtitleOf(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppPageColors.cardBgOf(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subtitleColor),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget decksSettingsActionTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
  Color? iconColor,
  bool destructive = false,
}) {
  final accent = destructive ? Colors.red.shade600 : (iconColor ?? AppColors.primaryPurple);
  final subtitleColor = AppPageColors.subtitleOf(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppPageColors.cardBgOf(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: destructive ? Colors.red.shade700 : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subtitleColor),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget decksSettingsSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

Widget decksSettingsLabelField(
  BuildContext context,
  String label,
  String value,
  ValueChanged<String> onSave,
) {
  final border = AppPageColors.subtleBorderOf(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppPageColors.cardBgOf(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
      ),
      onFieldSubmitted: onSave,
    ),
  );
}

Widget decksSettingsNote(BuildContext context, String text) {
  final subtitleColor = AppPageColors.subtitleOf(context);
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: subtitleColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
        ),
      ],
    ),
  );
}

Widget decksSettingsPickerTile(
  BuildContext context, {
  required String title,
  Widget? subtitle,
  required String valueLabel,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppPageColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPageColors.subtleBorderOf(context), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle.merge(
                      style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                      child: subtitle,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryPurple, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget? decksSettingsCheckIcon(bool selected) {
  return selected
      ? const Icon(Icons.check, color: AppColors.primaryPurple)
      : null;
}
