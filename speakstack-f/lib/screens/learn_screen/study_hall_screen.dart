import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/conversation_training_session.dart';
import 'package:untitled2/models/speaking_session_record_model.dart';
import 'package:untitled2/services/conversation_service.dart';
import 'package:untitled2/services/main_navigation_coordinator.dart';
import 'package:untitled2/services/study_hall_service.dart';
import 'package:untitled2/services/tutor_memory_service.dart';

class StudyHallScreen extends StatefulWidget {
  const StudyHallScreen({super.key});

  @override
  State<StudyHallScreen> createState() => _StudyHallScreenState();
}

class _StudyHallScreenState extends State<StudyHallScreen> {
  bool _loading = true;
  String? _error;
  StudyHallSummary _summary = const StudyHallSummary();

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
      final summary = await StudyHallService.instance.fetchSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  Future<void> _deleteMemoryFact(int index) async {
    try {
      final facts = await TutorMemoryService.instance.deleteFact(index);
      if (!mounted) return;
      setState(() {
        _summary = StudyHallSummary(
          memoryFacts: facts,
          recentSessions: _summary.recentSessions,
          speakingWords: _summary.speakingWords,
          weakAreas: _summary.weakAreas,
          stats: StudyHallStats(
            totalSessions: _summary.stats.totalSessions,
            totalWordsFromSpeaking: _summary.stats.totalWordsFromSpeaking,
            memoryFactCount: facts.length,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove memory: $e')),
      );
    }
  }

  void _practiceWords() {
    final words = _summary.speakingWords.take(12).toList();
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save words from speaking conversations first.'),
        ),
      );
      return;
    }

    ConversationService.instance.startDeckPractice(
      deckName: 'From speaking',
      sourceKey: 'from_speaking',
      deckId: 0,
      words: words
          .map(
            (item) => ConversationTrainingWord(
              word: item.word,
              hint: item.definition,
            ),
          )
          .toList(),
    );
    MainNavigationCoordinator.goToMainTab(0, subIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatsRow(stats: _summary.stats),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'What I remember about you',
            subtitle: 'Personal details the tutor recalls across sessions',
          ),
          const SizedBox(height: 8),
          if (_summary.memoryFacts.isEmpty)
            const _EmptyCard(
              message:
                  'Chat about your goals, job, or hobbies — the tutor will remember them here.',
            )
          else
            ..._summary.memoryFacts.asMap().entries.map(
              (entry) => _MemoryCard(
                fact: entry.value,
                onDelete: () => _deleteMemoryFact(entry.key),
              ),
            ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Words from speaking',
            subtitle: 'Saved to your From speaking deck',
            actionLabel: _summary.speakingWords.isNotEmpty ? 'Practice' : null,
            onAction: _summary.speakingWords.isNotEmpty ? _practiceWords : null,
          ),
          const SizedBox(height: 8),
          if (_summary.speakingWords.isEmpty)
            const _EmptyCard(
              message:
                  'Save corrections or ask the tutor to remember words during chat.',
            )
          else
            ..._summary.speakingWords.take(20).map(
              (item) => _WordCard(word: item),
            ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Recent speaking sessions',
            subtitle: 'Scores and summaries from completed practice',
          ),
          const SizedBox(height: 8),
          if (_summary.recentSessions.isEmpty)
            const _EmptyCard(
              message: 'Complete a session and tap End & score to see history here.',
            )
          else
            ..._summary.recentSessions.map(
              (session) => _SessionCard(session: session),
            ),
          if (_summary.weakAreas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Weak areas',
              subtitle: 'Patterns from your corrections',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _summary.weakAreas
                  .map(
                    (area) => Chip(
                      label: Text('${area.label} (${area.count})'),
                      backgroundColor:
                          AppColors.primaryPurple.withValues(alpha: 0.08),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final StudyHallStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Sessions',
            value: '${stats.totalSessions}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Speaking words',
            value: '${stats.totalWordsFromSpeaking}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Memory facts',
            value: '${stats.memoryFactCount}',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.fact, required this.onDelete});

  final TutorMemoryFact fact;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(fact.fact),
        subtitle: Text(fact.category),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});

  final StudyHallSpeakingWord word;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          word.word,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          word.definition,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final SpeakingSessionRecord session;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(session.completedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.35),
          child: Text(
            '${session.score}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(session.historyTitle),
        subtitle: Text('${session.modeLabel} · $date'),
      ),
    );
  }
}
