import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riovox/models/conversation_session_model.dart';
import 'package:riovox/services/conversation_history_service.dart';
import 'package:riovox/services/main_navigation_coordinator.dart';
import 'package:riovox/services/main_tab_config.dart';
import 'package:riovox/widgets/swipe_action_backgrounds.dart';
import 'package:riovox/services/conversation_service.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/widgets/rio_empty_state.dart';

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

  String _title(ConversationSessionModel session) {
    final topic = session.topicTitle?.trim();
    if (topic != null && topic.isNotEmpty) return topic;
    final userTurn = session.transcript.where((t) => t.isUser && t.text.trim().isNotEmpty).firstOrNull;
    return userTurn?.text.trim() ?? 'Conversation';
  }

  /// Rio's last line, quoted.
  String? _lastTutorLine(ConversationSessionModel session) {
    final aiTurn = session.transcript.where((t) => !t.isUser && t.text.trim().isNotEmpty).lastOrNull;
    return aiTurn == null ? null : '“${aiTurn.text.trim()}”';
  }

  /// "Today", "Yesterday", else "Oct 21".
  String _dayLabel(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat.MMMd().format(local);
  }

  @override
  Widget build(BuildContext context) {
    // Sessions grouped under a day header each.
    final items = <Object>[];
    String? lastDay;
    for (final session in _sessions) {
      final day = _dayLabel(session.startedAt.toLocal());
      if (day != lastDay) {
        items.add(day);
        lastDay = day;
      }
      items.add(session);
    }

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    icon: Icon(Icons.chevron_left_rounded, size: 28, color: AppPageColors.textPrimaryOf(context)),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Conversation history',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  if (_sessions.isNotEmpty)
                    TextButton(
                      onPressed: _confirmClearAll,
                      style: TextButton.styleFrom(
                        foregroundColor: AppPageColors.accentOf(context),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(44, 44),
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const AppListSkeleton(itemHeight: 76)
                  : _sessions.isEmpty
                  ? const RioEmptyState(
                      title: 'No chats yet',
                      message: 'Talk with Rio on Today; each chat is saved here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is String) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(0, index == 0 ? 6 : 10, 0, 8),
                            child: Text(
                              item.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppPageColors.subtitleOf(context),
                              ),
                            ),
                          );
                        }
                        final session = item as ConversationSessionModel;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppStaggeredFadeIn(
                            index: index,
                            child: Dismissible(
                              key: ValueKey('history-${session.id}'),
                              direction: DismissDirection.endToStart,
                              background: SwipeActionBackgrounds.delete(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              confirmDismiss: (_) => _confirmDeleteSession(session),
                              onDismissed: (_) => _deleteSession(session),
                              child: _HistoryRow(
                                title: _title(session),
                                subtitle: _lastTutorLine(session),
                                time: DateFormat.Hm().format(session.startedAt.toLocal()),
                                fixes: session.correctionsCount,
                                onTap: () => _continueSession(session),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

/// Icon tile, first line and Rio's last line, time and a fixes badge.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.fixes,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String time;
  final int fixes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconTint = AppPageColors.tintOf(context, fixes > 0 ? AppTint.voice : AppTint.teal);
    final badge = AppPageColors.tintOf(context, fixes > 0 ? AppTint.warning : AppTint.success);
    return Material(
      color: AppPageColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconTint.bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(
                  Icons.forum_outlined,
                  size: 20,
                  color: AppPageColors.tintIconOf(context, fixes > 0 ? AppTint.voice : AppTint.teal),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: TextStyle(fontSize: 12, color: AppPageColors.mutedOf(context))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      fixes == 0 ? 'No fixes' : '$fixes fix${fixes == 1 ? '' : 'es'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge.fg),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
