import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/card_browser_screen.dart';
import 'package:fluentdeck/screens/learn_screen/flashcards_screen.dart';
import 'package:fluentdeck/data/flashcard_offline_store.dart';
import 'package:fluentdeck/services/deck_backup_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:fluentdeck/app_theme.dart';
import 'package:fluentdeck/ui_elements/handoff_tab_bar_view.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Decks shell: Decks | Card browser.
class DecksShellScreen extends StatefulWidget {
  const DecksShellScreen({
    super.key,
    required this.tabController,
    this.mainTabHandoff = const MainTabHandoff(),
  });

  final TabController tabController;
  final MainTabHandoff mainTabHandoff;

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
      unawaited(_syncPendingOnResume());
      unawaited(DeckBackupService.instance.runAutoBackupIfDue());
    }
  }

  Future<void> _syncPendingOnResume() async {
    final pending = await FlashcardOfflineStore.instance.pendingReviewCount();
    if (pending > 0) {
      await FlashcardSyncService.instance.syncNow();
    } else {
      await FlashcardSyncService.instance.refreshStatus();
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
    // "Dark mode (Decks)" forces dark here; otherwise follow the app theme.
    final theme = _settings.darkMode ? AppTheme.dark : Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? AppPageColors.darkPageBg
        : AppPageColors.pageBg;

    return Theme(
      data: theme,
      child: ColoredBox(
        color: bg,
        child: HandoffTabBarView(
          controller: widget.tabController,
          onHandoffPrevious: widget.mainTabHandoff.onPrevious,
          onHandoffNext: widget.mainTabHandoff.onNext,
          children: const [
            FlashcardsScreen(),
            CardBrowserScreen(embedInShell: true),
          ],
        ),
      ),
    );
  }
}
