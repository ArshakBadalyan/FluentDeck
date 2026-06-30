import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/models/conversation_session_model.dart';
import 'package:fluentdeck/services/conversation_history_service.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';
import 'package:fluentdeck/services/conversation_service.dart';

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
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Conversation history'),
        actions: [
          if (_sessions.isNotEmpty)
            TextButton(
              onPressed: _confirmClearAll,
              child: const Text('Clear all'),
            ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _sessions.isEmpty
              ? Center(
                child: Text(
                  'No saved conversations yet.\nChat on the Speak tab — history is saved after each exchange.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final date = DateFormat.yMMMd().add_jm().format(
                    session.startedAt.toLocal(),
                  );
                  return Dismissible(
                    key: ValueKey('history-${session.id}'),
                    direction: DismissDirection.endToStart,
                    background: SwipeActionBackgrounds.delete(),
                    confirmDismiss: (_) => _confirmDeleteSession(session),
                    onDismissed: (_) => _deleteSession(session),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _preview(session),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '$date · ${session.transcript.length} messages'
                        '${session.correctionsCount > 0 ? ' · ${session.correctionsCount} corrections' : ''}',
                      ),
                      onTap: () => _continueSession(session),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _continueSession(ConversationSessionModel session) async {
    await ConversationService.instance.loadSession(session);
    if (!mounted) return;
    Navigator.pop(context);
    MainNavigationCoordinator.goToMainTab(0);
  }
}
