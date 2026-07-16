import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_screen.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import 'profile_settings_general_section.dart';
import 'profile_settings_speaking_tab.dart';

enum ProfileSettingsCategory {
  aiSpeaking,
  decks,
  general,
}

extension ProfileSettingsCategoryMeta on ProfileSettingsCategory {
  String get title {
    switch (this) {
      case ProfileSettingsCategory.aiSpeaking:
        return 'AI Speaking';
      case ProfileSettingsCategory.decks:
        return 'Decks & flashcards';
      case ProfileSettingsCategory.general:
        return 'General';
    }
  }

  String get subtitle {
    switch (this) {
      case ProfileSettingsCategory.aiSpeaking:
        return 'Tutor language, voice, and conversation flow';
      case ProfileSettingsCategory.decks:
        return 'Review, sync, backup, and study options';
      case ProfileSettingsCategory.general:
        return 'App language, theme, and accessibility';
    }
  }
}

/// Full-screen settings category (opened from Profile → Settings hub).
class ProfileSettingsCategoryScreen extends StatefulWidget {
  const ProfileSettingsCategoryScreen({super.key, required this.category});

  final ProfileSettingsCategory category;

  @override
  State<ProfileSettingsCategoryScreen> createState() =>
      _ProfileSettingsCategoryScreenState();
}

class _ProfileSettingsCategoryScreenState extends State<ProfileSettingsCategoryScreen> {
  bool _studyLoading = true;
  bool _studySaving = false;
  bool _autoCreateFlashcards = true;

  @override
  void initState() {
    super.initState();
    if (widget.category == ProfileSettingsCategory.decks) {
      _loadStudySettings();
    }
  }

  Future<void> _loadStudySettings() async {
    setState(() => _studyLoading = true);
    try {
      final settings = await NoteService.instance.fetchStudySettings();
      if (!mounted) return;
      setState(() {
        _autoCreateFlashcards = settings.autoCreateFlashcards;
        _studyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _studyLoading = false);
    }
  }

  Future<void> _toggleAutoCreate(bool value) async {
    setState(() {
      _autoCreateFlashcards = value;
      _studySaving = true;
    });

    final ok = await NoteService.instance.updateAutoCreateFlashcards(value);
    if (!mounted) return;

    setState(() => _studySaving = false);

    if (!ok) {
      setState(() => _autoCreateFlashcards = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update setting')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: Text(widget.category.title),
      ),
      body: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              widget.category.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppPageColors.subtitleOf(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...switch (widget.category) {
              ProfileSettingsCategory.aiSpeaking => const [
                ProfileSettingsSpeakingSection(),
              ],
              ProfileSettingsCategory.decks => [
                AppSettingsGroup(
                  title: 'Saved words',
                  subtitle: 'When you save vocabulary from speaking practice.',
                  child: _studyLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppToggleRow(
                              title: 'Auto-create flashcards',
                              subtitle:
                                  'Add a card to Saved words or From speaking when you save a word.',
                              value: _autoCreateFlashcards,
                              enabled: !_studySaving,
                              onChanged: _toggleAutoCreate,
                            ),
                            if (_studySaving)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        ),
                ),
                AppSettingsGroup(
                  title: 'Deck options',
                  subtitle: 'Review, sync, backups, and study behavior.',
                  child: const DecksSettingsScreen(
                    embedInShell: true,
                    inlineInScroll: true,
                  ),
                ),
              ],
              ProfileSettingsCategory.general => const [
                ProfileSettingsGeneralSection(),
              ],
            },
          ],
        ),
      ),
    );
  }
}
