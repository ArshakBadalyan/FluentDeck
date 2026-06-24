import 'package:shared_preferences/shared_preferences.dart';

/// Persisted "seen" state for first-visit coach flows.
class ScreenTutorialService {
  ScreenTutorialService._();
  static final ScreenTutorialService instance = ScreenTutorialService._();

  static const _prefsVersion = 15;

  String _key(String tutorialId) =>
      'screen_tutorial_v${_prefsVersion}_$tutorialId';

  Future<bool> isComplete(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(tutorialId)) ?? false;
  }

  Future<void> markComplete(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(tutorialId), true);
  }

  Future<void> clearCompletion(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(tutorialId));
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    for (final id in ScreenTutorialCatalog.allTutorialIds) {
      await p.remove(_key(id));
    }
  }
}

class ScreenTutorialReplayCoordinator {
  ScreenTutorialReplayCoordinator._();

  static Future<void> Function()? replayCurrentTabIntro;
  static Future<void> Function()? resetAllTabIntros;
  static int Function()? currentMainTabIndex;
  static int Function()? currentSubTabIndex;

  static Future<void> replayCurrent() async {
    final fn = replayCurrentTabIntro;
    if (fn != null) await fn();
  }

  static Future<void> resetAll() async {
    final fn = resetAllTabIntros;
    if (fn != null) await fn();
  }

  static int? readMainTabIndex() => currentMainTabIndex?.call();
  static int readSubTabIndex() => currentSubTabIndex?.call() ?? 0;
}

class ScreenTutorialStep {
  const ScreenTutorialStep({
    required this.titleKey,
    required this.bodyKey,
    this.targetId,
    this.titleVars,
    this.bodyVars,
  });

  final String titleKey;
  final String bodyKey;
  final String? targetId;
  final Map<String, dynamic>? titleVars;
  final Map<String, dynamic>? bodyVars;
}

/// Speakstack screen tours. Legacy MatheApp practice/topics tours were removed.
abstract final class ScreenTutorialCatalog {
  static const List<String> allTutorialIds = <String>[];

  static String? idForMainAndSubTab({
    required int mainIndex,
    required int subIndex,
  }) {
    return null;
  }

  static List<ScreenTutorialStep> stepsFor(String tutorialId) {
    return _steps[tutorialId] ?? const [];
  }

  static final Map<String, List<ScreenTutorialStep>> _steps = {};
}
