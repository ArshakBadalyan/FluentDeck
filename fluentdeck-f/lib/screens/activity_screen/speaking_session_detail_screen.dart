import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/models/speaking_session_record_model.dart';
import 'package:fluentdeck/routing/app_route_names.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/user_facing_api_error.dart';

class SpeakingSessionDetailScreen extends StatelessWidget {
  const SpeakingSessionDetailScreen({super.key, required this.session});

  final SpeakingSessionRecord session;

  String _formatSessionTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = session.summary.isNotEmpty ? session.summary : session.title;

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        title: Text(l10n.t('speaking-activity.session-detail.title')),
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ScoreHero(score: session.score),
          const SizedBox(height: 12),
          // Skill boxes only when the evaluation rated them (newer sessions).
          if (session.fluencyScore != null ||
              session.grammarScore != null ||
              session.vocabularyScore != null) ...[
            Row(
              children: [
                for (final (label, value) in [
                  ('Fluency', session.fluencyScore),
                  ('Grammar', session.grammarScore),
                  ('Vocabulary', session.vocabularyScore),
                ])
                  if (value != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _SkillBox(label: label, score: value),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _InfoCard(
            children: [
              _InfoRow(
                label: l10n.t('speaking-activity.session-detail.mode'),
                value: session.modeLabel,
              ),
              _InfoRow(
                label: l10n.t('speaking-activity.session-detail.completed'),
                value: _formatSessionTime(context, session.completedAt),
              ),
              if (session.durationMinutes > 0)
                _InfoRow(
                  label: l10n.t('speaking-activity.session-detail.duration'),
                  value: l10n.t(
                    'speaking-activity.session-detail.duration-minutes',
                    vars: {'minutes': session.durationMinutes},
                  ),
                ),
              if (session.turnCount > 0)
                _InfoRow(
                  label: l10n.t('speaking-activity.session-detail.turns'),
                  value: '${session.turnCount}',
                ),
            ],
          ),
          if (title.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: l10n.t('speaking-activity.session-detail.summary'),
              body: title,
            ),
          ],
          if (session.feedback.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: l10n.t('speaking-activity.session-detail.feedback'),
              body: session.feedback,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.t('speaking-activity.session-detail.transcript-hint'),
            style: TextStyle(color: AppPageColors.subtitleOf(context), height: 1.45),
          ),
        ],
      ),
    );
  }

  static Route<void> route(SpeakingSessionRecord session) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: '${AppRouteNames.speakingSessionDetail}/${session.id}',
      ),
      builder: (_) => SpeakingSessionDetailScreen(session: session),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final value = (score / 10).clamp(0.0, 1.0);
    final verdict = score >= 8
        ? 'Clear and confident'
        : score >= 5
        ? 'Good progress'
        : 'A good start';
    // Score ring beside a short verdict (Lagoon Daylight).
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.14),
                  ),
                  Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$score/10 · ${AppLocalizations.of(context).t('speaking-activity.session-detail.score')}',
                  style: TextStyle(color: AppPageColors.subtitleOf(context), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: AppPageColors.subtitleOf(context), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}

String speakingSessionLoadError(BuildContext context, Object error) {
  return AppLocalizations.of(context).t(userFacingErrorLocalizationKey(error));
}

/// One skill (Fluency / Grammar / Vocabulary) as a word plus its 0-10 score:
/// green when strong, orange when it needs work.
class _SkillBox extends StatelessWidget {
  const _SkillBox({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (word, base) = score >= 8
        ? ('Strong', const Color(0xFF2EE66B))
        : score >= 6
        ? ('Good', AppPageColors.accentOf(context))
        : ('Fair', const Color(0xFFFF8F3D));
    final ink = isDark ? base : Color.lerp(base, Colors.black, 0.45)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        children: [
          Text(word, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 2),
          Text(
            '$label · $score/10',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
          ),
        ],
      ),
    );
  }
}
