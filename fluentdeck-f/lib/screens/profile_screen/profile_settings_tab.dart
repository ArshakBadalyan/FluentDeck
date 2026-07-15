import 'package:flutter/material.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import 'profile_settings_category_screen.dart';

/// Scroll Profile → Settings to a section (`ai-speaking`, `decks`, `general`).
class ProfileSettingsNavigation {
  ProfileSettingsNavigation._();

  static void Function(String sectionId)? openCategory;
  static String? pendingSectionId;

  static const aiSpeakingSectionId = 'ai-speaking';

  /// Profile → Settings → AI Speaking (Sync deck language toggle).
  static void openAiSpeakingSection({BuildContext? context}) {
    if (context != null) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    }
    pendingSectionId = aiSpeakingSectionId;
    MainNavigationCoordinator.goToTab(
      MainTabId.profile,
      subIndex: kProfileSettingsTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingOpen());
  }

  static void flushPendingOpen() {
    final id = pendingSectionId;
    if (id == null) return;
    openCategory?.call(id);
    pendingSectionId = null;
  }

  static ProfileSettingsCategory categoryFor(String sectionId) {
    return switch (sectionId) {
      'decks' => ProfileSettingsCategory.decks,
      'general' => ProfileSettingsCategory.general,
      _ => ProfileSettingsCategory.aiSpeaking,
    };
  }
}

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => ProfileSettingsTabState();
}

class ProfileSettingsTabState extends State<ProfileSettingsTab> {
  @override
  void initState() {
    super.initState();
    ProfileSettingsNavigation.openCategory = _openCategory;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ProfileSettingsNavigation.flushPendingOpen(),
    );
  }

  @override
  void dispose() {
    if (ProfileSettingsNavigation.openCategory == _openCategory) {
      ProfileSettingsNavigation.openCategory = null;
    }
    super.dispose();
  }

  void _openCategory(String sectionId) {
    if (!mounted) return;
    final category = ProfileSettingsNavigation.categoryFor(sectionId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsCategoryScreen(category: category),
      ),
    );
  }

  void _open(ProfileSettingsCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsCategoryScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            'Choose a category to manage your preferences.',
            style: TextStyle(
              fontSize: 13,
              color: AppPageColors.subtitleOf(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          AppSettingsCategoryTile(
            icon: Icons.record_voice_over_outlined,
            title: 'AI Speaking',
            subtitle: 'Learning language, tutor voice, chat, and daily goals',
            onTap: () => _open(ProfileSettingsCategory.aiSpeaking),
          ),
          AppSettingsCategoryTile(
            icon: Icons.style_outlined,
            title: 'Decks & flashcards',
            subtitle: 'Study screen, review, sync, backups, and gestures',
            onTap: () => _open(ProfileSettingsCategory.decks),
          ),
          AppSettingsCategoryTile(
            icon: Icons.tune_rounded,
            title: 'General',
            subtitle: 'App language, theme, and accessibility',
            onTap: () => _open(ProfileSettingsCategory.general),
          ),
        ],
      ),
    );
  }
}
