import 'dart:async';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/rio.dart';

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
import 'package:fluentdeck/services/conversation_start_ad.dart';

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

  /// True while a start is waiting on the conversation-start ad, so a second
  /// tap can't start twice.
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Free users outside high-value ad countries: have the ad ready for "Start".
    ConversationStartAd.instance.preload();
  }

  /// Archives the active chat (if any), starts a fresh free conversation, and opens it.
  Future<void> startNewFreeChat() async {
    if (_starting) return;
    _starting = true;
    try {
      await ConversationService.instance.archiveAndStartNew();
      await ConversationStartAd.instance.showIfNeeded();
    } finally {
      _starting = false;
    }
    if (!mounted) return;
    ConversationService.instance.startSession(SpeakingSessionContext.freeChat());
    if (widget.tabController.index != 0) {
      widget.tabController.index = 0;
    }
    setState(() => _inSession = true);
    widget.onSessionActiveChanged?.call(true);
  }

  Future<void> _startSession(SpeakingSessionContext context) async {
    if (_starting) return;
    _starting = true;
    try {
      // The ad finishes before the session opens, so the tutor's greeting
      // doesn't play behind it.
      await ConversationStartAd.instance.showIfNeeded();
    } finally {
      _starting = false;
    }
    if (!mounted) return;
    ConversationService.instance.startSession(context);
    setState(() => _inSession = true);
    widget.onSessionActiveChanged?.call(true);
  }

  /// Shows the active chat UI after [ConversationService.loadSession].
  void enterLoadedSession() {
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
          // Light session header: back, Rio, the session title, settings.
          Material(
            color: AppPageColors.pageBgOf(context),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _exitSession,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                      tooltip: 'Exit session',
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPageColors.accentOf(context).withValues(alpha: 0.16),
                      ),
                      child: Transform.scale(
                        scale: 2.1,
                        alignment: const Alignment(0, -0.62),
                        child: Image.asset(
                          RioPose.happy.asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rio',
                            style: TextStyle(
                              color: AppPageColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            ConversationService.instance.sessionContext.title,
                            style: TextStyle(
                              color: AppPageColors.subtitleOf(context),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => showConversationChatSettingsSheet(context),
                      icon: Icon(
                        Icons.tune_rounded,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                      tooltip: 'Chat settings',
                    ),
                    const SizedBox(width: 4),
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
