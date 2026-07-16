import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/profile_screen/profile_settings_tab.dart';

/// Tappable hint shown when sync deck language is on; opens Profile → Settings → AI Speaking.
class SyncedLearningLanguageHint extends StatelessWidget {
  const SyncedLearningLanguageHint({
    super.key,
    this.includeSettingsSuffix = false,
    this.padding = const EdgeInsets.only(top: 4),
  });

  /// When true, appends " in Settings." (note editor copy).
  final bool includeSettingsSuffix;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final linkColor = AppColors.primaryPurple;
    final label =
        includeSettingsSuffix
            ? 'Synced to your learning language in Settings.'
            : 'Synced to your learning language.';

    return Padding(
      padding: padding,
      child: Semantics(
        button: true,
        label: 'Open sync deck language settings',
        child: GestureDetector(
          onTap: () => ProfileSettingsNavigation.openAiSpeakingSection(
            context: context,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
