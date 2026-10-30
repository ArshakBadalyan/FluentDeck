import 'package:flutter/material.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/services/theme_settings_store.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import 'about_us/profile_about_tab.dart';
import 'profile_notifications_tab.dart';
import 'profile_settings_category_screen.dart';
import 'profile_sound_tab.dart';
import 'package:animations/animations.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

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

  /// Settings pages open "above" the list: Material shared axis Z.
  void _pushSettingsPage(WidgetBuilder builder) {
    Navigator.of(context).push(
      AppSharedAxisRoute<void>(
        transitionType: SharedAxisTransitionType.scaled,
        page: Builder(builder: builder),
      ),
    );
  }

  void _openCategory(String sectionId) {
    if (!mounted) return;
    final category = ProfileSettingsNavigation.categoryFor(sectionId);
    _pushSettingsPage((_) => ProfileSettingsCategoryScreen(category: category));
  }

  void _open(ProfileSettingsCategory category) {
    _pushSettingsPage((_) => ProfileSettingsCategoryScreen(category: category));
  }

  /// Notifications / Sound open as their own settings pages.
  void _openPage(String title, Widget page) {
    _pushSettingsPage(
      (context) => Scaffold(
        backgroundColor: AppPageColors.pageBgOf(context),
        appBar: AppBar(
          // Light header on the page background, like the main tabs.
          backgroundColor: AppPageColors.pageBgOf(context),
          foregroundColor: AppPageColors.textPrimaryOf(context),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(title),
        ),
        body: page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.mic_none_rounded,
                tint: AppTint.voice,
                title: 'Speaking',
                subtitle: 'Learning language, tutor voice, chat and daily goal',
                onTap: () => _open(ProfileSettingsCategory.aiSpeaking),
              ),
              _SettingsRow(
                icon: Icons.style_outlined,
                tint: AppTint.teal,
                title: 'Decks and flashcards',
                subtitle: 'Study screen, review, sync, backups and gestures',
                onTap: () => _open(ProfileSettingsCategory.decks),
              ),
              _SettingsRow(
                icon: Icons.language_rounded,
                tint: AppTint.success,
                title: 'Languages',
                subtitle: 'App language and accessibility',
                onTap: () => _open(ProfileSettingsCategory.general),
              ),
              _SettingsRow(
                icon: Icons.notifications_none_rounded,
                tint: AppTint.reward,
                title: 'Notifications',
                subtitle: 'Push notifications and daily reminders',
                onTap: () => _openPage('Notifications', const ProfileNotificationsTab()),
              ),
              _SettingsRow(
                icon: Icons.volume_up_outlined,
                tint: AppTint.info,
                title: 'Sound and haptics',
                subtitle: 'Sound effects, music and volume',
                onTap: () => _openPage('Sound and haptics', const ProfileSoundTab()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
          const SizedBox(height: 10),
          const _ThemePicker(),
          const SizedBox(height: 18),
          _SettingsCard(
            children: [
              _SettingsRow(
                title: 'About Riovox',
                trailingText: 'Help, privacy, version',
                onTap: () => _openPage('About Riovox', const ProfileAboutTab()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// White card holding rows split by hairlines.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPageColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Tinted icon tile, title and detail, chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.tint = AppTint.teal,
    this.subtitle,
    this.trailingText,
  });

  final IconData? icon;
  final AppTint tint;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPageColors.tintOf(context, tint).bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppPageColors.tintIconOf(context, tint)),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Text(trailingText!, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppPageColors.mutedOf(context)),
          ],
        ),
      ),
    );
  }
}

/// Light · Dark · System as three buttons; the chosen one is outlined teal.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final store = ThemeSettingsStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final teal = AppPageColors.tintOf(context, AppTint.teal);
        return Row(
          children: [
            for (final (i, mode) in const [ThemeMode.light, ThemeMode.dark, ThemeMode.system].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: store.themeMode == mode,
                  child: Material(
                    color: store.themeMode == mode ? teal.bg : AppPageColors.cardBgOf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: store.themeMode == mode
                          ? BorderSide(color: AppPageColors.accentOf(context), width: 2)
                          : BorderSide(color: AppPageColors.subtleBorderOf(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => store.setThemeMode(mode),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            mode == ThemeMode.system ? 'System' : store.label(mode),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: store.themeMode == mode ? FontWeight.w600 : FontWeight.w500,
                              color: store.themeMode == mode ? teal.fg : AppPageColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
