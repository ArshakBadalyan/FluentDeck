import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/models/conversation_session_model.dart';
import 'package:fluentdeck/services/conversation_history_service.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  bool _loading = true;
  List<ConversationSessionModel> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await ConversationHistoryService.instance.listSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _confirmClearAll() async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This removes every saved conversation from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ConversationService.instance.clearAllHistoryAndReset();
    await _load();
  }

  Future<void> _deleteSession(ConversationSessionModel session) async {
    if (session.id == null) return;
    await ConversationHistoryService.instance.deleteSession(session.id!);
    await ConversationService.instance.clearIfSessionDeleted(session);
    await _load();
  }

  Future<bool> _confirmDeleteSession(ConversationSessionModel session) async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text('This removes it from your saved history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  String _preview(ConversationSessionModel session) {
    final userTurn = session.transcript.where((t) => t.isUser).firstOrNull;
    if (userTurn != null && userTurn.text.trim().isNotEmpty) {
      final text = userTurn.text.trim();
      return text.length > 80 ? '${text.substring(0, 80)}…' : text;
    }
    final aiTurn = session.transcript.where((t) => !t.isUser).firstOrNull;
    return aiTurn?.text.trim() ?? 'Conversation';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        // Light header on the page background, like the main tabs.
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Conversation history'),
        actions: [
          if (_sessions.isNotEmpty)
            TextButton(
              onPressed: _confirmClearAll,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: _loading
          ? const AppListSkeleton(itemHeight: 76)
          : _sessions.isEmpty
          ? Center(
              child: Text(
                'No saved conversations yet.\nChat on the Speak tab — history is saved after each exchange.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPageColors.subtitleOf(context)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final date = DateFormat.MMMd().add_jm().format(
                  session.startedAt.toLocal(),
                );
                final fixes = session.correctionsCount;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                // Orange badge for sessions with fixes, green when clean.
                final badgeColor = fixes > 0 ? AppColors.orangeHard : AppColors.greenCorrect;
                final badgeText = isDark ? badgeColor : Color.lerp(badgeColor, Colors.black, 0.5)!;
                return AppStaggeredFadeIn(
                  index: index,
                  child: Dismissible(
                    key: ValueKey('history-${session.id}'),
                    direction: DismissDirection.endToStart,
                    background: SwipeActionBackgrounds.delete(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    confirmDismiss: (_) => _confirmDeleteSession(session),
                    onDismissed: (_) => _deleteSession(session),
                    child: Material(
                      color: AppPageColors.cardBgOf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _continueSession(session),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppPageColors.accentOf(context).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.forum_outlined,
                                  size: 20,
                                  color: AppPageColors.accentOf(context),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _preview(session),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$date · ${session.transcript.length} messages',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppPageColors.subtitleOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  fixes == 0
                                      ? 'No fixes'
                                      : '$fixes fix${fixes == 1 ? '' : 'es'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: badgeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _continueSession(ConversationSessionModel session) async {
    await ConversationService.instance.loadSession(session);
    if (!mounted) return;
    // Speak hub only shows ConversationScreen when _inSession is true;
    // loadSession alone does not flip that flag.
    MainNavigationCoordinator.enterSpeakSession();
    Navigator.pop(context);
    MainNavigationCoordinator.goToTab(MainTabId.speak);
  }
}
