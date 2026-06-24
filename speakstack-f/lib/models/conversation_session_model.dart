import 'conversation_turn_model.dart';

class ConversationSessionModel {
  final int? id;
  final int? userId;
  final DateTime startedAt;
  final List<ConversationTurnModel> transcript;
  final int correctionsCount;

  const ConversationSessionModel({
    this.id,
    this.userId,
    required this.startedAt,
    this.transcript = const [],
    this.correctionsCount = 0,
  });

  factory ConversationSessionModel.fromJson(Map<String, dynamic> json) {
    final rawTranscript = json['transcript'];
    return ConversationSessionModel(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      transcript:
          rawTranscript is List
              ? rawTranscript
                  .map(
                    (e) => ConversationTurnModel.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList()
              : const [],
      correctionsCount: json['correctionsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'userId': userId,
    'startedAt': startedAt.toIso8601String(),
    'transcript': transcript.map((t) => t.toJson()).toList(),
    'correctionsCount': correctionsCount,
  };
}
