import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:flutter/material.dart';

Widget decksSettingsNavTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final accentColor = AppPageColors.accentOf(context);
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
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
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPageColors.subtitleOf(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppPageColors.subtitleOf(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget decksSettingsActionTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
  Color? iconColor,
  bool destructive = false,
}) {
  final accent =
      destructive ? Colors.red.shade400 : (iconColor ?? AppPageColors.accentOf(context));
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
                        color: destructive
                            ? Colors.red.shade400
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPageColors.subtitleOf(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppPageColors.subtitleOf(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget decksSettingsSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppPageColors.accentOf(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
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
  final borderColor = AppPageColors.subtleBorderOf(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppPageColors.subtitleOf(context)),
        isDense: true,
        filled: true,
        fillColor: AppPageColors.fieldBgOf(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 1.5),
        ),
      ),
      onFieldSubmitted: onSave,
    ),
  );
}

Widget decksSettingsNote(BuildContext context, String text) {
  final color = AppPageColors.subtitleOf(context);
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    ),
  );
}

Widget decksSettingsPickerTile({
  required BuildContext context,
  required String title,
  Widget? subtitle,
  required String valueLabel,
  required VoidCallback onTap,
}) {
  final accentColor = AppPageColors.accentOf(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppPageColors.fieldBgOf(context),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppPageColors.subtitleOf(context),
                      ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, color: accentColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget? decksSettingsCheckIcon(BuildContext context, bool selected) {
  return selected
      ? Icon(Icons.check, color: AppPageColors.accentOf(context))
      : null;
}
