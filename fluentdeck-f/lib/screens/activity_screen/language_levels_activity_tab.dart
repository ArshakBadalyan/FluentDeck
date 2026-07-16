import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/language_levels_snapshot.dart';
import 'package:fluentdeck/services/language_levels_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Activity tab: current learning language, AI tutor level, analytics estimate, history.
class LanguageLevelsActivityTab extends StatefulWidget {
  const LanguageLevelsActivityTab({super.key});

  @override
  State<LanguageLevelsActivityTab> createState() =>
      _LanguageLevelsActivityTabState();
}

class _LanguageLevelsActivityTabState extends State<LanguageLevelsActivityTab> {
  bool _loading = true;
  String? _error;
  LanguageLevelsSnapshot? _snapshot;

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
      final snapshot = await LanguageLevelsService.instance.fetch(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ActivityScreenSkeleton();
    }

    if (_error != null) {
      return AppPageBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final service = LanguageLevelsService.instance;
    final currentLabel = service.languageLabel(snapshot.practiceLanguage);

    return AppPageBackground(
      child: AppFadeIn(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primaryPurple,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeroCard(
                languageLabel: currentLabel,
                estimatedLevel: snapshot.estimatedLevel,
                tutorLevel: snapshot.tutorLevel,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.mic_none_rounded,
                      label: 'Speaking turns',
                      value: '${snapshot.speakingTurns}',
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.style_outlined,
                      label: 'Deck words',
                      value: '${snapshot.deckWordsReviewed}',
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricTile(
                icon: Icons.abc_rounded,
                label: 'Unique words spoken',
                value: '${snapshot.uniqueWordsSpoken}',
                color: AppColors.primaryPurple,
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Language history',
                icon: Icons.history_rounded,
                child: snapshot.languages.isEmpty
                    ? const _EmptyHint(
                        text:
                            'Switch practice languages in Settings to build your learning history.',
                      )
                    : Column(
                        children: [
                          for (final record in snapshot.languages)
                            _LanguageHistoryCard(
                              languageLabel: service.languageLabel(
                                record.languageCode,
                              ),
                              isCurrent:
                                  record.languageCode == snapshot.practiceLanguage,
                              tutorLevel: record.tutorLevel,
                              estimatedLevel: record.estimatedLevel,
                              speakingTurns: record.speakingTurns,
                              deckWords: record.deckWordsReviewed,
                              lastActive: record.lastActiveAt,
                            ),
                        ],
                      ),
              ),
              if (snapshot.levelHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: 'Level timeline (${currentLabel})',
                  icon: Icons.timeline_rounded,
                  child: Column(
                    children: [
                      for (final entry in snapshot.levelHistory.reversed)
                        _TimelineRow(entry: entry),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.languageLabel,
    required this.estimatedLevel,
    required this.tutorLevel,
  });

  final String languageLabel;
  final String estimatedLevel;
  final String tutorLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B3DFF), Color(0xFF7A24E4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning $languageLabel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estimatedLevel,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated from speaking + decks',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AI tutor level: $tutorLevel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context))),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LanguageHistoryCard extends StatelessWidget {
  const _LanguageHistoryCard({
    required this.languageLabel,
    required this.isCurrent,
    required this.tutorLevel,
    required this.estimatedLevel,
    required this.speakingTurns,
    required this.deckWords,
    this.lastActive,
  });

  final String languageLabel;
  final bool isCurrent;
  final String tutorLevel;
  final String estimatedLevel;
  final int speakingTurns;
  final int deckWords;
  final DateTime? lastActive;

  @override
  Widget build(BuildContext context) {
    final dateLabel = lastActive != null
        ? DateFormat('MMM d, yyyy').format(lastActive!.toLocal())
        : '—';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primaryPurple.withValues(alpha: 0.12)
            : AppPageColors.fieldBgOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryPurple.withValues(alpha: 0.25)
              : AppPageColors.subtleBorderOf(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                languageLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                estimatedLevel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI tutor $tutorLevel · $speakingTurns turns · $deckWords deck words · $dateLabel',
            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final LanguageLevelHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final when = entry.recordedAt != null
        ? DateFormat('MMM d, yyyy').format(entry.recordedAt!.toLocal())
        : '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            entry.estimatedLevel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              when,
              style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppPageColors.subtitleOf(context), fontSize: 14, height: 1.45),
    );
  }
}
