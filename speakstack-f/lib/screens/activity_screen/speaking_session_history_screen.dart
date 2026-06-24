import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/speaking_session_record_model.dart';
import 'package:untitled2/services/speaking_session_service.dart';

class SpeakingSessionHistoryScreen extends StatefulWidget {
  const SpeakingSessionHistoryScreen({super.key});

  @override
  State<SpeakingSessionHistoryScreen> createState() =>
      _SpeakingSessionHistoryScreenState();
}

class _SpeakingSessionHistoryScreenState
    extends State<SpeakingSessionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<SpeakingSessionRecord> _history = const [];

  static const _pageBg = Color(0xFFF7F5FB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await SpeakingSessionService.instance.fetchRecent(
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatSessionTime(DateTime dt) {
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Session history'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
              : _history.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Complete a speaking session and tap End & score to see history here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.45),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryPurple,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final session = _history[index];
                    return _SessionHistoryCard(
                      title: '${session.historyTitle} — ${session.modeLabel}',
                      subtitle: _formatSessionTime(session.completedAt),
                      score: session.score,
                    );
                  },
                ),
              ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final String title;
  final String subtitle;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.greenCorrect.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greenCorrect.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.greenCorrect,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenCorrect.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score/10',
              style: const TextStyle(
                color: Color(0xFF1B9E4B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
