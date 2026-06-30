import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/models/conversation_session_model.dart';
import 'package:fluentdeck/models/conversation_turn_model.dart';
import 'package:fluentdeck/services/token_storage.dart';

const _storageKeyPrefix = 'conversation_history_v1_';

class ConversationHistoryService {
  ConversationHistoryService._();
  static final ConversationHistoryService instance = ConversationHistoryService._();

  Future<String?> _userKey() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return null;
    return '$_storageKeyPrefix$userId';
  }

  Future<List<ConversationSessionModel>> listSessions() async {
    final key = await _userKey();
    if (key == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List? ?? [];
    return list
        .whereType<Map>()
        .map(
          (m) => ConversationSessionModel.fromJson(
            Map<String, dynamic>.from(m),
          ),
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<int?> saveCurrentSession(
    List<ConversationTurnModel> turns, {
    int? sessionId,
  }) async {
    if (turns.length < 2) return null;

    final key = await _userKey();
    if (key == null) return null;

    final userId = await TokenStorage.getUserId();
    final correctionsCount = turns
        .where((t) => t.isUser)
        .fold<int>(0, (sum, t) => sum + t.corrections.length);

    final resolvedId = sessionId ?? DateTime.now().millisecondsSinceEpoch;

    final session = ConversationSessionModel(
      id: resolvedId,
      userId: userId,
      startedAt: turns.first.timestamp ?? DateTime.now(),
      transcript: List<ConversationTurnModel>.from(turns),
      correctionsCount: correctionsCount,
    );

    final sessions = await listSessions();
    final firstUserText =
        turns.where((t) => t.isUser).map((t) => t.text.trim()).firstOrNull;
    sessions.removeWhere((s) {
      if (s.id == resolvedId) return false;
      if (firstUserText == null || firstUserText.isEmpty) return false;
      final sFirst =
          s.transcript.where((t) => t.isUser).map((t) => t.text.trim()).firstOrNull;
      if (sFirst != firstUserText) return false;
      return s.startedAt.difference(session.startedAt).inMinutes.abs() < 5;
    });
    sessions.removeWhere((s) => s.id == resolvedId);
    sessions.insert(0, session);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
    return resolvedId;
  }

  Future<void> deleteSession(int sessionId) async {
    final key = await _userKey();
    if (key == null) return;

    final sessions = await listSessions()
      ..removeWhere((s) => s.id == sessionId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final key = await _userKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
