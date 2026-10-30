import 'package:flutter/material.dart';

/// Decks settings sections.
enum DecksSettingsSection {
  general,
  newStudyScreen,
  reviewing,
  sync,
  notifications,
  appearance,
  controls,
  accessibility,
  backups,
  advanced,
  about,
}

/// Sections shown in Profile → Settings (deck-specific only).
const List<DecksSettingsSection> decksProfileHubSections = [
  DecksSettingsSection.general,
  DecksSettingsSection.newStudyScreen,
  DecksSettingsSection.reviewing,
  DecksSettingsSection.sync,
  DecksSettingsSection.controls,
  DecksSettingsSection.backups,
  DecksSettingsSection.advanced,
];

extension DecksSettingsSectionMeta on DecksSettingsSection {
  String get title {
    switch (this) {
      case DecksSettingsSection.general:
        return 'General';
      case DecksSettingsSection.newStudyScreen:
        return 'New study screen';
      case DecksSettingsSection.reviewing:
        return 'Reviewing';
      case DecksSettingsSection.sync:
        return 'Sync';
      case DecksSettingsSection.notifications:
        return 'Notifications';
      case DecksSettingsSection.appearance:
        return 'Appearance';
      case DecksSettingsSection.controls:
        return 'Controls';
      case DecksSettingsSection.accessibility:
        return 'Accessibility';
      case DecksSettingsSection.backups:
        return 'Backups';
      case DecksSettingsSection.advanced:
        return 'Advanced';
      case DecksSettingsSection.about:
        return 'About';
    }
  }

  String get subtitle {
    switch (this) {
      case DecksSettingsSection.general:
        return 'Collection, note types, shared decks';
      case DecksSettingsSection.newStudyScreen:
        return 'New card order and study display';
      case DecksSettingsSection.reviewing:
        return 'Answer buttons, leeches, reveal';
      case DecksSettingsSection.sync:
        return 'Cloud sync and upload status';
      case DecksSettingsSection.notifications:
        return 'Daily review reminders';
      case DecksSettingsSection.appearance:
        return 'Dark mode and screen wake';
      case DecksSettingsSection.controls:
        return 'Swipe and tap gestures';
      case DecksSettingsSection.accessibility:
        return 'Text and button sizing';
      case DecksSettingsSection.backups:
        return 'Automatic and manual backups';
      case DecksSettingsSection.advanced:
        return 'Import, export, reset settings';
      case DecksSettingsSection.about:
        return 'Version, help, release notes';
    }
  }

  IconData get icon {
    switch (this) {
      case DecksSettingsSection.general:
        return Icons.tune_outlined;
      case DecksSettingsSection.newStudyScreen:
        return Icons.school_outlined;
      case DecksSettingsSection.reviewing:
        return Icons.rate_review_outlined;
      case DecksSettingsSection.sync:
        return Icons.cloud_sync_outlined;
      case DecksSettingsSection.notifications:
        return Icons.notifications_outlined;
      case DecksSettingsSection.appearance:
        return Icons.palette_outlined;
      case DecksSettingsSection.controls:
        return Icons.touch_app_outlined;
      case DecksSettingsSection.accessibility:
        return Icons.accessibility_new_outlined;
      case DecksSettingsSection.backups:
        return Icons.backup_outlined;
      case DecksSettingsSection.advanced:
        return Icons.build_outlined;
      case DecksSettingsSection.about:
        return Icons.info_outline;
    }
  }
}
