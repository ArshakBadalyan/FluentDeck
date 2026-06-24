import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/speaking_session_context.dart';
import '../../services/conversation_service.dart';
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
    this.onSessionActiveChanged,
  });

  final TabController tabController;
  final ValueChanged<bool>? onSessionActiveChanged;

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

    return TabBarView(
      controller: widget.tabController,
      children: [
        SpeakingChatTab(onStart: _startSession),
        SpeakingNotesTab(onStart: _startSession),
        SpeakingPracticeTab(onStart: _startSession),
        SpeakingGamesTab(onStart: _startSession),
        SpeakingRolePlayTab(onStart: _startSession),
        SpeakingTopicsTab(onStart: _startSession),
      ],
    );
  }
}
