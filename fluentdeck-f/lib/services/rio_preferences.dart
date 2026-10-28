import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    showRio.value = prefs.getBool(_key) ?? true;
    showRioStage.value = prefs.getBool(_stageKey) ?? false;
  }

  Future<void> setShowRioStage(bool value) async {
    showRioStage.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stageKey, value);
  }

  Future<void> setShowRio(bool value) async {
    showRio.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
