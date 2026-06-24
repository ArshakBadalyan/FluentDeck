import 'package:untitled2/services/api_service.dart';

class TutorMemoryFact {
  final String fact;
  final String category;

  const TutorMemoryFact({required this.fact, required this.category});

  factory TutorMemoryFact.fromJson(Map<String, dynamic> json) {
    return TutorMemoryFact(
      fact: json['fact']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
    );
  }
}

class TutorMemoryService {
  TutorMemoryService._();
  static final TutorMemoryService instance = TutorMemoryService._();

  Future<List<TutorMemoryFact>> fetchFacts() async {
    final data = await ApiService.get('ai/memory');
    if (data is! Map) return [];
    final facts = data['facts'];
    if (facts is! List) return [];
    return facts
        .whereType<Map>()
        .map((item) => TutorMemoryFact.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.fact.trim().isNotEmpty)
        .toList();
  }

  Future<List<TutorMemoryFact>> deleteFact(int index) async {
    final data = await ApiService.delete('ai/memory?index=$index');
    if (data is! Map) return [];
    final facts = data['facts'];
    if (facts is! List) return [];
    return facts
        .whereType<Map>()
        .map((item) => TutorMemoryFact.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.fact.trim().isNotEmpty)
        .toList();
  }
}
