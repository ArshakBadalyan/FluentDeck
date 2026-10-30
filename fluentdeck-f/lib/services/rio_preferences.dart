import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tutor_persona.dart';

/// "Show tutor" on the conversation screen: the tutor character (Rio by
/// default) or the plain chat. A display choice, so it is kept on this device
/// only (not in the account's speaking preferences). On by default.
class RioPreferences {
  RioPreferences._();
  static final RioPreferences instance = RioPreferences._();

  static const _key = 'show_rio';

  /// Listen to this to rebuild when the switch changes.
  final ValueNotifier<bool> showRio = ValueNotifier<bool>(true);

  /// "Video-call view": Rio big with the latest reply over him, instead of
  /// the chat bubbles. Off by default (the chat is the main view).
  final ValueNotifier<bool> showRioStage = ValueNotifier<bool>(false);
  static const _stageKey = 'show_rio_stage';

  /// "Show corrections": the "Say it better" cards and inline fixes under
  /// your messages. On by default; corrections are still saved when off.
  final ValueNotifier<bool> showCorrections = ValueNotifier<bool>(true);
  static const _correctionsKey = 'show_corrections';

  /// "Your tutor": Rio (default) or one of the people, shown in the chat
  /// (avatar, reactions, video-call view).
  final ValueNotifier<TutorPersona> tutor = ValueNotifier<TutorPersona>(TutorPersona.rio);
  static const _tutorKey = 'tutor_persona';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    showRio.value = prefs.getBool(_key) ?? true;
    showRioStage.value = prefs.getBool(_stageKey) ?? false;
    showCorrections.value = prefs.getBool(_correctionsKey) ?? true;
    tutor.value = TutorPersona.byId(prefs.getString(_tutorKey));
  }

  Future<void> setTutor(TutorPersona value) async {
    tutor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tutorKey, value.id);
  }

  Future<void> setShowRioStage(bool value) async {
    showRioStage.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stageKey, value);
  }

  Future<void> setShowCorrections(bool value) async {
    showCorrections.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_correctionsKey, value);
  }

  Future<void> setShowRio(bool value) async {
    showRio.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
