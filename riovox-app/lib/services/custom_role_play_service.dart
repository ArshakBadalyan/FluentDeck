import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_prompt_model.dart';
import '../models/speaking_session_context.dart';

class CustomRolePlayService {
  CustomRolePlayService._();
  static final CustomRolePlayService instance = CustomRolePlayService._();

  static const _prefsKey = 'custom_role_plays_v1';

  Future<List<ConversationPromptModel>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (row) => ConversationPromptModel.fromLocalJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ConversationPromptModel> create({
    required String title,
    required String userRole,
    required String tutorRole,
    required String situation,
  }) async {
    final existing = await fetchAll();
    final id = DateTime.now().millisecondsSinceEpoch;
    final prompt = ConversationPromptModel(
      id: id,
      title: title.trim(),
      scenario: situation.trim(),
      difficultyLevel: 'B1',
      category: 'custom',
      userRole: userRole.trim(),
      tutorRole: tutorRole.trim(),
      iconKey: 'theater_comedy',
      isLocal: true,
    );
    existing.insert(0, prompt);
    await _persist(existing);
    return prompt;
  }

  Future<void> delete(int id) async {
    final existing = await fetchAll();
    existing.removeWhere((p) => p.id == id);
    await _persist(existing);
  }

  Future<void> _persist(List<ConversationPromptModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toLocalJson()).toList()),
    );
  }

  SpeakingSessionContext toSessionContext(ConversationPromptModel prompt) {
    return SpeakingSessionContext(
      mode: SpeakingMode.rolePlay,
      title: prompt.displayTitle,
      referenceKey: prompt.referenceKey,
      userRole: prompt.userRole.isNotEmpty ? prompt.userRole : 'Learner',
      tutorRole:
          prompt.tutorRole.isNotEmpty ? prompt.tutorRole : 'Conversation partner',
      situation: prompt.scenario,
      scenario: prompt.scenario,
      suggestedVocabulary: prompt.suggestedVocabulary,
    );
  }
}
