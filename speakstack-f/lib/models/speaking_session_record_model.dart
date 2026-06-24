import 'speaking_session_context.dart';

class SpeakingSessionRecord {
  final int id;
  final SpeakingMode mode;
  final String? referenceKey;
  final String title;
  final int score;
  final String feedback;
  final String summary;
  final int durationMinutes;
  final int turnCount;
  final DateTime completedAt;

  const SpeakingSessionRecord({
    required this.id,
    this.mode = SpeakingMode.chat,
    this.referenceKey,
    required this.title,
    required this.score,
    this.feedback = '',
    this.summary = '',
    this.durationMinutes = 0,
    this.turnCount = 0,
    required this.completedAt,
  });

  String get modeLabel {
    switch (mode) {
      case SpeakingMode.chat:
        return 'Chat';
      case SpeakingMode.rolePlay:
        return 'Role-Play';
      case SpeakingMode.topic:
        return 'Topics';
      case SpeakingMode.game:
        return 'Games';
      case SpeakingMode.lesson:
        return 'Lesson';
    }
  }

  String get historyTitle => summary.isNotEmpty ? summary : title;

  factory SpeakingSessionRecord.fromJson(Map<String, dynamic> json) {
    final modeRaw = json['mode']?.toString() ?? 'chat';
    SpeakingMode mode = SpeakingMode.chat;
    switch (modeRaw) {
      case 'role_play':
        mode = SpeakingMode.rolePlay;
        break;
      case 'topic':
        mode = SpeakingMode.topic;
        break;
      case 'game':
        mode = SpeakingMode.game;
        break;
      case 'lesson':
        mode = SpeakingMode.lesson;
        break;
      default:
        mode = SpeakingMode.chat;
    }

    return SpeakingSessionRecord(
      id: json['id'] as int? ?? 0,
      mode: mode,
      referenceKey: json['referenceKey'] as String?,
      title: json['title'] as String? ?? '',
      score: (json['score'] as num?)?.round() ?? 0,
      feedback: json['feedback'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.round() ?? 0,
      turnCount: (json['turnCount'] as num?)?.round() ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
