import 'grammar_correction.dart';

class ConversationTurnModel {
  final String speaker;
  final String text;
  final String? audioUrl;
  final String? translation;
  final List<GrammarCorrection> corrections;
  final DateTime? timestamp;

  const ConversationTurnModel({
    required this.speaker,
    required this.text,
    this.audioUrl,
    this.translation,
    this.corrections = const [],
    this.timestamp,
  });

  bool get isUser => speaker == 'user';

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    if (audioUrl != null) 'audioUrl': audioUrl,
    if (translation != null && translation!.isNotEmpty) 'translation': translation,
    'corrections': corrections.map((c) => c.toJson()).toList(),
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };

  factory ConversationTurnModel.fromJson(Map<String, dynamic> json) {
    final rawCorrections = json['corrections'];
    return ConversationTurnModel(
      speaker: json['speaker'] as String? ?? 'user',
      text: json['text'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      translation: json['translation'] as String?,
      corrections:
          rawCorrections is List
              ? rawCorrections
                  .map(
                    (e) => GrammarCorrection.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList()
              : const [],
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString())
              : null,
    );
  }
}
