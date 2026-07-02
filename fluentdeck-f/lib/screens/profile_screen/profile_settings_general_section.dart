import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:fluentdeck/services/theme_settings_store.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Appearance and accessibility settings (stored locally, app-wide).
class ProfileSettingsGeneralSection extends StatefulWidget {
  const ProfileSettingsGeneralSection({super.key});

  @override
  State<ProfileSettingsGeneralSection> createState() =>
      _ProfileSettingsGeneralSectionState();
}

class _ProfileSettingsGeneralSectionState
    extends State<ProfileSettingsGeneralSection> {
  bool _loading = true;
  ReviewSettings _settings = const ReviewSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ReviewSettingsStore.instance.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(ReviewSettings next) async {
    setState(() => _settings = next);
    await ReviewSettingsStore.instance.save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: ThemeSettingsStore.instance,
          builder: (context, _) => AppNavRow(
            title:
                'App theme  ·  ${ThemeSettingsStore.instance.label(ThemeSettingsStore.instance.themeMode)}',
            icon: Icons.palette_outlined,
            onTap: () => _showThemeModeSheet(context),
          ),
        ),
        const SizedBox(height: 4),
        AppToggleRow(
          title: 'Dark mode (Decks)',
          subtitle: 'Use dark theme in the Decks section, regardless of app theme',
          value: _settings.darkMode,
          onChanged: (v) => _save(_settings.copyWith(darkMode: v)),
        ),
        AppToggleRow(
          title: 'Keep screen on',
          subtitle: 'Prevent sleep during review sessions',
          value: _settings.keepScreenOn,
          onChanged: (v) => _save(_settings.copyWith(keepScreenOn: v)),
        ),
        const SizedBox(height: 16),
        Text(
          'Accessibility',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        AppSliderRow(
          title: 'Card text size',
          value: _settings.cardTextScale,
          min: 0.8,
          max: 1.6,
          divisions: 8,
          label: '${(_settings.cardTextScale * 100).round()}%',
          onChanged: (v) => _save(_settings.copyWith(cardTextScale: v)),
        ),
        AppSliderRow(
          title: 'Review button size',
          value: _settings.reviewButtonScale,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(_settings.reviewButtonScale * 100).round()}%',
          onChanged: (v) => _save(_settings.copyWith(reviewButtonScale: v)),
        ),
      ],
    );
  }

  Future<void> _showThemeModeSheet(BuildContext context) {
    return showFrostedBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: ThemeSettingsStore.instance,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'App theme',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: ThemeSettingsStore.instance.themeMode,
                    onChanged: (m) {
                      if (m != null) ThemeSettingsStore.instance.setThemeMode(m);
                    },
                    activeColor: AppColors.primaryPurple,
                    title: Text(ThemeSettingsStore.instance.label(mode)),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
