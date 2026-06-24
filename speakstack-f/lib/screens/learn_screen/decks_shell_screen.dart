import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speakstack/screens/learn_screen/card_browser_screen.dart';
import 'package:speakstack/screens/learn_screen/flashcards_screen.dart';
import 'package:speakstack/services/flashcard_sync_service.dart';
import 'package:speakstack/services/review_settings_store.dart';
import 'package:speakstack/ui_elements/modern_page_widgets.dart';

/// Anki-style shell: Decks | Card browser.
class DecksShellScreen extends StatefulWidget {
  const DecksShellScreen({super.key, required this.tabController});

  final TabController tabController;

  @override
  State<DecksShellScreen> createState() => DecksShellScreenState();
}

class DecksShellScreenState extends State<DecksShellScreen> with WidgetsBindingObserver {
  ReviewSettings _settings = const ReviewSettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reloadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(FlashcardSyncService.instance.syncNow());
    }
  }

  Future<void> reloadSettings() async {
    final settings = await ReviewSettingsStore.instance.load();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _settings.darkMode;
    final bg = dark ? const Color(0xFF121212) : AppPageColors.pageBg;

    return Theme(
      data: dark ? ThemeData.dark(useMaterial3: false) : Theme.of(context),
      child: ColoredBox(
        color: bg,
        child: TabBarView(
          controller: widget.tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            FlashcardsScreen(),
            CardBrowserScreen(embedInShell: true),
          ],
        ),
      ),
    );
  }
}
