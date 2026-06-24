import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/localization/app_localizations.dart';
import 'package:speakstack/models/speaking_session_record_model.dart';
import 'package:speakstack/routing/app_route_names.dart';
import 'package:speakstack/utils/user_facing_api_error.dart';

class SpeakingSessionDetailScreen extends StatelessWidget {
  const SpeakingSessionDetailScreen({super.key, required this.session});

  final SpeakingSessionRecord session;

  static const _pageBg = Color(0xFFF7F5FB);

  String _formatSessionTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = session.summary.isNotEmpty ? session.summary : session.title;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: Text(l10n.t('speaking-activity.session-detail.title')),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ScoreHero(score: session.score),
          const SizedBox(height: 12),
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
            style: TextStyle(color: Colors.grey.shade600, height: 1.45),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greenCorrect.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$score/10',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B9E4B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).t('speaking-activity.session-detail.score'),
            style: TextStyle(color: Colors.grey.shade600),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
