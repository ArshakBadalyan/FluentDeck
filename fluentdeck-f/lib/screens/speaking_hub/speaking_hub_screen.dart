import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/speaking_session_context.dart';
import '../../services/conversation_service.dart';
import '../../ui_elements/handoff_tab_bar_view.dart';
import '../conversation_screen/conversation_chat_settings_sheet.dart';
import '../conversation_screen/conversation_screen.dart';
import 'speaking_chat_tab.dart';
import 'speaking_games_tab.dart';
import 'speaking_notes_tab.dart';
import 'speaking_practice_tab.dart';
import 'speaking_role_play_tab.dart';
import 'speaking_topics_tab.dart';

/// Same purple as [MainAppBar] background.
const Color _speakSessionBarColor = Color(0xFF7A24E4);

class SpeakingHubScreen extends StatefulWidget {
  const SpeakingHubScreen({
    super.key,
    required this.tabController,
    this.mainTabHandoff = const MainTabHandoff(),
    this.onSessionActiveChanged,
    this.visibleTabIds = const [
      'chat',
      'notes',
      'practice',
      'games',
      'roleplay',
      'topics',
    ],
  });

  final TabController tabController;
  final MainTabHandoff mainTabHandoff;
  final ValueChanged<bool>? onSessionActiveChanged;

  /// Must stay in the same order/id-set as `_speakSubTabDefs` in
  /// EnglishMainScreenState so tab-strip labels line up with these children.
  final List<String> visibleTabIds;

  @override
  State<SpeakingHubScreen> createState() => SpeakingHubScreenState();
}

class SpeakingHubScreenState extends State<SpeakingHubScreen> {
  bool _inSession = false;

  /// Archives the active chat (if any), starts a fresh free conversation, and opens it.
  Future<void> startNewFreeChat() async {
    await ConversationService.instance.archiveAndStartNew();
    if (!mounted) return;
    ConversationService.instance.startSession(SpeakingSessionContext.freeChat());
    if (widget.tabController.index != 0) {
      widget.tabController.index = 0;
    }
    setState(() => _inSession = true);
    widget.onSessionActiveChanged?.call(true);
  }

  void _startSession(SpeakingSessionContext context) {
    ConversationService.instance.startSession(context);
    setState(() => _inSession = true);
    widget.onSessionActiveChanged?.call(true);
  }

  /// Shows the active chat UI after [ConversationService.loadSession].
  void enterLoadedSession() {
    // #region agent log
    // ignore: avoid_print
    print(
      '[dbg-fcee54] SpeakingHub.enterLoadedSession '
      'wasInSession=$_inSession turns=${ConversationService.instance.turns.length} '
      'chatActive=${ConversationService.instance.isChatActive}',
    );
    // #endregion
    setState(() => _inSession = true);
    widget.onSessionActiveChanged?.call(true);
  }

  void _exitSession() {
    unawaited(ConversationService.instance.leaveChat());
    setState(() => _inSession = false);
    widget.onSessionActiveChanged?.call(false);
  }

  @override
  void dispose() {
    if (_inSession) {
      unawaited(ConversationService.instance.leaveChat());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_inSession) {
      return Column(
        children: [
          Material(
            color: _speakSessionBarColor,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _exitSession,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Exit session',
                    ),
                    Expanded(
                      child: Text(
                        ConversationService.instance.sessionContext.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Rubik',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => showConversationChatSettingsSheet(context),
                      icon: const Icon(Icons.tune_rounded, color: Colors.white),
                      tooltip: 'Chat settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(
            child: ConversationScreen(embedInShell: true),
          ),
        ],
      );
    }

    final allTabs = <String, Widget>{
      'chat': SpeakingChatTab(onStart: _startSession),
      'notes': SpeakingNotesTab(onStart: _startSession),
      'practice': SpeakingPracticeTab(onStart: _startSession),
      'games': SpeakingGamesTab(onStart: _startSession),
      'roleplay': SpeakingRolePlayTab(onStart: _startSession),
      'topics': SpeakingTopicsTab(onStart: _startSession),
    };

    return HandoffTabBarView(
      controller: widget.tabController,
      onHandoffPrevious: widget.mainTabHandoff.onPrevious,
      onHandoffNext: widget.mainTabHandoff.onNext,
      children:
          widget.visibleTabIds
              .map((id) => allTabs[id])
              .whereType<Widget>()
              .toList(),
    );
  }
}
