import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_screen.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import 'profile_settings_general_section.dart';
import 'profile_settings_speaking_tab.dart';

/// Scroll Profile → Settings to a section (`ai-speaking`, `decks`, `general`).
class ProfileSettingsNavigation {
  ProfileSettingsNavigation._();

  static void Function(String sectionId)? scrollToSection;
}

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => ProfileSettingsTabState();
}

class ProfileSettingsTabState extends State<ProfileSettingsTab> {
  final _scrollController = ScrollController();
  final _aiSpeakingKey = GlobalKey();
  final _decksKey = GlobalKey();
  final _generalKey = GlobalKey();

  bool _studyLoading = true;
  bool _studySaving = false;
  bool _autoCreateFlashcards = true;

  @override
  void initState() {
    super.initState();
    ProfileSettingsNavigation.scrollToSection = _scrollToSection;
    _loadStudySettings();
  }

  @override
  void dispose() {
    if (ProfileSettingsNavigation.scrollToSection == _scrollToSection) {
      ProfileSettingsNavigation.scrollToSection = null;
    }
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToSection(String sectionId) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = switch (sectionId) {
        'decks' => _decksKey,
        'general' => _generalKey,
        _ => _aiSpeakingKey,
      };
      final context = key.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    });
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
    return AppPageBackground(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: _aiSpeakingKey,
              child: const AppSectionCard(
                title: 'AI Speaking',
                icon: Icons.record_voice_over_outlined,
                subtitle: 'Tutor language, translations, and conversation flow.',
                child: ProfileSettingsSpeakingSection(),
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _decksKey,
              child: AppSectionCard(
                title: 'Decks & flashcards',
                icon: Icons.style_outlined,
                subtitle: 'Deck review, sync, and flashcard behavior.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_studyLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else
                      AppToggleRow(
                        title: 'Auto-create flashcards',
                        subtitle:
                            'When you save a word or correction, add a card to Saved words or From speaking.',
                        value: _autoCreateFlashcards,
                        enabled: !_studySaving,
                        onChanged: _toggleAutoCreate,
                      ),
                    if (_studySaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    const SizedBox(height: 8),
                    const DecksSettingsScreen(
                      embedInShell: true,
                      inlineInScroll: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _generalKey,
              child: const AppSectionCard(
                title: 'General',
                icon: Icons.tune_rounded,
                subtitle: 'Language, appearance, and accessibility for the app.',
                child: ProfileSettingsGeneralSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
